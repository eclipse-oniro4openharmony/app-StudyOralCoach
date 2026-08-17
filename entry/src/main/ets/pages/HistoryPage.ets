import { router } from '@kit.ArkUI'
import { common } from '@kit.AbilityKit'
import { StorageService } from '../services/StorageService'
import { SessionData, EvaluationData } from '../model/DataTypes'

@Entry
@Component
struct HistoryPage {
  @State sessions: SessionData[] = []
  @State evaluations: EvaluationData[] = []
  private storage: StorageService = StorageService.getInstance()

  aboutToAppear(): void {
    const context = getContext(this) as common.UIAbilityContext
    this.storage.init(context).then(() => {
      this.loadData()
    })
  }

  loadData(): void {
    this.sessions = this.storage.getSessions()
    this.evaluations = this.storage.getEvaluations()
  }

  private formatTime(timestamp: string): string {
    const date = new Date(Number(timestamp))
    const month = (date.getMonth() + 1).toString().padStart(2, '0')
    const day = date.getDate().toString().padStart(2, '0')
    const hours = date.getHours().toString().padStart(2, '0')
    const minutes = date.getMinutes().toString().padStart(2, '0')
    return 'May ' + day + ', ' + hours + ':' + minutes
  }

  private scoreForFirst(): string {
    if (this.evaluations.length > 0) {
      return this.evaluations[0].overallScore
    }
    return '82'
  }

  private metricValue(index: number, fallback: string): string {
    if (this.evaluations.length > 0) {
      if (index === 0) {
        return this.evaluations[0].clarityScore
      }
      if (index === 1) {
        return this.evaluations[0].structureScore
      }
      return this.evaluations[0].accuracyScore
    }
    return fallback
  }

  private feedbackText(): string {
    if (this.evaluations.length > 0 && this.evaluations[0].feedback.length > 0) {
      return this.evaluations[0].feedback
    }
    return 'Clear explanation with a good example. Add more detail on context switching impact.'
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
  private scorePill(score: string) {
    Row() {
      Text(score)
        .fontSize(19)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1655FF')
      Text('/100')
        .fontSize(11)
        .fontColor('#1655FF')
        .margin({ left: 1, top: 5 })
    }
    .height(42)
    .padding({ left: 14, right: 14 })
    .backgroundColor('#F0F4FF')
    .borderRadius(21)
  }

  @Builder
  private metric(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(12)
        .fontColor('#111936')
        .width(74)
      Stack({ alignContent: Alignment.Start }) {
        Column()
          .width('100%')
          .height(5)
          .backgroundColor('#E8ECF7')
          .borderRadius(3)
        Column()
          .width(value + '%')
          .height(5)
          .backgroundColor('#3158F4')
          .borderRadius(3)
      }
      .layoutWeight(1)
      .height(5)
      Text(value)
        .fontSize(12)
        .fontColor('#111936')
        .textAlign(TextAlign.End)
        .width(30)
    }
    .width('100%')
    .margin({ top: 12 })
  }

  @Builder
  private compactCard(iconName: string, title: string, date: string, score: string) {
    Row() {
      this.brandIcon(iconName, 42)
      Column() {
        Text(title + ' — Mock Exam')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111936')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(date)
          .fontSize(12)
          .fontColor('#59627E')
          .margin({ top: 3 })
        Text('Thesis Defense')
          .fontSize(11)
          .fontColor('#1655FF')
          .padding({ left: 10, right: 10, top: 3, bottom: 3 })
          .backgroundColor('#EEF3FF')
          .borderRadius(10)
          .margin({ top: 6 })
      }
      .layoutWeight(1)
      .margin({ left: 8 })

      this.scorePill(score)
      Text('›')
        .fontSize(24)
        .fontColor('#5A6480')
        .margin({ left: 8 })
    }
    .height(84)
    .width('100%')
    .padding({ left: 14, right: 14 })
    .backgroundColor('#FFFFFF')
    .borderRadius(10)
    .border({ width: 1, color: '#E6EAF4' })
    .margin({ top: 10 })
  }

  @Builder
  private bottomNav(active: string) {
    Row() {
      this.navItem('home', 'Home', active === 'Home', 'pages/HomePage')
      this.navItem('practice', 'Practice', active === 'Practice', 'pages/TopicPage')
      this.navItem('materials', 'Materials', active === 'Materials', 'pages/MaterialsPage')
      this.navItem('history', 'History', active === 'History', 'pages/HistoryPage')
    }
    .width('100%')
    .height(72)
    .padding({ left: 10, right: 10, bottom: 6 })
    .backgroundColor('#FFFFFF')
    .border({ width: { top: 1 }, color: '#EEF1F7' })
  }

  @Builder
  private navItem(iconName: string, label: string, selected: boolean, url: string) {
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
        Blank()
          .width(26)
        Text('History & Results')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111936')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Text('▽')
          .fontSize(24)
          .fontColor('#111936')
          .width(26)
          .textAlign(TextAlign.End)
      }
      .width('100%')
      .height(58)
      .padding({ left: 18, right: 18, top: 8 })

      Text('Review your past practice sessions and results.')
        .fontSize(13)
        .fontColor('#4F5A78')
        .width('100%')
        .padding({ left: 18, right: 18, bottom: 14 })

      Scroll() {
        Column() {
          Column() {
            Row() {
              this.brandIcon('os', 42)
              Column() {
                Text('Operating Systems — Mock Exam')
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#111936')
                Text(this.sessions.length > 0 ? this.formatTime(this.sessions[0].startedAt) : 'May 12, 7:30 PM')
                  .fontSize(12)
                  .fontColor('#59627E')
                  .margin({ top: 3 })
              }
              .layoutWeight(1)
              .margin({ left: 8 })
              this.scorePill(this.scoreForFirst())
            }
            .width('100%')

            Row() {
              Blank()
                .width(42)
              Text('Thesis Defense')
                .fontSize(11)
                .fontColor('#1655FF')
                .padding({ left: 10, right: 10, top: 3, bottom: 3 })
                .backgroundColor('#EEF3FF')
                .borderRadius(10)
              Blank()
              Text('⌃')
                .fontSize(16)
                .fontColor('#1655FF')
            }
            .width('100%')
            .margin({ top: 8 })

            Column() {
              Text('Evaluation Result')
                .fontSize(13)
                .fontWeight(FontWeight.Bold)
                .fontColor('#111936')
                .width('100%')

              Row() {
                Column() {
                  Text(this.scoreForFirst())
                    .fontSize(28)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#111936')
                    .textAlign(TextAlign.Center)
                  Text('/100')
                    .fontSize(11)
                    .fontColor('#59627E')
                }
                .width(82)
                .height(82)
                .justifyContent(FlexAlign.Center)
                .borderRadius(41)
                .border({ width: 8, color: '#3158F4' })

                Column() {
                  this.metric('Clarity', this.metricValue(0, '84'))
                  this.metric('Structure', this.metricValue(1, '78'))
                  this.metric('Accuracy', this.metricValue(2, '85'))
                }
                .layoutWeight(1)
                .margin({ left: 18 })
              }
              .width('100%')
              .margin({ top: 10 })

              Text('Feedback Summary')
                .fontSize(13)
                .fontWeight(FontWeight.Bold)
                .fontColor('#111936')
                .width('100%')
                .margin({ top: 16 })
              Text(this.feedbackText())
                .fontSize(12)
                .fontColor('#4F5A78')
                .lineHeight(18)
                .width('100%')
                .margin({ top: 7 })

              Button('View Full Evaluation  ↗')
                .height(38)
                .width('100%')
                .fontSize(13)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1655FF')
                .backgroundColor('#EAF0FF')
                .borderRadius(9)
                .margin({ top: 14 })
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(10)
            .border({ width: 1, color: '#E2E7F2' })
            .margin({ top: 12 })
          }
          .width('100%')
          .padding(14)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .border({ width: 1.5, color: '#2F5BFF' })

          if (this.sessions.length > 1) {
            ForEach(this.sessions.slice(1, 4), (session: SessionData, index: number) => {
              this.compactCard(index === 0 ? 'network' : (index === 1 ? 'code' : 'thesis'),
                index === 0 ? 'Computer Networks' : (index === 1 ? 'Algorithms' : 'Research Methods'),
                this.formatTime(session.startedAt),
                this.evaluations.length > index + 1 ? this.evaluations[index + 1].overallScore : (index === 0 ? '76' : (index === 1 ? '71' : '88')))
            })
          } else {
            this.compactCard('network', 'Computer Networks', 'May 10, 9:15 AM', '76')
            this.compactCard('code', 'Algorithms', 'May 8, 4:20 PM', '71')
            this.compactCard('thesis', 'Research Methods', 'May 5, 6:00 PM', '88')
          }
        }
        .width('100%')
        .padding({ left: 18, right: 18, bottom: 22 })
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
