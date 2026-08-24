import http from '@ohos.net.http'
import { buildAnswerEvaluateUrl } from './BackendConfig'

class AnswerEvaluateRequest {
  question: string = ''
  referenceAnswer: string = ''
  userAnswer: string = ''

  constructor(question: string, referenceAnswer: string, userAnswer: string) {
    this.question = question
    this.referenceAnswer = referenceAnswer
    this.userAnswer = userAnswer
  }
}

export class AnswerEvaluateResponse {
  available: boolean = false
  verdict: string = 'unknown'
  adjustment: number = 0
  feedback: string = ''
}

export class AnswerEvaluationBackendService {
  async evaluate(question: string, referenceAnswer: string, userAnswer: string): Promise<AnswerEvaluateResponse | null> {
    const request = http.createHttp()
    try {
      const response = await request.request(buildAnswerEvaluateUrl(), {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        extraData: JSON.stringify(new AnswerEvaluateRequest(question, referenceAnswer, userAnswer)),
        expectDataType: http.HttpDataType.STRING,
        readTimeout: 20000,
        connectTimeout: 8000
      })

      if (response.responseCode !== 200) {
        return null
      }
      return JSON.parse(response.result.toString()) as AnswerEvaluateResponse
    } finally {
      request.destroy()
    }
  }
}
