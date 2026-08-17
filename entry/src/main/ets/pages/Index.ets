import { router } from '@kit.ArkUI'

@Entry
@Component
struct Index {
  aboutToAppear(): void {
    router.replaceUrl({ url: 'pages/HomePage' })
  }

  build() {
    Column() {
      Column() {
        Text('|||')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .textAlign(TextAlign.Center)
      }
      .width(72)
      .height(72)
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#2754F2')
      .borderRadius(20)
      .shadow({ radius: 18, color: '#334FE04D', offsetY: 8 })
      .margin({ top: 80, bottom: 18 })

      Text('StudyOral Coach')
        .fontSize(34)
        .fontWeight(FontWeight.Bold)
        .fontColor('#080D2D')

      Text('AI oral exam practice for exams, thesis defenses, and academic interviews.')
        .fontSize(16)
        .fontColor('#485170')
        .textAlign(TextAlign.Center)
        .lineHeight(24)
        .width('82%')
        .margin({ top: 10 })

      Blank()

      Button('Start Mock Exam')
        .width('84%')
        .height(54)
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .backgroundColor('#2754F2')
        .borderRadius(14)
        .shadow({ radius: 20, color: '#2754F24D', offsetY: 10 })
        .onClick(() => {
          router.pushUrl({ url: 'pages/HomePage' })
        })

      Button('Manage Topics')
        .width('84%')
        .height(54)
        .fontSize(17)
        .fontColor('#2754F2')
        .backgroundColor('#EEF3FF')
        .borderRadius(14)
        .margin({ top: 14, bottom: 52 })
        .onClick(() => {
          router.pushUrl({ url: 'pages/TopicPage' })
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8FAFF')
  }
}
