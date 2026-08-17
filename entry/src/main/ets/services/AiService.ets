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

  async evaluateAnswer(userAnswer: string, question: string): Promise<EvaluationResult> {
    const wordCount = userAnswer.split(/\s+/).length
    const sentenceCount = userAnswer.split(/[.!?]+/).filter(s => s.trim().length > 0).length
    const clarityScore = Math.min(100, Math.max(0, wordCount * 2 + sentenceCount * 5))
    const structureScore = Math.min(100, Math.max(0, 40 + Math.floor(Math.random() * 60)))
    const completenessScore = Math.min(100, Math.max(0, wordCount * 1.5 + Math.floor(Math.random() * 30)))
    const accuracyScore = Math.min(100, Math.max(0, 50 + Math.floor(Math.random() * 50)))
    const confidenceScore = Math.min(100, Math.max(0, 45 + Math.floor(Math.random() * 55)))
    const overallScore = Math.round(
      clarityScore * 0.2 + structureScore * 0.2 +
      completenessScore * 0.25 + accuracyScore * 0.25 + confidenceScore * 0.1
    )

    const feedbackParts: string[] = []
    if (clarityScore < 60) {
      feedbackParts.push('Focus on clearer articulation and simpler sentence structures.')
    }
    if (structureScore < 60) {
      feedbackParts.push('Organize your response with a clear introduction, body, and conclusion.')
    }
    if (completenessScore < 60) {
      feedbackParts.push('Provide more detailed examples and supporting evidence.')
    }
    if (accuracyScore < 60) {
      feedbackParts.push('Review the core concepts and ensure factual accuracy.')
    }
    if (confidenceScore < 60) {
      feedbackParts.push('Speak more confidently with a steady pace and firm tone.')
    }
    if (feedbackParts.length === 0) {
      feedbackParts.push('Good response! Try to add more specific examples for a stronger impact.')
    }

    const modelAnswer = 'Here is a model answer: ' + question +
      ' A comprehensive answer should include: 1) Clear definition and context, ' +
      '2) Key arguments with supporting evidence, ' +
      '3) Critical analysis of strengths and weaknesses, ' +
      '4) Practical implications and real-world examples, ' +
      '5) A concise conclusion summarizing the main points.'

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
