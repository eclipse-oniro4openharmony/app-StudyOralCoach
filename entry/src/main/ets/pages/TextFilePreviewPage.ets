import { router } from '@kit.ArkUI'
import fs from '@ohos.file.fs'

interface TextFilePreviewParams {
  filePath?: string
  title?: string
}

@Entry
@Component
struct TextFilePreviewPage {
  @State private title: string = 'Document'
  @State private body: string = ''
  @State private loadFailed: boolean = false

  aboutToAppear(): void {
    const params = router.getParams() as TextFilePreviewParams | null
    const filePath = params?.filePath ?? ''
    this.title = params?.title ?? 'Document'
    if (filePath.length === 0) {
      this.loadFailed = true
      return
    }
    try {
      this.body = fs.readTextSync(filePath)
    } catch (err) {
      this.loadFailed = true
      console.error('[StudyOralTextPreview] load failed: ' + JSON.stringify(err))
    }
  }

  build() {
    Column() {
      Row() {
        Text('‹')
          .fontSize(34)
          .fontColor('#111936')
          .onClick(() => router.back())
        Text(this.title)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111936')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Blank().width(34)
      }
      .width('100%')
      .height(58)
      .padding({ left: 18, right: 18, top: 8 })
      .backgroundColor('#FFFFFF')

      if (this.loadFailed) {
        Column() {
          Text('无法预览此文本文件')
            .fontSize(16)
            .fontColor('#59627E')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        Scroll() {
          Text(this.body)
            .fontSize(14)
            .fontColor('#222B45')
            .lineHeight(22)
            .width('100%')
            .textAlign(TextAlign.Start)
            .padding(18)
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Auto)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FDFEFF')
  }
}
