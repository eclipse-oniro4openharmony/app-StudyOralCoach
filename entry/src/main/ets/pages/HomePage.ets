import { promptAction, router } from '@kit.ArkUI'
import { common } from '@kit.AbilityKit'
import document from '@ohos.document'
import { StorageService } from '../services/StorageService'
import { MaterialIngestionService } from '../services/MaterialIngestionService'
import { EvaluationData, SessionData, TopicData } from '../model/DataTypes'
import { MaterialQuestionAnswerRecord, StudyMaterialRecord } from '../model/StudyMaterialRecord'


@Entry
@Component
struct HomePage {
  @State totalSessions: number = 0
  @State averageScore: number = 0
  @State recentScore: number = 0
  @State weakTopics: string[] = []
  @State topics: TopicData[] = []
  @State currentTab: number = 0
  @State materialCount: number = 0
  @State questionBankCount: number = 0
  @State practicedQuestionCount: number = 0
  @State missedProblemCount: number = 0
  @State hasLatestPracticeRecord: boolean = false
  @State latestPracticeQuestion: string = ''
  @State latestPracticeFileName: string = ''
  @State latestPracticeSessionId: string = ''
  @State latestPracticeMaterialId: string = ''
  @State latestPracticeTime: string = ''
  @State uploadedMaterialName: string = ''
  @State uploadStatus: string = 'No materials uploaded yet'
  @State uploadSource: string = 'Upload slides, notes, papers, or PDF files.'
  @State recentMaterials: StudyMaterialRecord[] = []
  @State revealedMaterialId: string = ''
  @State materialSwipeOffset: number = 0
  @State materialSwipeStartOffset: number = 0
  @State isPracticeHold: boolean = false
  private storage: StorageService = StorageService.getInstance()

  aboutToAppear(): void {
    const routeParams = router.getParams()
    let tab = ''
    if (routeParams !== undefined && routeParams !== null) {
      const params = routeParams as Record<string, string>
      tab = params.tab ?? ''
    }
    if (tab === 'practice') {
      this.currentTab = 1
    } else if (tab === 'materials') {
      this.currentTab = 2
    } else if (tab === 'history') {
      this.currentTab = 3
    } else {
      this.currentTab = 0
    }
    const context = getContext(this) as common.UIAbilityContext
    this.storage.init(context).then(() => {
      this.loadData()
      this.loadMaterialData()
    })
  }

  loadData(): void {
    this.totalSessions = this.storage.getTotalSessions()
    this.averageScore = this.storage.getAverageScore()
    this.weakTopics = this.storage.getWeakTopics()
    const evaluations = this.storage.getEvaluations()
    const sessions = this.storage.getSessions()
    this.recentScore = evaluations.length > 0 ? Number(evaluations[0].overallScore) : 0
    this.missedProblemCount = evaluations
      .filter((evaluation: EvaluationData) => {
        const relatedSession = sessions.find((session: SessionData) => session.id === evaluation.sessionId)
        return Number(evaluation.overallScore) < 60 && relatedSession !== undefined && relatedSession.questionId.length > 0
      }).length
    const latestSession = sessions.find((session: SessionData) => session.questionId.length > 0)
    if (latestSession !== undefined) {
      this.hasLatestPracticeRecord = true
      this.latestPracticeSessionId = latestSession.id
      this.latestPracticeQuestion = latestSession.questionContent
      this.latestPracticeTime = this.formatHomeTime(latestSession.startedAt)
    } else {
      this.hasLatestPracticeRecord = false
      this.latestPracticeQuestion = ''
      this.latestPracticeFileName = ''
      this.latestPracticeSessionId = ''
      this.latestPracticeMaterialId = ''
      this.latestPracticeTime = ''
    }
    this.topics = this.storage.getTopics()
  }

  private formatHomeTime(timestamp: string): string {
    const value = Number(timestamp)
    if (value <= 0) {
      return ''
    }
    const date = new Date(value)
    return (date.getMonth() + 1).toString() + '/' + date.getDate().toString() + ' ' +
      date.getHours().toString().padStart(2, '0') + ':' + date.getMinutes().toString().padStart(2, '0')
  }

  private displayRecentScore(): number {
    return this.recentScore
  }

  private displayAverageScore(): number {
    return this.averageScore
  }

  private displayPracticed(): number {
    return this.practicedQuestionCount
  }

  private displayWeakTopics(): number {
    return this.missedProblemCount
  }

  private latestQuestionCount(): number {
    return this.questionBankCount
  }

  private async uploadMaterialFile(): Promise<void> {
    this.currentTab = 2
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
      promptAction.showToast({
        message: this.materialStatusLabel(material),
        duration: 1800
      })
    } catch (err) {
      this.uploadStatus = 'Upload cancelled'
      this.uploadSource = 'No file was selected or the selected file could not be copied. Error: ' + JSON.stringify(err)
      promptAction.showToast({
        message: 'Upload cancelled',
        duration: 1600
      })
    }
  }

  private async loadMaterialData(): Promise<void> {
    try {
      const context = getContext(this) as common.UIAbilityContext
      const service = new MaterialIngestionService(context)
      const allMaterials = await service.listRecent(1000)
      this.recentMaterials = allMaterials.slice(0, 5)
      this.materialCount = await service.count()
      const allQuestions = await service.listAllQuestions(1000)
      this.questionBankCount = allQuestions.length
      this.practicedQuestionCount = (await service.listPracticedQuestions(1000)).length
      const latestSession = this.storage.getSessions().find((session: SessionData) => session.questionId.length > 0)
      if (latestSession !== undefined) {
        const latestQuestion = allQuestions.find((question: MaterialQuestionAnswerRecord) => question.id === latestSession.questionId)
        if (latestQuestion !== undefined) {
          const material = allMaterials.find((item: StudyMaterialRecord) => item.id === latestQuestion.materialId)
          this.latestPracticeMaterialId = latestQuestion.materialId
          this.latestPracticeFileName = material !== undefined ? material.fileName : 'Practice file'
        }
      }
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
      router.      pushUrl({ url: 'pages/ImagePreviewPage', params: { imageUri: uri } })
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

  private getTopicProgress(topic: TopicData, index: number): number {
    const count = Number(topic.questionCount)
    if (count > 0) {
      const progress = count * 13
      return progress > 78 ? 78 : progress
    }
    if (index === 0) {
      return 78
    }
    if (index === 1) {
      return 65
    }
    if (index === 2) {
      return 54
    }
    return 41
  }

  @Builder
  private appIcon(size: number) {
    Image($r('app.media.app_icon_full'))
      .width(size)
      .height(size)
      .objectFit(ImageFit.Contain)
  }

  @Builder
  private brandIcon(name: string, size: number, dimmed: boolean = false) {
    if (name === 'mic') {
      Image($r('app.media.ic_mic')).width(size).height(size).objectFit(ImageFit.Contain).opacity(dimmed ? 0.55 : 1)
    } else if (name === 'upload') {
      Image($r('app.media.ic_upload')).width(size).height(size).objectFit(ImageFit.Contain).opacity(dimmed ? 0.55 : 1)
    } else if (name === 'home') {
      Image($r('app.media.ic_home')).width(size).height(size).objectFit(ImageFit.Contain).opacity(dimmed ? 0.55 : 1)
    } else if (name === 'practice') {
      Image($r('app.media.ic_practice')).width(size).height(size).objectFit(ImageFit.Contain).opacity(dimmed ? 0.55 : 1)
    } else if (name === 'materials') {
      Image($r('app.media.ic_materials')).width(size).height(size).objectFit(ImageFit.Contain).opacity(dimmed ? 0.55 : 1)
    } else if (name === 'history') {
      Image($r('app.media.ic_history')).width(size).height(size).objectFit(ImageFit.Contain).opacity(dimmed ? 0.55 : 1)
    } else if (name === 'target') {
      Image($r('app.media.ic_target')).width(size).height(size).objectFit(ImageFit.Contain).opacity(dimmed ? 0.55 : 1)
    } else if (name === 'result') {
      Image($r('app.media.ic_result')).width(size).height(size).objectFit(ImageFit.Contain).opacity(dimmed ? 0.55 : 1)
    } else if (name === 'os') {
      Image($r('app.media.ic_os')).width(size).height(size).objectFit(ImageFit.Contain)
    } else if (name === 'network') {
      Image($r('app.media.ic_network')).width(size).height(size).objectFit(ImageFit.Contain)
    } else if (name === 'thesis') {
      Image($r('app.media.ic_thesis')).width(size).height(size).objectFit(ImageFit.Contain)
    } else {
      Image($r('app.media.ic_code')).width(size).height(size).objectFit(ImageFit.Contain)
    }
  }

  @Builder
  private quickCard(title: string, subtitle: string, iconName: string, routeUrl: string) {
    Column() {
      Row() {
        this.brandIcon(iconName, 34)
        Blank()
        Image($r('app.media.ic_next_question'))
          .width(20)
          .height(20)
          .objectFit(ImageFit.Contain)
          .draggable(false)
      }
      .width('100%')

      Text(title)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#111936')
        .width('100%')
        .textAlign(TextAlign.Start)
        .margin({ top: 8 })
      Text(subtitle)
        .fontSize(12)
        .fontColor('#59627E')
        .lineHeight(19)
        .width('100%')
        .textAlign(TextAlign.Start)
        .margin({ top: 6 })
    }
    .height(124)
    .padding(14)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .border({ width: 1, color: '#E6EAF4' })
    .onClick(() => {
      this.getUIContext().getRouter().pushUrl({ url: routeUrl })
    })
  }

  @Builder
  private uploadQuickCard() {
    Column() {
      Row() {
        this.brandIcon('upload', 34)
        Blank()
        Image($r('app.media.ic_next_question'))
          .width(20)
          .height(20)
          .objectFit(ImageFit.Contain)
          .draggable(false)
      }
      .width('100%')

      Text('Upload Materials')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#111936')
        .width('100%')
        .textAlign(TextAlign.Start)
        .margin({ top: 8 })
      Text('Add slides, notes, or papers')
        .fontSize(12)
        .fontColor('#59627E')
        .lineHeight(19)
        .width('100%')
        .textAlign(TextAlign.Start)
        .margin({ top: 6 })
    }
    .height(124)
    .padding(14)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .border({ width: 1, color: '#E6EAF4' })
    .onClick(() => {
      this.uploadMaterialFile()
    })
  }

  @Builder
  private miniCard(title: string, value: string, iconName: string, mode: string, routeUrl: string) {
    Column() {
      Row() {
        this.brandIcon(iconName, 34)
        Blank()
        Image($r('app.media.ic_next_question'))
          .width(20)
          .height(20)
          .objectFit(ImageFit.Contain)
          .draggable(false)
      }
      .width('100%')

      if (mode === 'exam') {
        Text(title)
          .fontSize(12)
          .fontColor('#313A59')
          .width('100%')
          .textAlign(TextAlign.Start)
          .margin({ top: 7 })
        Text(value)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111936')
          .width('100%')
          .textAlign(TextAlign.Start)
          .margin({ top: 5 })
        Text('Change')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1655FF')
          .width('100%')
          .textAlign(TextAlign.Start)
          .margin({ top: 7 })
      } else {
        Text(title)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor('#59627E')
          .width('100%')
          .textAlign(TextAlign.Start)
          .margin({ top: 10 })
        Row() {
          Text(value)
            .fontSize(29)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1B55FF')
          if (mode === 'score') {
            Text('/100')
              .fontSize(15)
              .fontColor('#39435F')
              .margin({ left: 3, top: 10 })
          }
        }
        .width('100%')
      }
    }
    .height(124)
    .padding(14)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .border({ width: 1, color: '#E6EAF4' })
    .onClick(() => {
      this.getUIContext().getRouter().pushUrl({ url: routeUrl })
    })
  }

  @Builder
  private homeActionRow(title: string, value: string, detail: string, iconName: string, routeUrl: string,
    actionName: string, showDivider: boolean) {
    Column() {
      Row() {
        Column() {
          this.brandIcon(iconName, 38)
        }
        .width(44)
        .height(44)
        .justifyContent(FlexAlign.Center)

        Column() {
          Text(title)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111936')
            .width('100%')
          Text(detail)
            .fontSize(12)
            .fontColor('#59627E')
            .lineHeight(18)
            .width('100%')
            .margin({ top: 3 })
        }
        .layoutWeight(1)
        .margin({ left: 12 })

        if (value.length > 0) {
          Text(value)
            .fontSize(19)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1655FF')
            .margin({ left: 10, right: 8 })
        }
        Image($r('app.media.ic_next_question'))
          .width(22)
          .height(22)
          .objectFit(ImageFit.Contain)
          .draggable(false)
      }
      .width('100%')
      .height(74)

      if (showDivider) {
        Column()
          .height(1)
          .width('100%')
          .backgroundColor('#EEF1F7')
          .margin({ left: 56 })
      }
    }
    .width('100%')
    .onClick(() => {
      if (actionName === 'upload') {
        this.uploadMaterialFile()
      } else if (actionName === 'practice') {
        this.getUIContext().getRouter().pushUrl({ url: routeUrl, params: { topicId: '' } })
      } else {
        this.getUIContext().getRouter().pushUrl({ url: routeUrl })
      }
    })
  }

  @Builder
  private topicRow(title: string, percent: number, iconName: string, color: string, routeId: string) {
    Row() {
      Column() {
        this.brandIcon(iconName, 50)
      }
      .width(52)
      .height(52)
      .justifyContent(FlexAlign.Center)

      Column() {
        Row() {
          Text(title)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#111936')
            .layoutWeight(1)
          Text(percent.toString() + '%')
            .fontSize(12)
            .fontColor('#4F5A78')
        }
        .width('100%')

        Stack({ alignContent: Alignment.Start }) {
          Column()
            .width('100%')
            .height(4)
            .backgroundColor('#E8ECF4')
            .borderRadius(3)
          Column()
            .width(percent.toString() + '%')
            .height(4)
            .backgroundColor('#3158F4')
            .borderRadius(3)
        }
        .width('100%')
        .height(4)
        .margin({ top: 9 })
      }
      .layoutWeight(1)
      .margin({ left: 14 })

      Image($r('app.media.ic_next_question'))
        .width(22)
        .height(22)
        .objectFit(ImageFit.Contain)
        .margin({ left: 10 })
        .draggable(false)
    }
    .height(62)
    .width('100%')
    .onClick(() => {
      if (routeId.length > 0) {
        this.getUIContext().getRouter().pushUrl({ url: 'pages/TopicDetailPage', params: { topicId: routeId } })
      }
    })
  }

  @Builder
  private bottomNav() {
    Row() {
      this.navItem('home', 'Home', 0)
      this.navItem('practice', 'Practice', 1)
      this.navItem('materials', 'Materials', 2)
      this.navItem('history', 'History', 3)
    }
    .width('100%')
    .height(72)
    .padding({ left: 10, right: 10, bottom: 6 })
    .backgroundColor('#FFFFFF')
    .border({ width: { top: 1 }, color: '#EEF1F7' })
  }

  @Builder
  private navItem(iconName: string, label: string, index: number) {
    Column() {
      this.brandIcon(iconName, 30, this.currentTab !== index)
      Text(label)
        .fontSize(10)
        .fontColor(this.currentTab === index ? '#1655FF' : '#5E6884')
        .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Normal)
        .margin({ top: 2 })
    }
    .layoutWeight(1)
    .height(58)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.currentTab = index
    })
  }

  @Builder
  private practiceStartButton() {
    Column() {
      Stack({ alignContent: Alignment.Center }) {
        Image($r('app.media.ic_practice_idle'))
          .width(190)
          .height(190)
          .objectFit(ImageFit.Contain)
          .opacity(this.isPracticeHold ? 0 : 1)
          .draggable(false)
        Image($r('app.media.ic_practice_hold'))
          .width(190)
          .height(190)
          .objectFit(ImageFit.Contain)
          .opacity(this.isPracticeHold ? 1 : 0)
          .draggable(false)
      }
      .width('100%')
      .height(204)
      .scale({ x: this.isPracticeHold ? 0.96 : 1, y: this.isPracticeHold ? 0.96 : 1 })
      .animation({ duration: 120, curve: Curve.EaseOut })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.isPracticeHold = true
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.isPracticeHold = false
      }
    })
    .onClick(() => {
      this.getUIContext().getRouter().pushUrl({ url: 'pages/PracticePage', params: { topicId: '' } })
    })
  }

  @Builder
  private practiceTab() {
    Scroll() {
      Column() {
        Row() {
          Column() {
            Text('Practice')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor('#080D2D')
            Text('Choose a topic and start a mock oral exam.')
              .fontSize(13)
              .fontColor('#56607D')
              .margin({ top: 7 })
          }
          .layoutWeight(1)
        }
        .width('100%')
        .margin({ top: 12, bottom: 18 })

        Column() {
          this.practiceStartButton()
        }
        .width('100%')
          .layoutWeight(1)
        .justifyContent(FlexAlign.Center)

      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Start)
      .padding({ left: 18, right: 18, bottom: 22 })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
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
          this.brandIcon('materials', 34)
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

  @Builder
  private materialsTab() {
    Scroll() {
      Column() {
        Column() {
          Image($r('app.media.ic_material_upload'))
            .width(92)
            .height(92)
            .objectFit(ImageFit.Contain)
            .draggable(false)
          Text(this.materialCount > 0 ? 'Material Ready' : 'Upload Materials')
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
        .margin({ top: 12 })
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .border({ width: 1, color: '#E6EAF4' })

        if (this.recentMaterials.length > 0) {
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
          .margin({ top: 18 })
        }

        Column() {
          this.homeActionRow(
            'Converted Q&A',
            '',
            'Converted questions and answers',
            'target',
            'pages/QuestionBankPage',
            '',
            false
          )
        }
        .width('100%')
        .padding({ left: 14, right: 14, top: 6, bottom: 6 })
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .border({ width: 1, color: '#E6EAF4' })
        .margin({ top: 18 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Start)
      .padding({ left: 18, right: 18, bottom: 24 })
    }
    .layoutWeight(1)
    .width('100%')
    .scrollBar(BarState.Off)
  }

  @Builder
  private historyTab() {
    Scroll() {
      Column() {
        Row() {
          Text('History')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#080D2D')
            .layoutWeight(1)
        }
        .width('100%')
        .margin({ top: 12, bottom: 8 })

        Column() {
          Row() {
            this.brandIcon('materials', 42)
            Row() {
              Text(this.hasLatestPracticeRecord ? (this.latestPracticeFileName.length > 0 ? this.latestPracticeFileName : 'Practice file') : 'No practice records yet')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#111936')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)
              Text(this.hasLatestPracticeRecord ? this.latestPracticeTime : 'Submit an answer in Practice')
                .fontSize(12)
                .fontColor('#59627E')
                .margin({ left: 10 })
            }
            .layoutWeight(1)
            .margin({ left: 8 })
            Image($r('app.media.ic_next_question'))
              .width(22)
              .height(22)
              .objectFit(ImageFit.Contain)
              .margin({ left: 8 })
              .draggable(false)
          }
          .width('100%')
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .border({ width: 1, color: '#E6EAF4' })
        .onClick(() => {
          if (this.hasLatestPracticeRecord) {
            this.getUIContext().getRouter().pushUrl({
              url: 'pages/HistoryDetailPage',
              params: { sessionId: this.latestPracticeSessionId, materialId: this.latestPracticeMaterialId }
            })
          } else {
            this.getUIContext().getRouter().pushUrl({ url: 'pages/HistoryPage' })
          }
        })

      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Start)
      .padding({ left: 18, right: 18, bottom: 22 })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }

  build() {
    Column() {
      if (this.currentTab === 0) {
        Scroll() {
          Column() {
            Row() {
              Column() {
                Text('Home')
                  .fontSize(22)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#080D2D')
              }
              .layoutWeight(1)
              this.brandIcon('home', 44)
            }
            .width('100%')
            .margin({ top: 12, bottom: 18 })

            Column() {
              this.homeActionRow(
                'Start Practice',
                '',
                'Practice uploaded question bank',
                'practice',
                'pages/PracticePage',
                'practice',
                true
              )
              this.homeActionRow(
                'Upload Materials',
                '',
                'Add documents and generate Q&A',
                'upload',
                '',
                'upload',
                true
              )
              this.homeActionRow(
                'Question Bank',
                '',
                'Prepared questions and answers',
                'materials',
                'pages/QuestionBankPage',
                '',
                true
              )
              this.homeActionRow(
                'Missed problems',
                '',
                'Wrong answers from practice',
                'target',
                'pages/WeakTopicsPage',
                '',
                true
              )
              this.homeActionRow(
                'Practiced',
                '',
                'Questions already practiced',
                'history',
                'pages/PracticeStatsPage',
                '',
                false
              )
            }
            .width('100%')
            .padding({ left: 14, right: 14, top: 6, bottom: 6 })
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .border({ width: 1, color: '#E6EAF4' })
          }
          .width('100%')
          .padding({ left: 18, right: 18, bottom: 22 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      } else if (this.currentTab === 1) {
        this.practiceTab()
      } else if (this.currentTab === 2) {
        this.materialsTab()
      } else {
        this.historyTab()
      }

      this.bottomNav()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FDFEFF')
  }
}
