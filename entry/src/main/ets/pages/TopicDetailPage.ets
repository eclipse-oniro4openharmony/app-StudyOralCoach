import { router } from '@kit.ArkUI'
import { common } from '@kit.AbilityKit'
import { StorageService } from '../services/StorageService'
import { TopicData, QuestionData } from '../model/DataTypes'

@Entry
@Component
struct TopicDetailPage {
  @State topicId: string = ''
  @State topicTitle: string = ''
  @State topicDescription: string = ''
  @State topicCategory: string = ''
  @State questions: QuestionData[] = []
  @State newQuestionContent: string = ''
  @State newQuestionDifficulty: number = 1
  private storage: StorageService = StorageService.getInstance()

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>
    this.topicId = params.topicId ?? ''
    const context = getContext(this) as common.UIAbilityContext
    this.storage.init(context).then(() => {
      this.loadData()
    })
  }

  loadData(): void {
    const topics = this.storage.getTopics()
    const topic = topics.find(t => t.id === this.topicId)
    if (topic) {
      this.topicTitle = topic.title
      this.topicDescription = topic.description
      this.topicCategory = topic.category
    }
    this.questions = this.storage.getQuestionsByTopicId(this.topicId)
  }

  addQuestion(): void {
    if (this.newQuestionContent.length === 0) {
      return
    }
    const question = new QuestionData()
    question.id = Date.now().toString()
    question.topicId = this.topicId
    question.content = this.newQuestionContent
    question.difficulty = this.newQuestionDifficulty.toString()
    question.followUpEnabled = 'true'
    question.createdAt = Date.now().toString()
    this.storage.addQuestion(question)
    this.newQuestionContent = ''
    this.loadData()
  }

  deleteQuestion(id: string): void {
    this.storage.deleteQuestion(id)
    this.loadData()
  }

  startPractice(): void {
    router.pushUrl({
      url: 'pages/PracticePage',
      params: { topicId: this.topicId }
    })
  }
  private getDifficultyStars(difficulty: string): string {
    const diff = Number(difficulty)
    return '★'.repeat(diff) + '☆'.repeat(4 - diff)
  }

  build() {
    Column() {
      Row() {
        Text('<')
          .fontSize(24)
          .onClick(() => {
            router.back()
          })
        Text(this.topicTitle.length > 0 ? this.topicTitle : 'Topic')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 8 })

      Column() {
        Text(this.topicDescription)
          .fontSize(14)
          .fontColor('#666666')
        Text('Category: ' + this.topicCategory)
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 4 })
      }
      .width('90%')
      .padding(16)
      .backgroundColor('#E3F2FD')
      .borderRadius(8)
      .margin({ bottom: 16 })

      Row() {
        TextInput({ placeholder: 'Add a question...' })
          .layoutWeight(1)
          .onChange((value: string) => {
            this.newQuestionContent = value
          })
        Button('Add')
          .margin({ left: 8 })
          .onClick(() => {
            this.addQuestion()
          })
      }
      .width('90%')
      .margin({ bottom: 16 })

      Text('Questions')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .width('90%')
        .margin({ bottom: 8 })

      if (this.questions.length === 0) {
        Column() {
          Text('No questions yet')
            .fontSize(16)
            .fontColor('#999999')
          Text('Add questions to practice with')
            .fontSize(12)
            .fontColor('#BBBBBB')
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.questions, (question: QuestionData) => {
            ListItem() {
              Row() {
                Column() {
                  Text(question.content)
                    .fontSize(14)
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text('Difficulty: ' + this.getDifficultyStars(question.difficulty))
                    .fontSize(12)
                    .fontColor('#FF9800')
                    .margin({ top: 4 })
                }.layoutWeight(1)

                Text('X')
                  .fontSize(18)
                  .fontColor('#F44336')
                  .margin({ left: 8 })
                  .onClick(() => {
                    this.deleteQuestion(question.id)
                  })
              }
              .width('100%')
              .padding(12)
              .backgroundColor('#FFFFFF')
              .borderRadius(8)
            }
          })
        }
        .layoutWeight(1)
      }

      Button('Start Practice')
        .width('90%')
        .height(50)
        .fontSize(18)
        .backgroundColor('#4CAF50')
        .margin({ top: 16, bottom: 16 })
        .onClick(() => {
          this.startPractice()
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
