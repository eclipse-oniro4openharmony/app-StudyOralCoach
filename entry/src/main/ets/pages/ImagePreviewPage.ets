import { router } from '@kit.ArkUI'

interface ImagePreviewParams {
  imageUri?: string
}

@Entry
@Component
struct ImagePreviewPage {
  @State private imageUri: string = ''
  @State private imageScale: number = 1
  @State private imageTranslateX: number = 0
  @State private imageTranslateY: number = 0

  private pinchStartScale: number = 1
  private pinchStartTranslateX: number = 0
  private pinchStartTranslateY: number = 0
  private pinchStartCenterX: number = 0
  private pinchStartCenterY: number = 0
  private pinchStartDistance: number = 0
  private panStartX: number = 0
  private panStartY: number = 0
  private panStartTranslateX: number = 0
  private panStartTranslateY: number = 0
  private pinchActive: boolean = false
  private panActive: boolean = false
  private static readonly MIN_SCALE: number = 1
  private static readonly MAX_SCALE: number = 4

  aboutToAppear(): void {
    const params = router.getParams() as ImagePreviewParams | null
    this.imageUri = params?.imageUri ?? ''
  }

  private clampScale(scale: number): number {
    if (scale < ImagePreviewPage.MIN_SCALE) {
      return ImagePreviewPage.MIN_SCALE
    }
    if (scale > ImagePreviewPage.MAX_SCALE) {
      return ImagePreviewPage.MAX_SCALE
    }
    return scale
  }

  private touchDistance(a: TouchObject, b: TouchObject): number {
    const dx = Number(a.x) - Number(b.x)
    const dy = Number(a.y) - Number(b.y)
    return Math.sqrt(dx * dx + dy * dy)
  }

  private beginPinch(t1: TouchObject, t2: TouchObject): void {
    this.pinchActive = true
    this.panActive = false
    this.pinchStartScale = this.imageScale
    this.pinchStartTranslateX = this.imageTranslateX
    this.pinchStartTranslateY = this.imageTranslateY
    this.pinchStartCenterX = (Number(t1.x) + Number(t2.x)) / 2
    this.pinchStartCenterY = (Number(t1.y) + Number(t2.y)) / 2
    this.pinchStartDistance = Math.max(1, this.touchDistance(t1, t2))
  }

  private updatePinch(t1: TouchObject, t2: TouchObject): void {
    const centerX = (Number(t1.x) + Number(t2.x)) / 2
    const centerY = (Number(t1.y) + Number(t2.y)) / 2
    const distance = Math.max(1, this.touchDistance(t1, t2))
    const nextScale = this.clampScale(this.pinchStartScale * (distance / this.pinchStartDistance))
    const imagePointX = (this.pinchStartCenterX - this.pinchStartTranslateX) / this.pinchStartScale
    const imagePointY = (this.pinchStartCenterY - this.pinchStartTranslateY) / this.pinchStartScale
    this.imageScale = nextScale
    this.imageTranslateX = centerX - imagePointX * nextScale
    this.imageTranslateY = centerY - imagePointY * nextScale
  }

  private beginPan(t: TouchObject): void {
    this.panActive = this.imageScale > 1.001
    this.panStartX = Number(t.x)
    this.panStartY = Number(t.y)
    this.panStartTranslateX = this.imageTranslateX
    this.panStartTranslateY = this.imageTranslateY
  }

  private updatePan(t: TouchObject): void {
    if (!this.panActive) {
      return
    }
    this.imageTranslateX = this.panStartTranslateX + Number(t.x) - this.panStartX
    this.imageTranslateY = this.panStartTranslateY + Number(t.y) - this.panStartY
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#E6000000')
        .onClick(() => router.back())

      if (this.imageUri.length > 0) {
        Image(this.imageUri)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Contain)
          .translate({ x: this.imageTranslateX, y: this.imageTranslateY })
          .scale({ x: this.imageScale, y: this.imageScale })
          .hitTestBehavior(HitTestMode.Block)
          .onTouch((event: TouchEvent) => {
            if (event.touches.length >= 2) {
              const t1 = event.touches[0]
              const t2 = event.touches[1]
              if (event.type === TouchType.Down || !this.pinchActive) {
                this.beginPinch(t1, t2)
              }
              if (event.type === TouchType.Move || event.type === TouchType.Down) {
                this.updatePinch(t1, t2)
              }
              return
            }
            if (event.touches.length === 1) {
              const t = event.touches[0]
              if (event.type === TouchType.Down) {
                this.pinchActive = false
                this.beginPan(t)
              } else if (event.type === TouchType.Move) {
                this.updatePan(t)
              }
              return
            }
            if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
              this.pinchActive = false
              this.panActive = false
            }
          })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#E6000000')
  }
}
