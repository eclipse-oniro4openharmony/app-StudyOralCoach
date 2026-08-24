// Use 127.0.0.1 only for a local emulator on the same computer.
// For a physical phone, use the computer's Wi-Fi/LAN IPv4 address.
export const STUDY_ORAL_PDF_BACKEND_BASE_URL: string = 'http://192.168.123.131:18081'

export function buildPdfExtractUrl(): string {
  return STUDY_ORAL_PDF_BACKEND_BASE_URL + '/api/pdf/extract'
}

export function buildAnswerEvaluateUrl(): string {
  return STUDY_ORAL_PDF_BACKEND_BASE_URL + '/api/answer/evaluate'
}

export function buildAsrListenUrl(): string {
  return STUDY_ORAL_PDF_BACKEND_BASE_URL.replace('http://', 'ws://').replace('https://', 'wss://') + '/listen'
}
