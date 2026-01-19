<template>
  <div class="post-form-card">
    <div class="card-head">
      <div>
        <p class="eyebrow">Nowy / Edycja wpisu</p>
        <h3>Stwórz coś fajnego</h3>
        <p class="muted">Drag & drop pliki, przełącz tryb przekierowania lub klasyczny wpis.</p>
      </div>
      <span class="badge" :class="{ success: !redirectMode, warning: redirectMode }">
        {{ redirectMode ? 'Tryb redirect' : 'Tryb wpisu' }}
      </span>
    </div>

    <form
      :action="actionUrl"
      :method="formMethod"
      enctype="multipart/form-data"
      class="form-body"
    >
      <input type="hidden" name="authenticity_token" :value="csrfToken">
      <input v-if="shouldSpoofMethod" type="hidden" name="_method" value="patch">

      <div class="toggle-row">
        <label class="toggle">
          <input type="checkbox" :checked="redirectMode" @change="setRedirectMode($event.target.checked)">
          <span class="slider"></span>
        </label>
        <div>
          <div class="toggle-label">Włącz tryb przekierowania</div>
          <div class="toggle-help">Gdy włączone, reszta pól jest ukrywana.</div>
        </div>
      </div>

      <div v-if="redirectMode" class="field">
        <label>Redirect URL</label>
        <input
          name="post[redirect_url]"
          type="url"
          v-model="form.redirectUrl"
          placeholder="https://example.com"
          required
        >
        <p class="hint">Po zapisaniu wpis przekieruje na ten adres.</p>
      </div>

      <template v-else>
        <div class="field">
          <label>Slug</label>
          <input name="post[slug]" type="text" v-model="form.slug" placeholder="np. moj-wpis-123">
          <p class="hint">Dozwolone: a-z, A-Z, 0-9, -, _, + (puste = losowy).</p>
        </div>

        <div class="field">
          <label>Tytuł</label>
          <input name="post[title]" type="text" v-model="form.title" placeholder="Krótki tytuł">
        </div>

        <div class="field">
          <label>Opis</label>
          <textarea
            name="post[description]"
            rows="4"
            v-model="form.description"
            placeholder="Treść wpisu..."
          ></textarea>
        </div>

        <div class="field">
          <label>Status</label>
          <select name="post[status]" v-model="form.status">
            <option value="public">Public</option>
            <option value="private">Private</option>
            <option value="unlisted">Unlisted</option>
          </select>
        </div>

        <div class="field">
          <label class="d-flex align-center">
            Pliki
            <span class="pill">drag & drop</span>
          </label>
          <input
            ref="fileInput"
            type="file"
            name="post[files][]"
            class="hidden-input"
            multiple
            @change="onFileSelect"
          >
          <div
            class="dropzone"
            :class="{ drag: isDragging }"
            @dragover.prevent="isDragging = true"
            @dragleave.prevent="isDragging = false"
            @drop.prevent="onDrop"
            @click="fileInput?.click()"
          >
            <div class="drop-content">
              <div class="drop-icon">⬆</div>
              <div>
                <strong>Upuść pliki tutaj</strong>
                <p class="hint">lub kliknij, aby wybrać</p>
              </div>
            </div>
            <div v-if="files.length" class="file-list">
              <div v-for="(file, index) in files" :key="file.name" class="file-chip">
                <span>{{ file.name }}</span>
                <button type="button" @click.stop="removeFile(index)">×</button>
              </div>
            </div>
          </div>
        </div>
      </template>

      <div v-if="showUsername" class="field">
        <label>Username <span class="required">(wymagane)</span></label>
        <input name="post[username]" type="text" v-model="form.username" placeholder="Twój login">
        <p class="hint">Przypisz wpis do konta.</p>
      </div>

      <button type="submit" class="submit-btn">
        {{ redirectMode ? 'Zapisz przekierowanie' : 'Zapisz wpis' }}
      </button>
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
.post-form-card {
  background: linear-gradient(135deg, #0f172a, #111827);
  border: 1px solid rgba(255,255,255,0.08);
  border-radius: 16px;
  padding: 20px;
  box-shadow: 0 20px 40px rgba(0,0,0,0.4);
  color: #e5e7eb;
}
.card-head {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 16px;
}
.eyebrow {
  text-transform: uppercase;
  letter-spacing: 0.08em;
  font-size: 12px;
  color: #93c5fd;
  margin: 0 0 4px;
}
.muted { color: #9ca3af; margin: 4px 0 0; }
.badge {
  height: fit-content;
  padding: 8px 12px;
  border-radius: 999px;
  font-size: 12px;
  border: 1px solid rgba(255,255,255,0.1);
}
.badge.success { background: rgba(52,211,153,0.1); color: #34d399; }
.badge.warning { background: rgba(251,191,36,0.1); color: #fbbf24; }
.form-body { display: flex; flex-direction: column; gap: 14px; }
.field label { display: block; margin-bottom: 6px; font-weight: 600; }
.field input, .field textarea, .field select {
  width: 100%;
  border-radius: 10px;
  border: 1px solid rgba(255,255,255,0.12);
  background: rgba(255,255,255,0.03);
  color: #e5e7eb;
  padding: 10px 12px;
  transition: border-color 0.2s, box-shadow 0.2s;
}
.field input:focus, .field textarea:focus, .field select:focus {
  outline: none;
  border-color: #60a5fa;
  box-shadow: 0 0 0 3px rgba(96,165,250,0.2);
}
.hint { font-size: 12px; color: #9ca3af; margin: 6px 0 0; }
.toggle-row { display: flex; gap: 12px; align-items: center; padding: 10px 12px; border-radius: 12px; background: rgba(255,255,255,0.04); }
.toggle { position: relative; display: inline-block; width: 46px; height: 26px; }
.toggle input { opacity: 0; width: 0; height: 0; }
.slider {
  position: absolute; cursor: pointer; top: 0; left: 0; right: 0; bottom: 0;
  background-color: #374151; transition: .2s; border-radius: 34px;
}
.slider:before {
  position: absolute; content: ""; height: 18px; width: 18px; left: 4px; bottom: 4px;
  background-color: white; transition: .2s; border-radius: 50%;
}
.toggle input:checked + .slider { background-color: #2563eb; }
.toggle input:checked + .slider:before { transform: translateX(20px); }
.dropzone {
  border: 1px dashed rgba(255,255,255,0.3);
  border-radius: 14px;
  padding: 16px;
  background: rgba(255,255,255,0.02);
  cursor: pointer;
  transition: border-color 0.2s, background 0.2s;
}
.dropzone.drag { border-color: #60a5fa; background: rgba(96,165,250,0.08); }
.drop-content { display: flex; align-items: center; gap: 12px; }
.drop-icon { font-size: 22px; width: 44px; height: 44px; display: grid; place-items: center; border-radius: 12px; background: rgba(96,165,250,0.12); color: #bfdbfe; }
.file-list { display: flex; flex-wrap: wrap; gap: 8px; margin-top: 12px; }
.file-chip {
  display: inline-flex; align-items: center; gap: 6px;
  padding: 6px 10px; border-radius: 12px;
  background: rgba(255,255,255,0.08); font-size: 13px;
}
.file-chip button {
  background: none; border: none; color: #fca5a5;
  cursor: pointer; font-size: 16px; line-height: 1;
}
.pill {
  margin-left: 8px; font-size: 11px; color: #a5b4fc;
  background: rgba(129,140,248,0.15); padding: 2px 8px; border-radius: 10px;
}
.required { color: #f87171; }
.submit-btn {
  margin-top: 6px;
  background: linear-gradient(90deg, #2563eb, #7c3aed);
  border: none;
  color: white;
  padding: 12px;
  border-radius: 12px;
  font-weight: 700;
  cursor: pointer;
  transition: transform 0.15s, box-shadow 0.15s;
}
.submit-btn:hover { transform: translateY(-1px); box-shadow: 0 10px 30px rgba(124,58,237,0.35); }
.hidden-input { display: none; }
@media (max-width: 640px) {
  .card-head { flex-direction: column; align-items: flex-start; }
}
</style>
