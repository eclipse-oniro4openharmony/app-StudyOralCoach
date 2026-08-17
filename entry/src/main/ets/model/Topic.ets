export class Topic {
  id: string
  title: string
  description: string
  category: string
  questionCount: number
  createdAt: number
  updatedAt: number

  constructor(id: string, title: string, description: string, category: string,
    questionCount: number = 0, createdAt: number = 0, updatedAt: number = 0) {
    this.id = id
    this.title = title
    this.description = description
    this.category = category
    this.questionCount = questionCount
    this.createdAt = createdAt
    this.updatedAt = updatedAt
  }
}

export class Question {
  id: string
  topicId: string
  content: string
  difficulty: number
  followUpEnabled: boolean
  createdAt: number

  constructor(id: string, topicId: string, content: string, difficulty: number = 1,
    followUpEnabled: boolean = true, createdAt: number = 0) {
    this.id = id
    this.topicId = topicId
    this.content = content
    this.difficulty = difficulty
    this.followUpEnabled = followUpEnabled
    this.createdAt = createdAt
  }
}

export class PracticeSession {
  id: string
  topicId: string
  questionId: string
  questionContent: string
  userAnswer: string
  recordingPath: string
  duration: number
  startedAt: number
  endedAt: number

  constructor(id: string, topicId: string, questionId: string, questionContent: string,
    userAnswer: string = '', recordingPath: string = '', duration: number = 0,
    startedAt: number = 0, endedAt: number = 0) {
    this.id = id
    this.topicId = topicId
    this.questionId = questionId
    this.questionContent = questionContent
    this.userAnswer = userAnswer
    this.recordingPath = recordingPath
    this.duration = duration
    this.startedAt = startedAt
    this.endedAt = endedAt
  }
}

export class Evaluation {
  id: string
  sessionId: string
  clarityScore: number
  structureScore: number
  completenessScore: number
  accuracyScore: number
  confidenceScore: number
  overallScore: number
  feedback: string
  modelAnswer: string
  weakTopics: string[]
  createdAt: number

  constructor(id: string, sessionId: string, clarityScore: number = 0,
    structureScore: number = 0, completenessScore: number = 0,
    accuracyScore: number = 0, confidenceScore: number = 0,
    overallScore: number = 0, feedback: string = '', modelAnswer: string = '',
    weakTopics: string[] = [], createdAt: number = 0) {
    this.id = id
    this.sessionId = sessionId
    this.clarityScore = clarityScore
    this.structureScore = structureScore
    this.completenessScore = completenessScore
    this.accuracyScore = accuracyScore
    this.confidenceScore = confidenceScore
    this.overallScore = overallScore
    this.feedback = feedback
    this.modelAnswer = modelAnswer
    this.weakTopics = weakTopics
    this.createdAt = createdAt
  }
}

export class ChatMessage {
  id: string
  sessionId: string
  role: string
  content: string
  timestamp: number

  constructor(id: string, sessionId: string, role: string, content: string,
    timestamp: number = 0) {
    this.id = id
    this.sessionId = sessionId
    this.role = role
    this.content = content
    this.timestamp = timestamp
  }
}
