import { router } from '@kit.ArkUI'

@Entry
@Component
struct ScorePage {
  @Builder
  private metric(label: string, value: number) {
    Row() {
      Text(label).fontSize(13).fontColor('#111936').width(86)
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
        Text('Recent Score').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#111936').layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(34)
      }
      .height(58)
      .padding({ left: 18, right: 18, top: 8 })

      Column() {
        Image($r('app.media.ic_result')).width(72).height(72).objectFit(ImageFit.Contain)
        Text('82').fontSize(58).fontWeight(FontWeight.Bold).fontColor('#1655FF').margin({ top: 12 })
        Text('/100').fontSize(16).fontColor('#59627E')
        this.metric('Clarity', 84)
        this.metric('Structure', 78)
        this.metric('Accuracy', 85)
        Button('View History')
          .height(44)
          .width('100%')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1655FF')
          .backgroundColor('#EAF0FF')
          .borderRadius(11)
          .margin({ top: 22 })
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({ url: 'pages/HistoryPage' })
          })
      }
      .width('100%')
      .padding(20)
      .margin({ left: 18, right: 18, top: 22 })
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .border({ width: 1, color: '#E6EAF4' })

      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FDFEFF')
  }
}
