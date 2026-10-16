import { promptAction, router, SymbolGlyphModifier } from '@kit.ArkUI'
import { hdsMaterial, HdsAnimationMode, HdsTabs, HdsTabsController, HdsTabsModifier } from '@kit.UIDesignKit'
import { common } from '@kit.AbilityKit'
import document from '@ohos.document'
import { StorageService } from '../services/StorageService'
import { MaterialIngestionService } from '../services/MaterialIngestionService'
import { EvaluationData, PracticeExamData, SessionData, TopicData } from '../model/DataTypes'
import { MaterialQuestionAnswerRecord, StudyMaterialRecord } from '../model/StudyMaterialRecord'
import {
  BannerCard,
  BannerData,
  BannerState,
  TabBarType
} from '../vendor/sample_in_harmonyos/features/commonbusiness/Index'

class HomePracticeHistoryRecord {
  id: string = ''
  examId: string = ''
  materialId: string = ''
  fileName: string = ''
  progressText: string = ''
  scoreText: string = ''
  clarityScore: string = ''
  structureScore: string = ''
  completenessScore: string = ''
  accuracyScore: string = ''
  latestSessionId: string = ''
  latestPracticeAt: string = ''
  rows: HomePracticeHistoryQuestionResult[] = []
  isIncomplete: boolean = false
}

class HomePracticeHistoryQuestionResult {
  id: string = ''
  question: string = ''
  correctAnswer: string = ''
  practiced: boolean = false
  userAnswer: string = ''
  score: string = '0'
  feedback: string = ''
}

@Entry
@Component
struct HomePage {
  @State totalSessions: number = 0
  @State averageScore: number = 0
  @State recentScore: number = 0
  @State weakTopics: string[] = []
  @State topics: TopicData[] = []
  @State currentTab: number = 0
  @StorageProp('immersiveSystemTopInsetPx') immersiveSystemTopInsetPx: number = 0
  @StorageProp('immersiveNavigationIndicatorHeightVp') @Watch('configureHdsTabs') navigationIndicatorHeightVp: number =
    16
  @State hdsTabsModifier: HdsTabsModifier = new HdsTabsModifier()
  @State materialCount: number = 0
  @State questionBankCount: number = 0
  @State practicedQuestionCount: number = 0
  @State missedProblemCount: number = 0
  @State hasLatestPracticeRecord: boolean = false
  @State hasIncompletePractice: boolean = false
  @State incompletePracticeExamId: string = ''
  @State incompletePracticeProgress: string = ''
  @State incompletePracticeFiles: string = ''
  @State incompletePracticeTime: string = ''
  @State latestPracticeQuestion: string = ''
  @State latestPracticeFileName: string = ''
  @State latestPracticeSessionId: string = ''
  @State latestPracticeExamId: string = ''
  @State latestPracticeMaterialId: string = ''
  @State latestPracticeTime: string = ''
  @State uploadedMaterialName: string = ''
  @State uploadStatus: string = 'No materials uploaded yet'
  @State uploadSource: string = 'Upload slides, notes, papers, or PDF files.'
  @State recentMaterials: StudyMaterialRecord[] = []
  @State historyRecords: HomePracticeHistoryRecord[] = []
  @State selectedHistoryRecordId: string = ''
  @State selectedHistoryFileName: string = ''
  @State selectedHistoryProgressText: string = ''
  @State selectedHistoryScoreText: string = ''
  @State selectedHistoryClarityScore: string = ''
  @State selectedHistoryStructureScore: string = ''
  @State selectedHistoryCompletenessScore: string = ''
  @State selectedHistoryAccuracyScore: string = ''
  @State selectedHistoryRows: HomePracticeHistoryQuestionResult[] = []
  @State revealedMaterialId: string = ''
  @State materialSwipeOffset: number = 0
  @State materialSwipeStartOffset: number = 0
  @State bannerState: BannerState = new BannerState()
  private storage: StorageService = StorageService.getInstance()
  private hdsTabsController: HdsTabsController = new HdsTabsController()
  private scrollDirection: number = 0
  private scrollDistance: number = 0
  private isBottomTabBarHidden: boolean = false

  aboutToAppear(): void {
    this.initializeHomeBanners()
    const routeParams = router.getParams()
    let tab = ''
    if (routeParams !== undefined && routeParams !== null) {
      const params = routeParams as Record<string, string>
      tab = params.tab ?? ''
    }
    if (tab === 'materials') {
      this.currentTab = 1
    } else if (tab === 'history') {
      this.currentTab = 2
    } else {
      this.currentTab = 0
    }
    this.configureHdsTabs()
    const context = getContext(this) as common.UIAbilityContext
    this.storage.init(context).then(() => {
      this.loadData()
      this.loadMaterialData()
    })
  }

  private initializeHomeBanners(): void {
    this.bannerState.bannerHeight = 237
    const banners: BannerData[] = [
      this.createHomeBanner(1, 'home_banner_ai_oral_practice.png'),
      this.createHomeBanner(2, 'home_banner_ai_study_file_converter.png'),
      this.createHomeBanner(3, 'home_banner_get_feedback.png')
    ]
    this.bannerState.bannerResource.setDataArray(banners)
  }

  private createHomeBanner(id: number, mediaUrl: string): BannerData {
    const banner = new BannerData()
    banner.id = id
    banner.title = ''
    banner.subTitle = ''
    banner.desc = ''
    banner.mediaUrl = mediaUrl
    banner.themeColor = '#3158F4'
    return banner
  }

  onBackPress(): boolean {
    if (this.selectedHistoryRecordId.length > 0) {
      this.clearSelectedHistoryRecord()
      return true
    }
    if (this.revealedMaterialId.length > 0 || this.materialSwipeOffset !== 0) {
      this.revealedMaterialId = ''
      this.materialSwipeOffset = 0
      this.materialSwipeStartOffset = 0
      return true
    }
    if (this.currentTab !== 0) {
      this.currentTab = 0
      return true
    }
    return false
  }

  configureHdsTabs(): void {
    this.hdsTabsModifier
      .vertical(false)
      .barPosition(BarPosition.End)
      .barHeight(56)
  }

  private handleVerticalPageScroll(yOffset: number, scrollSource: ScrollSource): void {
    if (scrollSource !== ScrollSource.DRAG) {
      return
    }
    if (Math.abs(yOffset) < 0.5) {
      return
    }
    const direction = yOffset > 0 ? 1 : -1
    if (direction !== this.scrollDirection) {
      this.scrollDirection = direction
      this.scrollDistance = 0
    }
    this.scrollDistance += Math.abs(yOffset)
    if (this.scrollDistance < 20) {
      return
    }
    this.scrollDistance = 0

    // Scroll offset is opposite to the finger direction: positive means an upward swipe.
    const shouldHide = direction > 0
    if (shouldHide === this.isBottomTabBarHidden) {
      return
    }
    this.isBottomTabBarHidden = shouldHide
    if (shouldHide) {
      this.hdsTabsController.applyHideAnimation(HdsAnimationMode.SCROLL_ANIMATION)
    } else {
      this.hdsTabsController.applyShowAnimation(HdsAnimationMode.SCROLL_ANIMATION)
    }
  }

  private showBottomTabBar(): void {
    this.scrollDirection = 0
    this.scrollDistance = 0
    if (!this.isBottomTabBarHidden) {
      return
    }
    this.isBottomTabBarHidden = false
    this.hdsTabsController.applyShowAnimation(HdsAnimationMode.SCROLL_ANIMATION)
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
        return Number(evaluation.overallScore) < 60 && relatedSession !== undefined &&
          relatedSession.questionId.length > 0
      }).length
    const latestSession = sessions.find((session: SessionData) => session.questionId.length > 0)
    if (latestSession !== undefined) {
      this.hasLatestPracticeRecord = true
      this.latestPracticeSessionId = latestSession.id
      this.latestPracticeExamId = latestSession.examId ?? ''
      this.latestPracticeQuestion = latestSession.questionContent
      this.latestPracticeTime = this.formatHomeTime(latestSession.startedAt)
    } else {
      this.hasLatestPracticeRecord = false
      this.latestPracticeQuestion = ''
      this.latestPracticeFileName = ''
      this.latestPracticeSessionId = ''
      this.latestPracticeExamId = ''
      this.latestPracticeMaterialId = ''
      this.latestPracticeTime = ''
    }
    const incompleteExam = this.storage.getLatestIncompletePracticeExam()
    if (incompleteExam !== null) {
      this.hasIncompletePractice = true
      this.incompletePracticeExamId = incompleteExam.id
      this.incompletePracticeProgress =
        incompleteExam.answeredQuestionIds.length.toString() + '/' + incompleteExam.questionIds.length.toString()
      this.incompletePracticeTime = this.formatHomeTime(incompleteExam.updatedAt)
    } else {
      this.hasIncompletePractice = false
      this.incompletePracticeExamId = ''
      this.incompletePracticeProgress = ''
      this.incompletePracticeFiles = ''
      this.incompletePracticeTime = ''
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
    this.currentTab = 1
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
      this.historyRecords = this.buildHomeHistoryRecords(allQuestions, allMaterials)
      const incompleteExam = this.storage.getLatestIncompletePracticeExam()
      if (incompleteExam !== null) {
        this.incompletePracticeFiles = this.fileNamesForExam(incompleteExam, allMaterials)
      }
      const latestSession = this.storage.getSessions().find((session: SessionData) => session.questionId.length > 0)
      if (latestSession !== undefined) {
        const latestQuestion =
          allQuestions.find((question: MaterialQuestionAnswerRecord) => question.id === latestSession.questionId)
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

  private fileNamesForExam(exam: PracticeExamData, materials: StudyMaterialRecord[]): string {
    const names: string[] = []
    exam.materialIds.forEach((materialId: string) => {
      const material = materials.find((item: StudyMaterialRecord) => item.id === materialId)
      if (material !== undefined && names.indexOf(material.fileName) < 0) {
        names.push(material.fileName)
      }
    })
    if (names.length === 0) {
      return 'Practice files'
    }
    if (names.length <= 2) {
      return names.join(', ')
    }
    return names[0] + ', ' + names[1] + ' +' + (names.length - 2).toString()
  }

  private fileNamesForExamQuestions(exam: PracticeExamData, questions: MaterialQuestionAnswerRecord[],
    materials: StudyMaterialRecord[]): string {
    if (exam.materialIds.length > 0) {
      return this.fileNamesForExam(exam, materials)
    }
    const materialIds: string[] = []
    exam.questionIds.forEach((questionId: string) => {
      const question = questions.find((item: MaterialQuestionAnswerRecord) => item.id === questionId)
      if (question !== undefined && question.materialId.length > 0 && materialIds.indexOf(question.materialId) < 0) {
        materialIds.push(question.materialId)
      }
    })
    const fallbackExam = new PracticeExamData()
    fallbackExam.materialIds = materialIds
    return this.fileNamesForExam(fallbackExam, materials)
  }

  private buildHomeHistoryRecords(questions: MaterialQuestionAnswerRecord[],
    materials: StudyMaterialRecord[]): HomePracticeHistoryRecord[] {
    const sessions = this.storage.getSessions().filter((session: SessionData) => session.questionId.length > 0)
    const evaluations = this.storage.getEvaluations()
    const records: HomePracticeHistoryRecord[] = []
    const exams = this.storage.getPracticeExams()

    exams.forEach((exam: PracticeExamData) => {
      if (exam.answeredQuestionIds.length === 0) {
        return
      }
      const record = new HomePracticeHistoryRecord()
      record.id = exam.id
      record.examId = exam.id
      record.fileName = this.fileNamesForExamQuestions(exam, questions, materials)
      record.progressText = exam.answeredQuestionIds.length.toString() + '/' + exam.questionIds.length.toString()
      record.latestPracticeAt = exam.updatedAt
      record.isIncomplete = exam.status !== 'completed' && exam.questionIds.length > exam.answeredQuestionIds.length
      const latestSession = sessions.find((session: SessionData) => (session.examId ?? '') === exam.id)
      record.latestSessionId = latestSession !== undefined ? latestSession.id : ''
      this.applyHomeEvaluationToRecord(record, evaluations)
      record.rows = this.buildHomeQuestionRowsForExam(exam, questions, sessions, evaluations)
      records.push(record)
    })

    sessions.forEach((session: SessionData) => {
      if ((session.examId ?? '').length > 0) {
        return
      }
      const question = questions.find((item: MaterialQuestionAnswerRecord) => item.id === session.questionId)
      if (question === undefined) {
        return
      }
      const material = materials.find((item: StudyMaterialRecord) => item.id === question.materialId)
      let record = records.find((item: HomePracticeHistoryRecord) => item.materialId === question.materialId)
      if (record === undefined) {
        record = new HomePracticeHistoryRecord()
        record.id = question.materialId
        record.materialId = question.materialId
        record.fileName = material !== undefined ? material.fileName : 'Practice file'
        record.progressText = 'Legacy'
        record.rows = this.buildHomeQuestionRowsForMaterial(question.materialId, questions, sessions, evaluations)
        records.push(record)
      }
      if (record.latestSessionId.length === 0 || Number(session.startedAt) > Number(record.latestPracticeAt)) {
        record.latestSessionId = session.id
        record.latestPracticeAt = session.startedAt
        this.applyHomeEvaluationToRecord(record, evaluations)
      }
    })

    return records.sort((a: HomePracticeHistoryRecord, b: HomePracticeHistoryRecord) =>
    Number(b.latestPracticeAt) - Number(a.latestPracticeAt))
  }

  private buildHomeQuestionRowsForExam(exam: PracticeExamData, questions: MaterialQuestionAnswerRecord[],
    sessions: SessionData[], evaluations: EvaluationData[]): HomePracticeHistoryQuestionResult[] {
    const rows: HomePracticeHistoryQuestionResult[] = []
    exam.questionIds.forEach((questionId: string) => {
      const question = questions.find((item: MaterialQuestionAnswerRecord) => item.id === questionId)
      if (question !== undefined) {
        rows.push(this.toHomeQuestionResult(question, sessions, evaluations, exam.id))
      }
    })
    return rows
  }

  private buildHomeQuestionRowsForMaterial(materialId: string, questions: MaterialQuestionAnswerRecord[],
    sessions: SessionData[], evaluations: EvaluationData[]): HomePracticeHistoryQuestionResult[] {
    const rows: HomePracticeHistoryQuestionResult[] = []
    questions
      .filter((question: MaterialQuestionAnswerRecord) => question.materialId === materialId)
      .forEach((question: MaterialQuestionAnswerRecord) => {
        rows.push(this.toHomeQuestionResult(question, sessions, evaluations, ''))
      })
    return rows
  }

  private toHomeQuestionResult(question: MaterialQuestionAnswerRecord, sessions: SessionData[],
    evaluations: EvaluationData[], examId: string): HomePracticeHistoryQuestionResult {
    const row = new HomePracticeHistoryQuestionResult()
    row.id = question.id
    row.question = question.question
    row.correctAnswer = question.answer
    const practicedSession = examId.length > 0 ?
      sessions.find((session: SessionData) => (session.examId ?? '') === examId && session.questionId === question.id) :
      sessions.find((session: SessionData) => session.questionId === question.id)
    if (practicedSession !== undefined) {
      row.practiced = true
      row.userAnswer = practicedSession.userAnswer
      const evaluation = evaluations.find((item: EvaluationData) => item.sessionId === practicedSession.id)
      if (evaluation !== undefined) {
        row.score = evaluation.overallScore
        row.feedback = evaluation.feedback
      }
    }
    return row
  }

  private applyHomeEvaluationToRecord(record: HomePracticeHistoryRecord, evaluations: EvaluationData[]): void {
    if (record.latestSessionId.length === 0) {
      return
    }
    const evaluation = evaluations.find((item: EvaluationData) => item.sessionId === record.latestSessionId)
    if (evaluation === undefined) {
      return
    }
    record.scoreText = evaluation.overallScore
    record.clarityScore = evaluation.clarityScore
    record.structureScore = evaluation.structureScore
    record.completenessScore = evaluation.completenessScore
    record.accuracyScore = evaluation.accuracyScore
  }

  private selectHistoryRecord(record: HomePracticeHistoryRecord): void {
    this.selectedHistoryRecordId = record.id
    this.selectedHistoryFileName = record.fileName
    this.selectedHistoryProgressText = record.progressText
    this.selectedHistoryScoreText = record.scoreText
    this.selectedHistoryClarityScore = record.clarityScore
    this.selectedHistoryStructureScore = record.structureScore
    this.selectedHistoryCompletenessScore = record.completenessScore
    this.selectedHistoryAccuracyScore = record.accuracyScore
    this.selectedHistoryRows = record.rows
  }

  private clearSelectedHistoryRecord(): void {
    this.selectedHistoryRecordId = ''
    this.selectedHistoryFileName = ''
    this.selectedHistoryProgressText = ''
    this.selectedHistoryScoreText = ''
    this.selectedHistoryClarityScore = ''
    this.selectedHistoryStructureScore = ''
    this.selectedHistoryCompletenessScore = ''
    this.selectedHistoryAccuracyScore = ''
    this.selectedHistoryRows = []
  }

  private continuePracticeExam(examId: string): void {
    if (examId.length === 0) {
      return
    }
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/PracticePage',
      params: { topicId: '', examId: examId }
    })
  }

  private startNewPractice(routeUrl: string): void {
    this.getUIContext().getRouter().pushUrl({ url: routeUrl, params: { topicId: '' } })
  }

  private openPracticeStart(routeUrl: string): void {
    const incompleteExam = this.storage.getLatestIncompletePracticeExam()
    if (incompleteExam === null) {
      this.startNewPractice(routeUrl)
      return
    }
    const progress =
      incompleteExam.answeredQuestionIds.length.toString() + '/' + incompleteExam.questionIds.length.toString()
    AlertDialog.show({
      title: 'Unfinished Practice',
      message: 'You have an unfinished practice exam (' + progress + ').',
      autoCancel: true,
      buttons: [
        {
          value: 'Continue',
          action: () => {
            this.continuePracticeExam(incompleteExam.id)
          }
        },
        {
          value: 'Start',
          action: () => {
            this.startNewPractice(routeUrl)
          }
        },
        {
          value: 'Cancel',
          action: () => {
          }
        }
      ]
    })
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
      router.pushUrl(
        { url: 'pages/TextFilePreviewPage', params: { filePath: material.sandboxPath, title: material.fileName } })
      return
    }
    try {
      await document.show(material.originalUri.length > 0 ? material.originalUri : uri,
        this.mimeTypeForMaterial(material))
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
      Image($r('app.media.ic_materials'))
        .width(size)
        .height(size)
        .objectFit(ImageFit.Contain)
        .opacity(dimmed ? 0.55 : 1)
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
        Row() {
          Blank()
            .width(56)
          Column()
            .height(1)
            .layoutWeight(1)
            .backgroundColor('#EEF1F7')
        }
        .width('100%')
      }
    }
    .width('100%')
    .onClick(() => {
      if (actionName === 'upload') {
        this.uploadMaterialFile()
      } else if (actionName === 'practice') {
        this.openPracticeStart(routeUrl)
      } else if (routeUrl.length > 0) {
        this.getUIContext().getRouter().pushUrl({ url: routeUrl })
      }
    })
  }

  @Builder
  private incompletePracticeCard() {
    Column() {
      Row() {
        this.brandIcon('practice', 40)
        Column() {
          Text('Continue Practice')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111936')
            .width('100%')
          Text(this.incompletePracticeFiles.length > 0 ? this.incompletePracticeFiles : 'Practice files')
            .fontSize(12)
            .fontColor('#59627E')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .margin({ left: 12 })

        Text(this.incompletePracticeProgress)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1655FF')
          .margin({ left: 8, right: 8 })
        Image($r('app.media.ic_next_question'))
          .width(22)
          .height(22)
          .objectFit(ImageFit.Contain)
          .draggable(false)
      }
      .width('100%')

      Text(this.incompletePracticeTime.length > 0 ? ('Last updated ' + this.incompletePracticeTime) :
        'Resume unfinished questions')
        .fontSize(12)
        .fontColor('#68728D')
        .width('100%')
        .margin({ top: 10 })
    }
    .layoutWeight(1)
    .padding(16)
    .backgroundColor('#F6F9FF')
    .borderRadius(12)
    .border({ width: 1, color: '#C9D8FF' })
    .margin({ bottom: 14 })
    .onClick(() => {
      this.continuePracticeExam(this.incompletePracticeExamId)
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

  private bottomTabBarStyle(icon: Resource, label: string): BottomTabBarStyle {
    const normalGlyph = new SymbolGlyphModifier(icon)
      .renderingStrategy(SymbolRenderingStrategy.SINGLE)
      .fontColor([$r('sys.color.icon_primary')])
    const selectedGlyph = new SymbolGlyphModifier(icon)
      .renderingStrategy(SymbolRenderingStrategy.SINGLE)
    return BottomTabBarStyle.of({
      normal: normalGlyph,
      selected: selectedGlyph
    }, label)
      .labelStyle({ unselectedColor: $r('sys.color.font_primary') })
  }

  private immersiveTopInsetVp(): number {
    return this.getUIContext().px2vp(this.immersiveSystemTopInsetPx) + 8
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
          if (this.materialCount === 0) {
            Text('Add slides, notes, papers, or PDFs for focused oral exam practice.')
              .fontSize(13)
              .fontColor('#59627E')
              .lineHeight(20)
              .textAlign(TextAlign.Center)
              .margin({ top: 6 })
          }
          Button('Add Material')
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
        .margin({ top: this.immersiveTopInsetVp() })
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
        .padding({
          left: 14,
          right: 14,
          top: 6,
          bottom: 6
        })
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
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .onWillScroll((_xOffset: number, yOffset: number, _scrollState: ScrollState, scrollSource: ScrollSource) => {
      this.handleVerticalPageScroll(yOffset, scrollSource)
    })
    .edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  private homeHistoryRow(record: HomePracticeHistoryRecord) {
    Row() {
      this.brandIcon('materials', 42)
      Column() {
        Text(record.fileName)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111936')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Text((record.isIncomplete ? 'In Progress' : 'Practice Result') +
          (record.progressText.length > 0 ? (' · ' + record.progressText) : ''))
          .fontSize(12)
          .fontColor('#59627E')
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .margin({ left: 10 })

      if (record.isIncomplete) {
        Button('Continue')
          .height(34)
          .padding({ left: 12, right: 12 })
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .backgroundColor('#1655FF')
          .borderRadius(10)
          .margin({ left: 8 })
          .onClick(() => {
            this.continuePracticeExam(record.examId)
          })
      } else {
        Text(this.formatHomeTime(record.latestPracticeAt))
          .fontSize(12)
          .fontColor('#59627E')
          .margin({ left: 8 })
        Image($r('app.media.ic_next_question'))
          .width(22)
          .height(22)
          .objectFit(ImageFit.Contain)
          .margin({ left: 8 })
          .draggable(false)
      }
    }
    .width('100%')
    .height(74)
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .border({ width: 1, color: '#E6EAF4' })
    .margin({ bottom: 12 })
    .onClick(() => {
      if (record.isIncomplete) {
        this.continuePracticeExam(record.examId)
      } else {
        this.selectHistoryRecord(record)
      }
    })
  }

  @Builder
  private homeResultMetric(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(12)
        .fontColor('#111936')
        .width(104)
      Stack({ alignContent: Alignment.Start }) {
        Column().height(6).width('100%').backgroundColor('#E8ECF7').borderRadius(3)
        Column().height(6).width(value.length > 0 ? (value + '%') : '0%').backgroundColor('#3158F4').borderRadius(3)
      }
      .layoutWeight(1)

      Text(value.length > 0 ? value : '-')
        .fontSize(12)
        .fontColor('#111936')
        .textAlign(TextAlign.End)
        .width(34)
    }
    .width('100%')
    .margin({ top: 12 })
  }

  @Builder
  private homeQuestionResultCard(row: HomePracticeHistoryQuestionResult) {
    Column() {
      Row() {
        Text(row.practiced ? row.score + '/100' : 'Not practiced')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(row.practiced ? (Number(row.score) < 60 ? '#F03A43' : '#1655FF') : '#59627E')
          .padding({
            left: 10,
            right: 10,
            top: 4,
            bottom: 4
          })
          .backgroundColor(row.practiced ? (Number(row.score) < 60 ? '#FFF1F1' : '#EEF3FF') : '#F4F6FA')
          .borderRadius(10)
        Blank()
      }
      .width('100%')

      Text(row.question)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#111936')
        .lineHeight(22)
        .width('100%')
        .margin({ top: 10 })

      if (row.practiced) {
        Text('Your Answer')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#59627E')
          .width('100%')
          .margin({ top: 12 })
        Text(row.userAnswer.length > 0 ? row.userAnswer : 'No answer')
          .fontSize(13)
          .fontColor('#3F4966')
          .lineHeight(20)
          .width('100%')
          .margin({ top: 6 })
      }

      Text('Correct Answer')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1655FF')
        .width('100%')
        .margin({ top: 12 })
      Text(row.correctAnswer)
        .fontSize(13)
        .fontColor('#3F4966')
        .lineHeight(20)
        .width('100%')
        .margin({ top: 6 })

      if (row.feedback.length > 0) {
        Text(row.feedback)
          .fontSize(12)
          .fontColor('#59627E')
          .lineHeight(19)
          .width('100%')
          .margin({ top: 12 })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .border({ width: 1, color: '#E6EAF4' })
    .margin({ bottom: 12 })
  }

  @Builder
  private selectedHistoryPracticeResult() {
    Column() {
      Row() {
        Text('‹')
          .fontSize(34)
          .fontColor('#111936')
          .onClick(() => {
            this.clearSelectedHistoryRecord()
          })
        Text('Practice Result')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111936')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Blank().width(34)
      }
      .height(58)

      Column() {
        Text('Result Evaluation')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#59627E')
          .width('100%')
        Text(this.selectedHistoryScoreText.length > 0 ? (this.selectedHistoryScoreText + '/100') : 'Practice Result')
          .fontSize(this.selectedHistoryScoreText.length > 0 ? 34 : 24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.selectedHistoryScoreText.length > 0 ? '#1655FF' : '#111936')
          .width('100%')
          .margin({ top: 6 })
        Text(
          'Attachments: ' + (this.selectedHistoryFileName.length > 0 ? this.selectedHistoryFileName : 'Practice files'))
          .fontSize(12)
          .fontColor('#59627E')
          .lineHeight(18)
          .width('100%')
          .margin({ top: 10 })
        if (this.selectedHistoryProgressText.length > 0) {
          Text('Progress: ' + this.selectedHistoryProgressText)
            .fontSize(12)
            .fontColor('#59627E')
            .width('100%')
            .margin({ top: 4 })
        }
        this.homeResultMetric('Clarity', this.selectedHistoryClarityScore)
        this.homeResultMetric('Structure', this.selectedHistoryStructureScore)
        this.homeResultMetric('Completeness', this.selectedHistoryCompletenessScore)
        this.homeResultMetric('Accuracy', this.selectedHistoryAccuracyScore)
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .border({ width: 1, color: '#E6EAF4' })
      .margin({ bottom: 16 })

      Text('All questions in this exam')
        .fontSize(13)
        .fontColor('#59627E')
        .width('100%')
        .margin({ bottom: 12 })
      ForEach(this.selectedHistoryRows, (row: HomePracticeHistoryQuestionResult) => {
        this.homeQuestionResultCard(row)
      }, (row: HomePracticeHistoryQuestionResult) => row.id)
    }
    .width('100%')
  }

  @Builder
  private historyTab() {
    Scroll() {
      Column() {
        if (this.selectedHistoryRecordId.length > 0) {
          this.selectedHistoryPracticeResult()
        }

        if (this.selectedHistoryRecordId.length === 0 && this.historyRecords.length === 0) {
          Column() {
            Image($r('app.media.ic_history'))
              .width(70)
              .height(70)
              .objectFit(ImageFit.Contain)
            Text('No practice records yet.')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor('#111936')
              .margin({ top: 12 })
            Text('Practice results will appear here.')
              .fontSize(13)
              .fontColor('#59627E')
              .lineHeight(20)
              .textAlign(TextAlign.Center)
              .margin({ top: 8 })
          }
          .width('100%')
          .padding({ top: 36 })
        } else if (this.selectedHistoryRecordId.length === 0) {
          ForEach(this.historyRecords, (record: HomePracticeHistoryRecord) => {
            this.homeHistoryRow(record)
          }, (record: HomePracticeHistoryRecord) => record.id)
        }
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Start)
      .padding({ left: 18, right: 18, top: this.immersiveTopInsetVp(), bottom: 22 })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .onWillScroll((_xOffset: number, yOffset: number, _scrollState: ScrollState, scrollSource: ScrollSource) => {
      this.handleVerticalPageScroll(yOffset, scrollSource)
    })
    .edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  private homeTab() {
    Scroll() {
      Column() {
        BannerCard({ bannerState: this.bannerState, tabViewType: TabBarType.HOME })
          .width('100%')
          .margin({ top: this.immersiveTopInsetVp() })

        if (this.hasIncompletePractice) {
          Row() {
            Blank().width(18)
            this.incompletePracticeCard()
            Blank().width(18)
          }
          .width('100%')
          .margin({ top: 10 })
        }

        Row() {
          Blank().width(18)
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
          .layoutWeight(1)
          .padding({
            left: 14,
            right: 14,
            top: 6,
            bottom: 6
          })
          .margin({ top: 5 })
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .border({ width: 1, color: '#E6EAF4' })

          Blank().width(18)
        }
        .width('100%')

        Blank()
          .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Start)
      .padding({ bottom: 22 })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .onWillScroll((_xOffset: number, yOffset: number, _scrollState: ScrollState, scrollSource: ScrollSource) => {
      this.handleVerticalPageScroll(yOffset, scrollSource)
    })
    .edgeEffect(EdgeEffect.Spring)
  }

  build() {
    Column() {
      HdsTabs({ controller: this.hdsTabsController, index: this.currentTab }) {
        TabContent() {
          this.homeTab()
        }
        .tabBar(this.bottomTabBarStyle($r('sys.symbol.house_fill'), 'Home'))

        TabContent() {
          this.materialsTab()
        }
        .tabBar(this.bottomTabBarStyle($r('sys.symbol.archivebox_fill'), 'Materials'))

        TabContent() {
          this.historyTab()
        }
        .tabBar(this.bottomTabBarStyle($r('sys.symbol.arrow_counterclockwise_clock'), 'History'))
      }
      .barPosition(BarPosition.End)
      .barOverlap(true)
      .vertical(false)
      .animationDuration(0)
      .attributeModifier(this.hdsTabsModifier)
      .barFloatingStyle({
        adaptToHandedness: true,
        barBottomMargin: this.navigationIndicatorHeightVp > 0 ? this.navigationIndicatorHeightVp : 16,
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.IMMERSIVE,
          materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
        }
      })
      .onChange((index: number) => {
        this.currentTab = index
        this.showBottomTabBar()
      })
      .scrollable(false)
      .width('100%')
      .height('100%')
      .backgroundColor('#FDFEFF')
    }
    .width('100%')
    .height('100%')
  }
}
