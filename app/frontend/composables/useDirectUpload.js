import { DirectUpload } from '@rails/activestorage'
import { ref, computed } from 'vue'

/**
 * Composable for handling Active Storage direct uploads with progress tracking
 * @param {string} directUploadUrl - URL for direct upload endpoint (default: '/rails/active_storage/direct_uploads')
 */
export function useDirectUpload(directUploadUrl = '/rails/active_storage/direct_uploads') {
  const uploads = ref([]) // Array of { id, file, progress, status, signedId, error }
  const isUploading = ref(false)
  let nextId = 1 // Unique ID counter for uploads

  const totalProgress = computed(() => {
    if (uploads.value.length === 0) return 0
    const sum = uploads.value.reduce((acc, u) => acc + (u.progress || 0), 0)
    return Math.round(sum / uploads.value.length)
  })

  const completedUploads = computed(() =>
    uploads.value.filter(u => u.status === 'completed')
  )

  const signedIds = computed(() =>
    completedUploads.value.map(u => u.signedId).filter(Boolean)
  )

  const hasErrors = computed(() =>
    uploads.value.some(u => u.status === 'error')
  )

  const allCompleted = computed(() =>
    uploads.value.length > 0 && uploads.value.every(u => u.status === 'completed')
  )

  /**
   * Add files to the upload queue (without uploading yet)
   * @param {File[]} files - Array of File objects
   */
  const addFiles = (files) => {
    const newUploads = Array.from(files).map(file => ({
      id: nextId++,
      file,
      progress: 0,
      status: 'pending', // pending, uploading, completed, error
      signedId: null,
      error: null
    }))
    uploads.value = [...uploads.value, ...newUploads]
    return newUploads
  }

  /**
   * Add files and immediately start uploading them
   * @param {File[]} files - Array of File objects
   * @returns {Promise<string[]>} - Array of signed IDs
   */
  const addFilesAndUpload = async (files) => {
    const newUploads = addFiles(files)

    // Upload new files immediately (in parallel for speed)
    isUploading.value = true

    try {
      const promises = newUploads.map(uploadItem =>
        uploadFile(uploadItem).catch(error => {
          console.error('Upload error:', error)
          return null
        })
      )

      const results = await Promise.all(promises)
      return results.filter(Boolean)
    } finally {
      isUploading.value = false
    }
  }

  /**
   * Add already completed uploads (e.g., after form validation error)
   * @param {Array} completedFiles - Array of { signed_id, filename, byte_size }
   */
  const addCompletedFiles = (completedFiles) => {
    const newUploads = completedFiles.map(file => ({
      id: nextId++,
      file: { name: file.filename, size: file.byte_size }, // Mock file object for display
      progress: 100,
      status: 'completed',
      signedId: file.signed_id,
      error: null
    }))
    uploads.value = [...uploads.value, ...newUploads]
    return newUploads
  }

  /**
   * Remove a file from the upload queue
   * @param {number} index - Index of the file to remove
   */
  const removeFile = (index) => {
    const copy = [...uploads.value]
    copy.splice(index, 1)
    uploads.value = copy
  }

  /**
   * Clear all uploads
   */
  const clearUploads = () => {
    uploads.value = []
  }

  /**
   * Upload a single file with progress tracking
   * @param {Object} uploadItem - Upload item from uploads array
   * @returns {Promise<string>} - Signed ID of the uploaded blob
   */
  const uploadFile = (uploadItem) => {
    return new Promise((resolve, reject) => {
      const uploadId = uploadItem.id

      // Helper to update upload by ID
      const updateUpload = (updates) => {
        const index = uploads.value.findIndex(u => u.id === uploadId)
        if (index !== -1) {
          uploads.value = uploads.value.map((u, i) =>
            i === index ? { ...u, ...updates } : u
          )
        }
      }

      updateUpload({ status: 'uploading' })

      const delegate = {
        directUploadWillStoreFileWithXHR(request) {
          request.upload.addEventListener('progress', (event) => {
            if (event.lengthComputable) {
              updateUpload({ progress: Math.round((event.loaded / event.total) * 100) })
            }
          })
        }
      }

      const upload = new DirectUpload(uploadItem.file, directUploadUrl, delegate)

      upload.create((error, blob) => {
        if (error) {
          updateUpload({ status: 'error', error: error.message || 'Upload failed' })
          reject(error)
        } else {
          updateUpload({ status: 'completed', progress: 100, signedId: blob.signed_id })
          resolve(blob.signed_id)
        }
      })
    })
  }

  /**
   * Upload all pending files
   * @returns {Promise<string[]>} - Array of signed IDs
   */
  const uploadAllFiles = async () => {
    isUploading.value = true
    const results = []

    const pendingUploads = uploads.value.filter(u => u.status === 'pending')

    try {
      // Upload files sequentially to show individual progress
      for (const uploadItem of pendingUploads) {
        try {
          const signedId = await uploadFile(uploadItem)
          results.push(signedId)
        } catch (error) {
          console.error('Upload error:', error)
          // Continue with other files even if one fails
        }
      }

      return results
    } finally {
      isUploading.value = false
    }
  }

  /**
   * Upload files in parallel (faster, but progress is less precise)
   * @returns {Promise<string[]>} - Array of signed IDs
   */
  const uploadAllFilesParallel = async () => {
    isUploading.value = true

    const pendingUploads = uploads.value.filter(u => u.status === 'pending')

    try {
      const promises = pendingUploads.map(uploadItem =>
        uploadFile(uploadItem).catch(error => {
          console.error('Upload error:', error)
          return null
        })
      )

      const results = await Promise.all(promises)
      return results.filter(Boolean)
    } finally {
      isUploading.value = false
    }
  }

  return {
    uploads,
    isUploading,
    totalProgress,
    completedUploads,
    signedIds,
    hasErrors,
    allCompleted,
    addFiles,
    addFilesAndUpload,
    addCompletedFiles,
    removeFile,
    clearUploads,
    uploadFile,
    uploadAllFiles,
    uploadAllFilesParallel
  }
}
