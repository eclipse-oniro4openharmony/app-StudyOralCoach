import { router } from '@kit.ArkUI'
import { common } from '@kit.AbilityKit'
import { EvaluationData, SessionData } from '../model/DataTypes'
import { StorageService } from '../services/StorageService'

class MissedProblemView {
  id: string = ''
  question: string = ''
  userAnswer: string = ''
  correctAnswer: string = ''
  score: number = 0
  feedback: string = ''
  createdAt: string = ''
}

@Entry
@Component
struct WeakTopicsPage {
  @State missedProblems: MissedProblemView[] = []
  private storage: StorageService = StorageService.getInstance()

  aboutToAppear(): void {
    const context = getContext(this) as common.UIAbilityContext
    this.storage.init(context).then(() => {
      this.loadMissedProblems()
    })
  }

  private loadMissedProblems(): void {
    const sessions = this.storage.getSessions()
    const evaluations = this.storage.getEvaluations()
    const rows: MissedProblemView[] = []
    evaluations.forEach((evaluation: EvaluationData) => {
      const score = Number(evaluation.overallScore)
      if (score >= 60) {
        return
      }
      const session = sessions.find((item: SessionData) => item.id === evaluation.sessionId)
      if (session === undefined) {
        return
      }
      if (session.questionId.length === 0) {
        return
      }
      const row = new MissedProblemView()
      row.id = evaluation.id
      row.question = session.questionContent
      row.userAnswer = session.userAnswer
      row.correctAnswer = evaluation.modelAnswer
      row.score = score
      row.feedback = evaluation.feedback
      row.createdAt = evaluation.createdAt
      rows.push(row)
    })
    this.missedProblems = rows
  }

  private formatTime(timestamp: string): string {
    const value = Number(timestamp)
    if (value <= 0) {
      return ''
    }
    const date = new Date(value)
    return (date.getMonth() + 1).toString() + '/' + date.getDate().toString() + ' ' +
      date.getHours().toString().padStart(2, '0') + ':' + date.getMinutes().toString().padStart(2, '0')
  }

  @Builder
  private missedCard(item: MissedProblemView) {
    Column() {
      Row() {
        Text(item.score.toString() + '/100')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#F03A43')
        Blank()
        Text(this.formatTime(item.createdAt))
          .fontSize(12)
          .fontColor('#59627E')
      }
      .width('100%')

      Text(item.question)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#111936')
        .lineHeight(22)
        .width('100%')
        .margin({ top: 10 })

      Text('Your Answer')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor('#F03A43')
        .width('100%')
        .margin({ top: 12 })
      Text(item.userAnswer.length > 0 ? item.userAnswer : 'No answer')
        .fontSize(13)
        .fontColor('#3F4966')
        .lineHeight(20)
        .width('100%')
        .margin({ top: 6 })

      if (item.correctAnswer.length > 0) {
        Text('Correct Answer')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1655FF')
          .width('100%')
          .margin({ top: 12 })
        Text(item.correctAnswer)
          .fontSize(13)
          .fontColor('#3F4966')
          .lineHeight(20)
          .width('100%')
          .margin({ top: 6 })
      }

      if (item.feedback.length > 0) {
        Text(item.feedback)
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
        Text('Missed problems').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#111936').layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(34)
      }
      .height(58)
      .padding({ left: 18, right: 18, top: 8 })

      Scroll() {
        Column() {
          if (this.missedProblems.length === 0) {
            Image($r('app.media.ic_target')).width(64).height(64).objectFit(ImageFit.Contain).margin({ top: 28 })
            Text('No missed problems yet.')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor('#111936')
              .margin({ top: 12 })
            Text('Questions scored below 60 will appear here.')
              .fontSize(13)
              .fontColor('#59627E')
              .lineHeight(20)
              .textAlign(TextAlign.Center)
              .margin({ top: 8 })
          } else {
            Text(this.missedProblems.length.toString() + ' missed problems')
              .fontSize(13)
              .fontColor('#59627E')
              .width('100%')
              .margin({ bottom: 14 })
            ForEach(this.missedProblems, (item: MissedProblemView) => {
              this.missedCard(item)
            }, (item: MissedProblemView) => item.id)
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
