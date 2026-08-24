import fs from '@ohos.file.fs'
import { image } from '@kit.ImageKit'
import { textRecognition } from '@kit.CoreVisionKit'
import { PdfExtractQuestionAnswer, PdfExtractResponse, PdfTextBackendService } from './PdfTextBackendService'

class CoreVisionInfo implements textRecognition.VisionInfo {
  pixelMap: image.PixelMap

  constructor(pixelMap: image.PixelMap) {
    this.pixelMap = pixelMap
  }
}

class CoreVisionTextConfig implements textRecognition.TextRecognitionConfiguration {
  isDirectionDetectionSupported: boolean = true
}

export class DocumentTextResult {
  text: string = ''
  status: string = 'empty'
  error: string = ''
  qaPairs: DocumentQuestionAnswer[] = []
}

export class DocumentQuestionAnswer {
  question: string = ''
  answer: string = ''
}

export class DocumentTextExtractor {
  async extract(path: string, extension: string, fileName: string = ''): Promise<DocumentTextResult> {
    const result = new DocumentTextResult()
    const normalizedExtension = extension.toLowerCase()
    try {
      if (this.isImageExtension(normalizedExtension)) {
        result.text = await this.extractTextFromImage(path)
      } else if (this.isPlainTextExtension(normalizedExtension)) {
        result.text = fs.readTextSync(path).trim()
      } else if (normalizedExtension === '.pdf') {
        const backend = new PdfTextBackendService()
        const extracted: PdfExtractResponse = await backend.extractPdfText(path, fileName.length > 0 ? fileName : 'document.pdf')
        result.text = extracted.text.trim()
        result.qaPairs = this.normalizeQaPairs(extracted.qaPairs)
      } else {
        result.status = 'unsupported'
        result.error = 'Text extraction is currently supported for images, TXT, Markdown, and PDF files.'
        return result
      }

      if (result.text.trim().length === 0) {
        result.status = 'empty'
        result.error = 'No text was extracted from this document.'
      } else {
        result.text = result.text.trim()
        result.status = 'ready'
      }
    } catch (err) {
      result.status = 'failed'
      result.error = JSON.stringify(err)
    }
    return result
  }

  private async extractTextFromImage(path: string): Promise<string> {
    const file = fs.openSync(path, fs.OpenMode.READ_ONLY)
    try {
      const source = image.createImageSource(file.fd)
      const pixelMap = await source.createPixelMap({ editable: false })
      const visionInfo = new CoreVisionInfo(pixelMap)
      const config = new CoreVisionTextConfig()
      const result = await textRecognition.recognizeText(visionInfo, config)
      return result.value.trim()
    } finally {
      fs.closeSync(file.fd)
    }
  }

  private isImageExtension(extension: string): boolean {
    return extension === '.png' || extension === '.jpg' || extension === '.jpeg' || extension === '.webp'
  }

  private isPlainTextExtension(extension: string): boolean {
    return extension === '.txt' || extension === '.md'
  }

  private normalizeQaPairs(pairs: PdfExtractQuestionAnswer[]): DocumentQuestionAnswer[] {
    const result: DocumentQuestionAnswer[] = []
    if (!Array.isArray(pairs)) {
      return result
    }
    for (let index = 0; index < pairs.length; index++) {
      const pair = pairs[index]
      if (pair.question.trim().length < 3 || pair.answer.trim().length === 0) {
        continue
      }
      const normalized = new DocumentQuestionAnswer()
      normalized.question = pair.question.trim()
      normalized.answer = pair.answer.trim()
      result.push(normalized)
    }
    return result
  }
}
