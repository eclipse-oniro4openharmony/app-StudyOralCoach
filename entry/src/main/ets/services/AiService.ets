import { AnswerEvaluationBackendService, AnswerEvaluateResponse } from './AnswerEvaluationBackendService'

export class EvaluationResult {
  clarityScore: number = 0
  structureScore: number = 0
  completenessScore: number = 0
  accuracyScore: number = 0
  confidenceScore: number = 0
  overallScore: number = 0
  feedback: string = ''
  modelAnswer: string = ''
}

export class AiService {
  private static instance: AiService
  private answerBackend: AnswerEvaluationBackendService = new AnswerEvaluationBackendService()

  static getInstance(): AiService {
    if (!AiService.instance) {
      AiService.instance = new AiService()
    }
    return AiService.instance
  }

  async generateQuestion(topicTitle: string): Promise<string> {
    const prompts: string[] = [
      'Please explain the key concepts of ' + topicTitle + ' in your own words.',
      'What are the main arguments for ' + topicTitle + '? Provide a structured response.',
      'Describe the methodology used in ' + topicTitle + '. What are its strengths and weaknesses?',
      'How does ' + topicTitle + ' relate to current trends in the field?',
      'Critically analyze the impact of ' + topicTitle + ' on modern practices.',
      'What are the common challenges in ' + topicTitle + '? How would you address them?',
      'Compare and contrast different approaches to ' + topicTitle + '.',
      'What future developments do you expect in ' + topicTitle + '?',
      'Explain the practical applications of ' + topicTitle + '.',
      'What questions might an examiner ask about ' + topicTitle + '? Answer them.'
    ]
    const index = Math.floor(Math.random() * prompts.length)
    return prompts[index]
  }

  async generateFollowUp(userAnswer: string, topicTitle: string): Promise<string> {
    const answerPreview = userAnswer.substring(0, 50)
    const followUps: string[] = [
      'Can you elaborate on the point about "' + answerPreview + '..."?',
      'That is interesting. What evidence supports this view?',
      'How would you respond to someone who disagrees with your perspective?',
      'Could you provide a specific example to illustrate your point?',
      'What are the limitations of the approach you described?',
      'How does this connect to the broader context of ' + topicTitle + '?',
      'What alternative perspectives should be considered?',
      'Can you summarize your answer in three key points?'
    ]
    const index = Math.floor(Math.random() * followUps.length)
    return followUps[index]
  }

  private importantTerms(text: string): string[] {
    const commonWords: string[] = [
      'the', 'and', 'for', 'that', 'this', 'with', 'from', 'are', 'was', 'were', 'you', 'your', 'they',
      'their', 'have', 'has', 'had', 'not', 'but', 'can', 'will', 'would', 'should', 'could', 'about',
      'into', 'than', 'then', 'when', 'where', 'what', 'which', 'because', 'answer', 'question', 'is',
      'it', 'a', 'an', 'of', 'to', 'in', 'on', 'as', 'by'
    ]
    const matches = text.toLowerCase().match(/[a-z0-9]+|[\u4e00-\u9fa5]/g)
    if (matches === null) {
      return []
    }
    const terms: string[] = []
    matches.forEach((term: string) => {
      if (term.length > 2 && commonWords.indexOf(term) < 0 && terms.indexOf(term) < 0) {
        terms.push(term)
      }
    })
    return terms
  }

  private normalizedText(text: string): string {
    return text.toLowerCase().replace(/[^a-z0-9\u4e00-\u9fa5 ]/g, ' ').replace(/\s+/g, ' ').trim()
  }

  private exactAnswerScore(userAnswer: string, referenceAnswer: string): number {
    const normalizedUser = this.normalizedText(userAnswer)
    const normalizedReference = this.normalizedText(referenceAnswer)
    if (normalizedReference.length === 0 || normalizedUser.length === 0) {
      return 0
    }
    if (normalizedUser === normalizedReference) {
      return 100
    }
    const referenceTerms = this.importantTerms(referenceAnswer)
    const userTerms = this.importantTerms(userAnswer)
    if (normalizedUser.indexOf(normalizedReference) >= 0 &&
      userTerms.length > 0 &&
      userTerms.every((term: string) => referenceTerms.indexOf(term) >= 0)) {
      return 100
    }
    return 0
  }

  private isCertainAnswer(referenceAnswer: string): boolean {
    const normalized = this.normalizedText(referenceAnswer)
    if (normalized.length === 0) {
      return false
    }
    const terms = this.importantTerms(referenceAnswer)
    if (terms.length <= 3 && normalized.length <= 60) {
      return true
    }
    if (/^(yes|no|true|false|正确|错误|是|否)$/i.test(normalized)) {
      return true
    }
    if (/^[0-9]{1,4}$/.test(normalized)) {
      return true
    }
    return false
  }

  private overlapScore(userAnswer: string, referenceAnswer: string): number {
    const referenceTerms = this.importantTerms(referenceAnswer)
    const userTerms = this.importantTerms(userAnswer)
    if (referenceTerms.length === 0 || userTerms.length === 0) {
      return this.exactAnswerScore(userAnswer, referenceAnswer)
    }
    let matchedReference = 0
    referenceTerms.forEach((term: string) => {
      if (userTerms.indexOf(term) >= 0) {
        matchedReference += 1
      }
    })
    let matchedUser = 0
    userTerms.forEach((term: string) => {
      if (referenceTerms.indexOf(term) >= 0) {
        matchedUser += 1
      }
    })
    const recall = matchedReference / referenceTerms.length
    const precision = matchedUser / userTerms.length
    if (recall + precision === 0) {
      return 0
    }
    return Math.round((2 * recall * precision / (recall + precision)) * 100)
  }

  private missingReferenceTerms(userAnswer: string, referenceAnswer: string): string[] {
    const referenceTerms = this.importantTerms(referenceAnswer)
    const userTerms = this.importantTerms(userAnswer)
    const missing: string[] = []
    referenceTerms.forEach((term: string) => {
      if (missing.length < 5 && userTerms.indexOf(term) < 0) {
        missing.push(term)
      }
    })
    return missing
  }

  private isNonAnswer(userAnswer: string): boolean {
    const normalized = userAnswer.toLowerCase().replace(/[^a-z0-9 ]/g, ' ').replace(/\s+/g, ' ').trim()
    const nonAnswers: string[] = [
      'i dont know', 'i do not know', 'dont know', 'do not know', 'no idea', 'not sure',
      'i am not sure', 'i have no idea', 'idk', '不知道', '不会', '我不知道', '我不会'
    ]
    if (normalized.length === 0) {
      return true
    }
    if (normalized.split(' ').length <= 4) {
      let matched = false
      nonAnswers.forEach((phrase: string) => {
        if (normalized === phrase || normalized.indexOf(phrase) >= 0) {
          matched = true
        }
      })
      return matched
    }
    return false
  }

  async evaluateAnswer(userAnswer: string, question: string, referenceAnswer: string = ''): Promise<EvaluationResult> {
    const hasReference = referenceAnswer.trim().length > 0
    const modelAnswer = hasReference ? referenceAnswer : ''
    if (this.isNonAnswer(userAnswer)) {
      const result = new EvaluationResult()
      result.clarityScore = 0
      result.structureScore = 0
      result.completenessScore = 0
      result.accuracyScore = 0
      result.confidenceScore = 0
      result.overallScore = 0
      result.feedback = hasReference ? 'No answer was provided. Review the saved reference answer and try again.' :
        'No answer was provided.'
      result.modelAnswer = modelAnswer
      return result
    }

    const wordCount = userAnswer.split(/\s+/).length
    const sentenceCount = userAnswer.split(/[.!?]+/).filter(s => s.trim().length > 0).length
    const clarityScore = Math.min(100, Math.max(0, wordCount * 2 + sentenceCount * 5))
    let structureScore = sentenceCount > 1 ? Math.min(100, 35 + sentenceCount * 10) : 20
    let completenessScore = Math.min(100, Math.max(0, wordCount * 2))
    let accuracyScore = 0
    let confidenceScore = Math.min(100, Math.max(0, clarityScore))
    let overlap = 0
    let exactAnswerMode = false
    let aiResult: AnswerEvaluateResponse | null = null
    if (hasReference) {
      exactAnswerMode = this.isCertainAnswer(referenceAnswer)
      overlap = exactAnswerMode ? this.exactAnswerScore(userAnswer, referenceAnswer) : this.overlapScore(userAnswer, referenceAnswer)
      try {
        aiResult = await this.answerBackend.evaluate(question, referenceAnswer, userAnswer)
      } catch (err) {
        console.warn('[StudyOralAi] answer backend evaluation failed: ' + JSON.stringify(err))
      }
      let aiAdjustment = 0
      if (aiResult !== null && aiResult.available) {
        aiAdjustment = aiResult.adjustment
        if (aiResult.verdict === 'incorrect') {
          aiAdjustment = Math.min(aiAdjustment, -5)
        } else if (aiResult.verdict === 'correct') {
          aiAdjustment = Math.max(aiAdjustment, 3)
        }
      }
      const adjustedOverlap = exactAnswerMode && overlap < 100 ? 0 : Math.max(0, Math.min(100, overlap + aiAdjustment))
      structureScore = adjustedOverlap > 0 ? Math.min(100, Math.max(20, sentenceCount * 16 + wordCount)) : 0
      completenessScore = adjustedOverlap
      accuracyScore = adjustedOverlap
      confidenceScore = adjustedOverlap > 0 ? Math.min(100, Math.max(20, clarityScore)) : 0
    }
    let overallScore = hasReference ? Math.round(accuracyScore * 0.7 + completenessScore * 0.2 + structureScore * 0.1) :
      Math.round(clarityScore * 0.4 + structureScore * 0.3 + completenessScore * 0.2 + confidenceScore * 0.1)
    if (hasReference && exactAnswerMode && overlap < 100) {
      overallScore = 0
    }

    const feedbackParts: string[] = []
    if (hasReference) {
      if (exactAnswerMode && overallScore === 0) {
        feedbackParts.push('This question expects a definite answer. Your answer does not match the saved correct answer.')
      } else if (overlap === 0) {
        feedbackParts.push('Your answer has no meaningful overlap with the saved correct answer.')
      } else if (overlap < 40) {
        feedbackParts.push('Answer overlap with the saved correct answer: ' + overlap.toString() + '%.')
      } else if (overlap < 75) {
        feedbackParts.push('Your answer partially matches the saved correct answer: ' + overlap.toString() + '%.')
      } else {
        feedbackParts.push('Your answer mostly matches the saved correct answer: ' + overlap.toString() + '%.')
      }
      const missingTerms = this.missingReferenceTerms(userAnswer, referenceAnswer)
      if (missingTerms.length > 0) {
        feedbackParts.push('Missing reference terms: ' + missingTerms.join(', ') + '.')
      }
      if (aiResult !== null && aiResult.available && aiResult.feedback.length > 0) {
        feedbackParts.push('AI analysis: ' + aiResult.feedback)
      }
    } else {
      feedbackParts.push('No saved reference answer is available for this question, so accuracy cannot be checked.')
    }

    const result = new EvaluationResult()
    result.clarityScore = clarityScore
    result.structureScore = structureScore
    result.completenessScore = completenessScore
    result.accuracyScore = accuracyScore
    result.confidenceScore = confidenceScore
    result.overallScore = overallScore
    result.feedback = feedbackParts.join(' ')
    result.modelAnswer = modelAnswer
    return result
  }

  generateInitialGreeting(topicTitle: string): string {
    return 'Welcome to your practice session on "' + topicTitle + '". ' +
      'I\'ll be your oral exam coach today. Let\'s begin with a practice question. ' +
      'Are you ready?'
  }
}
