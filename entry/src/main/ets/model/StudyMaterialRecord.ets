export class StudyMaterialRecord {
  id: string = ''
  fileName: string = ''
  originalUri: string = ''
  sandboxPath: string = ''
  extension: string = ''
  extractedText: string = ''
  textPreview: string = ''
  extractionStatus: string = 'pending'
  extractionError: string = ''
  createdAt: string = ''
  updatedAt: string = ''
  questionCount: number = 0
  parserVersion: number = 0
}

export class MaterialQuestionAnswerRecord {
  id: string = ''
  materialId: string = ''
  question: string = ''
  answer: string = ''
  sourceText: string = ''
  position: number = 0
  practiceCount: number = 0
  lastPracticedAt: string = ''
  createdAt: string = ''
}
