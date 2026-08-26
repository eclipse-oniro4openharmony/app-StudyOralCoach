import { preferences } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import { TopicData, QuestionData, SessionData, EvaluationData, ChatMessageData, PracticeExamData } from '../model/DataTypes'

export class StorageService {
  private static instance: StorageService
  private topicsStr: string = '[]'
  private questionsStr: string = '[]'
  private sessionsStr: string = '[]'
  private practiceExamsStr: string = '[]'
  private evaluationsStr: string = '[]'
  private chatMessagesStr: string = '[]'
  private prefStore: preferences.Preferences | null = null
  private initialized: boolean = false

  static getInstance(): StorageService {
    if (!StorageService.instance) {
      StorageService.instance = new StorageService()
    }
    return StorageService.instance
  }

  async init(context: common.UIAbilityContext): Promise<void> {
    if (this.initialized) {
      return
    }
    try {
      this.prefStore = await preferences.getPreferences(context, 'studyoral_storage')
      await this.loadData()
      this.initialized = true
    } catch (e) {
      console.error('StorageService: init error', e)
    }
  }

  private async loadData(): Promise<void> {
    if (!this.prefStore) {
      return
    }
    try {
      this.topicsStr = await this.prefStore.get('topics', '[]') as string
      this.questionsStr = await this.prefStore.get('questions', '[]') as string
      this.sessionsStr = await this.prefStore.get('sessions', '[]') as string
      this.practiceExamsStr = await this.prefStore.get('practiceExams', '[]') as string
      this.evaluationsStr = await this.prefStore.get('evaluations', '[]') as string
      this.chatMessagesStr = await this.prefStore.get('chatMessages', '[]') as string
    } catch (e) {
      console.error('StorageService: loadData error', e)
    }
  }

  private async saveData(): Promise<void> {
    if (!this.prefStore) {
      return
    }
    try {
      await this.prefStore.put('topics', this.topicsStr)
      await this.prefStore.put('questions', this.questionsStr)
      await this.prefStore.put('sessions', this.sessionsStr)
      await this.prefStore.put('practiceExams', this.practiceExamsStr)
      await this.prefStore.put('evaluations', this.evaluationsStr)
      await this.prefStore.put('chatMessages', this.chatMessagesStr)
      await this.prefStore.flush()
    } catch (e) {
      console.error('StorageService: saveData error', e)
    }
  }

  getTopics(): TopicData[] {
    return JSON.parse(this.topicsStr) as TopicData[]
  }

  addTopic(topic: TopicData): void {
    const arr = JSON.parse(this.topicsStr) as TopicData[]
    arr.push(topic)
    this.topicsStr = JSON.stringify(arr)
    this.saveData()
  }

  updateTopic(updatedTopic: TopicData): void {
    const arr = JSON.parse(this.topicsStr) as TopicData[]
    const index = arr.findIndex(t => t.id === updatedTopic.id)
    if (index >= 0) {
      arr[index] = updatedTopic
      this.topicsStr = JSON.stringify(arr)
      this.saveData()
    }
  }

  deleteTopic(id: string): void {
    let arr = JSON.parse(this.topicsStr) as TopicData[]
    arr = arr.filter(t => t.id !== id)
    this.topicsStr = JSON.stringify(arr)
    let qArr = JSON.parse(this.questionsStr) as QuestionData[]
    qArr = qArr.filter(q => q.topicId !== id)
    this.questionsStr = JSON.stringify(qArr)
    this.saveData()
  }

  getQuestionsByTopicId(topicId: string): QuestionData[] {
    const arr = JSON.parse(this.questionsStr) as QuestionData[]
    return arr.filter(q => q.topicId === topicId)
  }

  addQuestion(question: QuestionData): void {
    const arr = JSON.parse(this.questionsStr) as QuestionData[]
    arr.push(question)
    this.questionsStr = JSON.stringify(arr)
    const topics = JSON.parse(this.topicsStr) as TopicData[]
    const topic = topics.find(t => t.id === question.topicId)
    if (topic) {
      const count = arr.filter(q => q.topicId === question.topicId).length
      topic.questionCount = count.toString()
      topic.updatedAt = Date.now().toString()
      this.topicsStr = JSON.stringify(topics)
    }
    this.saveData()
  }

  deleteQuestion(id: string): void {
    const arr = JSON.parse(this.questionsStr) as QuestionData[]
    const question = arr.find(q => q.id === id)
    const filtered = arr.filter(q => q.id !== id)
    this.questionsStr = JSON.stringify(filtered)
    if (question) {
      const topics = JSON.parse(this.topicsStr) as TopicData[]
      const topic = topics.find(t => t.id === question.topicId)
      if (topic) {
        topic.questionCount = filtered.filter(q => q.topicId === question.topicId).length.toString()
        this.topicsStr = JSON.stringify(topics)
      }
    }
    this.saveData()
  }

  getSessions(): SessionData[] {
    const arr = JSON.parse(this.sessionsStr) as SessionData[]
    return arr.sort((a, b) => Number(b.startedAt) - Number(a.startedAt))
  }

  addSession(session: SessionData): void {
    const arr = JSON.parse(this.sessionsStr) as SessionData[]
    arr.push(session)
    this.sessionsStr = JSON.stringify(arr)
    this.saveData()
  }

  getPracticeExams(): PracticeExamData[] {
    const arr = JSON.parse(this.practiceExamsStr) as PracticeExamData[]
    return arr
      .map((exam: PracticeExamData) => this.normalizePracticeExam(exam))
      .sort((a: PracticeExamData, b: PracticeExamData) => Number(b.updatedAt) - Number(a.updatedAt))
  }

  getPracticeExamById(examId: string): PracticeExamData | null {
    if (examId.length === 0) {
      return null
    }
    const found = this.getPracticeExams().find((exam: PracticeExamData) => exam.id === examId)
    return found ?? null
  }

  getLatestIncompletePracticeExam(): PracticeExamData | null {
    const found = this.getPracticeExams().find((exam: PracticeExamData) =>
      exam.status !== 'completed' && exam.questionIds.length > exam.answeredQuestionIds.length)
    return found ?? null
  }

  upsertPracticeExam(exam: PracticeExamData): void {
    const arr = JSON.parse(this.practiceExamsStr) as PracticeExamData[]
    const normalized = this.normalizePracticeExam(exam)
    const index = arr.findIndex((item: PracticeExamData) => item.id === normalized.id)
    if (index >= 0) {
      arr[index] = normalized
    } else {
      arr.push(normalized)
    }
    this.practiceExamsStr = JSON.stringify(arr)
    this.saveData()
  }

  markPracticeExamAnswered(examId: string, questionId: string): PracticeExamData | null {
    const exam = this.getPracticeExamById(examId)
    if (exam === null) {
      return null
    }
    if (questionId.length > 0 && exam.answeredQuestionIds.indexOf(questionId) < 0) {
      exam.answeredQuestionIds.push(questionId)
    }
    exam.updatedAt = Date.now().toString()
    if (exam.questionIds.length > 0 && exam.answeredQuestionIds.length >= exam.questionIds.length) {
      exam.status = 'completed'
      exam.completedAt = exam.updatedAt
    }
    this.upsertPracticeExam(exam)
    return exam
  }

  private normalizePracticeExam(source: PracticeExamData): PracticeExamData {
    const exam = new PracticeExamData()
    exam.id = source.id ?? ''
    exam.status = source.status ?? 'in_progress'
    exam.questionIds = source.questionIds ?? []
    exam.answeredQuestionIds = source.answeredQuestionIds ?? []
    exam.materialIds = source.materialIds ?? []
    exam.startedAt = source.startedAt ?? '0'
    exam.updatedAt = source.updatedAt ?? exam.startedAt
    exam.completedAt = source.completedAt ?? ''
    return exam
  }

  getEvaluations(): EvaluationData[] {
    const arr = JSON.parse(this.evaluationsStr) as EvaluationData[]
    return arr.sort((a, b) => Number(b.createdAt) - Number(a.createdAt))
  }

  getEvaluationBySessionId(sessionId: string): EvaluationData | null {
    const arr = JSON.parse(this.evaluationsStr) as EvaluationData[]
    const found = arr.find(e => e.sessionId === sessionId)
    return found ?? null
  }

  addEvaluation(evaluation: EvaluationData): void {
    const arr = JSON.parse(this.evaluationsStr) as EvaluationData[]
    arr.push(evaluation)
    this.evaluationsStr = JSON.stringify(arr)
    this.saveData()
  }

  getChatMessages(sessionId: string): ChatMessageData[] {
    const arr = JSON.parse(this.chatMessagesStr) as ChatMessageData[]
    return arr
      .filter(m => m.sessionId === sessionId)
      .sort((a, b) => Number(a.timestamp) - Number(b.timestamp))
  }

  addChatMessage(message: ChatMessageData): void {
    const arr = JSON.parse(this.chatMessagesStr) as ChatMessageData[]
    arr.push(message)
    this.chatMessagesStr = JSON.stringify(arr)
    this.saveData()
  }

  getWeeklyStats(): number[] {
    const now = Date.now()
    const weekAgo = now - 7 * 24 * 60 * 60 * 1000
    const stats: number[] = [0, 0, 0, 0, 0, 0, 0]
    const arr = JSON.parse(this.sessionsStr) as SessionData[]
    for (const session of arr) {
      const startedAt = Number(session.startedAt)
      if (startedAt >= weekAgo) {
        const day = Math.floor((startedAt - weekAgo) / (24 * 60 * 60 * 1000))
        if (day >= 0 && day < 7) {
          stats[day]++
        }
      }
    }
    return stats
  }

  getTotalSessions(): number {
    const arr = JSON.parse(this.sessionsStr) as SessionData[]
    return arr.length
  }

  getAverageScore(): number {
    const arr = JSON.parse(this.evaluationsStr) as EvaluationData[]
    if (arr.length === 0) {
      return 0
    }
    const total = arr.reduce((sum, e) => sum + Number(e.overallScore), 0)
    return Math.round(total / arr.length)
  }

  getWeakTopics(): string[] {
    const topicScores: Map<string, number[]> = new Map()
    const evalArr = JSON.parse(this.evaluationsStr) as EvaluationData[]
    const sessArr = JSON.parse(this.sessionsStr) as SessionData[]
    const topicsArr = JSON.parse(this.topicsStr) as TopicData[]

    for (const evaluation of evalArr) {
      const session = sessArr.find(s => s.id === evaluation.sessionId)
      if (session) {
        const existing = topicScores.get(session.topicId)
        if (existing) {
          existing.push(Number(evaluation.overallScore))
        } else {
          topicScores.set(session.topicId, [Number(evaluation.overallScore)])
        }
      }
    }

    const weakTopics: string[] = []
    topicScores.forEach((scores, topicId) => {
      const avg = scores.reduce((a, b) => a + b, 0) / scores.length
      if (avg < 60) {
        const topic = topicsArr.find(t => t.id === topicId)
        if (topic) {
          weakTopics.push(topic.title)
        }
      }
    })
    return weakTopics
  }
}
