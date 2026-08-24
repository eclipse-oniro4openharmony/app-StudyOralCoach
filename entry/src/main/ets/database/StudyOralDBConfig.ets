import { relationalStore } from '@kit.ArkData'

export class DbTableConfig {
  tableName: string = ''
  sqlCreate: string = ''
  columns: string[] = []
}

export class StudyOralDBConfig {
  static readonly STORE_CONFIG: relationalStore.StoreConfig = {
    name: 'study_oral_coach.db',
    securityLevel: relationalStore.SecurityLevel.S1
  }

  static readonly MATERIAL_TABLE: DbTableConfig = {
    tableName: 'study_materials',
    sqlCreate: 'CREATE TABLE IF NOT EXISTS study_materials(' +
      'id TEXT PRIMARY KEY,' +
      'file_name TEXT NOT NULL,' +
      'original_uri TEXT,' +
      'sandbox_path TEXT NOT NULL,' +
      'extension TEXT,' +
      'extracted_text TEXT,' +
      'text_preview TEXT,' +
      'extraction_status TEXT NOT NULL,' +
      'extraction_error TEXT,' +
      'created_at TEXT NOT NULL,' +
      'updated_at TEXT NOT NULL,' +
      'question_count INTEGER DEFAULT 0,' +
      'parser_version INTEGER DEFAULT 0)',
    columns: [
      'id', 'file_name', 'original_uri', 'sandbox_path', 'extension', 'extracted_text',
      'text_preview', 'extraction_status', 'extraction_error', 'created_at', 'updated_at', 'question_count',
      'parser_version'
    ]
  }

  static readonly MATERIAL_QUESTION_TABLE: DbTableConfig = {
    tableName: 'material_questions',
    sqlCreate: 'CREATE TABLE IF NOT EXISTS material_questions(' +
      'id TEXT PRIMARY KEY,' +
      'material_id TEXT NOT NULL,' +
      'question TEXT NOT NULL,' +
      'answer TEXT NOT NULL,' +
      'source_text TEXT,' +
      'position INTEGER DEFAULT 0,' +
      'practice_count INTEGER DEFAULT 0,' +
      'last_practiced_at TEXT,' +
      'created_at TEXT NOT NULL)',
    columns: [
      'id', 'material_id', 'question', 'answer', 'source_text',
      'position', 'practice_count', 'last_practiced_at', 'created_at'
    ]
  }

  static readonly MATERIAL_UPDATED_INDEX_SQL: string =
    'CREATE INDEX IF NOT EXISTS idx_study_materials_updated_at ON study_materials(updated_at)'

  static readonly MATERIAL_QUESTION_INDEX_SQL: string =
    'CREATE INDEX IF NOT EXISTS idx_material_questions_material_id ON material_questions(material_id)'

  static readonly MATERIAL_QUESTION_PRACTICE_INDEX_SQL: string =
    'CREATE INDEX IF NOT EXISTS idx_material_questions_practice ON material_questions(practice_count, last_practiced_at)'
}
