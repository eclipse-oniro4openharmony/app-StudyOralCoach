import { router } from '@kit.ArkUI'
import { common } from '@kit.AbilityKit'
import { EvaluationData, PracticeExamData, SessionData } from '../model/DataTypes'
import { MaterialQuestionAnswerRecord, StudyMaterialRecord } from '../model/StudyMaterialRecord'
import { MaterialIngestionService } from '../services/MaterialIngestionService'
import { StorageService } from '../services/StorageService'

class PracticeFileHistoryRecord {
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
  rows: PracticeHistoryQuestionResult[] = []
}

class PracticeHistoryQuestionResult {
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
struct HistoryPage {
  @State records: PracticeFileHistoryRecord[] = []
  @State selectedRecordId: string = ''
  @State selectedFileName: string = ''
  @State selectedProgressText: string = ''
  @State selectedScoreText: string = ''
  @State selectedClarityScore: string = ''
  @State selectedStructureScore: string = ''
  @State selectedCompletenessScore: string = ''
  @State selectedAccuracyScore: string = ''
  @State selectedRows: PracticeHistoryQuestionResult[] = []
  @State isLoading: boolean = true
  private storage: StorageService = StorageService.getInstance()

  aboutToAppear(): void {
    const context = getContext(this) as common.UIAbilityContext
    this.storage.init(context).then(async () => {
      await this.loadData(context)
    })
  }

  private async loadData(context: common.UIAbilityContext): Promise<void> {
    const service = new MaterialIngestionService(context)
    const sessions = this.storage.getSessions().filter((session: SessionData) => session.questionId.length > 0)
    const questions = await service.listAllQuestions(1000)
    const materials = await service.listRecent(1000)
    const evaluations = this.storage.getEvaluations()
    const records: PracticeFileHistoryRecord[] = []
    const exams = this.storage.getPracticeExams()

    exams.forEach((exam: PracticeExamData) => {
      if (exam.answeredQuestionIds.length === 0) {
        return
      }
      const record = new PracticeFileHistoryRecord()
      record.id = exam.id
      record.examId = exam.id
      record.fileName = this.fileNamesForExam(exam, questions, materials)
      record.progressText = exam.answeredQuestionIds.length.toString() + '/' + exam.questionIds.length.toString()
      record.latestPracticeAt = exam.updatedAt
      const latestSession = sessions.find((session: SessionData) => (session.examId ?? '') === exam.id)
      record.latestSessionId = latestSession !== undefined ? latestSession.id : ''
      this.applyEvaluationToRecord(record, evaluations)
      record.rows = this.buildQuestionRowsForExam(exam, questions, sessions, evaluations)
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
      let record = records.find((item: PracticeFileHistoryRecord) => item.materialId === question.materialId)
      if (record === undefined) {
        record = new PracticeFileHistoryRecord()
        record.id = question.materialId
        record.materialId = question.materialId
        record.fileName = material !== undefined ? material.fileName : 'Practice file'
        record.progressText = 'Legacy'
        record.rows = this.buildQuestionRowsForMaterial(question.materialId, questions, sessions, evaluations)
        records.push(record)
      }

      if (record.latestSessionId.length === 0 || Number(session.startedAt) > Number(record.latestPracticeAt)) {
        record.latestSessionId = session.id
        record.latestPracticeAt = session.startedAt
        this.applyEvaluationToRecord(record, evaluations)
      }
    })

    this.records = records.sort((a: PracticeFileHistoryRecord, b: PracticeFileHistoryRecord) =>
      Number(b.latestPracticeAt) - Number(a.latestPracticeAt))
    this.isLoading = false
  }

  private buildQuestionRowsForExam(exam: PracticeExamData, questions: MaterialQuestionAnswerRecord[],
    sessions: SessionData[], evaluations: EvaluationData[]): PracticeHistoryQuestionResult[] {
    const rows: PracticeHistoryQuestionResult[] = []
    exam.questionIds.forEach((questionId: string) => {
      const question = questions.find((item: MaterialQuestionAnswerRecord) => item.id === questionId)
      if (question !== undefined) {
        rows.push(this.toQuestionResult(question, sessions, evaluations, exam.id))
      }
    })
    return rows
  }

  private buildQuestionRowsForMaterial(materialId: string, questions: MaterialQuestionAnswerRecord[],
    sessions: SessionData[], evaluations: EvaluationData[]): PracticeHistoryQuestionResult[] {
    const rows: PracticeHistoryQuestionResult[] = []
    questions
      .filter((question: MaterialQuestionAnswerRecord) => question.materialId === materialId)
      .forEach((question: MaterialQuestionAnswerRecord) => {
        rows.push(this.toQuestionResult(question, sessions, evaluations, ''))
      })
    return rows
  }

  private toQuestionResult(question: MaterialQuestionAnswerRecord, sessions: SessionData[],
    evaluations: EvaluationData[], examId: string): PracticeHistoryQuestionResult {
    const row = new PracticeHistoryQuestionResult()
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

  private applyEvaluationToRecord(record: PracticeFileHistoryRecord, evaluations: EvaluationData[]): void {
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

  private fileNamesForMaterialIds(materialIds: string[], materials: StudyMaterialRecord[]): string {
    const names: string[] = []
    materialIds.forEach((materialId: string) => {
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

  private fileNamesForExam(exam: PracticeExamData, questions: MaterialQuestionAnswerRecord[],
    materials: StudyMaterialRecord[]): string {
    let materialIds = exam.materialIds
    if (materialIds.length === 0) {
      materialIds = []
      exam.questionIds.forEach((questionId: string) => {
        const question = questions.find((item: MaterialQuestionAnswerRecord) => item.id === questionId)
        if (question !== undefined && question.materialId.length > 0 && materialIds.indexOf(question.materialId) < 0) {
          materialIds.push(question.materialId)
        }
      })
    }
    return this.fileNamesForMaterialIds(materialIds, materials)
  }

  private formatTime(timestamp: string): string {
    const value = Number(timestamp)
    if (value <= 0) {
      return ''
    }
    const date = new Date(value)
    return (date.getMonth() + 1).toString() + '/' + date.getDate().toString() + ' ' +
      date.getHours().toString().padStart(2, '0') + ':' + date.getMinutes().toString().padStart(2, '0')
  }

  private selectRecord(record: PracticeFileHistoryRecord): void {
    this.selectedRecordId = record.id
    this.selectedFileName = record.fileName
    this.selectedProgressText = record.progressText
    this.selectedScoreText = record.scoreText
    this.selectedClarityScore = record.clarityScore
    this.selectedStructureScore = record.structureScore
    this.selectedCompletenessScore = record.completenessScore
    this.selectedAccuracyScore = record.accuracyScore
    this.selectedRows = record.rows
  }

  private clearSelectedRecord(): void {
    this.selectedRecordId = ''
    this.selectedFileName = ''
    this.selectedProgressText = ''
    this.selectedScoreText = ''
    this.selectedClarityScore = ''
    this.selectedStructureScore = ''
    this.selectedCompletenessScore = ''
    this.selectedAccuracyScore = ''
    this.selectedRows = []
  }

  @Builder
  private brandIcon(name: string, size: number, dimmed: boolean = false) {
    if (name === 'home') {
      Image($r('app.media.ic_home')).width(size).height(size).objectFit(ImageFit.Contain).opacity(dimmed ? 0.55 : 1)
    } else if (name === 'practice') {
      Image($r('app.media.ic_practice')).width(size).height(size).objectFit(ImageFit.Contain).opacity(dimmed ? 0.55 : 1)
    } else if (name === 'materials') {
      Image($r('app.media.ic_materials')).width(size).height(size).objectFit(ImageFit.Contain).opacity(dimmed ? 0.55 : 1)
    } else if (name === 'history') {
      Image($r('app.media.ic_history')).width(size).height(size).objectFit(ImageFit.Contain).opacity(dimmed ? 0.55 : 1)
    } else {
      Image($r('app.media.ic_result')).width(size).height(size).objectFit(ImageFit.Contain)
    }
  }

  @Builder
  private historyFileRow(record: PracticeFileHistoryRecord) {
    Row() {
      this.brandIcon('materials', 44)
      Column() {
        Text(record.fileName)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111936')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Text('Practice Result' + (record.progressText.length > 0 ? (' · ' + record.progressText) : ''))
          .fontSize(12)
          .fontColor('#59627E')
          .margin({ top: 4 })
      }
      .width('100%')
      .layoutWeight(1)
      .margin({ left: 12 })

      Text(this.formatTime(record.latestPracticeAt))
        .fontSize(12)
        .fontColor('#59627E')
        .margin({ left: 10 })

      Image($r('app.media.ic_next_question'))
        .width(22)
        .height(22)
        .objectFit(ImageFit.Contain)
        .margin({ left: 8 })
        .draggable(false)
    }
    .width('100%')
    .height(74)
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .border({ width: 1, color: '#E6EAF4' })
    .margin({ bottom: 12 })
    .onClick(() => {
      this.selectRecord(record)
    })
  }

  @Builder
  private resultMetric(label: string, value: string) {
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
  private questionResultCard(row: PracticeHistoryQuestionResult) {
    Column() {
      Row() {
        Text(row.practiced ? row.score + '/100' : 'Not practiced')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(row.practiced ? (Number(row.score) < 60 ? '#F03A43' : '#1655FF') : '#59627E')
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
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
  private selectedPracticeResult() {
    Column() {
      Row() {
        Text('‹').fontSize(34).fontColor('#111936').onClick(() => this.clearSelectedRecord())
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
        Text(this.selectedScoreText.length > 0 ? (this.selectedScoreText + '/100') : 'Practice Result')
          .fontSize(this.selectedScoreText.length > 0 ? 34 : 24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.selectedScoreText.length > 0 ? '#1655FF' : '#111936')
          .width('100%')
          .margin({ top: 6 })
        Text('Attachments: ' + (this.selectedFileName.length > 0 ? this.selectedFileName : 'Practice files'))
          .fontSize(12)
          .fontColor('#59627E')
          .lineHeight(18)
          .width('100%')
          .margin({ top: 10 })
        if (this.selectedProgressText.length > 0) {
          Text('Progress: ' + this.selectedProgressText)
            .fontSize(12)
            .fontColor('#59627E')
            .width('100%')
            .margin({ top: 4 })
        }
        this.resultMetric('Clarity', this.selectedClarityScore)
        this.resultMetric('Structure', this.selectedStructureScore)
        this.resultMetric('Completeness', this.selectedCompletenessScore)
        this.resultMetric('Accuracy', this.selectedAccuracyScore)
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
      ForEach(this.selectedRows, (row: PracticeHistoryQuestionResult) => {
        this.questionResultCard(row)
      }, (row: PracticeHistoryQuestionResult) => row.id)
    }
    .width('100%')
  }

  @Builder
  private bottomNav(active: string) {
    Row() {
      this.navItem('home', 'Home', active === 'Home')
      this.navItem('practice', 'Practice', active === 'Practice')
      this.navItem('materials', 'Materials', active === 'Materials')
      this.navItem('history', 'History', active === 'History')
    }
    .width('100%')
    .height(72)
    .padding({ left: 10, right: 10, bottom: 6 })
    .backgroundColor('#FFFFFF')
    .border({ width: { top: 1 }, color: '#EEF1F7' })
  }

  @Builder
  private navItem(iconName: string, label: string, selected: boolean) {
    Column() {
      this.brandIcon(iconName, 30, !selected)
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
      router.replaceUrl({
        url: 'pages/HomePage',
        params: { tab: label === 'Practice' ? 'practice' : (label === 'Materials' ? 'materials' : (label === 'History' ? 'history' : 'home')) }
      })
    })
  }

  build() {
    Column() {
      if (this.selectedRecordId.length === 0) {
        Row() {
          Blank().width(34)
          Text('History')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111936')
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
          Blank().width(34)
        }
        .height(58)
        .padding({ left: 18, right: 18, top: 8 })
      }

      Scroll() {
        Column() {
          if (this.selectedRecordId.length > 0) {
            this.selectedPracticeResult()
          } else if (this.isLoading) {
            Text('Loading history...')
              .fontSize(14)
              .fontColor('#59627E')
              .width('100%')
              .textAlign(TextAlign.Center)
              .margin({ top: 32 })
          } else if (this.records.length === 0) {
            Image($r('app.media.ic_history')).width(70).height(70).objectFit(ImageFit.Contain).margin({ top: 32 })
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
          } else {
            ForEach(this.records, (record: PracticeFileHistoryRecord) => {
              this.historyFileRow(record)
            }, (record: PracticeFileHistoryRecord) => record.id)
          }
        }
        .width('100%')
        .padding({ left: 18, right: 18, top: 16, bottom: 24 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      this.bottomNav('History')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FDFEFF')
  }
}
