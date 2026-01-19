<template>
  <div class="post-form-wrapper">
    <form
      :action="actionUrl"
      :method="formMethod"
      enctype="multipart/form-data"
      class="post-form"
    >
      <input type="hidden" name="authenticity_token" :value="csrfToken">
      <input v-if="shouldSpoofMethod" type="hidden" name="_method" value="patch">

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
            name="post[files][]"
            class="d-none"
            multiple
            @change="onFileSelect"
          >
          <div
            class="dropzone"
            :class="{ 'dropzone-drag': isDragging }"
            @dragover.prevent="isDragging = true"
            @dragleave.prevent="isDragging = false"
            @drop.prevent="onDrop"
            @click="fileInput?.click()"
          >
            <div class="dropzone-content">
              <i class="fas fa-cloud-upload-alt dropzone-icon"></i>
              <div>
                <strong>Drag and drop files here</strong>
                <small class="form-text d-block">or click to select files</small>
              </div>
            </div>

            <!-- File List -->
            <div v-if="files.length" class="file-chips mt-3">
              <div v-for="(file, index) in files" :key="file.name" class="file-chip">
                <i class="fas fa-file"></i>
                <span class="file-name">{{ file.name }}</span>
                <button
                  type="button"
                  class="file-chip-remove"
                  @click.stop="removeFile(index)"
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
        <button type="submit" class="btn btn-primary">
          {{ redirectMode ? 'Save Redirect' : 'Save Post' }}
        </button>
      </div>
    </form>
  </div>
</template>

<script setup>
import { computed, reactive, ref } from 'vue'

const props = defineProps({
  actionUrl: { type: String, default: '/posts' },
  httpMethod: { type: String, default: 'POST' },
  initialPost: { type: Object, default: () => ({}) },
  requireUsername: { type: [Boolean, String], default: false }
})

const normalizeBool = value => value === true || value === 'true'
const fileInput = ref(null)
const isDragging = ref(false)
const files = ref([])

const base = props.initialPost || {}
const form = reactive({
  slug: base.slug || '',
  title: base.title || '',
  description: base.description || '',
  status: base.status || 'public',
  redirectUrl: base.redirect_url || '',
  username: base.username || ''
})

const redirectMode = ref(!!form.redirectUrl)
const csrfToken = computed(() => document.querySelector('meta[name="csrf-token"]')?.content || '')
const showUsername = computed(() => normalizeBool(props.requireUsername))
const shouldSpoofMethod = computed(() => props.httpMethod?.toUpperCase() === 'PATCH')
const formMethod = computed(() => (shouldSpoofMethod.value ? 'post' : props.httpMethod || 'post'))

const syncFileInput = newFiles => {
  files.value = newFiles
  if (!fileInput.value || typeof DataTransfer === 'undefined') return
  const dt = new DataTransfer()
  newFiles.forEach(file => dt.items.add(file))
  fileInput.value.files = dt.files
}

const onDrop = event => {
  const dropped = Array.from(event.dataTransfer?.files || [])
  if (dropped.length) syncFileInput(dropped)
  isDragging.value = false
}

const onFileSelect = event => {
  const picked = Array.from(event.target.files || [])
  syncFileInput(picked)
}

const removeFile = index => {
  const copy = [ ...files.value ]
  copy.splice(index, 1)
  syncFileInput(copy)
}

const setRedirectMode = enabled => {
  redirectMode.value = enabled
  if (enabled) {
    form.title = ''
    form.description = ''
    form.status = 'public'
    syncFileInput([])
  } else {
    form.redirectUrl = ''
  }
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

.file-chips {
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem;
  justify-content: center;
}

.file-chip {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 0.75rem;
  background-color: #495057;
  border-radius: 5px;
  font-size: 0.875rem;
  color: #f8f9fa;
  word-break: break-word;
  max-width: 100%;
}

.file-chip i {
  color: #0d6efd;
  flex-shrink: 0;
}

.file-name {
  flex: 1;
  word-break: break-word;
  max-width: 300px;
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
