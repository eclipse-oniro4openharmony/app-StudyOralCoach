import { router } from '@kit.ArkUI'

@Entry
@Component
struct ExamModePage {
  @State selectedMode: string = 'Thesis Defense'

  @Builder
  private modeRow(title: string, desc: string, iconName: string) {
    Row() {
      Image(iconName === 'thesis' ? $r('app.media.ic_thesis') : $r('app.media.ic_result'))
        .width(48)
        .height(48)
        .objectFit(ImageFit.Contain)
      Column() {
        Text(title).fontSize(15).fontWeight(FontWeight.Bold).fontColor('#111936')
        Text(desc).fontSize(12).fontColor('#59627E').margin({ top: 4 })
      }
      .layoutWeight(1)
      .margin({ left: 14 })
      Text(this.selectedMode === title ? '✓' : '›')
        .fontSize(20)
        .fontColor('#1655FF')
    }
    .height(80)
    .width('100%')
    .padding({ left: 14, right: 14 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .border({ width: 1, color: this.selectedMode === title ? '#2F5BFF' : '#E6EAF4' })
    .margin({ bottom: 12 })
    .onClick(() => {
      this.selectedMode = title
    })
  }

  build() {
    Column() {
      Row() {
        Text('‹').fontSize(34).fontColor('#111936').onClick(() => router.back())
        Text('Exam Mode').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#111936').layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(34)
      }
      .height(58)
      .padding({ left: 18, right: 18, top: 8 })

      Column() {
        this.modeRow('Thesis Defense', 'Long-form academic defense practice', 'thesis')
        this.modeRow('Mock Oral Exam', 'Timed question-by-question practice', 'result')
        this.modeRow('Academic Interview', 'Concise answer and follow-up training', 'result')
        Button('Start Practice')
          .height(46)
          .width('100%')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .backgroundColor('#1655FF')
          .borderRadius(12)
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({ url: 'pages/TopicPage' })
          })
      }
      .padding({ left: 18, right: 18, top: 22 })
      .width('100%')

      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FDFEFF')
  }
}
