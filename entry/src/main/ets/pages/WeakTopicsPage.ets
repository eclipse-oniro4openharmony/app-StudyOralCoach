import { router } from '@kit.ArkUI'

@Entry
@Component
struct WeakTopicsPage {
  @Builder
  private topic(title: string, percent: number, iconName: string) {
    Row() {
      Image(iconName === 'code' ? $r('app.media.ic_code') : (iconName === 'os' ? $r('app.media.ic_os') : $r('app.media.ic_network')))
        .width(52)
        .height(52)
        .objectFit(ImageFit.Contain)
      Column() {
        Row() {
          Text(title).fontSize(15).fontWeight(FontWeight.Bold).fontColor('#111936').layoutWeight(1)
          Text(percent.toString() + '%').fontSize(12).fontColor('#59627E')
        }
        Stack({ alignContent: Alignment.Start }) {
          Column().height(5).width('100%').backgroundColor('#E8ECF4').borderRadius(3)
          Column().height(5).width(percent.toString() + '%').backgroundColor('#3158F4').borderRadius(3)
        }
        .height(5)
        .margin({ top: 10 })
      }
      .layoutWeight(1)
      .margin({ left: 14 })
      Text('›').fontSize(24).fontColor('#59627E').margin({ left: 8 })
    }
    .height(78)
    .width('100%')
    .padding({ left: 14, right: 14 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .border({ width: 1, color: '#E6EAF4' })
    .margin({ bottom: 12 })
    .onClick(() => {
      this.getUIContext().getRouter().pushUrl({ url: 'pages/TopicPage' })
    })
  }

  build() {
    Column() {
      Row() {
        Text('‹').fontSize(34).fontColor('#111936').onClick(() => router.back())
        Text('Weak Topics').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#111936').layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(34)
      }
      .height(58)
      .padding({ left: 18, right: 18, top: 8 })

      Column() {
        this.topic('Computer Networks', 54, 'network')
        this.topic('Operating Systems', 65, 'os')
        this.topic('Algorithms', 78, 'code')
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
