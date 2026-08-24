import { router } from '@kit.ArkUI'
import { common } from '@kit.AbilityKit'
import { MaterialQuestionAnswerRecord } from '../model/StudyMaterialRecord'
import { MaterialIngestionService } from '../services/MaterialIngestionService'

@Entry
@Component
struct QuestionBankPage {
  @State questions: MaterialQuestionAnswerRecord[] = []
  @State isLoading: boolean = true

  aboutToAppear(): void {
    const context = getContext(this) as common.UIAbilityContext
    const service = new MaterialIngestionService(context)
    service.listAllQuestions(1000).then((items: MaterialQuestionAnswerRecord[]) => {
      this.questions = items
      this.isLoading = false
    }).catch((err: Error) => {
      console.error('[StudyOralQuestionBank] load failed: ' + JSON.stringify(err))
      this.isLoading = false
    })
  }

  @Builder
  private questionCard(item: MaterialQuestionAnswerRecord, index: number) {
    Column() {
      Row() {
        Text('#' + (index + 1).toString())
          .fontSize(12)
          .fontColor('#1655FF')
          .fontWeight(FontWeight.Bold)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor('#EEF3FF')
          .borderRadius(8)
        Blank()
        if (item.practiceCount > 0) {
          Text('Practiced ' + item.practiceCount.toString() + 'x')
            .fontSize(12)
            .fontColor('#59627E')
        }
      }
      .width('100%')

      Text(item.question)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#111936')
        .lineHeight(22)
        .width('100%')
        .margin({ top: 12 })

      Text('Answer')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1655FF')
        .width('100%')
        .margin({ top: 14 })

      Text(item.answer)
        .fontSize(13)
        .fontColor('#3F4966')
        .lineHeight(20)
        .width('100%')
        .margin({ top: 6 })
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
        Text('Question Bank').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#111936').layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(34)
      }
      .height(58)
      .padding({ left: 18, right: 18, top: 8 })

      Scroll() {
        Column() {
          if (this.isLoading) {
            Text('Loading questions...')
              .fontSize(14)
              .fontColor('#59627E')
              .width('100%')
              .textAlign(TextAlign.Center)
              .margin({ top: 32 })
          } else if (this.questions.length === 0) {
            Image($r('app.media.ic_materials')).width(64).height(64).objectFit(ImageFit.Contain).margin({ top: 28 })
            Text('No questions are ready yet.')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor('#111936')
              .margin({ top: 12 })
            Text('Upload a document in Materials to generate Q&A.')
              .fontSize(13)
              .fontColor('#59627E')
              .lineHeight(20)
              .textAlign(TextAlign.Center)
              .margin({ top: 8 })
          } else {
            Text(this.questions.length.toString() + ' prepared Q&A')
              .fontSize(13)
              .fontColor('#59627E')
              .width('100%')
              .margin({ bottom: 14 })
            ForEach(this.questions, (item: MaterialQuestionAnswerRecord, index: number) => {
              this.questionCard(item, index)
            }, (item: MaterialQuestionAnswerRecord) => item.id)
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
