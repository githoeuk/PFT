import { Capacitor, registerPlugin } from '@capacitor/core'
import { Directory, Encoding, Filesystem } from '@capacitor/filesystem'
import { Share } from '@capacitor/share'

interface BackupDocumentsPlugin {
  save(options: { fileName: string; contents: string }): Promise<{ cancelled: boolean }>
}

const BackupDocuments = registerPlugin<BackupDocumentsPlugin>('BackupDocuments')

export type BackupSaveResult = 'saved' | 'downloaded' | 'cancelled'
export type BackupShareResult = 'opened' | 'dismissed' | 'cancelled'

const downloadInBrowser = (fileName: string, contents: string): void => {
  const url = URL.createObjectURL(new Blob([contents], { type: 'application/json' }))
  const anchor = document.createElement('a')
  anchor.href = url
  anchor.download = fileName
  document.body.appendChild(anchor)
  try {
    anchor.click()
  } finally {
    anchor.remove()
    // Give the browser time to consume the download before releasing its URL.
    window.setTimeout(() => URL.revokeObjectURL(url), 1000)
  }
}

export async function saveBackupFile(
  fileName: string,
  contents: string,
): Promise<BackupSaveResult> {
  if (Capacitor.getPlatform() === 'android') {
    const result = await BackupDocuments.save({ fileName, contents })
    return result.cancelled ? 'cancelled' : 'saved'
  }

  if (Capacitor.isNativePlatform()) {
    throw new Error('이 기기에서는 공유하기로 백업 파일을 내보내 주세요.')
  }

  downloadInBrowser(fileName, contents)
  return 'downloaded'
}

const backupFile = (fileName: string, contents: string): File =>
  new File([contents], fileName, { type: 'application/json' })

export function canShareBackupFile(): boolean {
  if (Capacitor.isNativePlatform()) return true

  return (
    typeof navigator.share === 'function' &&
    typeof navigator.canShare === 'function' &&
    navigator.canShare({ files: [backupFile('backup.json', '{}')] })
  )
}

const isShareCancelled = (error: unknown): boolean => {
  if (!error || typeof error !== 'object') return false

  return (
    ('name' in error && error.name === 'AbortError') ||
    ('message' in error && error.message === 'Share canceled')
  )
}

export async function shareBackupFile(
  fileName: string,
  contents: string,
): Promise<BackupShareResult> {
  if (!Capacitor.isNativePlatform()) {
    const files = [backupFile(fileName, contents)]
    if (!canShareBackupFile() || !navigator.canShare({ files })) {
      throw new Error('이 브라우저는 파일 공유를 지원하지 않습니다. 파일로 저장해 주세요.')
    }

    try {
      await navigator.share({ title: '태광페인트 데이터 백업', files })
      return 'opened'
    } catch (error) {
      if (isShareCancelled(error)) return 'cancelled'
      throw error
    }
  }

  const result = await Filesystem.writeFile({
    path: `backups/${fileName}`,
    data: contents,
    directory: Directory.Cache,
    encoding: Encoding.UTF8,
    recursive: true,
  })

  try {
    const shared = await Share.share({
      title: '태광페인트 데이터 백업',
      files: [result.uri],
      dialogTitle: '백업 파일 공유',
    })
    // Android cannot confirm that the receiving app finished saving or sending.
    return shared.activityType ? 'opened' : 'dismissed'
  } catch (error) {
    if (isShareCancelled(error)) return 'cancelled'
    throw error
  }
}
