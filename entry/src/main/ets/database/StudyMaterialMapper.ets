import { relationalStore } from '@kit.ArkData'
import { MaterialQuestionAnswerRecord, StudyMaterialRecord } from '../model/StudyMaterialRecord'

export function studyMaterialToBucket(record: StudyMaterialRecord): relationalStore.ValuesBucket {
  const bucket: relationalStore.ValuesBucket = {}
  bucket.id = record.id
  bucket.file_name = record.fileName
  bucket.original_uri = record.originalUri
  bucket.sandbox_path = record.sandboxPath
  bucket.extension = record.extension
  bucket.extracted_text = record.extractedText
  bucket.text_preview = record.textPreview
  bucket.extraction_status = record.extractionStatus
  bucket.extraction_error = record.extractionError
  bucket.created_at = record.createdAt
  bucket.updated_at = record.updatedAt
  bucket.question_count = record.questionCount
  bucket.parser_version = record.parserVersion
  return bucket
}

export function resultSetToStudyMaterials(resultSet: relationalStore.ResultSet): StudyMaterialRecord[] {
  const records: StudyMaterialRecord[] = []
  while (resultSet.goToNextRow()) {
    const record = new StudyMaterialRecord()
    record.id = resultSet.getString(resultSet.getColumnIndex('id'))
    record.fileName = resultSet.getString(resultSet.getColumnIndex('file_name'))
    record.originalUri = resultSet.getString(resultSet.getColumnIndex('original_uri'))
    record.sandboxPath = resultSet.getString(resultSet.getColumnIndex('sandbox_path'))
    record.extension = resultSet.getString(resultSet.getColumnIndex('extension'))
    record.extractedText = resultSet.getString(resultSet.getColumnIndex('extracted_text'))
    record.textPreview = resultSet.getString(resultSet.getColumnIndex('text_preview'))
    record.extractionStatus = resultSet.getString(resultSet.getColumnIndex('extraction_status'))
    record.extractionError = resultSet.getString(resultSet.getColumnIndex('extraction_error'))
    record.createdAt = resultSet.getString(resultSet.getColumnIndex('created_at'))
    record.updatedAt = resultSet.getString(resultSet.getColumnIndex('updated_at'))
    record.questionCount = resultSet.getLong(resultSet.getColumnIndex('question_count'))
    record.parserVersion = resultSet.getLong(resultSet.getColumnIndex('parser_version'))
    records.push(record)
  }
  return records
}

export function materialQuestionToBucket(record: MaterialQuestionAnswerRecord): relationalStore.ValuesBucket {
  const bucket: relationalStore.ValuesBucket = {}
  bucket.id = record.id
  bucket.material_id = record.materialId
  bucket.question = record.question
  bucket.answer = record.answer
  bucket.source_text = record.sourceText
  bucket.position = record.position
  bucket.practice_count = record.practiceCount
  bucket.last_practiced_at = record.lastPracticedAt
  bucket.created_at = record.createdAt
  return bucket
}

export function resultSetToMaterialQuestions(resultSet: relationalStore.ResultSet): MaterialQuestionAnswerRecord[] {
  const records: MaterialQuestionAnswerRecord[] = []
  while (resultSet.goToNextRow()) {
    const record = new MaterialQuestionAnswerRecord()
    record.id = resultSet.getString(resultSet.getColumnIndex('id'))
    record.materialId = resultSet.getString(resultSet.getColumnIndex('material_id'))
    record.question = resultSet.getString(resultSet.getColumnIndex('question'))
    record.answer = resultSet.getString(resultSet.getColumnIndex('answer'))
    record.sourceText = resultSet.getString(resultSet.getColumnIndex('source_text'))
    record.position = resultSet.getLong(resultSet.getColumnIndex('position'))
    record.practiceCount = resultSet.getLong(resultSet.getColumnIndex('practice_count'))
    record.lastPracticedAt = resultSet.getString(resultSet.getColumnIndex('last_practiced_at'))
    record.createdAt = resultSet.getString(resultSet.getColumnIndex('created_at'))
    records.push(record)
  }
  return records
}
