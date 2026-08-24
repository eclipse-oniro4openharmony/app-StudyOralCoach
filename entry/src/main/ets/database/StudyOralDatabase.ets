import { Context } from '@kit.AbilityKit'
import { relationalStore } from '@kit.ArkData'
import { StudyOralDBConfig } from './StudyOralDBConfig'

export class StudyOralDatabase {
  private static instance: StudyOralDatabase | null = null
  private store: relationalStore.RdbStore

  private constructor(store: relationalStore.RdbStore) {
    this.store = store
  }

  static async getInstance(context: Context): Promise<StudyOralDatabase> {
    if (StudyOralDatabase.instance === null) {
      const store = await relationalStore.getRdbStore(context, StudyOralDBConfig.STORE_CONFIG)
      await store.executeSql(StudyOralDBConfig.MATERIAL_TABLE.sqlCreate)
      try {
        await store.executeSql('ALTER TABLE study_materials ADD COLUMN question_count INTEGER DEFAULT 0')
      } catch (_) {
      }
      try {
        await store.executeSql('ALTER TABLE study_materials ADD COLUMN parser_version INTEGER DEFAULT 0')
      } catch (_) {
      }
      await store.executeSql(StudyOralDBConfig.MATERIAL_QUESTION_TABLE.sqlCreate)
      try {
        await store.executeSql('ALTER TABLE material_questions ADD COLUMN position INTEGER DEFAULT 0')
      } catch (_) {
      }
      try {
        await store.executeSql('ALTER TABLE material_questions ADD COLUMN practice_count INTEGER DEFAULT 0')
      } catch (_) {
      }
      try {
        await store.executeSql('ALTER TABLE material_questions ADD COLUMN last_practiced_at TEXT')
      } catch (_) {
      }
      await store.executeSql(StudyOralDBConfig.MATERIAL_UPDATED_INDEX_SQL)
      await store.executeSql(StudyOralDBConfig.MATERIAL_QUESTION_INDEX_SQL)
      await store.executeSql(StudyOralDBConfig.MATERIAL_QUESTION_PRACTICE_INDEX_SQL)
      StudyOralDatabase.instance = new StudyOralDatabase(store)
      console.info('[StudyOralDB] initialized ' + StudyOralDBConfig.STORE_CONFIG.name)
    }
    return StudyOralDatabase.instance
  }

  getStore(): relationalStore.RdbStore {
    return this.store
  }
}
