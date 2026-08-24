import { router } from '@kit.ArkUI'
import { common } from '@kit.AbilityKit'
import { EvaluationData, SessionData } from '../model/DataTypes'
import { StorageService } from '../services/StorageService'

@Entry
@Component
struct ScorePage {
  @State hasScore: boolean = false
  @State hasSession: boolean = false
  @State latestEvaluation: EvaluationData = new EvaluationData()
  @State latestSession: SessionData = new SessionData()
  private storage: StorageService = StorageService.getInstance()

  aboutToAppear(): void {
    const context = getContext(this) as common.UIAbilityContext
    this.storage.init(context).then(() => {
      const evaluations = this.storage.getEvaluations()
      if (evaluations.length > 0) {
        this.hasScore = true
        this.latestEvaluation = evaluations[0]
        const session = this.storage.getSessions().find((item: SessionData) => item.id === evaluations[0].sessionId)
        if (session !== undefined) {
          this.hasSession = true
          this.latestSession = session
        }
      }
    })
  }

  private metricValue(value: string): number {
    const parsed = Number(value)
    if (Number.isNaN(parsed)) {
      return 0
    }
    return Math.max(0, Math.min(100, Math.round(parsed)))
  }

  @Builder
  private metric(label: string, value: number) {
    Row() {
      Text(label).fontSize(13).fontColor('#111936').width(104)
      Stack({ alignContent: Alignment.Start }) {
        Column().height(6).width('100%').backgroundColor('#E8ECF7').borderRadius(3)
        Column().height(6).width(value.toString() + '%').backgroundColor('#3158F4').borderRadius(3)
      }
      .layoutWeight(1)
      Text(value.toString()).fontSize(13).fontColor('#111936').width(34).textAlign(TextAlign.End)
    }
    .width('100%')
    .margin({ top: 16 })
  }

  build() {
    Column() {
      Row() {
        Text('‹').fontSize(34).fontColor('#111936').onClick(() => router.back())
        Text('Score Results').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#111936').layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(34)
      }
      .height(58)
      .padding({ left: 18, right: 18, top: 8 })

      Scroll() {
        Column() {
          if (!this.hasScore) {
            Image($r('app.media.ic_result')).width(72).height(72).objectFit(ImageFit.Contain).margin({ top: 28 })
            Text('No score yet.')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor('#111936')
              .margin({ top: 12 })
            Text('Submit an answer in Practice to generate a score.')
              .fontSize(13)
              .fontColor('#59627E')
              .lineHeight(20)
              .textAlign(TextAlign.Center)
              .margin({ top: 8 })
          } else {
            Column() {
              Image($r('app.media.ic_result')).width(72).height(72).objectFit(ImageFit.Contain)
              Text(this.metricValue(this.latestEvaluation.overallScore).toString())
                .fontSize(58)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1655FF')
                .margin({ top: 12 })
              Text('/100').fontSize(16).fontColor('#59627E')
              this.metric('Clarity', this.metricValue(this.latestEvaluation.clarityScore))
              this.metric('Structure', this.metricValue(this.latestEvaluation.structureScore))
              this.metric('Completeness', this.metricValue(this.latestEvaluation.completenessScore))
              this.metric('Accuracy', this.metricValue(this.latestEvaluation.accuracyScore))
              if (this.latestEvaluation.feedback.length > 0) {
                Text(this.latestEvaluation.feedback)
                  .fontSize(13)
                  .fontColor('#59627E')
                  .lineHeight(20)
                  .width('100%')
                  .margin({ top: 18 })
              }
            }
            .width('100%')
            .padding(20)
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .border({ width: 1, color: '#E6EAF4' })

            if (this.hasSession) {
              Column() {
                Text('Question')
                  .fontSize(12)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#1655FF')
                  .width('100%')
                Text(this.latestSession.questionContent)
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#111936')
                  .lineHeight(21)
                  .width('100%')
                  .margin({ top: 8 })
                Text('Your Answer')
                  .fontSize(12)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#59627E')
                  .width('100%')
                  .margin({ top: 14 })
                Text(this.latestSession.userAnswer)
                  .fontSize(13)
                  .fontColor('#3F4966')
                  .lineHeight(20)
                  .width('100%')
                  .margin({ top: 6 })
                if (this.latestEvaluation.modelAnswer.length > 0) {
                  Text('Correct Answer')
                    .fontSize(12)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#1655FF')
                    .width('100%')
                    .margin({ top: 14 })
                  Text(this.latestEvaluation.modelAnswer)
                    .fontSize(13)
                    .fontColor('#3F4966')
                    .lineHeight(20)
                    .width('100%')
                    .margin({ top: 6 })
                }
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#FFFFFF')
              .borderRadius(12)
              .border({ width: 1, color: '#E6EAF4' })
              .margin({ top: 14 })
            }

            Button('View History')
              .height(44)
              .width('100%')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1655FF')
              .backgroundColor('#EAF0FF')
              .borderRadius(11)
              .margin({ top: 16 })
              .onClick(() => {
                this.getUIContext().getRouter().pushUrl({ url: 'pages/HistoryPage' })
              })
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
