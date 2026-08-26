export class TopicData {
  id: string = ''
  title: string = ''
  description: string = ''
  category: string = ''
  questionCount: string = '0'
  createdAt: string = '0'
  updatedAt: string = '0'
}

export class QuestionData {
  id: string = ''
  topicId: string = ''
  content: string = ''
  difficulty: string = '1'
  followUpEnabled: string = 'true'
  createdAt: string = '0'
}

export class SessionData {
  id: string = ''
  examId: string = ''
  topicId: string = ''
  questionId: string = ''
  questionContent: string = ''
  userAnswer: string = ''
  recordingPath: string = ''
  duration: string = '0'
  startedAt: string = '0'
  endedAt: string = '0'
}

export class PracticeExamData {
  id: string = ''
  status: string = 'in_progress'
  questionIds: string[] = []
  answeredQuestionIds: string[] = []
  materialIds: string[] = []
  startedAt: string = '0'
  updatedAt: string = '0'
  completedAt: string = ''
}

export class EvaluationData {
  id: string = ''
  sessionId: string = ''
  clarityScore: string = '0'
  structureScore: string = '0'
  completenessScore: string = '0'
  accuracyScore: string = '0'
  confidenceScore: string = '0'
  overallScore: string = '0'
  feedback: string = ''
  modelAnswer: string = ''
  weakTopics: string = '[]'
  createdAt: string = '0'
}

export class ChatMessageData {
  id: string = ''
  sessionId: string = ''
  role: string = ''
  content: string = ''
  timestamp: string = '0'
}
