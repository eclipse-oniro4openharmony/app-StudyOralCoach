import { MaterialQuestionAnswerRecord } from '../model/StudyMaterialRecord'

class ParsedQuestionBlock {
  question: string = ''
  answerParts: string[] = []
  sourceParts: string[] = []
}

export class MaterialQuestionGenerator {
  private readonly maxQuestions: number = 200

  generate(materialId: string, text: string): MaterialQuestionAnswerRecord[] {
    const cleanText = this.normalizeText(text)
    if (cleanText.length === 0) {
      return []
    }
    return this.extractQuestionAnswers(materialId, cleanText)
  }

  private extractQuestionAnswers(materialId: string, text: string): MaterialQuestionAnswerRecord[] {
    const lines = text.split('\n')
    const records: MaterialQuestionAnswerRecord[] = []
    const seenQuestions: string[] = []
    let current: ParsedQuestionBlock | null = null

    for (let index = 0; index < lines.length; index++) {
      const line = lines[index].trim()
      if (line.length === 0) {
        continue
      }

      const inlinePair = this.parseInlinePair(line)
      if (inlinePair !== null) {
        this.flushBlock(materialId, current, records, seenQuestions)
        current = null
        this.pushRecord(materialId, inlinePair.question, inlinePair.answerParts.join('\n'), line, records, seenQuestions)
        if (records.length >= this.maxQuestions) {
          break
        }
        continue
      }

      if (this.isQuestionLine(line, current !== null && current.answerParts.length > 0)) {
        this.flushBlock(materialId, current, records, seenQuestions)
        current = new ParsedQuestionBlock()
        current.question = this.cleanQuestion(line)
        current.sourceParts.push(line)
        continue
      }

      if (current !== null) {
        const answerLine = this.cleanAnswer(line)
        if (answerLine.length > 0) {
          current.answerParts.push(answerLine)
          current.sourceParts.push(line)
        }
      }
    }

    this.flushBlock(materialId, current, records, seenQuestions)
    return records
  }

  private flushBlock(
    materialId: string,
    block: ParsedQuestionBlock | null,
    records: MaterialQuestionAnswerRecord[],
    seenQuestions: string[]
  ): void {
    if (block === null || records.length >= this.maxQuestions) {
      return
    }
    const answer = block.answerParts.join('\n').trim()
    if (answer.length === 0) {
      return
    }
    this.pushRecord(materialId, block.question, answer, block.sourceParts.join('\n'), records, seenQuestions)
  }

  private pushRecord(
    materialId: string,
    question: string,
    answer: string,
    sourceText: string,
    records: MaterialQuestionAnswerRecord[],
    seenQuestions: string[]
  ): void {
    const cleanQuestion = this.cleanQuestion(question)
    const cleanAnswer = answer.trim()
    if (!this.isValidQuestionTitle(cleanQuestion) || cleanAnswer.length === 0) {
      return
    }

    const questionKey = cleanQuestion.toLowerCase().replace(/\s+/g, ' ')
    if (seenQuestions.indexOf(questionKey) >= 0) {
      return
    }

    const record = this.record(materialId, cleanQuestion, cleanAnswer, sourceText, records.length)
    records.push(record)
    seenQuestions.push(questionKey)
  }

  private record(
    materialId: string,
    question: string,
    answer: string,
    sourceText: string,
    position: number
  ): MaterialQuestionAnswerRecord {
    const now = Date.now().toString()
    const record = new MaterialQuestionAnswerRecord()
    record.id = materialId + '_qa_' + position.toString() + '_' + Math.floor(Math.random() * 100000).toString()
    record.materialId = materialId
    record.question = question.trim()
    record.answer = answer.trim()
    record.sourceText = sourceText.trim()
    record.position = position
    record.practiceCount = 0
    record.lastPracticedAt = ''
    record.createdAt = now
    return record
  }

  private normalizeText(text: string): string {
    return text
      .replace(/\r\n/g, '\n')
      .replace(/\r/g, '\n')
      .replace(/[ \t]+/g, ' ')
      .trim()
  }

  private parseInlinePair(line: string): ParsedQuestionBlock | null {
    const answerMarker = this.answerMarkerIndex(line)
    if (answerMarker <= 0) {
      return null
    }

    const left = line.substring(0, answerMarker).trim()
    const right = line.substring(answerMarker).trim()
    if (!this.isQuestionLine(left)) {
      return null
    }

    const block = new ParsedQuestionBlock()
    block.question = this.cleanQuestion(left)
    block.answerParts.push(this.cleanAnswer(right))
    return block
  }

  private answerMarkerIndex(line: string): number {
    const markers: string[] = [' A:', ' a:', ' Answer:', ' answer:', ' Ans:', ' ans:']
    for (let index = 0; index < markers.length; index++) {
      const markerIndex = line.indexOf(markers[index])
      if (markerIndex >= 0) {
        return markerIndex + 1
      }
    }
    return -1
  }

  private isQuestionLine(line: string, hasCurrentAnswer: boolean = false): boolean {
    const clean = line.trim()
    const lower = clean.toLowerCase()
    if (lower.indexOf('q:') === 0 || lower.indexOf('q ') === 0 || lower.indexOf('question:') === 0) {
      return true
    }
    if (lower.match(/^q[0-9]+[\.:)]\s+/) !== null) {
      return true
    }
    if (clean.match(/^[0-9]+[\.)、]\s*\S+/) !== null && clean.length <= 220) {
      return this.isLikelyNumberedQuestion(clean, hasCurrentAnswer)
    }
    if (clean.indexOf('?') >= 0 || clean.indexOf('？') >= 0) {
      return this.isLikelyQuestionSentence(clean)
    }
    return false
  }

  private isLikelyNumberedQuestion(line: string, hasCurrentAnswer: boolean): boolean {
    const body = line.replace(/^[0-9]+[\.)、]\s*/, '').trim()
    const lower = body.toLowerCase()
    if (body.indexOf(' / ') >= 0) {
      return true
    }
    if (body.indexOf('?') >= 0 || body.indexOf('？') >= 0) {
      return this.isLikelyQuestionSentence(body)
    }
    if (lower.match(/^(what|why|how|when|where|which|who|define|explain|describe|compare|list|types|advantages|disadvantages)\b/) !== null) {
      return true
    }
    return !hasCurrentAnswer && body.length <= 80
  }

  private isLikelyQuestionSentence(line: string): boolean {
    const clean = line.trim()
    const lower = clean.toLowerCase()
    if (clean.length > 220) {
      return false
    }

    const questionIndex = Math.max(clean.indexOf('?'), clean.indexOf('？'))
    const colonIndex = Math.max(clean.indexOf(':'), clean.indexOf('：'))
    if (colonIndex >= 0 && questionIndex > colonIndex) {
      return false
    }

    if (lower.match(/^(what|why|how|when|where|which|who|define|explain|describe|compare|list|types|advantages|disadvantages)\b/) !== null) {
      return true
    }
    return clean.endsWith('?') || clean.endsWith('？')
  }

  private isValidQuestionTitle(question: string): boolean {
    const clean = question.trim()
    const lower = clean.toLowerCase()
    if (clean.length < 3 || clean.length > 220) {
      return false
    }
    if (clean.indexOf('|') >= 0) {
      return false
    }
    if (clean.match(/^(post|get|put|delete|patch)$/i) !== null) {
      return false
    }
    if (clean.match(/[A-Za-z]/) === null) {
      return false
    }
    if (clean.match(/^(on expiry|mechanisms)\b/i) !== null) {
      return false
    }
    if (clean.match(/^(authentication|authorization|accountability)\b/i) !== null && clean.indexOf(':') >= 0) {
      return false
    }
    if (this.isLikelyQuestionSentence(clean)) {
      return true
    }
    if (lower.match(/^(what|why|how|when|where|which|who|define|explain|describe|compare|list|types|advantages|disadvantages)\b/) !== null) {
      return true
    }
    if (clean.indexOf(' / ') >= 0) {
      return true
    }

    const words = clean.split(/\s+/)
    let wordCount = 0
    for (let index = 0; index < words.length; index++) {
      if (words[index].match(/[A-Za-z0-9]/) !== null) {
        wordCount++
      }
    }
    return wordCount >= 2
  }

  private cleanQuestion(question: string): string {
    let clean = question.trim()
    clean = clean.replace(/^Q[0-9]*[\.:)]\s*/i, '')
    clean = clean.replace(/^Question[\.:]\s*/i, '')
    clean = clean.replace(/^[0-9]+[\.)、]\s*/, '')
    clean = clean.replace(/\s*\/\s*$/, '')
    return clean.trim()
  }

  private cleanAnswer(line: string): string {
    let clean = line.trim()
    clean = clean.replace(/^A[\.:)]\s*/i, '')
    clean = clean.replace(/^Answer[\.:]\s*/i, '')
    clean = clean.replace(/^Ans[\.:]\s*/i, '')
    return clean.trim()
  }
}
