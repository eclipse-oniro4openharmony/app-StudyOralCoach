import { router } from '@kit.ArkUI'

@Entry
@Component
struct MaterialsPage {
  @State materialCount: number = 0

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
        this.icon('upload', 82)
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
      .margin({ left: 18, right: 18, top: 22 })
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .border({ width: 1, color: '#E6EAF4' })

      Blank()

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
