import { audio } from '@kit.AudioKit'
import webSocket from '@ohos.net.webSocket'
import { buildAsrListenUrl } from './BackendConfig'

export class TranscriptionSegment {
  text: string
  isFinal: boolean
  timestamp: number

  constructor(text: string, isFinal: boolean, timestamp: number) {
    this.text = text
    this.isFinal = isFinal
    this.timestamp = timestamp
  }
}

export interface AsrListener {
  onPartialResult(segment: TranscriptionSegment): void
  onFinalResult(fullText: string): void
  onError(error: string): void
}

export class DeepgramAsrListener implements AsrListener {
  private partialHandler: (segment: TranscriptionSegment) => void
  private finalHandler: (fullText: string) => void
  private errorHandler: (error: string) => void

  constructor(
    partialHandler: (segment: TranscriptionSegment) => void,
    finalHandler: (fullText: string) => void,
    errorHandler: (error: string) => void
  ) {
    this.partialHandler = partialHandler
    this.finalHandler = finalHandler
    this.errorHandler = errorHandler
  }

  onPartialResult(segment: TranscriptionSegment): void {
    this.partialHandler(segment)
  }

  onFinalResult(fullText: string): void {
    this.finalHandler(fullText)
  }

  onError(error: string): void {
    this.errorHandler(error)
  }
}

interface DeepgramAlternative {
  transcript: string
}

interface DeepgramChannel {
  alternatives: DeepgramAlternative[]
}

interface DeepgramMessage {
  is_final: boolean
  channel: DeepgramChannel
}

export class DeepgramAsrClient {
  private audioCapturer: audio.AudioCapturer | null = null
  private ws: webSocket.WebSocket | null = null
  private isStarted: boolean = false
  private isStopping: boolean = false
  private isWsOpen: boolean = false
  private startTime: number = 0
  private accumulatedText: string = ''
  private currentUtterance: string = ''
  private stopResolver: (() => void) | null = null

  async start(listener: AsrListener): Promise<void> {
    if (this.isStarted) {
      return
    }
    this.isStarted = true
    this.isStopping = false
    this.isWsOpen = false
    this.startTime = Date.now()
    this.accumulatedText = ''
    this.currentUtterance = ''

    try {
      await this.initAudioCapturer()
      this.initWebSocket(listener)
      await this.audioCapturer?.start()
      this.captureLoop(listener)
    } catch (error) {
      this.isStarted = false
      listener.onError(JSON.stringify(error))
      await this.releaseAudio()
    }
  }

  async stop(): Promise<void> {
    if (!this.isStarted) {
      return
    }
    this.isStarted = false
    this.isStopping = true
    await this.releaseAudio()

    if (this.ws !== null && this.isWsOpen) {
      const waitForClose = new Promise<void>((resolve) => {
        this.stopResolver = resolve
      })
      await this.ws.send(JSON.stringify({ type: 'Finalize' }))
      await this.ws.send(JSON.stringify({ type: 'CloseStream' }))
      await Promise.race([
        waitForClose,
        new Promise<void>((resolve) => setTimeout(resolve, 1500))
      ])
    }
    this.closeSocket()
    this.isStopping = false
  }

  private async initAudioCapturer(): Promise<void> {
    const audioConfig: audio.AudioCapturerOptions = {
      streamInfo: {
        samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_16000,
        channels: audio.AudioChannel.CHANNEL_1,
        sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
        encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
      },
      capturerInfo: {
        source: audio.SourceType.SOURCE_TYPE_MIC,
        capturerFlags: 0
      }
    }
    this.audioCapturer = await audio.createAudioCapturer(audioConfig)
  }

  private initWebSocket(listener: AsrListener): void {
    this.ws = webSocket.createWebSocket()
    this.ws.on('open', () => {
      this.isWsOpen = true
    })
    this.ws.on('message', (error, value) => {
      if (error || typeof value !== 'string') {
        return
      }
      this.handleDeepgramMessage(value, listener)
    })
    this.ws.on('close', () => {
      this.isWsOpen = false
      const finalText = (this.accumulatedText + this.currentUtterance).trim()
      if (finalText.length > 0) {
        listener.onFinalResult(finalText)
      }
      if (this.stopResolver !== null) {
        this.stopResolver()
        this.stopResolver = null
      }
    })
    this.ws.on('error', (error) => {
      const hasTranscript = (this.accumulatedText + this.currentUtterance).trim().length > 0
      if (!this.isStopping && !hasTranscript) {
        listener.onError(JSON.stringify(error))
      }
    })
    this.ws.connect(buildAsrListenUrl(), () => {})
  }

  private handleDeepgramMessage(raw: string, listener: AsrListener): void {
    try {
      const message = JSON.parse(raw) as DeepgramMessage
      const transcript = message.channel?.alternatives?.[0]?.transcript?.trim() ?? ''
      if (transcript.length === 0) {
        return
      }
      if (message.is_final) {
        this.accumulatedText += transcript + ' '
        this.currentUtterance = ''
      } else {
        this.currentUtterance = transcript
      }
      listener.onPartialResult(new TranscriptionSegment(
        (this.accumulatedText + this.currentUtterance).trim(),
        message.is_final,
        Date.now() - this.startTime
      ))
    } catch (error) {
      if (!this.isStopping) {
        listener.onError(JSON.stringify(error))
      }
    }
  }

  private async captureLoop(listener: AsrListener): Promise<void> {
    while (this.isStarted && this.audioCapturer !== null) {
      try {
        const bufferSize = await this.audioCapturer.getBufferSize()
        const buffer = await this.audioCapturer.read(bufferSize, true)
        if (buffer !== undefined && this.ws !== null && this.isWsOpen) {
          await this.ws.send(buffer)
        }
      } catch (error) {
        if (this.isStarted && !this.isStopping) {
          listener.onError(JSON.stringify(error))
          await new Promise<void>((resolve) => setTimeout(resolve, 40))
        }
      }
    }
  }

  private async releaseAudio(): Promise<void> {
    if (this.audioCapturer === null) {
      return
    }
    try {
      await this.audioCapturer.stop()
    } catch (error) {
    }
    try {
      await this.audioCapturer.release()
    } catch (error) {
    }
    this.audioCapturer = null
  }

  private closeSocket(): void {
    if (this.ws !== null) {
      try {
        this.ws.close()
      } catch (error) {
      }
    }
    this.ws = null
    this.isWsOpen = false
  }
}
