import { common } from '@kit.AbilityKit'
import { picker } from '@kit.CoreFileKit'
import fs from '@ohos.file.fs'

export class UploadedMaterial {
  originalUri: string = ''
  sandboxPath: string = ''
  fileName: string = ''
  extension: string = ''
  uploadedAt: string = ''
}

export class MaterialUploadHelper {
  private context: common.Context

  constructor(context: common.Context) {
    this.context = context
  }

  async selectFile(): Promise<UploadedMaterial> {
    const options = new picker.DocumentSelectOptions()
    const documentPicker = new picker.DocumentViewPicker()
    const result = await documentPicker.select(options)
    if (!result || result.length === 0) {
      throw new Error('No file selected')
    }
    const originalUri = result[0]
    const fileName = this.fileNameFromUri(originalUri)
    return this.copyPickedUri(originalUri, fileName, this.extensionFromUri(fileName))
  }

  private copyPickedUri(originalUri: string, fileName: string, extension: string): UploadedMaterial {
    const sandboxPath = this.context.filesDir + '/studyMaterial_' + Date.now().toString() + extension
    const source = fs.openSync(originalUri, fs.OpenMode.READ_ONLY)
    const target = fs.openSync(sandboxPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC)
    try {
      fs.copyFileSync(source.fd, target.fd)
    } finally {
      fs.closeSync(source.fd)
      fs.closeSync(target.fd)
    }

    const material = new UploadedMaterial()
    material.originalUri = originalUri
    material.sandboxPath = sandboxPath
    material.fileName = fileName
    material.extension = extension
    material.uploadedAt = Date.now().toString()
    return material
  }

  private fileNameFromUri(uri: string): string {
    const cleanUri = uri.split('?')[0]
    const segments = cleanUri.split('/')
    const rawName = segments.length > 0 ? segments[segments.length - 1] : ''
    if (rawName.length === 0) {
      return 'Study material'
    }
    try {
      return decodeURIComponent(rawName)
    } catch (_) {
      return rawName
    }
  }

  private extensionFromUri(uri: string): string {
    const lower = uri.toLowerCase()
    const knownExtensions: string[] = ['.pdf', '.ppt', '.pptx', '.doc', '.docx', '.txt', '.md', '.png', '.jpg', '.jpeg', '.webp']
    for (const extension of knownExtensions) {
      if (lower.endsWith(extension)) {
        return extension
      }
    }
    return '.dat'
  }
}
