import { promptAction, router } from '@kit.ArkUI'
import { common } from '@kit.AbilityKit'
import document from '@ohos.document'
import { MaterialIngestionService } from '../services/MaterialIngestionService'
import { StudyMaterialRecord } from '../model/StudyMaterialRecord'

@Entry
@Component
struct MaterialsPage {
  @State materialCount: number = 0
  @State uploadedMaterialName: string = ''
  @State uploadStatus: string = 'No materials uploaded yet'
  @State uploadSource: string = 'Upload slides, notes, papers, or PDF files.'
  @State recentMaterials: StudyMaterialRecord[] = []
  @State revealedMaterialId: string = ''
  @State materialSwipeOffset: number = 0
  @State materialSwipeStartOffset: number = 0

  aboutToAppear(): void {
    this.loadMaterialData()
  }

  private async uploadMaterialFile(): Promise<void> {
    this.uploadStatus = 'Opening file picker...'
    this.uploadSource = 'Choose a study material file from this device.'
    try {
      const context = getContext(this) as common.UIAbilityContext
      const service = new MaterialIngestionService(context)
      const material = await service.uploadExtractAndSave()
      this.uploadedMaterialName = material.fileName
      this.uploadStatus = this.materialStatusLabel(material)
      this.uploadSource = this.materialSourceLabel(material)
      await this.loadMaterialData()
      promptAction.showToast({ message: this.materialStatusLabel(material), duration: 1800 })
    } catch (err) {
      this.uploadStatus = 'Upload cancelled'
      this.uploadSource = 'No file was selected or the selected file could not be copied. Error: ' + JSON.stringify(err)
      promptAction.showToast({ message: 'Upload cancelled', duration: 1600 })
    }
  }

  private async loadMaterialData(): Promise<void> {
    try {
      const context = getContext(this) as common.UIAbilityContext
      const service = new MaterialIngestionService(context)
      this.recentMaterials = await service.listRecent(20)
      this.materialCount = await service.count()
      if (this.recentMaterials.length > 0) {
        const latest = this.recentMaterials[0]
        this.uploadedMaterialName = latest.fileName
        this.uploadStatus = this.materialStatusLabel(latest)
        this.uploadSource = this.materialSourceLabel(latest)
      }
    } catch (err) {
      console.error('[StudyOralMaterials] load failed: ' + JSON.stringify(err))
    }
  }

  private materialStatusLabel(material: StudyMaterialRecord): string {
    if (material.extractionStatus === 'ready') {
      return material.questionCount > 0 ? 'Material saved - ' + material.questionCount.toString() + ' Q&A generated' :
        'Material saved with extracted text'
    }
    if (material.extractionStatus === 'unsupported') {
      return 'Material saved'
    }
    if (material.extractionStatus === 'failed') {
      return 'Material saved, text extraction failed'
    }
    return 'Material saved, no text found'
  }

  private materialSourceLabel(material: StudyMaterialRecord): string {
    if (material.textPreview.length > 0) {
      return material.textPreview
    }
    if (material.extractionError.length > 0) {
      return material.extractionError
    }
    return 'Saved to app storage: ' + material.sandboxPath
  }

  private materialCardHeight(material: StudyMaterialRecord): number {
    return 74
  }

  private async deleteMaterial(material: StudyMaterialRecord): Promise<void> {
    try {
      const context = getContext(this) as common.UIAbilityContext
      const service = new MaterialIngestionService(context)
      await service.deleteMaterial(material.id)
      this.revealedMaterialId = ''
      this.materialSwipeOffset = 0
      this.materialSwipeStartOffset = 0
      await this.loadMaterialData()
      promptAction.showToast({ message: 'Document deleted', duration: 1600 })
    } catch (err) {
      promptAction.showToast({ message: 'Delete failed', duration: 1600 })
      console.error('[StudyOralMaterials] delete failed: ' + JSON.stringify(err))
    }
  }

  private async openMaterial(material: StudyMaterialRecord): Promise<void> {
    if (this.revealedMaterialId === material.id && this.materialSwipeOffset < 0) {
      this.revealedMaterialId = ''
      this.materialSwipeOffset = 0
      this.materialSwipeStartOffset = 0
      return
    }
    const lowerName = material.fileName.toLowerCase()
    const uri = 'file://' + material.sandboxPath
    if (this.isImageMaterial(material)) {
      router.pushUrl({ url: 'pages/ImagePreviewPage', params: { imageUri: uri } })
      return
    }
    if (lowerName.endsWith('.pdf') || material.extension.toLowerCase() === '.pdf') {
      router.pushUrl({ url: 'pages/PdfViewerPage', params: { pdfUri: uri, title: material.fileName } })
      return
    }
    if (this.isTextMaterial(material)) {
      router.pushUrl({ url: 'pages/TextFilePreviewPage', params: { filePath: material.sandboxPath, title: material.fileName } })
      return
    }
    try {
      await document.show(material.originalUri.length > 0 ? material.originalUri : uri, this.mimeTypeForMaterial(material))
    } catch (err) {
      promptAction.showToast({ message: 'Preview coming soon', duration: 1200 })
      console.error('[StudyOralMaterials] open failed: ' + JSON.stringify(err))
    }
  }

  private isImageMaterial(material: StudyMaterialRecord): boolean {
    const extension = material.extension.toLowerCase()
    return extension === '.png' || extension === '.jpg' || extension === '.jpeg' || extension === '.webp'
  }

  private isTextMaterial(material: StudyMaterialRecord): boolean {
    const extension = material.extension.toLowerCase()
    return extension === '.txt' || extension === '.md'
  }

  private mimeTypeForMaterial(material: StudyMaterialRecord): string {
    const extension = material.extension.toLowerCase()
    if (extension === '.doc') {
      return 'application/msword'
    }
    if (extension === '.docx') {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    }
    if (extension === '.ppt') {
      return 'application/vnd.ms-powerpoint'
    }
    if (extension === '.pptx') {
      return 'application/vnd.openxmlformats-officedocument.presentationml.presentation'
    }
    return '*/*'
  }

  private materialCardSwipeOffset(material: StudyMaterialRecord): number {
    return this.revealedMaterialId === material.id ? this.materialSwipeOffset : 0
  }

  private beginMaterialSwipe(material: StudyMaterialRecord): void {
    if (this.revealedMaterialId === material.id) {
      this.materialSwipeStartOffset = this.materialSwipeOffset
    } else {
      this.revealedMaterialId = material.id
      this.materialSwipeOffset = 0
      this.materialSwipeStartOffset = 0
    }
  }

  private updateMaterialSwipe(material: StudyMaterialRecord, offsetX: number): void {
    if (this.revealedMaterialId !== material.id) {
      return
    }
    let nextOffset = this.materialSwipeStartOffset + offsetX
    if (nextOffset > 0) {
      nextOffset = 0
    }
    if (nextOffset < -92) {
      nextOffset = -92
    }
    this.materialSwipeOffset = nextOffset
  }

  private endMaterialSwipe(material: StudyMaterialRecord): void {
    if (this.revealedMaterialId !== material.id) {
      return
    }
    this.materialSwipeOffset = this.materialSwipeOffset <= -44 ? -78 : 0
    this.materialSwipeStartOffset = this.materialSwipeOffset
    if (this.materialSwipeOffset === 0) {
      this.revealedMaterialId = ''
    }
  }

  @Builder
  private icon(name: string, size: number, dimmed: boolean = false) {
    if (name === 'home') {
      Image($r('app.media.ic_home')).width(size).height(size).objectFit(ImageFit.Contain).opacity(dimmed ? 0.55 : 1)
    } else if (name === 'practice') {
      Image($r('app.media.ic_practice')).width(size).height(size).objectFit(ImageFit.Contain).opacity(dimmed ? 0.55 : 1)
    } else if (name === 'materials') {
      Image($r('app.media.ic_materials')).width(size).height(size).objectFit(ImageFit.Contain).opacity(dimmed ? 0.55 : 1)
    } else if (name === 'history') {
      Image($r('app.media.ic_history')).width(size).height(size).objectFit(ImageFit.Contain).opacity(dimmed ? 0.55 : 1)
    } else {
      Image($r('app.media.ic_upload')).width(size).height(size).objectFit(ImageFit.Contain)
    }
  }

  @Builder
  private navItem(iconName: string, label: string, selected: boolean, url: string) {
    Column() {
      this.icon(iconName, 30, !selected)
      Text(label)
        .fontSize(10)
        .fontColor(selected ? '#1655FF' : '#5E6884')
        .fontWeight(selected ? FontWeight.Bold : FontWeight.Normal)
        .margin({ top: 2 })
    }
    .layoutWeight(1)
    .height(58)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.getUIContext().getRouter().replaceUrl({
        url: 'pages/HomePage',
        params: { tab: label === 'Practice' ? 'practice' : (label === 'Materials' ? 'materials' : (label === 'History' ? 'history' : 'home')) }
      })
    })
  }

  @Builder
  private materialCard(material: StudyMaterialRecord) {
    Stack() {
      Row() {
        Blank().layoutWeight(1)
        Button('Delete')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .backgroundColor('#B42318')
          .borderRadius(12)
          .height(this.materialCardHeight(material))
          .width(78)
          .opacity(this.revealedMaterialId === material.id ? 1 : 0)
          .onClick(() => {
            this.deleteMaterial(material)
          })
      }
      .width('100%')
      .height(this.materialCardHeight(material))

      Column() {
        Row() {
          this.icon('materials', 34)
          Column() {
            Text(material.fileName)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor('#111936')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .layoutWeight(1)
          .margin({ left: 10 })
        }
        .width('100%')
      }
      .width('100%')
      .height(this.materialCardHeight(material))
      .padding(14)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .border({ width: 1, color: '#E6EAF4' })
      .offset({ x: this.materialCardSwipeOffset(material), y: 0 })
      .animation({ duration: 160, curve: Curve.EaseOut })
      .gesture(
        PanGesture({ direction: PanDirection.Horizontal, distance: 5 })
          .onActionStart(() => {
            this.beginMaterialSwipe(material)
          })
          .onActionUpdate((event: GestureEvent) => {
            this.updateMaterialSwipe(material, event.offsetX)
          })
          .onActionEnd(() => {
            this.endMaterialSwipe(material)
          })
      )
      .onClick(() => {
        void this.openMaterial(material)
      })
    }
    .width('100%')
    .height(this.materialCardHeight(material))
    .margin({ top: 12 })
  }

  build() {
    Column() {
      Row() {
        Text('‹')
          .fontSize(34)
          .fontColor('#111936')
          .onClick(() => router.back())
        Text('Materials')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111936')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Blank().width(34)
      }
      .height(58)
      .width('100%')
      .padding({ left: 18, right: 18, top: 8 })

      Column() {
        Column() {
          Image($r('app.media.ic_material_upload'))
            .width(92)
            .height(92)
            .objectFit(ImageFit.Contain)
            .draggable(false)
          Text(this.materialCount > 0 ? 'Material ready' : 'Upload Materials')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111936')
            .margin({ top: 18 })
          Text(this.uploadStatus)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.materialCount > 0 ? '#1655FF' : '#59627E')
            .textAlign(TextAlign.Center)
            .margin({ top: 8 })
          Text(this.materialCount > 0 ? this.uploadedMaterialName : 'Add slides, notes, papers, or PDFs for focused oral exam practice.')
            .fontSize(13)
            .fontColor('#59627E')
            .lineHeight(20)
            .textAlign(TextAlign.Center)
            .margin({ top: 6 })
          if (this.materialCount > 0) {
            Text(this.uploadSource)
              .fontSize(11)
              .fontColor('#7B849C')
              .lineHeight(16)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .textAlign(TextAlign.Center)
              .margin({ top: 8 })
          }
          Button(this.materialCount > 0 ? 'Replace Material' : 'Upload Material')
            .height(46)
            .width('100%')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .backgroundColor('#1655FF')
            .borderRadius(12)
            .margin({ top: 22 })
            .onClick(() => {
              this.uploadMaterialFile()
            })
        }
        .width('100%')
        .padding(20)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .border({ width: 1, color: '#E6EAF4' })
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
      .margin({ top: 22 })

      if (this.recentMaterials.length > 0) {
        Scroll() {
          Column() {
            Text('Uploaded Documents')
              .fontSize(17)
              .fontWeight(FontWeight.Bold)
              .fontColor('#111936')
              .width('100%')
            ForEach(this.recentMaterials, (material: StudyMaterialRecord) => {
              this.materialCard(material)
            }, (material: StudyMaterialRecord) => material.id)
          }
          .width('100%')
          .padding({ left: 20, right: 20, bottom: 16 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      } else {
      Blank()
      }

      Row() {
        this.navItem('home', 'Home', false, 'pages/HomePage')
        this.navItem('practice', 'Practice', false, 'pages/TopicPage')
        this.navItem('materials', 'Materials', true, 'pages/MaterialsPage')
        this.navItem('history', 'History', false, 'pages/HistoryPage')
      }
      .width('100%')
      .height(72)
      .padding({ left: 10, right: 10, bottom: 6 })
      .backgroundColor('#FFFFFF')
      .border({ width: { top: 1 }, color: '#EEF1F7' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FDFEFF')
  }
}
