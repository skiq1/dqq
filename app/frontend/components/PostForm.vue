<template>
  <div class="post-form-wrapper">
    <form
      :action="actionUrl"
      :method="formMethod"
      enctype="multipart/form-data"
      class="post-form"
      @submit.prevent="handleSubmit"
    >
      <input type="hidden" name="authenticity_token" :value="csrfToken">
      <input v-if="shouldSpoofMethod" type="hidden" name="_method" value="patch">
      <!-- Hidden inputs for direct upload signed IDs -->
      <input
        v-for="signedId in signedIds"
        :key="signedId"
        type="hidden"
        name="post[files][]"
        :value="signedId"
      >

      <!-- Redirect Mode Toggle -->
      <div class="form-group mb-2">
        <label class="form-label mb-0">
          <input
            type="checkbox"
            class="form-check-input"
            :checked="redirectMode"
            @change="setRedirectMode($event.target.checked)"
          >
          Enable Redirect Only Mode
        </label>
        <small class="form-text d-block mt-0">If checked, other fields will be ignored.</small>
      </div>

      <!-- Redirect URL Field -->
      <div v-if="redirectMode" class="form-group mb-2">
        <label for="redirect_url" class="form-label">Redirect URL</label>
        <input
          id="redirect_url"
          name="post[redirect_url]"
          type="url"
          v-model="form.redirectUrl"
          class="form-control"
          placeholder="https://example.com"
          required
        >
        <small class="form-text d-block">If filled, this post will redirect instead of displaying content.</small>
      </div>

      <!-- Post Fields -->
      <template v-else>
        <!-- Slug Field -->
        <div class="form-group mb-2">
          <label for="slug" class="form-label">Slug</label>
          <input
            id="slug"
            name="post[slug]"
            type="text"
            v-model="form.slug"
            class="form-control"
            placeholder="leave blank to random string"
          >
          <small class="form-text d-block">Allowed characters: a-z A-Z 0-9 - _ +</small>
        </div>

        <!-- Title Field -->
        <div class="form-group mb-2">
          <label for="title" class="form-label">Post</label>
          <input
            id="title"
            name="post[title]"
            type="text"
            v-model="form.title"
            class="form-control"
            placeholder="Enter post title"
          >
        </div>

        <!-- Description Field -->
        <div class="form-group mb-2">
          <!-- <label for="description" class="form-label">Description</label> -->
          <textarea
            id="description"
            name="post[description]"
            v-model="form.description"
            class="form-control"
            rows="4"
            placeholder="Enter post content..."
          ></textarea>
        </div>

        <!-- Status Field -->
        <div class="form-group mb-2">
          <!-- <label for="status" class="form-label">Status</label> -->
          <select id="status" name="post[status]" v-model="form.status" class="form-select">
            <option value="public">Public</option>
            <option value="private">Private</option>
            <option value="unlisted">Unlisted</option>
          </select>
        </div>

        <!-- File Upload Field -->
        <div class="form-group mb-2">
          <label for="files" class="form-label">Files</label>
          <input
            ref="fileInput"
            id="files"
            type="file"
            class="d-none"
            multiple
            @change="onFileSelect"
          >
          <div
            class="dropzone"
            :class="{ 'dropzone-drag': isDragging, 'dropzone-uploading': isUploading }"
            @dragover.prevent="isDragging = true"
            @dragleave.prevent="isDragging = false"
            @drop.prevent="onDrop"
            @click="!isUploading && fileInput?.click()"
          >
            <div class="dropzone-content">
              <i class="fas fa-cloud-upload-alt dropzone-icon"></i>
              <div>
                <strong>Drag and drop files here</strong>
                <small class="form-text d-block">or click to select files</small>
              </div>
            </div>

            <!-- Overall Progress Bar -->
            <div v-if="isUploading" class="upload-progress-overall mt-3">
              <div class="progress-label">
                <span>Uploading files...</span>
                <span>{{ totalProgress }}%</span>
              </div>
              <div class="progress">
                <div
                  class="progress-bar progress-bar-striped progress-bar-animated"
                  role="progressbar"
                  :style="{ width: totalProgress + '%' }"
                  :aria-valuenow="totalProgress"
                  aria-valuemin="0"
                  aria-valuemax="100"
                ></div>
              </div>
            </div>

            <!-- File List with Individual Progress -->
            <div v-if="uploads.length" class="file-chips mt-3">
              <div
                v-for="(upload, index) in uploads"
                :key="upload.id"
                class="file-chip"
                :class="{
                  'file-chip-uploading': upload.status === 'uploading',
                  'file-chip-completed': upload.status === 'completed',
                  'file-chip-error': upload.status === 'error'
                }"
              >
                <i :class="getFileIcon(upload)"></i>
                <div class="file-chip-content">
                  <span class="file-name">{{ upload.file.name }}</span>
                  <span class="file-size">{{ formatFileSize(upload.file.size) }}</span>
                  <!-- Individual Progress Bar -->
                  <div v-if="upload.status === 'uploading'" class="file-progress">
                    <div class="progress progress-sm">
                      <div
                        class="progress-bar"
                        role="progressbar"
                        :style="{ width: upload.progress + '%' }"
                      ></div>
                    </div>
                    <span class="progress-text">{{ upload.progress }}%</span>
                  </div>
                  <span v-if="upload.status === 'completed'" class="file-status text-success">
                    <i class="fas fa-check"></i> Uploaded
                  </span>
                  <span v-if="upload.status === 'error'" class="file-status text-danger">
                    <i class="fas fa-exclamation-triangle"></i> {{ upload.error }}
                  </span>
                </div>
                <button
                  v-if="upload.status !== 'uploading'"
                  type="button"
                  class="file-chip-remove"
                  @click.stop="removeUpload(index)"
                  title="Remove file"
                >
                  ×
                </button>
              </div>
            </div>
          </div>
        </div>
      </template>

      <!-- Username Field -->
      <div v-if="showUsername" class="form-group mb-2">
        <label for="username" class="form-label">
          Username <span class="text-danger">(required)</span>
        </label>
        <input
          id="username"
          name="post[username]"
          type="text"
          v-model="form.username"
          class="form-control"
          placeholder="Assign post to account"
        >
        <small class="form-text d-block">Assign post to an account</small>
      </div>

      <!-- Submit Button -->
      <div class="d-grid gap-2">
        <button
          type="submit"
          class="btn btn-primary"
          :disabled="isUploading || isSubmitting"
        >
          <span v-if="isUploading">
            <i class="fas fa-spinner fa-spin"></i> Uploading files...
          </span>
          <span v-else-if="isSubmitting">
            <i class="fas fa-spinner fa-spin"></i> Saving...
          </span>
          <span v-else>
            {{ redirectMode ? 'Save Redirect' : 'Save Post' }}
          </span>
        </button>
      </div>
    </form>
  </div>
</template>

<script setup>
import { computed, reactive, ref, onMounted } from 'vue'
import { useDirectUpload } from '../composables/useDirectUpload'

const props = defineProps({
  actionUrl: { type: String, default: '/manage/posts' },
  httpMethod: { type: String, default: 'POST' },
  initialPost: { type: Object, default: () => ({}) },
  initialFiles: { type: Array, default: () => [] },
  requireUsername: { type: [Boolean, String], default: false }
})

const normalizeBool = value => value === true || value === 'true'
const fileInput = ref(null)
const formRef = ref(null)
const isDragging = ref(false)
const isSubmitting = ref(false)

// Direct upload composable
const {
  uploads,
  isUploading,
  totalProgress,
  signedIds,
  hasErrors,
  allCompleted,
  addFilesAndUpload,
  addCompletedFiles,
  removeFile: removeUpload,
  clearUploads
} = useDirectUpload()

const base = props.initialPost || {}
const form = reactive({
  slug: base.slug || '',
  title: base.title || '',
  description: base.description || '',
  status: base.status || 'public',
  redirectUrl: base.redirect_url || '',
  username: base.username || ''
})

// Initialize with previously uploaded files (after validation error)
onMounted(() => {
  if (props.initialFiles && props.initialFiles.length > 0) {
    addCompletedFiles(props.initialFiles)
  }
})

const redirectMode = ref(!!form.redirectUrl)
const csrfToken = computed(() => document.querySelector('meta[name="csrf-token"]')?.content || '')
const showUsername = computed(() => normalizeBool(props.requireUsername))
const shouldSpoofMethod = computed(() => props.httpMethod?.toUpperCase() === 'PATCH')
const formMethod = computed(() => (shouldSpoofMethod.value ? 'post' : props.httpMethod || 'post'))

const onDrop = event => {
  if (isUploading.value) return
  const dropped = Array.from(event.dataTransfer?.files || [])
  if (dropped.length) addFilesAndUpload(dropped)
  isDragging.value = false
}

const onFileSelect = event => {
  const picked = Array.from(event.target.files || [])
  addFilesAndUpload(picked)
  // Reset input so same file can be selected again
  event.target.value = ''
}

const setRedirectMode = enabled => {
  redirectMode.value = enabled
  if (enabled) {
    form.title = ''
    form.description = ''
    form.status = 'public'
    clearUploads()
  } else {
    form.redirectUrl = ''
  }
}

// Helper functions for file display
const formatFileSize = (bytes) => {
  if (bytes === 0) return '0 Bytes'
  const k = 1024
  const sizes = ['Bytes', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
}

const getFileIcon = (upload) => {
  if (upload.status === 'uploading') return 'fas fa-spinner fa-spin'
  if (upload.status === 'completed') return 'fas fa-check-circle text-success'
  if (upload.status === 'error') return 'fas fa-exclamation-circle text-danger'
  return 'fas fa-file'
}

// Handle form submission
const handleSubmit = async (event) => {
  const formEl = event.target

  // Check if uploads are still in progress
  if (isUploading.value) {
    alert('Please wait for files to finish uploading.')
    return
  }

  // Check if there are upload errors
  if (hasErrors.value) {
    alert('Some files failed to upload. Please remove failed files and try again.')
    return
  }

  // Submit the form (files are already uploaded)
  isSubmitting.value = true

  // Use native form submission (for Turbo compatibility)
  formEl.submit()
}
</script>

<style scoped>
.post-form-wrapper {
  width: 100%;

}

.post-form {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.form-group label {
  margin-bottom: 0.5rem;
  font-weight: 500;
  color: #f8f9fa;
}

.form-control,
.form-select {
  background-color: #2c3035;
  border: 1px solid #495057;
  color: #f8f9fa;
  transition: all 0.2s ease-in-out;
}

.form-control::placeholder {
  color: #adb5bd;
}

.form-control:focus,
.form-select:focus {
  background-color: #2c3035;
  color: #f8f9fa;
  border-color: #0d6efd;
  box-shadow: 0 0 0 0.25rem rgba(13, 110, 253, 0.25);
}

.form-check-input {
  background-color: #2c3035;
  border: 1px solid #495057;
  cursor: pointer;
}

.form-check-input:checked {
  background-color: #0d6efd;
  border-color: #0d6efd;
}

.form-text {
  color: #adb5bd !important;
  font-size: 0.8rem;
}

.dropzone {
  border: 2px dashed #495057;
  border-radius: 5px;
  padding: 0.5rem;
  background-color: #2c3035;
  cursor: pointer;
  transition: all 0.2s ease-in-out;
  text-align: center;
  min-height: 50px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 1rem;
}

.dropzone:hover {
  border-color: #0d6efd;
  background-color: rgba(13, 110, 253, 0.05);
}

.dropzone-drag {
  border-color: #0d6efd;
  background-color: rgba(13, 110, 253, 0.1);
}

.dropzone-uploading {
  cursor: not-allowed;
  opacity: 0.8;
}

.dropzone-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.75rem;
  pointer-events: none;
}

.dropzone-icon {
  font-size: 2.5rem;
  color: #0d6efd;
}

.dropzone strong {
  color: #f8f9fa;
  display: block;
}

/* Overall upload progress */
.upload-progress-overall {
  width: 100%;
  padding: 0 1rem;
}

.upload-progress-overall .progress-label {
  display: flex;
  justify-content: space-between;
  margin-bottom: 0.25rem;
  font-size: 0.875rem;
  color: #f8f9fa;
}

.upload-progress-overall .progress {
  height: 0.5rem;
  background-color: #495057;
  border-radius: 0.25rem;
  overflow: hidden;
}

.upload-progress-overall .progress-bar {
  background-color: #0d6efd;
  transition: width 0.15s ease-in-out;
}

.file-chips {
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem;
  justify-content: center;
  width: 100%;
}

.file-chip {
  display: inline-flex;
  align-items: flex-start;
  gap: 0.5rem;
  padding: 0.5rem 0.75rem;
  background-color: #495057;
  border-radius: 5px;
  font-size: 0.875rem;
  color: #f8f9fa;
  word-break: break-word;
  max-width: 100%;
  min-width: 200px;
  transition: all 0.2s ease-in-out;
}

.file-chip-uploading {
  border: 1px solid #0d6efd;
}

.file-chip-completed {
  border: 1px solid #198754;
  background-color: rgba(25, 135, 84, 0.1);
}

.file-chip-error {
  border: 1px solid #dc3545;
  background-color: rgba(220, 53, 69, 0.1);
}

.file-chip > i {
  color: #0d6efd;
  flex-shrink: 0;
  margin-top: 0.15rem;
}

.file-chip-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 0.15rem;
  min-width: 0;
}

.file-name {
  word-break: break-word;
  max-width: 300px;
  font-weight: 500;
}

.file-size {
  font-size: 0.75rem;
  color: #adb5bd;
}

.file-progress {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-top: 0.25rem;
}

.file-progress .progress {
  flex: 1;
  height: 4px;
  background-color: #6c757d;
  border-radius: 2px;
  overflow: hidden;
}

.file-progress .progress-bar {
  background-color: #0d6efd;
  transition: width 0.1s ease-in-out;
}

.file-progress .progress-text {
  font-size: 0.7rem;
  color: #adb5bd;
  min-width: 35px;
  text-align: right;
}

.file-status {
  font-size: 0.75rem;
  display: flex;
  align-items: center;
  gap: 0.25rem;
}

.file-chip-remove {
  background: none;
  border: none;
  color: #adb5bd;
  cursor: pointer;
  font-size: 1.25rem;
  line-height: 1;
  padding: 0;
  flex-shrink: 0;
  transition: color 0.2s;
}

.file-chip-remove:hover {
  color: #f8f9fa;
}

.btn-primary {
  background-color: #0d6efd;
  border-color: #0d6efd;
  font-weight: 500;
  padding: 0.5rem 1rem;
}

.btn-primary:hover {
  background-color: #0b5ed7;
  border-color: #0a58ca;
}

.text-danger {
  color: #dc3545 !important;
}

@media (max-width: 768px) {
  .post-form {
    gap: 0.25rem;
  }

  .dropzone {
    padding: 0.5rem;
    min-height: 0px;
  }

  .dropzone-icon {
    font-size: 2rem;
  }
}
</style>
