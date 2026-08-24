import { pdfService, pdfViewManager, PdfView } from '@kit.PDFKit'
import { router } from '@kit.ArkUI'
import { fileUri } from '@kit.CoreFileKit'

interface PdfViewerParams {
  pdfUri?: string
  title?: string
}

@Entry
@Component
struct PdfViewerPage {
  @State private title: string = 'PDF'
  @State private loadFailed: boolean = false
  private controller: pdfViewManager.PdfController = new pdfViewManager.PdfController()

  aboutToAppear(): void {
    const params = router.getParams() as PdfViewerParams | null
    const pdfUri = params?.pdfUri ?? ''
    if (pdfUri.length === 0) {
      this.loadFailed = true
      return
    }
    this.title = params?.title ?? 'PDF'
    let filePath = ''
    try {
      const uriObj = new fileUri.FileUri(pdfUri)
      filePath = uriObj.path
    } catch (_) {
      filePath = pdfUri.startsWith('file://') ? pdfUri.substring(7) : pdfUri
    }
    void this.loadPdf(filePath)
  }

  private async loadPdf(filePath: string): Promise<void> {
    try {
      const result: pdfService.ParseResult = await this.controller.loadDocument(filePath)
      if (result !== pdfService.ParseResult.PARSE_SUCCESS) {
        this.loadFailed = true
      }
    } catch (err) {
      this.loadFailed = true
      console.error('[StudyOralPdfViewer] load failed: ' + JSON.stringify(err))
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
          Text('无法预览此 PDF 文件')
            .fontSize(16)
            .fontColor('#59627E')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        PdfView({
          controller: this.controller,
          pageFit: pdfService.PageFit.FIT_WIDTH,
          showScroll: true
        })
          .layoutWeight(1)
          .width('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
