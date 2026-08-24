import { router } from '@kit.ArkUI'
import { common } from '@kit.AbilityKit'
import { EvaluationData, SessionData } from '../model/DataTypes'
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
  @State materialId: string = ''
  @State fileName: string = 'Practice Result'
  @State selectedSession: SessionData = new SessionData()
  @State selectedEvaluation: EvaluationData = new EvaluationData()
  @State hasSelectedEvaluation: boolean = false
  @State rows: HistoryQuestionResult[] = []
  @State isLoading: boolean = true
  private storage: StorageService = StorageService.getInstance()

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>
    this.sessionId = params.sessionId ?? ''
    this.materialId = params.materialId ?? ''
    const context = getContext(this) as common.UIAbilityContext
    this.storage.init(context).then(async () => {
      await this.loadData(context)
    })
  }

  private async loadData(context: common.UIAbilityContext): Promise<void> {
    const sessions = this.storage.getSessions()
    const selected = sessions.find((session: SessionData) => session.id === this.sessionId)
    if (selected !== undefined) {
      this.selectedSession = selected
    }
    const evaluation = this.storage.getEvaluationBySessionId(this.sessionId)
    if (evaluation !== null) {
      this.selectedEvaluation = evaluation
      this.hasSelectedEvaluation = true
    }

    const evaluations = this.storage.getEvaluations()
    const service = new MaterialIngestionService(context)
    const materials = await service.listRecent(1000)
    const material = materials.find((item: StudyMaterialRecord) => item.id === this.materialId)
    if (material !== undefined) {
      this.fileName = material.fileName
    }
    const questions = this.materialId.length > 0 ? await service.listQuestions(this.materialId) :
      await service.listAllQuestions(1000)
    const resultRows: HistoryQuestionResult[] = []
    questions.forEach((question: MaterialQuestionAnswerRecord) => {
      const row = new HistoryQuestionResult()
      row.id = question.id
      row.question = question.question
      row.correctAnswer = question.answer
      const practicedSession = sessions.find((session: SessionData) => session.questionId === question.id)
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
    this.rows = resultRows
    this.isLoading = false
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
        Column().height(6).width(value + '%').backgroundColor('#3158F4').borderRadius(3)
      }
      .layoutWeight(1)
      Text(value)
        .fontSize(12)
        .fontColor('#111936')
        .textAlign(TextAlign.End)
        .width(34)
    }
    .width('100%')
    .margin({ top: 12 })
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
          if (this.hasSelectedEvaluation) {
            Column() {
              Text(this.selectedEvaluation.overallScore + '/100')
                .fontSize(34)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1655FF')
                .width('100%')
              Text(this.fileName)
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#111936')
                .lineHeight(21)
                .width('100%')
                .margin({ top: 10 })
              Text('Includes practiced and not practiced questions from this file.')
                .fontSize(12)
                .fontColor('#59627E')
                .lineHeight(18)
                .width('100%')
                .margin({ top: 6 })
              this.metric('Clarity', this.selectedEvaluation.clarityScore)
              this.metric('Structure', this.selectedEvaluation.structureScore)
              this.metric('Completeness', this.selectedEvaluation.completenessScore)
              this.metric('Accuracy', this.selectedEvaluation.accuracyScore)
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .border({ width: 1, color: '#E6EAF4' })
            .margin({ bottom: 16 })
          }

          if (this.isLoading) {
            Text('Loading results...')
              .fontSize(14)
              .fontColor('#59627E')
              .width('100%')
              .textAlign(TextAlign.Center)
              .margin({ top: 32 })
          } else if (this.rows.length === 0) {
            Image($r('app.media.ic_materials')).width(64).height(64).objectFit(ImageFit.Contain).margin({ top: 28 })
            Text('No question bank found.')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor('#111936')
              .margin({ top: 12 })
          } else {
            Text('All questions in this file')
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
}
