import { router } from '@kit.ArkUI'

@Entry
@Component
struct PracticeStatsPage {
  @Builder
  private stat(title: string, value: string, iconName: string) {
    Row() {
      Image(iconName === 'history' ? $r('app.media.ic_history') : $r('app.media.ic_materials'))
        .width(46)
        .height(46)
        .objectFit(ImageFit.Contain)
      Column() {
        Text(title).fontSize(13).fontColor('#59627E')
        Text(value).fontSize(24).fontWeight(FontWeight.Bold).fontColor('#1655FF').margin({ top: 3 })
      }
      .layoutWeight(1)
      .margin({ left: 14 })
      Text('›').fontSize(24).fontColor('#2E50F5')
    }
    .height(84)
    .width('100%')
    .padding({ left: 14, right: 14 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .border({ width: 1, color: '#E6EAF4' })
    .margin({ bottom: 12 })
    .onClick(() => {
      this.getUIContext().getRouter().pushUrl({ url: 'pages/HistoryPage' })
    })
  }

  build() {
    Column() {
      Row() {
        Text('‹').fontSize(34).fontColor('#111936').onClick(() => router.back())
        Text('Practice Stats').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#111936').layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(34)
      }
      .height(58)
      .padding({ left: 18, right: 18, top: 8 })

      Column() {
        this.stat('Questions Practiced', '48', 'materials')
        this.stat('Mock Exams Completed', '12', 'history')
        this.stat('Average Session Time', '18 min', 'history')
        Button('Continue Practice')
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
