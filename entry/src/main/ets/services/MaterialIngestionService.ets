import { common } from '@kit.AbilityKit'
import { MaterialQuestionAnswerRecord, StudyMaterialRecord } from '../model/StudyMaterialRecord'
import { StudyOralDatabase } from '../database/StudyOralDatabase'
import { StudyMaterialDAO } from '../database/StudyMaterialDAO'
import { DocumentQuestionAnswer, DocumentTextExtractor, DocumentTextResult } from './DocumentTextExtractor'
import { MaterialUploadHelper, UploadedMaterial } from './MaterialUploadHelper'
import { MaterialQuestionGenerator } from './MaterialQuestionGenerator'

export class MaterialIngestionService {
  private readonly parserVersion: number = 3
  private context: common.Context

  constructor(context: common.Context) {
    this.context = context
  }

  async uploadExtractAndSave(): Promise<StudyMaterialRecord> {
    const uploadHelper = new MaterialUploadHelper(this.context)
    const uploaded: UploadedMaterial = await uploadHelper.selectFile()
    const extractor = new DocumentTextExtractor()
    const extracted: DocumentTextResult = await extractor.extract(uploaded.sandboxPath, uploaded.extension, uploaded.fileName)
    const record = this.toRecord(uploaded, extracted)
    const questionGenerator = new MaterialQuestionGenerator()
    const questions = extracted.qaPairs.length > 0 ?
      this.recordsFromExtractedPairs(record.id, extracted.qaPairs) :
      questionGenerator.generate(record.id, record.extractedText)
    record.questionCount = questions.length
    record.parserVersion = this.parserVersion
    const database = await StudyOralDatabase.getInstance(this.context)
    const dao = new StudyMaterialDAO(database.getStore())
    await dao.upsert(record)
    await dao.replaceQuestions(record.id, questions)
    return record
  }

  async listRecent(limit: number = 20): Promise<StudyMaterialRecord[]> {
    const database = await StudyOralDatabase.getInstance(this.context)
    const dao = new StudyMaterialDAO(database.getStore())
    const records = await dao.listRecent(limit)
    const upgraded = await this.upgradeQuestionParser(records, dao)
    if (upgraded) {
      return await dao.listRecent(limit)
    }
    return records
  }

  async count(): Promise<number> {
    const database = await StudyOralDatabase.getInstance(this.context)
    const dao = new StudyMaterialDAO(database.getStore())
    return await dao.count()
  }

  async listAllQuestions(limit: number = 1000): Promise<MaterialQuestionAnswerRecord[]> {
    const database = await StudyOralDatabase.getInstance(this.context)
    const dao = new StudyMaterialDAO(database.getStore())
    return await dao.listAllQuestions(limit)
  }

  async countQuestions(): Promise<number> {
    const database = await StudyOralDatabase.getInstance(this.context)
    const dao = new StudyMaterialDAO(database.getStore())
    return await dao.countQuestions()
  }

  async listQuestions(materialId: string): Promise<MaterialQuestionAnswerRecord[]> {
    if (materialId.length === 0) {
      return []
    }
    const database = await StudyOralDatabase.getInstance(this.context)
    const dao = new StudyMaterialDAO(database.getStore())
    return await dao.listQuestions(materialId)
  }

  async listPracticedQuestions(limit: number = 1000): Promise<MaterialQuestionAnswerRecord[]> {
    const questions = await this.listAllQuestions(limit)
    return questions
      .filter((question: MaterialQuestionAnswerRecord) => question.practiceCount > 0)
      .sort((a: MaterialQuestionAnswerRecord, b: MaterialQuestionAnswerRecord) => Number(b.lastPracticedAt) - Number(a.lastPracticedAt))
  }

  async getRandomPracticeQuestion(): Promise<MaterialQuestionAnswerRecord | null> {
    const database = await StudyOralDatabase.getInstance(this.context)
    const dao = new StudyMaterialDAO(database.getStore())
    const questions = await dao.listPracticeQuestions(500)
    if (questions.length === 0) {
      return null
    }
    const index = Math.floor(Math.random() * questions.length)
    return questions[index]
  }

  async markQuestionPracticed(questionId: string, practiceCount: number): Promise<void> {
    if (questionId.length === 0) {
      return
    }
    const database = await StudyOralDatabase.getInstance(this.context)
    const dao = new StudyMaterialDAO(database.getStore())
    await dao.markQuestionPracticed(questionId, practiceCount, Date.now().toString())
  }

  async deleteMaterial(materialId: string): Promise<void> {
    const database = await StudyOralDatabase.getInstance(this.context)
    const dao = new StudyMaterialDAO(database.getStore())
    await dao.deleteMaterial(materialId)
  }

  private toRecord(uploaded: UploadedMaterial, extracted: DocumentTextResult): StudyMaterialRecord {
    const now = Date.now().toString()
    const record = new StudyMaterialRecord()
    record.id = 'material_' + now
    record.fileName = uploaded.fileName
    record.originalUri = uploaded.originalUri
    record.sandboxPath = uploaded.sandboxPath
    record.extension = uploaded.extension
    record.extractedText = extracted.text
    record.textPreview = this.previewText(extracted.text)
    record.extractionStatus = extracted.status
    record.extractionError = extracted.error
    record.createdAt = uploaded.uploadedAt.length > 0 ? uploaded.uploadedAt : now
    record.updatedAt = now
    record.parserVersion = this.parserVersion
    return record
  }

  private async upgradeQuestionParser(records: StudyMaterialRecord[], dao: StudyMaterialDAO): Promise<boolean> {
    let upgraded = false
    const generator = new MaterialQuestionGenerator()
    for (let index = 0; index < records.length; index++) {
      const record = records[index]
      if (record.parserVersion >= this.parserVersion || record.extractionStatus !== 'ready' ||
        record.extractedText.length === 0) {
        continue
      }

      const questions = generator.generate(record.id, record.extractedText)
      record.questionCount = questions.length
      record.parserVersion = this.parserVersion
      record.updatedAt = Date.now().toString()
      await dao.upsert(record)
      await dao.replaceQuestions(record.id, questions)
      upgraded = true
    }
    return upgraded
  }

  private previewText(text: string): string {
    const clean = text.trim().replace(/\s+/g, ' ')
    if (clean.length <= 180) {
      return clean
    }
    return clean.substring(0, 180)
  }

  private recordsFromExtractedPairs(materialId: string, pairs: DocumentQuestionAnswer[]): MaterialQuestionAnswerRecord[] {
    const records: MaterialQuestionAnswerRecord[] = []
    const seenQuestions: string[] = []
    for (let index = 0; index < pairs.length; index++) {
      const pair = pairs[index]
      const question = pair.question.trim()
      const answer = pair.answer.trim()
      const key = question.toLowerCase().replace(/\s+/g, ' ')
      if (question.length < 3 || answer.length === 0 || seenQuestions.indexOf(key) >= 0) {
        continue
      }
      const record = new MaterialQuestionAnswerRecord()
      record.id = materialId + '_ai_qa_' + records.length.toString() + '_' + Math.floor(Math.random() * 100000).toString()
      record.materialId = materialId
      record.question = question
      record.answer = answer
      record.sourceText = question + '\n' + answer
      record.position = records.length
      record.practiceCount = 0
      record.lastPracticedAt = ''
      record.createdAt = Date.now().toString()
      records.push(record)
      seenQuestions.push(key)
    }
    return records
  }
}
