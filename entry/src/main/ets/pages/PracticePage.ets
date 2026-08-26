import { promptAction, router } from '@kit.ArkUI'
import { common } from '@kit.AbilityKit'
import { StorageService } from '../services/StorageService'
import { AiService } from '../services/AiService'
import { MaterialIngestionService } from '../services/MaterialIngestionService'
import { DeepgramAsrClient, DeepgramAsrListener, TranscriptionSegment } from '../services/DeepgramAsrClient'
import { ChatMessageData, SessionData, EvaluationData, PracticeExamData } from '../model/DataTypes'
import { MaterialQuestionAnswerRecord } from '../model/StudyMaterialRecord'

@Entry
@Component
struct PracticePage {
  @State topicId: string = ''
  @State topicTitle: string = ''
  @State currentQuestion: string = ''
  @State currentReferenceAnswer: string = ''
  @State currentMaterialQuestionId: string = ''
  @State questionLabel: string = 'Practice Question'
  @State chatMessages: ChatMessageData[] = []
  @State isProcessing: boolean = false
  @State userAnswer: string = ''
  @State hasPracticeQuestion: boolean = false
  @State answerSubmitted: boolean = false
  @State practiceMode: string = 'speak'
  @State showEvaluation: boolean = false
  @State evalOverallScore: number = 0
  @State evalClarityScore: number = 0
  @State evalStructureScore: number = 0
  @State evalCompletenessScore: number = 0
  @State evalAccuracyScore: number = 0
  @State evalConfidenceScore: number = 0
  @State evalFeedback: string = ''
  @State sessionId: string = ''
  @State examId: string = ''
  @State isRecording: boolean = false
  @State speechStatus: string = 'Tap to answer aloud'
  @State questionProgressText: string = '0/0'
  private storage: StorageService = StorageService.getInstance()
  private ai: AiService = AiService.getInstance()
  private materialService: MaterialIngestionService | null = null
  private asrClient: DeepgramAsrClient = new DeepgramAsrClient()
  private currentQuestionPracticeCount: number = 0
  private currentPracticeIndex: number = 0
  private activeExam: PracticeExamData | null = null

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>
    this.topicId = params.topicId ?? ''
    this.examId = params.examId ?? ''
    const context = getContext(this) as common.UIAbilityContext
    this.materialService = new MaterialIngestionService(context)
    this.storage.init(context).then(() => {
      this.startSession()
    })
  }

  async startSession(): Promise<void> {
    this.chatMessages = []
    this.userAnswer = ''
    this.showEvaluation = false
    this.currentQuestion = ''
    this.hasPracticeQuestion = false
    this.answerSubmitted = false
    this.practiceMode = 'speak'
    this.isProcessing = false
    this.isRecording = false
    this.speechStatus = 'Tap to answer aloud'
    this.currentReferenceAnswer = ''
    this.currentMaterialQuestionId = ''
    this.questionLabel = 'Practice Question'
    this.currentQuestionPracticeCount = 0
    this.questionProgressText = '0/0'

    const topics = this.storage.getTopics()
    const topic = topics.find(t => t.id === this.topicId)
    if (topic) {
      this.topicTitle = topic.title
    } else if (this.topicId.length > 0) {
      this.topicTitle = 'Operating Systems'
    } else {
      this.topicTitle = 'Practice'
    }
    this.sessionId = Date.now().toString()
    let greeting = this.ai.generateInitialGreeting(this.topicTitle)
    let question = ''

    if (this.materialService !== null) {
      const allQuestions = await this.materialService.listAllQuestions(1000)
      const uploadedQuestion = this.nextExamQuestion(allQuestions)
      if (uploadedQuestion !== null) {
        if (this.activeExam !== null && this.activeExam.questionIds.length > 0) {
          this.currentPracticeIndex = this.activeExam.answeredQuestionIds.length + 1
          this.questionProgressText = this.currentPracticeIndex.toString() + '/' + this.activeExam.questionIds.length.toString()
        }
        this.currentMaterialQuestionId = uploadedQuestion.id
        this.currentReferenceAnswer = uploadedQuestion.answer
        this.currentQuestionPracticeCount = uploadedQuestion.practiceCount
        this.questionLabel = 'Practice Question'
        question = uploadedQuestion.question
        this.hasPracticeQuestion = true
        greeting = 'Welcome to your uploaded document practice session. I will ask a random question from your saved Q&A materials.'
      }
    }

    if (question.length === 0 && this.topicId.length === 0) {
      this.questionLabel = 'Question Practice'
      this.currentQuestion = 'No uploaded questions are ready yet.'
      this.currentPracticeIndex = 0
      this.questionProgressText = '0/0'
      return
    }

    const botMessage = new ChatMessageData()
    botMessage.id = Date.now().toString()
    botMessage.sessionId = this.sessionId
    botMessage.role = 'assistant'
    botMessage.content = greeting
    botMessage.timestamp = Date.now().toString()
    this.chatMessages.push(botMessage)
    this.storage.addChatMessage(botMessage)

    if (question.length === 0) {
      question = await this.ai.generateQuestion(this.topicTitle)
      this.hasPracticeQuestion = true
    }
    this.currentQuestion = question
    const questionMessage = new ChatMessageData()
    questionMessage.id = (Date.now() + 1).toString()
    questionMessage.sessionId = this.sessionId
    questionMessage.role = 'assistant'
    questionMessage.content = 'Here is your question:\n\n' + question
    questionMessage.timestamp = Date.now().toString()
    this.chatMessages.push(questionMessage)
    this.storage.addChatMessage(questionMessage)
  }

  async processAnswer(): Promise<void> {
    const trimmedAnswer = this.userAnswer.trim()
    if (!this.hasPracticeQuestion || this.currentQuestion.length === 0 || this.answerSubmitted || this.isProcessing) {
      return
    }
    if (trimmedAnswer.length === 0) {
      promptAction.showToast({ message: 'Please enter your answer first', duration: 1400 })
      return
    }
    this.userAnswer = trimmedAnswer
    this.isProcessing = true
    this.answerSubmitted = true

    try {
      const userMessage = new ChatMessageData()
      userMessage.id = Date.now().toString()
      userMessage.sessionId = this.sessionId
      userMessage.role = 'user'
      userMessage.content = this.userAnswer
      userMessage.timestamp = Date.now().toString()
      this.chatMessages.push(userMessage)
      this.storage.addChatMessage(userMessage)

      const evalResult = await this.ai.evaluateAnswer(this.userAnswer, this.currentQuestion, this.currentReferenceAnswer)
      let feedbackText = evalResult.feedback
      let modelAnswerText = evalResult.modelAnswer
      if (this.currentReferenceAnswer.length > 0) {
        modelAnswerText = this.currentReferenceAnswer
      }
      this.evalOverallScore = evalResult.overallScore
      this.evalClarityScore = evalResult.clarityScore
      this.evalStructureScore = evalResult.structureScore
      this.evalCompletenessScore = evalResult.completenessScore
      this.evalAccuracyScore = evalResult.accuracyScore
      this.evalConfidenceScore = evalResult.confidenceScore
      this.evalFeedback = feedbackText
      this.showEvaluation = true
      this.practiceMode = 'result'

      const evalObj = new EvaluationData()
      evalObj.id = Date.now().toString()
      evalObj.sessionId = this.sessionId
      evalObj.clarityScore = evalResult.clarityScore.toString()
      evalObj.structureScore = evalResult.structureScore.toString()
      evalObj.completenessScore = evalResult.completenessScore.toString()
      evalObj.accuracyScore = evalResult.accuracyScore.toString()
      evalObj.confidenceScore = evalResult.confidenceScore.toString()
      evalObj.overallScore = evalResult.overallScore.toString()
      evalObj.feedback = feedbackText
      evalObj.modelAnswer = modelAnswerText
      evalObj.weakTopics = '[]'
      evalObj.createdAt = Date.now().toString()
      this.storage.addEvaluation(evalObj)

      const feedbackMessage = new ChatMessageData()
      feedbackMessage.id = (Date.now() + 2).toString()
      feedbackMessage.sessionId = this.sessionId
      feedbackMessage.role = 'assistant'
      feedbackMessage.content = 'Evaluation Score: ' + evalResult.overallScore + '%\n\n' + feedbackText +
        (this.currentReferenceAnswer.length > 0 ? '\n\nReference answer from uploaded document:\n' + this.currentReferenceAnswer : '')
      feedbackMessage.timestamp = Date.now().toString()
      this.chatMessages.push(feedbackMessage)
      this.storage.addChatMessage(feedbackMessage)

      const sessionObj = new SessionData()
      sessionObj.id = this.sessionId
      sessionObj.examId = this.examId
      sessionObj.topicId = this.topicId
      sessionObj.questionId = this.currentMaterialQuestionId
      sessionObj.questionContent = this.currentQuestion
      sessionObj.userAnswer = this.userAnswer
      sessionObj.recordingPath = ''
      sessionObj.duration = '0'
      sessionObj.startedAt = Date.now().toString()
      sessionObj.endedAt = Date.now().toString()
      this.storage.addSession(sessionObj)
      if (this.examId.length > 0 && this.currentMaterialQuestionId.length > 0) {
        const updatedExam = this.storage.markPracticeExamAnswered(this.examId, this.currentMaterialQuestionId)
        this.activeExam = updatedExam
      }
      if (this.materialService !== null && this.currentMaterialQuestionId.length > 0) {
        await this.materialService.markQuestionPracticed(this.currentMaterialQuestionId, this.currentQuestionPracticeCount + 1)
        this.currentQuestionPracticeCount += 1
      }
    } catch (err) {
      this.answerSubmitted = false
      promptAction.showToast({ message: 'Evaluation failed', duration: 1400 })
      console.error('[StudyOralPractice] evaluation failed: ' + JSON.stringify(err))
    } finally {
      this.isProcessing = false
    }
  }

  private nextExamQuestion(allQuestions: MaterialQuestionAnswerRecord[]): MaterialQuestionAnswerRecord | null {
    if (allQuestions.length === 0) {
      return null
    }
    if (this.examId.length > 0) {
      const savedExam = this.storage.getPracticeExamById(this.examId)
      if (savedExam !== null && savedExam.status !== 'completed') {
        this.activeExam = savedExam
      }
    }
    if (this.activeExam === null || this.activeExam.status === 'completed') {
      const now = Date.now().toString()
      const exam = new PracticeExamData()
      exam.id = 'exam_' + now
      exam.status = 'in_progress'
      exam.questionIds = this.shuffledQuestionIds(allQuestions)
      exam.answeredQuestionIds = []
      exam.materialIds = this.materialIdsFromQuestions(allQuestions)
      exam.startedAt = now
      exam.updatedAt = now
      this.storage.upsertPracticeExam(exam)
      this.activeExam = exam
      this.examId = exam.id
    }

    const activeExam = this.activeExam
    if (activeExam === null) {
      return null
    }
    for (let index = 0; index < activeExam.questionIds.length; index++) {
      const questionId = activeExam.questionIds[index]
      if (activeExam.answeredQuestionIds.indexOf(questionId) >= 0) {
        continue
      }
      const question = allQuestions.find((item: MaterialQuestionAnswerRecord) => item.id === questionId)
      if (question !== undefined) {
        return question
      }
    }

    activeExam.status = 'completed'
    activeExam.completedAt = Date.now().toString()
    activeExam.updatedAt = activeExam.completedAt
    this.storage.upsertPracticeExam(activeExam)
    this.activeExam = activeExam
    return null
  }

  private materialIdsFromQuestions(questions: MaterialQuestionAnswerRecord[]): string[] {
    const ids: string[] = []
    questions.forEach((question: MaterialQuestionAnswerRecord) => {
      if (question.materialId.length > 0 && ids.indexOf(question.materialId) < 0) {
        ids.push(question.materialId)
      }
    })
    return ids
  }

  private shuffledQuestionIds(questions: MaterialQuestionAnswerRecord[]): string[] {
    const ids = questions.map((question: MaterialQuestionAnswerRecord) => question.id)
    for (let index = ids.length - 1; index > 0; index--) {
      const targetIndex = Math.floor(Math.random() * (index + 1))
      const current = ids[index]
      ids[index] = ids[targetIndex]
      ids[targetIndex] = current
    }
    return ids
  }

  private openMaterials(): void {
    router.replaceUrl({
      url: 'pages/HomePage',
      params: { tab: 'materials' }
    })
  }

  private async toggleSpeechCapture(): Promise<void> {
    if (this.isRecording) {
      await this.stopSpeechCapture(true)
      return
    }
    if (!this.hasPracticeQuestion || this.currentQuestion.length === 0) {
      return
    }

    this.userAnswer = ''
    this.isRecording = true
    this.speechStatus = 'Listening... tap again to stop'

    const listener = new DeepgramAsrListener(
      (segment: TranscriptionSegment): void => {
        this.userAnswer = segment.text
        this.speechStatus = segment.text.length > 0 ? segment.text : 'Listening... tap again to stop'
      },
      (fullText: string): void => {
        if (fullText.length > 0) {
          this.userAnswer = fullText
          this.practiceMode = 'write'
          this.speechStatus = 'Speech captured'
        } else {
          this.speechStatus = 'Tap to answer aloud'
        }
        this.isRecording = false
      },
      (error: string): void => {
        if (this.userAnswer.trim().length > 0) {
          this.speechStatus = 'Speech captured'
          this.practiceMode = 'write'
          this.isRecording = false
          console.warn('[StudyOralASR] ignored late error after transcript: ' + error)
          return
        }
        this.isRecording = false
        this.speechStatus = 'Speech transcription failed'
        promptAction.showToast({ message: 'Speech transcription failed', duration: 1400 })
        console.error('[StudyOralASR] ' + error)
      }
    )

    await this.asrClient.start(listener)
  }

  private async stopSpeechCapture(showToast: boolean = false): Promise<void> {
    if (!this.isRecording) {
      return
    }
    this.speechStatus = 'Finalizing speech...'
    await this.asrClient.stop()
    this.isRecording = false
    if (this.userAnswer.trim().length > 0) {
      this.practiceMode = 'write'
      if (showToast) {
        promptAction.showToast({ message: 'Speech captured', duration: 1200 })
      }
    } else {
      this.speechStatus = 'Tap to answer aloud'
      if (showToast) {
        promptAction.showToast({ message: 'No speech detected', duration: 1200 })
      }
    }
  }

  @Builder
  private brandIcon(name: string, size: number, dimmed: boolean = false) {
    if (name === 'mic') {
      Image($r('app.media.ic_mic')).width(size).height(size).objectFit(ImageFit.Contain).opacity(dimmed ? 0.55 : 1)
    } else if (name === 'home') {
      Image($r('app.media.ic_home')).width(size).height(size).objectFit(ImageFit.Contain).opacity(dimmed ? 0.55 : 1)
    } else if (name === 'practice') {
      Image($r('app.media.ic_practice')).width(size).height(size).objectFit(ImageFit.Contain).opacity(dimmed ? 0.55 : 1)
    } else if (name === 'materials') {
      Image($r('app.media.ic_materials')).width(size).height(size).objectFit(ImageFit.Contain).opacity(dimmed ? 0.55 : 1)
    } else if (name === 'history') {
      Image($r('app.media.ic_history')).width(size).height(size).objectFit(ImageFit.Contain).opacity(dimmed ? 0.55 : 1)
    } else if (name === 'result') {
      Image($r('app.media.ic_result')).width(size).height(size).objectFit(ImageFit.Contain).opacity(dimmed ? 0.55 : 1)
    } else {
      Image($r('app.media.foreground')).width(size).height(size).objectFit(ImageFit.Contain).opacity(dimmed ? 0.55 : 1)
    }
  }

  private scoreStatusTitle(): string {
    if (!this.showEvaluation) {
      return 'Practice Ready'
    }
    return this.evalOverallScore >= 60 ? 'Practice Ready' : 'Needs Review'
  }

  private scoreStatusDetail(): string {
    if (!this.showEvaluation) {
      return 'Answer below when you are ready.'
    }
    if (this.evalFeedback.length > 0) {
      return this.evalFeedback
    }
    return 'Review the reference answer and try another question.'
  }

  @Builder
  private questionPracticeCard() {
    Column() {
      Column() {
        Row() {
          Row() {
            Image($r('app.media.ic_practice_card_book'))
              .width(20)
              .height(20)
              .objectFit(ImageFit.Contain)
            Text(this.questionProgressText)
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor('#0D2A8B')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ left: 6 })
          }
          .height(32)
          .padding({ left: 12, right: 16 })
          .backgroundColor('#EEF3FF')
          .borderRadius(16)
          Blank()
          Text(this.currentQuestionPracticeCount > 0 ? ('Practiced ' + this.currentQuestionPracticeCount.toString() + 'x') : 'Question')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor('#59627E')
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)

        Text(this.currentQuestion.length > 0 ? this.currentQuestion : 'No uploaded questions are ready yet.')
          .fontSize(this.showEvaluation ? 16 : 24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#101733')
          .lineHeight(this.showEvaluation ? 22 : 31)
          .maxLines(this.showEvaluation ? 2 : 4)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .margin({ top: this.showEvaluation ? 12 : 24 })

        if (this.hasPracticeQuestion && !this.showEvaluation && this.practiceMode === 'speak') {
          Blank().layoutWeight(1)
          Stack({ alignContent: Alignment.Center }) {
            Column()
              .width(158)
              .height(158)
              .backgroundColor('#F2F5FF')
              .borderRadius(79)
            Column()
              .width(126)
              .height(126)
              .backgroundColor(this.isRecording ? '#F04438' : '#6547E8')
              .borderRadius(63)
              .shadow({ radius: 18, color: this.isRecording ? '#F0443840' : '#6547E84D', offsetY: 10 })
            Column() {
              Image($r('app.media.ic_practice_card_mic'))
                .width(50)
                .height(50)
                .objectFit(ImageFit.Contain)
              Text(this.isRecording ? 'Stop' : 'Speak')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
                .margin({ top: 8 })
            }
            .width(126)
            .height(126)
            .justifyContent(FlexAlign.Center)
          }
          .width('100%')
          .height(170)
          .margin({ top: 22 })
          .onClick(() => {
            this.toggleSpeechCapture()
          })

          Text(this.speechStatus)
            .fontSize(13)
            .fontColor('#66708E')
            .width('100%')
            .textAlign(TextAlign.Center)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 8 })

          Button() {
            Row() {
              Image($r('app.media.ic_practice_card_write'))
                .width(20)
                .height(20)
                .objectFit(ImageFit.Contain)
              Text('Write instead')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1655FF')
                .margin({ left: 8 })
            }
            .justifyContent(FlexAlign.Center)
            .width('100%')
          }
            .width(150)
            .height(44)
            .backgroundColor('#FFFFFF')
            .borderRadius(18)
            .border({ width: 1, color: '#2C5CFF' })
            .margin({ top: 24 })
            .onClick(() => {
              this.practiceMode = 'write'
            })
          Blank().layoutWeight(1)
        } else if (this.hasPracticeQuestion && !this.showEvaluation) {
          Column() {
            Text('Your Answer')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor('#101733')
              .width('100%')
            TextArea({ text: this.userAnswer, placeholder: 'Write your answer here...' })
              .width('100%')
              .height(166)
              .fontSize(14)
              .fontColor('#111936')
              .placeholderColor('#8A94AD')
              .backgroundColor('#FFFFFF')
              .borderRadius(14)
              .border({ width: 1, color: '#DDE5F5' })
              .padding(12)
              .margin({ top: 10 })
              .onChange((value: string) => {
                this.userAnswer = value
              })
          }
          .width('100%')
          .margin({ top: 34 })

          Button() {
            Row() {
              Image($r('app.media.ic_practice_card_mic'))
                .width(18)
                .height(18)
                .objectFit(ImageFit.Contain)
              Text('Switch to Speak')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1655FF')
                .margin({ left: 8 })
            }
            .justifyContent(FlexAlign.Center)
            .width('100%')
          }
            .width('100%')
            .height(44)
            .backgroundColor('#F3F6FF')
            .borderRadius(14)
            .margin({ top: 18 })
            .onClick(() => {
              this.practiceMode = 'speak'
            })

          Row() {
            Button('Cancel')
              .height(48)
              .layoutWeight(1)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1655FF')
              .backgroundColor('#FFFFFF')
              .borderRadius(14)
              .border({ width: 1, color: '#E3E7F4' })
              .onClick(() => {
                this.practiceMode = 'speak'
              })
            Button(this.isProcessing ? 'Evaluating...' : 'Submit Answer')
              .height(48)
              .layoutWeight(1.5)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .backgroundColor(this.isProcessing ? '#92A4FF' : '#7047E8')
              .borderRadius(14)
              .margin({ left: 14 })
              .onClick(() => {
                this.processAnswer()
              })
          }
          .width('100%')
          .margin({ top: 24 })
        } else if (this.hasPracticeQuestion) {
          Column() {
            Text('Your Answer')
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor('#101733')
              .width('100%')
            Text(this.userAnswer.length > 0 ? this.userAnswer : 'No answer')
              .fontSize(12)
              .fontColor('#101733')
              .lineHeight(17)
              .maxLines(4)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('100%')
              .margin({ top: 8 })
          }
          .width('100%')
          .padding(14)
          .backgroundColor('#FFFFFF')
          .borderRadius(14)
          .border({ width: 1, color: '#E3E7F4' })
          .margin({ top: 14 })

          Column() {
            Text('Answer Feedback')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor('#5B35D8')
              .width('100%')
            Text(this.scoreStatusDetail())
              .fontSize(12)
              .fontColor('#1F2A44')
              .lineHeight(16)
              .maxLines(4)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('100%')
              .margin({ top: 8 })
          }
          .width('100%')
          .padding(14)
          .backgroundColor('#FFFFFF')
          .borderRadius(14)
          .border({ width: 1, color: '#E3E7F4' })
          .margin({ top: 10 })

          if (this.currentReferenceAnswer.length > 0) {
            Column() {
              Text('Correct Answer')
                .fontSize(13)
                .fontWeight(FontWeight.Bold)
                .fontColor('#101733')
                .width('100%')
              Text(this.currentReferenceAnswer)
                .fontSize(12)
                .fontColor('#1F2A44')
                .lineHeight(16)
                .maxLines(4)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .width('100%')
                .margin({ top: 8 })
              .width('100%')
            }
            .width('100%')
            .padding(14)
            .backgroundColor('#F8FAFF')
            .borderRadius(14)
            .border({ width: 1, color: '#E3E7F4' })
            .margin({ top: 10 })
          }

          Row() {
            Button('Retry')
              .height(46)
              .layoutWeight(1)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1655FF')
              .backgroundColor('#FFFFFF')
              .borderRadius(14)
              .border({ width: 1, color: '#E3E7F4' })
              .onClick(() => {
                this.userAnswer = ''
                this.answerSubmitted = false
                this.showEvaluation = false
                this.practiceMode = 'write'
              })
            Button() {
              Row() {
                Text('Next Question')
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFFFFF')
                Image($r('app.media.ic_practice_card_next'))
                  .width(22)
                  .height(22)
                  .objectFit(ImageFit.Contain)
                  .margin({ left: 8 })
              }
              .justifyContent(FlexAlign.Center)
              .width('100%')
            }
              .height(46)
              .layoutWeight(1.5)
              .backgroundColor('#7047E8')
              .borderRadius(14)
              .shadow({ radius: 8, color: '#7047E833', offsetY: 4 })
              .margin({ left: 12 })
              .onClick(() => {
                this.startSession()
              })
          }
          .width('100%')
          .margin({ top: 10 })
        } else {
          Column() {
            this.brandIcon('materials', 66)
            Text('Upload a document with questions and answers to start practice.')
              .fontSize(15)
              .fontColor('#59627E')
              .lineHeight(22)
              .textAlign(TextAlign.Center)
              .width('100%')
              .margin({ top: 12 })
            Button('Open Materials')
              .height(50)
              .width('100%')
              .fontSize(15)
              .fontColor('#FFFFFF')
              .backgroundColor('#1E55FF')
              .borderRadius(16)
              .margin({ top: 18 })
              .onClick(() => {
                this.openMaterials()
              })
          }
          .width('100%')
          .padding({ top: 20, bottom: 6 })
        }
      }
      .width('100%')
      .height('100%')
      .padding({ left: 22, right: 22, top: 28, bottom: 18 })
      .backgroundColor('#FFFFFF')
      .borderRadius(0)
    }
    .width('100%')
    .height('100%')
    .padding({ top: 10 })
    .backgroundColor('#FFFFFF')
    .borderRadius(0)
  }

  @Builder
  private bottomNav(active: string) {
    Row() {
      this.navItem('home', 'Home', active === 'Home', 'pages/HomePage')
      this.navItem('practice', 'Practice', active === 'Practice', 'pages/TopicPage')
      this.navItem('materials', 'Materials', active === 'Materials', 'pages/MaterialsPage')
      this.navItem('history', 'History', active === 'History', 'pages/HistoryPage')
    }
    .width('100%')
    .height(72)
    .padding({ left: 10, right: 10, bottom: 6 })
    .backgroundColor('#FFFFFF')
    .border({ width: { top: 1 }, color: '#EEF1F7' })
  }

  @Builder
  private navItem(iconName: string, label: string, selected: boolean, url: string) {
    Column() {
      this.brandIcon(iconName, 30, !selected)
      Text(label)
        .fontSize(10)
        .fontColor(selected ? '#1655FF' : '#5E6884')
        .fontWeight(selected ? FontWeight.Bold : FontWeight.Normal)
        .margin({ top: 2 })
    }
    .layoutWeight(1)
    .height(58)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      router.replaceUrl({
        url: 'pages/HomePage',
        params: { tab: label === 'Practice' ? 'practice' : (label === 'Materials' ? 'materials' : (label === 'History' ? 'history' : 'home')) }
      })
    })
  }

  build() {
    Column() {
      Row() {
        Text('‹')
          .fontSize(34)
          .fontColor('#FFFFFF')
          .onClick(() => {
            router.back()
          })
        Text('Practice')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .layoutWeight(1)
          .textAlign(TextAlign.Start)
          .margin({ left: 10 })
      }
      .width('100%')
      .height(70)
      .padding({ left: 18, right: 18, top: 8 })
      .backgroundColor('#315DFF')

      Column() {
        this.questionPracticeCard()
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 0, right: 0, bottom: 0 })

      this.bottomNav('Practice')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#315DFF')
  }
}
