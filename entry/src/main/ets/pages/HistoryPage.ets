import { router } from '@kit.ArkUI'
import { common } from '@kit.AbilityKit'
import { SessionData } from '../model/DataTypes'
import { MaterialQuestionAnswerRecord, StudyMaterialRecord } from '../model/StudyMaterialRecord'
import { MaterialIngestionService } from '../services/MaterialIngestionService'
import { StorageService } from '../services/StorageService'

class PracticeFileHistoryRecord {
  materialId: string = ''
  fileName: string = ''
  latestSessionId: string = ''
  latestPracticeAt: string = ''
}

@Entry
@Component
struct HistoryPage {
  @State records: PracticeFileHistoryRecord[] = []
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
    const records: PracticeFileHistoryRecord[] = []

    sessions.forEach((session: SessionData) => {
      const question = questions.find((item: MaterialQuestionAnswerRecord) => item.id === session.questionId)
      if (question === undefined) {
        return
      }
      const material = materials.find((item: StudyMaterialRecord) => item.id === question.materialId)
      let record = records.find((item: PracticeFileHistoryRecord) => item.materialId === question.materialId)
      if (record === undefined) {
        record = new PracticeFileHistoryRecord()
        record.materialId = question.materialId
        record.fileName = material !== undefined ? material.fileName : 'Practice file'
        records.push(record)
      }

      if (record.latestSessionId.length === 0 || Number(session.startedAt) > Number(record.latestPracticeAt)) {
        record.latestSessionId = session.id
        record.latestPracticeAt = session.startedAt
      }
    })

    this.records = records.sort((a: PracticeFileHistoryRecord, b: PracticeFileHistoryRecord) =>
      Number(b.latestPracticeAt) - Number(a.latestPracticeAt))
    this.isLoading = false
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
      Row() {
        Text(record.fileName)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111936')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
        Text(this.formatTime(record.latestPracticeAt))
          .fontSize(12)
          .fontColor('#59627E')
          .margin({ left: 10 })
      }
      .width('100%')
      .layoutWeight(1)
      .margin({ left: 12 })

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
      router.pushUrl({
        url: 'pages/HistoryDetailPage',
        params: { sessionId: record.latestSessionId, materialId: record.materialId }
      })
    })
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

      Scroll() {
        Column() {
          if (this.isLoading) {
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
            }, (record: PracticeFileHistoryRecord) => record.materialId)
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
