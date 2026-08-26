import { router } from '@kit.ArkUI'
import { common } from '@kit.AbilityKit'
import { EvaluationData, PracticeExamData, SessionData } from '../model/DataTypes'
import { MaterialQuestionAnswerRecord, StudyMaterialRecord } from '../model/StudyMaterialRecord'
import { MaterialIngestionService } from '../services/MaterialIngestionService'
import { StorageService } from '../services/StorageService'

class HistoryQuestionResult {
  id: string = ''
  question: string = ''
  correctAnswer: string = ''
  practiced: boolean = false
  userAnswer: string = ''
  score: string = '0'
  feedback: string = ''
}

@Entry
@Component
struct HistoryDetailPage {
  @State sessionId: string = ''
  @State examId: string = ''
  @State materialId: string = ''
  @State fileName: string = 'Practice Result'
  @State attachmentNames: string = ''
  @State progressText: string = ''
  @State scoreText: string = ''
  @State selectedSession: SessionData = new SessionData()
  @State selectedEvaluation: EvaluationData = new EvaluationData()
  @State hasSelectedEvaluation: boolean = false
  @State rows: HistoryQuestionResult[] = []
  @State isLoading: boolean = true
  private storage: StorageService = StorageService.getInstance()

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>
    this.sessionId = params.sessionId ?? ''
    this.examId = params.examId ?? ''
    this.materialId = params.materialId ?? ''
    this.attachmentNames = params.attachmentNames ?? ''
    this.progressText = params.progressText ?? ''
    this.scoreText = params.scoreText ?? ''
    this.selectedEvaluation.overallScore = params.scoreText ?? '0'
    this.selectedEvaluation.clarityScore = params.clarityScore ?? '0'
    this.selectedEvaluation.structureScore = params.structureScore ?? '0'
    this.selectedEvaluation.completenessScore = params.completenessScore ?? '0'
    this.selectedEvaluation.accuracyScore = params.accuracyScore ?? '0'
    if ((params.scoreText ?? '').length > 0) {
      this.hasSelectedEvaluation = true
    }
    if (this.attachmentNames.length > 0) {
      this.fileName = this.attachmentNames
    }
    const context = getContext(this) as common.UIAbilityContext
    this.storage.init(context).then(async () => {
      await this.loadData(context)
    })
  }

  private async loadData(context: common.UIAbilityContext): Promise<void> {
    let nextSessionId = this.sessionId
    let nextSelectedSession = this.selectedSession
    let nextSelectedEvaluation = this.selectedEvaluation
    let nextHasSelectedEvaluation = this.hasSelectedEvaluation
    let nextScoreText = this.scoreText
    let nextFileName = this.fileName
    let nextAttachmentNames = this.attachmentNames
    let nextProgressText = this.progressText

    const sessions = this.storage.getSessions()
    const selected = this.sessionId.length > 0 ? sessions.find((session: SessionData) => session.id === this.sessionId) :
      sessions.find((session: SessionData) => (session.examId ?? '') === this.examId)
    if (selected !== undefined) {
      nextSelectedSession = selected
      nextSessionId = selected.id
    }
    const evaluation = this.storage.getEvaluationBySessionId(nextSessionId)
    if (evaluation !== null) {
      nextSelectedEvaluation = evaluation
      nextHasSelectedEvaluation = true
      nextScoreText = evaluation.overallScore
    }

    const evaluations = this.storage.getEvaluations()
    const service = new MaterialIngestionService(context)
    const materials = await service.listRecent(1000)
    const allQuestions = await service.listAllQuestions(1000)
    const exam = this.examId.length > 0 ? this.storage.getPracticeExamById(this.examId) : null
    let questions: MaterialQuestionAnswerRecord[] = []
    if (exam !== null) {
      const examAttachmentNames = this.fileNamesForExam(exam, allQuestions, materials)
      if (nextAttachmentNames.length === 0 && examAttachmentNames.length > 0) {
        nextAttachmentNames = examAttachmentNames
        nextFileName = examAttachmentNames
      }
      if (nextProgressText.length === 0) {
        nextProgressText = exam.answeredQuestionIds.length.toString() + '/' + exam.questionIds.length.toString()
      }
      exam.questionIds.forEach((questionId: string) => {
        const question = allQuestions.find((item: MaterialQuestionAnswerRecord) => item.id === questionId)
        if (question !== undefined) {
          questions.push(question)
        }
      })
    } else {
      const material = materials.find((item: StudyMaterialRecord) => item.id === this.materialId)
      if (material !== undefined) {
        nextFileName = material.fileName
        nextAttachmentNames = material.fileName
      }
      questions = this.materialId.length > 0 ? await service.listQuestions(this.materialId) : allQuestions
    }
    const resultRows: HistoryQuestionResult[] = []
    questions.forEach((question: MaterialQuestionAnswerRecord) => {
      const row = new HistoryQuestionResult()
      row.id = question.id
      row.question = question.question
      row.correctAnswer = question.answer
      const practicedSession = this.examId.length > 0 ?
        sessions.find((session: SessionData) => (session.examId ?? '') === this.examId && session.questionId === question.id) :
        sessions.find((session: SessionData) => session.questionId === question.id)
      if (practicedSession !== undefined) {
        row.practiced = true
        row.userAnswer = practicedSession.userAnswer
        const practicedEvaluation = evaluations.find((item: EvaluationData) => item.sessionId === practicedSession.id)
        if (practicedEvaluation !== undefined) {
          row.score = practicedEvaluation.overallScore
          row.feedback = practicedEvaluation.feedback
        }
      }
      resultRows.push(row)
    })
    this.sessionId = nextSessionId
    this.selectedSession = nextSelectedSession
    this.selectedEvaluation = nextSelectedEvaluation
    this.hasSelectedEvaluation = nextHasSelectedEvaluation
    this.scoreText = nextScoreText
    this.fileName = nextFileName
    this.attachmentNames = nextAttachmentNames
    this.progressText = nextProgressText
    this.rows = resultRows
    this.isLoading = false
  }

  private fileNamesForMaterialIds(materialIds: string[], materials: StudyMaterialRecord[]): string {
    const names: string[] = []
    materialIds.forEach((materialId: string) => {
      const material = materials.find((item: StudyMaterialRecord) => item.id === materialId)
      if (material !== undefined && names.indexOf(material.fileName) < 0) {
        names.push(material.fileName)
      }
    })
    if (names.length === 0) {
      return 'Practice files'
    }
    return names.join(', ')
  }

  private fileNamesForExam(exam: PracticeExamData, questions: MaterialQuestionAnswerRecord[],
    materials: StudyMaterialRecord[]): string {
    let materialIds = exam.materialIds
    if (materialIds.length === 0) {
      materialIds = []
      exam.questionIds.forEach((questionId: string) => {
        const question = questions.find((item: MaterialQuestionAnswerRecord) => item.id === questionId)
        if (question !== undefined && question.materialId.length > 0 && materialIds.indexOf(question.materialId) < 0) {
          materialIds.push(question.materialId)
        }
      })
    }
    return this.fileNamesForMaterialIds(materialIds, materials)
  }

  private metricDisplayValue(value: string): string {
    return value
  }

  private metricWidthValue(value: string): string {
    if (!this.hasSelectedEvaluation || value.length === 0) {
      return '0%'
    }
    return value + '%'
  }

  @Builder
  private metric(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(12)
        .fontColor('#111936')
        .width(104)
      Stack({ alignContent: Alignment.Start }) {
        Column().height(6).width('100%').backgroundColor('#E8ECF7').borderRadius(3)
        Column().height(6).width(this.metricWidthValue(value)).backgroundColor('#3158F4').borderRadius(3)
      }
      .layoutWeight(1)
      Text(this.metricDisplayValue(value))
        .fontSize(12)
        .fontColor('#111936')
        .textAlign(TextAlign.End)
        .width(34)
    }
    .width('100%')
    .margin({ top: 12 })
  }

  @Builder
  private resultSummaryCard() {
    Column() {
      Text('Result Evaluation')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#59627E')
        .width('100%')
      if (this.scoreText.length > 0) {
        Text(this.scoreText + '/100')
          .fontSize(34)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1655FF')
          .width('100%')
          .margin({ top: 6 })
      } else {
        Text('Practice Result')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111936')
          .width('100%')
          .margin({ top: 6 })
      }
      Text('Attachments: ' + (this.attachmentNames.length > 0 ? this.attachmentNames : this.fileName))
        .fontSize(12)
        .fontColor('#59627E')
        .lineHeight(18)
        .width('100%')
        .margin({ top: 10 })
      if (this.progressText.length > 0) {
        Text('Progress: ' + this.progressText)
          .fontSize(12)
          .fontColor('#59627E')
          .width('100%')
          .margin({ top: 4 })
      }
      if (this.hasSelectedEvaluation) {
        this.metric('Clarity', this.selectedEvaluation.clarityScore)
        this.metric('Structure', this.selectedEvaluation.structureScore)
        this.metric('Completeness', this.selectedEvaluation.completenessScore)
        this.metric('Accuracy', this.selectedEvaluation.accuracyScore)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .border({ width: 1, color: '#E6EAF4' })
    .margin({ bottom: 16 })
  }

  @Builder
  private questionResultCard(row: HistoryQuestionResult) {
    Column() {
      Row() {
        Text(row.practiced ? row.score + '/100' : 'Not practiced')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(row.practiced ? (Number(row.score) < 60 ? '#F03A43' : '#1655FF') : '#59627E')
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .backgroundColor(row.practiced ? (Number(row.score) < 60 ? '#FFF1F1' : '#EEF3FF') : '#F4F6FA')
          .borderRadius(10)
        Blank()
      }
      .width('100%')

      Text(row.question)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#111936')
        .lineHeight(22)
        .width('100%')
        .margin({ top: 10 })

      if (row.practiced) {
        Text('Your Answer')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#59627E')
          .width('100%')
          .margin({ top: 12 })
        Text(row.userAnswer.length > 0 ? row.userAnswer : 'No answer')
          .fontSize(13)
          .fontColor('#3F4966')
          .lineHeight(20)
          .width('100%')
          .margin({ top: 6 })
      }

      Text('Correct Answer')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1655FF')
        .width('100%')
        .margin({ top: 12 })
      Text(row.correctAnswer)
        .fontSize(13)
        .fontColor('#3F4966')
        .lineHeight(20)
        .width('100%')
        .margin({ top: 6 })

      if (row.feedback.length > 0) {
        Text(row.feedback)
          .fontSize(12)
          .fontColor('#59627E')
          .lineHeight(19)
          .width('100%')
          .margin({ top: 12 })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .border({ width: 1, color: '#E6EAF4' })
    .margin({ bottom: 12 })
  }

  build() {
    Column() {
      Row() {
        Text('‹').fontSize(34).fontColor('#111936').onClick(() => router.back())
        Text('Practice Result').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#111936').layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(34)
      }
      .height(58)
      .padding({ left: 18, right: 18, top: 8 })

      Scroll() {
        Column() {
          this.resultSummaryCard()

          if (!this.isLoading && this.rows.length === 0) {
            Image($r('app.media.ic_materials')).width(64).height(64).objectFit(ImageFit.Contain).margin({ top: 28 })
            Text('No question bank found.')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor('#111936')
              .margin({ top: 12 })
          } else if (!this.isLoading) {
            Text(this.examId.length > 0 ? 'All questions in this exam' : 'All questions in this file')
              .fontSize(13)
              .fontColor('#59627E')
              .width('100%')
              .margin({ bottom: 12 })
            ForEach(this.rows, (row: HistoryQuestionResult) => {
              this.questionResultCard(row)
            }, (row: HistoryQuestionResult) => row.id)
          }
        }
        .width('100%')
        .padding({ left: 18, right: 18, top: 16, bottom: 24 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FDFEFF')
  }

  pageTransition() {
    PageTransitionEnter({ type: RouteType.None, duration: 0 })
    PageTransitionExit({ type: RouteType.None, duration: 0 })
  }
}
