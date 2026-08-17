import { router } from '@kit.ArkUI'
import { common } from '@kit.AbilityKit'
import { StorageService } from '../services/StorageService'
import { AiService } from '../services/AiService'
import { ChatMessageData, SessionData, EvaluationData } from '../model/DataTypes'

@Entry
@Component
struct PracticePage {
  @State topicId: string = ''
  @State topicTitle: string = ''
  @State currentQuestion: string = ''
  @State chatMessages: ChatMessageData[] = []
  @State isRecording: boolean = true
  @State isProcessing: boolean = false
  @State userAnswer: string = ''
  @State showEvaluation: boolean = false
  @State evalOverallScore: number = 0
  @State evalClarityScore: number = 0
  @State evalStructureScore: number = 0
  @State evalCompletenessScore: number = 0
  @State evalAccuracyScore: number = 0
  @State evalConfidenceScore: number = 0
  @State evalFeedback: string = ''
  @State sessionId: string = ''
  private storage: StorageService = StorageService.getInstance()
  private ai: AiService = AiService.getInstance()

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>
    this.topicId = params.topicId ?? ''
    const context = getContext(this) as common.UIAbilityContext
    this.storage.init(context).then(() => {
      this.startSession()
    })
  }

  async startSession(): Promise<void> {
    const topics = this.storage.getTopics()
    const topic = topics.find(t => t.id === this.topicId)
    if (topic) {
      this.topicTitle = topic.title
    } else {
      this.topicTitle = 'Operating Systems'
    }
    this.sessionId = Date.now().toString()
    const greeting = this.ai.generateInitialGreeting(this.topicTitle)
    const botMessage = new ChatMessageData()
    botMessage.id = Date.now().toString()
    botMessage.sessionId = this.sessionId
    botMessage.role = 'assistant'
    botMessage.content = greeting
    botMessage.timestamp = Date.now().toString()
    this.chatMessages.push(botMessage)
    this.storage.addChatMessage(botMessage)

    const question = await this.ai.generateQuestion(this.topicTitle)
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

  pauseRecording(): void {
    this.isRecording = !this.isRecording
  }

  endAnswer(): void {
    this.isRecording = false
    this.processAnswer()
  }

  async processAnswer(): Promise<void> {
    if (this.userAnswer.length === 0) {
      this.userAnswer = 'Sample answer for demonstration purposes.'
    }
    this.isProcessing = true

    const userMessage = new ChatMessageData()
    userMessage.id = Date.now().toString()
    userMessage.sessionId = this.sessionId
    userMessage.role = 'user'
    userMessage.content = this.userAnswer
    userMessage.timestamp = Date.now().toString()
    this.chatMessages.push(userMessage)
    this.storage.addChatMessage(userMessage)

    const evalResult = await this.ai.evaluateAnswer(this.userAnswer, this.currentQuestion)
    this.evalOverallScore = evalResult.overallScore
    this.evalClarityScore = evalResult.clarityScore
    this.evalStructureScore = evalResult.structureScore
    this.evalCompletenessScore = evalResult.completenessScore
    this.evalAccuracyScore = evalResult.accuracyScore
    this.evalConfidenceScore = evalResult.confidenceScore
    this.evalFeedback = evalResult.feedback
    this.showEvaluation = true

    const evalObj = new EvaluationData()
    evalObj.id = Date.now().toString()
    evalObj.sessionId = this.sessionId
    evalObj.clarityScore = evalResult.clarityScore.toString()
    evalObj.structureScore = evalResult.structureScore.toString()
    evalObj.completenessScore = evalResult.completenessScore.toString()
    evalObj.accuracyScore = evalResult.accuracyScore.toString()
    evalObj.confidenceScore = evalResult.confidenceScore.toString()
    evalObj.overallScore = evalResult.overallScore.toString()
    evalObj.feedback = evalResult.feedback
    evalObj.modelAnswer = evalResult.modelAnswer
    evalObj.weakTopics = '[]'
    evalObj.createdAt = Date.now().toString()
    this.storage.addEvaluation(evalObj)

    const feedbackMessage = new ChatMessageData()
    feedbackMessage.id = (Date.now() + 2).toString()
    feedbackMessage.sessionId = this.sessionId
    feedbackMessage.role = 'assistant'
    feedbackMessage.content = 'Evaluation Score: ' + evalResult.overallScore + '%\n\n' + evalResult.feedback
    feedbackMessage.timestamp = Date.now().toString()
    this.chatMessages.push(feedbackMessage)
    this.storage.addChatMessage(feedbackMessage)

    const sessionObj = new SessionData()
    sessionObj.id = this.sessionId
    sessionObj.topicId = this.topicId
    sessionObj.questionId = ''
    sessionObj.questionContent = this.currentQuestion
    sessionObj.userAnswer = this.userAnswer
    sessionObj.recordingPath = ''
    sessionObj.duration = '0'
    sessionObj.startedAt = Date.now().toString()
    sessionObj.endedAt = Date.now().toString()
    this.storage.addSession(sessionObj)
    this.isProcessing = false
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
    } else {
      Image($r('app.media.foreground')).width(size).height(size).objectFit(ImageFit.Contain).opacity(dimmed ? 0.55 : 1)
    }
  }

  @Builder
  private controlButton(label: string, icon: string, kind: string) {
    Button(icon + '  ' + label)
      .height(46)
      .layoutWeight(1)
      .fontSize(13)
      .fontColor(kind === 'primary' ? '#FFFFFF' : (kind === 'danger' ? '#F03A43' : '#1655FF'))
      .backgroundColor(kind === 'primary' ? '#1E55FF' : '#FFFFFF')
      .borderRadius(11)
      .border({ width: kind === 'primary' ? 0 : 1, color: kind === 'danger' ? '#F03A43' : '#2C5CFF' })
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
          .fontColor('#101733')
          .onClick(() => {
            router.back()
          })
        Text('Mock Oral Exam')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111936')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Text('•••')
          .fontSize(19)
          .fontColor('#111936')
      }
      .width('100%')
      .height(58)
      .padding({ left: 18, right: 18, top: 8 })

      Scroll() {
        Column() {
          Text('▯  ' + (this.topicTitle.length > 0 ? this.topicTitle : 'Operating Systems'))
            .fontSize(13)
            .fontColor('#1655FF')
            .padding({ left: 15, right: 15, top: 8, bottom: 8 })
            .backgroundColor('#EEF3FF')
            .borderRadius(18)

          Row() {
            Text('Question 3 of 10')
              .fontSize(12)
              .fontColor('#4F5A78')
            Blank()
            Text('◷  04:18')
              .fontSize(14)
              .fontColor('#F03A43')
          }
          .width('100%')
          .margin({ top: 20, bottom: 12 })

          Column() {
            Text(this.currentQuestion.length > 0 ? this.currentQuestion : 'Explain the difference between a process and a thread, and describe when context switching occurs.')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#111936')
              .lineHeight(29)
              .width('100%')
          }
          .height(164)
          .width('100%')
          .padding({ left: 22, right: 22, top: 20 })
          .backgroundColor('#FFFFFF')
          .borderRadius(14)
          .border({ width: 1, color: '#E5EAF5' })
          .shadow({ radius: 12, color: '#10285A12', offsetY: 6 })

          Text('▂▅▇▃▆▂▅▇▃▆▂▇▅▃▂▅▇▃▆▂▅▇▃▆▂▅▇▃▆▂▅▇')
            .fontSize(22)
            .fontColor('#1655FF')
            .width('100%')
            .textAlign(TextAlign.Center)
            .margin({ top: 28 })

          Stack({ alignContent: Alignment.Center }) {
            Column()
              .width(124)
              .height(124)
              .backgroundColor('#F4F7FF')
              .borderRadius(62)
            Column()
              .width(106)
              .height(106)
              .backgroundColor('#FFFFFF')
              .borderRadius(53)
            Column() {
              this.brandIcon('mic', 72)
            }
            .width(92)
            .height(92)
            .justifyContent(FlexAlign.Center)
            .backgroundColor('#3B55EA')
            .borderRadius(46)
            .shadow({ radius: 22, color: '#3B55EA4D', offsetY: 10 })
          }
          .width(130)
          .height(130)
          .margin({ top: 16 })

          Row() {
            Column()
              .width(10)
              .height(10)
              .backgroundColor('#1655FF')
              .borderRadius(5)
            Text(this.isProcessing ? 'Evaluating answer...' : (this.isRecording ? 'Recording answer...' : 'Answer ended'))
              .fontSize(13)
              .fontColor('#59627E')
              .margin({ left: 10 })
          }
          .margin({ top: 4, bottom: 18 })

          Row() {
            Button('Ⅱ  Pause')
              .height(46)
              .layoutWeight(1)
              .fontSize(13)
              .fontColor('#1655FF')
              .backgroundColor('#FFFFFF')
              .borderRadius(11)
              .border({ width: 1, color: '#2C5CFF' })
              .onClick(() => {
                this.pauseRecording()
              })
            Button('■  End Answer')
              .height(46)
              .layoutWeight(1)
              .fontSize(13)
              .fontColor('#F03A43')
              .backgroundColor('#FFFFFF')
              .borderRadius(11)
              .border({ width: 1, color: '#F03A43' })
              .margin({ left: 12 })
              .onClick(() => {
                this.endAnswer()
              })
            Button('Next Question  ›')
              .height(46)
              .layoutWeight(1)
              .fontSize(13)
              .fontColor('#FFFFFF')
              .backgroundColor('#1E55FF')
              .borderRadius(11)
              .margin({ left: 12 })
              .onClick(() => {
                this.startSession()
              })
          }
          .width('100%')

          Row() {
            Column() {
              Text('✦  AI Follow-up')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1655FF')
                .width('100%')
              Text('Can you give a real operating-system example?')
                .fontSize(13)
                .fontColor('#111936')
                .lineHeight(20)
                .width('100%')
                .margin({ top: 10 })
            }
            .layoutWeight(1)
            Text('›')
              .fontSize(24)
              .fontColor('#111936')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .border({ width: 1, color: '#E5EAF5' })
          .margin({ top: 20 })

          Column() {
            Text('♧  Structure tip')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1655FF')
              .width('100%')
            Text('definition → differences → example → conclusion')
              .fontSize(12)
              .fontColor('#59627E')
              .width('100%')
              .margin({ top: 10 })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#F0F4FF')
          .borderRadius(12)
          .margin({ top: 14, bottom: 16 })
        }
        .width('100%')
        .padding({ left: 18, right: 18 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      this.bottomNav('Practice')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FDFEFF')
  }
}
