import fs from '@ohos.file.fs'
import http from '@ohos.net.http'
import util from '@ohos.util'
import { buildPdfExtractUrl } from './BackendConfig'

class PdfExtractRequest {
  fileName: string = ''
  fileBase64: string = ''

  constructor(fileName: string, fileBase64: string) {
    this.fileName = fileName
    this.fileBase64 = fileBase64
  }
}

export class PdfExtractResponse {
  fileName: string = ''
  method: string = ''
  pageCount: number = 0
  textLength: number = 0
  status: string = ''
  text: string = ''
  qaPairs: PdfExtractQuestionAnswer[] = []
}

export class PdfExtractQuestionAnswer {
  question: string = ''
  answer: string = ''
}

export class PdfTextBackendService {
  async extractPdfText(path: string, fileName: string): Promise<PdfExtractResponse> {
    const fileBase64 = this.readFileAsBase64(path)
    const requestBody = new PdfExtractRequest(fileName, fileBase64)
    const request = http.createHttp()
    try {
      console.info('[StudyOralPdfBackend] extract request url=' + buildPdfExtractUrl())
      const response = await request.request(buildPdfExtractUrl(), {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        extraData: JSON.stringify(requestBody),
        expectDataType: http.HttpDataType.STRING,
        readTimeout: 120000,
        connectTimeout: 15000
      })

      if (response.responseCode !== 200) {
        throw new Error('PDF backend extraction failed: ' + response.responseCode.toString() + ' ' +
        response.result.toString())
      }

      return JSON.parse(response.result.toString()) as PdfExtractResponse
    } finally {
      request.destroy()
    }
  }

  private readFileAsBase64(path: string): string {
    const file = fs.openSync(path, fs.OpenMode.READ_ONLY)
    try {
      const stat = fs.statSync(file.fd)
      const size = Number(stat.size)
      const rawBuffer = new ArrayBuffer(size)
      const readSize = fs.readSync(file.fd, rawBuffer)
      const bytes = new Uint8Array(rawBuffer, 0, readSize)
      const helper = new util.Base64Helper()
      return helper.encodeToStringSync(bytes)
    } finally {
      fs.closeSync(file.fd)
    }
  }
}
