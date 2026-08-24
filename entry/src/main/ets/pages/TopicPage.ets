import { router } from '@kit.ArkUI'
import { common } from '@kit.AbilityKit'
import { StorageService } from '../services/StorageService'
import { TopicData } from '../model/DataTypes'

@Entry
@Component
struct TopicPage {
  @State topics: TopicData[] = []
  @State showAddDialog: boolean = false
  @State newTopicTitle: string = ''
  @State newTopicDescription: string = ''
  @State selectedCategory: string = 'Thesis Defense'
  private storage: StorageService = StorageService.getInstance()

  aboutToAppear(): void {
    const context = getContext(this) as common.UIAbilityContext
    this.storage.init(context).then(() => {
      this.loadTopics()
    })
  }

  loadTopics(): void {
    this.topics = this.storage.getTopics()
  }

  addTopic(): void {
    if (this.newTopicTitle.length === 0) {
      return
    }
    const topic = new TopicData()
    topic.id = Date.now().toString()
    topic.title = this.newTopicTitle
    topic.description = this.newTopicDescription
    topic.category = this.selectedCategory
    topic.questionCount = '0'
    topic.createdAt = Date.now().toString()
    topic.updatedAt = Date.now().toString()
    this.storage.addTopic(topic)
    this.newTopicTitle = ''
    this.newTopicDescription = ''
    this.showAddDialog = false
    this.loadTopics()
  }

  private topicProgress(topic: TopicData, index: number): number {
    const count = Number(topic.questionCount)
    if (count > 0) {
      const value = count * 13
      return value > 88 ? 88 : value
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
  private brandIcon(name: string, size: number, dimmed: boolean = false) {
    if (name === 'mic') {
      Image($r('app.media.ic_mic')).width(size).height(size).objectFit(ImageFit.Contain).opacity(dimmed ? 0.55 : 1)
    } else if (name === 'home') {
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
  private topicCard(title: string, desc: string, percent: number, iconName: string, color: string, id: string) {
    Row() {
      Column() {
        this.brandIcon(iconName, 58)
      }
      .width(60)
      .height(60)
      .justifyContent(FlexAlign.Center)

      Column() {
        Row() {
          Text(title)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111936')
            .layoutWeight(1)
          Text(percent.toString() + '%')
            .fontSize(12)
            .fontColor('#4F5A78')
        }
        .width('100%')

        Text(desc.length > 0 ? desc : 'Mock exam practice')
          .fontSize(12)
          .fontColor('#59627E')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .margin({ top: 5 })

        Stack({ alignContent: Alignment.Start }) {
          Column()
            .height(4)
            .width('100%')
            .backgroundColor('#E8ECF4')
            .borderRadius(3)
          Column()
            .height(4)
            .width(percent.toString() + '%')
            .backgroundColor('#3158F4')
            .borderRadius(3)
        }
        .width('100%')
        .height(4)
        .margin({ top: 10 })
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
    .width('100%')
    .height(92)
    .padding({ left: 14, right: 14 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .border({ width: 1, color: '#E5EAF5' })
    .margin({ bottom: 12 })
    .onClick(() => {
      if (id.length > 0) {
        router.pushUrl({ url: 'pages/PracticePage', params: { topicId: id } })
      }
    })
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
        Text('‹')
          .fontSize(34)
          .fontColor('#111936')
          .onClick(() => {
            router.back()
          })
        Text('Practice')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111936')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Text('+')
          .fontSize(28)
          .fontColor('#111936')
          .onClick(() => {
            this.showAddDialog = true
          })
      }
      .width('100%')
      .height(58)
      .padding({ left: 18, right: 18, top: 8 })

      Scroll() {
        Column() {
          Row() {
            Column() {
              Text('Choose a topic')
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor('#080D2D')
              Text('Start a mock oral exam from your practice library.')
                .fontSize(13)
                .fontColor('#56607D')
                .lineHeight(20)
                .margin({ top: 6 })
            }
            .layoutWeight(1)
          }
          .width('100%')
          .margin({ bottom: 18 })

          Column() {
            Text('Start Mock Exam')
              .fontSize(17)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .width('100%')
            Text('Pick a topic below and practice under exam conditions.')
              .fontSize(13)
              .fontColor('#EEF3FF')
              .lineHeight(20)
              .width('100%')
              .margin({ top: 8 })
          }
          .width('100%')
          .height(110)
          .padding(18)
          .backgroundColor('#2E50F5')
          .borderRadius(12)
          .shadow({ radius: 18, color: '#2E50F533', offsetY: 8 })
          .margin({ bottom: 18 })

          if (this.topics.length === 0) {
            this.topicCard('Algorithms', 'Coding and complexity questions', 78, 'code', '#2E50F5', '')
            this.topicCard('Operating Systems', 'Processes, threads, memory, scheduling', 65, 'os', '#496CEB', '')
            this.topicCard('Computer Networks', 'Protocols, routing, transport layers', 54, 'network', '#55B7AA', '')
            this.topicCard('Thesis Defense', 'Research methods and defense answers', 41, 'thesis', '#5A45B8', '')
          } else {
            ForEach(this.topics, (topic: TopicData, index: number) => {
              this.topicCard(topic.title, topic.description, this.topicProgress(topic, index),
                index === 0 ? 'code' : (index === 1 ? 'os' : (index === 2 ? 'network' : 'thesis')),
                index === 0 ? '#2E50F5' : (index === 1 ? '#496CEB' : (index === 2 ? '#55B7AA' : '#5A45B8')),
                topic.id)
            })
          }
        }
        .width('100%')
        .padding({ left: 18, right: 18, bottom: 22 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      this.bottomNav('Practice')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FDFEFF')
  }
}
