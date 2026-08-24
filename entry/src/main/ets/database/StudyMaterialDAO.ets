import { relationalStore } from '@kit.ArkData'
import { MaterialQuestionAnswerRecord, StudyMaterialRecord } from '../model/StudyMaterialRecord'
import { StudyOralDBConfig } from './StudyOralDBConfig'
import {
  materialQuestionToBucket,
  resultSetToMaterialQuestions,
  resultSetToStudyMaterials,
  studyMaterialToBucket
} from './StudyMaterialMapper'

export class StudyMaterialDAO {
  private store: relationalStore.RdbStore

  constructor(store: relationalStore.RdbStore) {
    this.store = store
  }

  async upsert(record: StudyMaterialRecord): Promise<number> {
    return await this.store.insert(
      StudyOralDBConfig.MATERIAL_TABLE.tableName,
      studyMaterialToBucket(record),
      relationalStore.ConflictResolution.ON_CONFLICT_REPLACE
    )
  }

  async replaceQuestions(materialId: string, questions: MaterialQuestionAnswerRecord[]): Promise<void> {
    await this.deleteQuestionsByMaterialId(materialId)
    for (let index = 0; index < questions.length; index++) {
      await this.store.insert(
        StudyOralDBConfig.MATERIAL_QUESTION_TABLE.tableName,
        materialQuestionToBucket(questions[index]),
        relationalStore.ConflictResolution.ON_CONFLICT_REPLACE
      )
    }
  }

  async listQuestions(materialId: string): Promise<MaterialQuestionAnswerRecord[]> {
    const predicates = new relationalStore.RdbPredicates(StudyOralDBConfig.MATERIAL_QUESTION_TABLE.tableName)
    predicates.equalTo('material_id', materialId)
    predicates.orderByAsc('position')
    const resultSet = await this.store.query(predicates, StudyOralDBConfig.MATERIAL_QUESTION_TABLE.columns)
    const records = resultSetToMaterialQuestions(resultSet)
    resultSet.close()
    return records
  }

  async listAllQuestions(limit: number = 1000): Promise<MaterialQuestionAnswerRecord[]> {
    const predicates = new relationalStore.RdbPredicates(StudyOralDBConfig.MATERIAL_QUESTION_TABLE.tableName)
    predicates.orderByAsc('material_id')
    predicates.orderByAsc('position')
    predicates.limitAs(limit)
    const resultSet = await this.store.query(predicates, StudyOralDBConfig.MATERIAL_QUESTION_TABLE.columns)
    const records = resultSetToMaterialQuestions(resultSet)
    resultSet.close()
    return records
  }

  async countQuestions(): Promise<number> {
    const predicates = new relationalStore.RdbPredicates(StudyOralDBConfig.MATERIAL_QUESTION_TABLE.tableName)
    const resultSet = await this.store.query(predicates, ['id'])
    const total = resultSet.rowCount
    resultSet.close()
    return total
  }

  async listPracticeQuestions(limit: number = 500): Promise<MaterialQuestionAnswerRecord[]> {
    const predicates = new relationalStore.RdbPredicates(StudyOralDBConfig.MATERIAL_QUESTION_TABLE.tableName)
    predicates.orderByAsc('practice_count')
    predicates.orderByAsc('last_practiced_at')
    predicates.limitAs(limit)
    const resultSet = await this.store.query(predicates, StudyOralDBConfig.MATERIAL_QUESTION_TABLE.columns)
    const records = resultSetToMaterialQuestions(resultSet)
    resultSet.close()
    return records
  }

  async markQuestionPracticed(questionId: string, practiceCount: number, practicedAt: string): Promise<number> {
    const bucket: relationalStore.ValuesBucket = {}
    bucket.practice_count = practiceCount
    bucket.last_practiced_at = practicedAt
    const predicates = new relationalStore.RdbPredicates(StudyOralDBConfig.MATERIAL_QUESTION_TABLE.tableName)
    predicates.equalTo('id', questionId)
    return await this.store.update(bucket, predicates)
  }

  async deleteMaterial(materialId: string): Promise<number> {
    await this.deleteQuestionsByMaterialId(materialId)
    const predicates = new relationalStore.RdbPredicates(StudyOralDBConfig.MATERIAL_TABLE.tableName)
    predicates.equalTo('id', materialId)
    return await this.store.delete(predicates)
  }

  private async deleteQuestionsByMaterialId(materialId: string): Promise<number> {
    const predicates = new relationalStore.RdbPredicates(StudyOralDBConfig.MATERIAL_QUESTION_TABLE.tableName)
    predicates.equalTo('material_id', materialId)
    return await this.store.delete(predicates)
  }

  async listRecent(limit: number = 20): Promise<StudyMaterialRecord[]> {
    const predicates = new relationalStore.RdbPredicates(StudyOralDBConfig.MATERIAL_TABLE.tableName)
    predicates.orderByDesc('updated_at')
    predicates.limitAs(limit)
    const resultSet = await this.store.query(predicates, StudyOralDBConfig.MATERIAL_TABLE.columns)
    const records = resultSetToStudyMaterials(resultSet)
    resultSet.close()
    return records
  }

  async count(): Promise<number> {
    const predicates = new relationalStore.RdbPredicates(StudyOralDBConfig.MATERIAL_TABLE.tableName)
    const resultSet = await this.store.query(predicates, ['id'])
    const total = resultSet.rowCount
    resultSet.close()
    return total
  }
}
