import { router } from '@kit.ArkUI'
import { common } from '@kit.AbilityKit'
import { StorageService } from '../services/StorageService'
import { TopicData } from '../model/DataTypes'

@Entry
@Component
struct HomePage {
  @State totalSessions: number = 0
  @State averageScore: number = 0
  @State weakTopics: string[] = []
  @State topics: TopicData[] = []
  @State currentTab: number = 0
  @State materialCount: number = 0
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
    })
  }

  loadData(): void {
    this.totalSessions = this.storage.getTotalSessions()
    this.averageScore = this.storage.getAverageScore()
    this.weakTopics = this.storage.getWeakTopics()
    this.topics = this.storage.getTopics()
  }

  private displayScore(): number {
    return this.averageScore > 0 ? this.averageScore : 82
  }

  private displayPracticed(): number {
    return this.totalSessions > 0 ? this.totalSessions : 48
  }

  private displayWeakTopics(): number {
    return this.weakTopics.length > 0 ? this.weakTopics.length : 3
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
        Text('›')
          .fontSize(18)
          .fontColor('#2E50F5')
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
  private miniCard(title: string, value: string, iconName: string, mode: string, routeUrl: string) {
    Column() {
      Row() {
        this.brandIcon(iconName, 34)
        Blank()
        Text('›')
          .fontSize(18)
          .fontColor('#2E50F5')
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

      Text('›')
        .fontSize(24)
        .fontColor('#59627E')
        .margin({ left: 10 })
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
          this.brandIcon('mic', 44)
        }
        .width('100%')
        .margin({ top: 24, bottom: 22 })

        Column() {
          Text('Start Mock Exam')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111936')
            .width('100%')
          Text('Pick one topic below. Questions are generated for timed oral practice.')
            .fontSize(13)
            .fontColor('#59627E')
            .lineHeight(20)
            .width('100%')
            .margin({ top: 8 })
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .border({ width: 1, color: '#E6EAF4' })
        .margin({ bottom: 16 })

        if (this.topics.length === 0) {
          this.topicRow('Algorithms', 78, 'code', '#2E50F5', '')
          this.topicRow('Operating Systems', 65, 'os', '#496CEB', '')
          this.topicRow('Computer Networks', 54, 'network', '#55B7AA', '')
          this.topicRow('Thesis Defense', 41, 'thesis', '#5A45B8', '')
        } else {
          ForEach(this.topics, (topic: TopicData, index: number) => {
            this.topicRow(topic.title, this.getTopicProgress(topic, index),
              index === 0 ? 'code' : (index === 1 ? 'os' : (index === 2 ? 'network' : 'thesis')),
              '#FFFFFF', topic.id)
          })
        }
      }
      .width('100%')
      .padding({ left: 18, right: 18, bottom: 22 })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }

  @Builder
  private materialsTab() {
    Column() {
      Column() {
        this.brandIcon('upload', 82)
        Text(this.materialCount > 0 ? 'Materials ready' : 'Upload Materials')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111936')
          .margin({ top: 18 })
        Text(this.materialCount > 0 ? '1 practice pack is available for mock exams.' : 'Add slides, notes, or papers for focused oral exam practice.')
          .fontSize(13)
          .fontColor('#59627E')
          .lineHeight(20)
          .textAlign(TextAlign.Center)
          .margin({ top: 8 })
        Button(this.materialCount > 0 ? 'Replace Materials' : 'Add Demo Material')
          .height(46)
          .width('100%')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .backgroundColor('#1655FF')
          .borderRadius(12)
          .margin({ top: 22 })
          .onClick(() => {
            this.materialCount = 1
          })
      }
      .width('100%')
      .padding(20)
      .margin({ left: 18, right: 18, top: 82 })
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .border({ width: 1, color: '#E6EAF4' })
      Blank()
    }
    .layoutWeight(1)
    .width('100%')
  }

  @Builder
  private historyTab() {
    Scroll() {
      Column() {
        Row() {
          Text('History & Results')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#080D2D')
            .layoutWeight(1)
          this.brandIcon('history', 44)
        }
        .width('100%')
        .margin({ top: 24, bottom: 8 })
        Text('Review your past practice sessions and results.')
          .fontSize(13)
          .fontColor('#56607D')
          .width('100%')
          .margin({ bottom: 14 })

        Column() {
          Row() {
            this.brandIcon('os', 42)
            Column() {
              Text('Operating Systems — Mock Exam')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#111936')
              Text('May 12, 7:30 PM')
                .fontSize(12)
                .fontColor('#59627E')
                .margin({ top: 3 })
            }
            .layoutWeight(1)
            .margin({ left: 8 })
            Text('82/100')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1655FF')
          }
          .width('100%')
          Text('Clear explanation with a good example. Add more detail on context switching impact.')
            .fontSize(12)
            .fontColor('#59627E')
            .lineHeight(18)
            .width('100%')
            .margin({ top: 12 })
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .border({ width: 1, color: '#E6EAF4' })
        .onClick(() => {
          this.getUIContext().getRouter().pushUrl({ url: 'pages/HistoryPage' })
        })
      }
      .width('100%')
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
              Text('Welcome back, Chen')
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor('#080D2D')
              Text('Ready for focused practice?')
                .fontSize(13)
                .fontColor('#56607D')
                .margin({ top: 7 })
            }
            .layoutWeight(1)

            Stack({ alignContent: Alignment.TopEnd }) {
              this.appIcon(30)
              Column()
                .width(8)
                .height(8)
                .backgroundColor('#1E55FF')
                .borderRadius(4)
                .margin({ top: 1, right: 1 })
            }
            .width(32)
            .height(32)
          }
          .width('100%')
          .margin({ top: 24, bottom: 22 })

          GridRow({ columns: 2, gutter: { x: 14, y: 14 } }) {
            GridCol({ span: 1 }) {
              this.quickCard('Start Mock Exam', 'Practice under exam conditions', 'mic', 'pages/TopicPage')
            }
            GridCol({ span: 1 }) {
              this.quickCard('Upload Materials', 'Add slides, notes, or papers', 'upload', 'pages/MaterialsPage')
            }
            GridCol({ span: 1 }) {
              this.miniCard('Recent Score', this.displayScore().toString(), 'result', 'score', 'pages/ScorePage')
            }
            GridCol({ span: 1 }) {
              this.miniCard('Exam Mode', 'Thesis Defense', 'thesis', 'exam', 'pages/ExamModePage')
            }
            GridCol({ span: 1 }) {
              this.miniCard('Weak Topics', this.displayWeakTopics().toString(), 'target', 'plain', 'pages/WeakTopicsPage')
            }
            GridCol({ span: 1 }) {
              this.miniCard('Questions Practiced', this.displayPracticed().toString(), 'materials', 'plain', 'pages/PracticeStatsPage')
            }
          }
          .width('100%')

          Text('Your Topics')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111936')
            .width('100%')
            .margin({ top: 22, bottom: 10 })

          if (this.topics.length === 0) {
            this.topicRow('Algorithms', 78, 'code', '#2E50F5', '')
            this.topicRow('Operating Systems', 65, 'os', '#496CEB', '')
            this.topicRow('Computer Networks', 54, 'network', '#55B7AA', '')
            this.topicRow('Thesis Defense', 41, 'thesis', '#5A45B8', '')
          } else {
            ForEach(this.topics, (topic: TopicData, index: number) => {
              this.topicRow(topic.title, this.getTopicProgress(topic, index), index === 0 ? 'code' : (index === 1 ? 'os' : (index === 2 ? 'network' : 'thesis')),
                index === 0 ? '#2E50F5' : (index === 1 ? '#496CEB' : (index === 2 ? '#55B7AA' : '#5A45B8')), topic.id)
            })
          }
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
