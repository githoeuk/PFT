import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const native = vi.hoisted(() => ({
  platform: 'android',
  save: vi.fn<(options: { fileName: string; contents: string }) => Promise<{ cancelled: boolean }>>(),
  writeFile: vi.fn<(options: unknown) => Promise<{ uri: string }>>(),
  share: vi.fn<(options: unknown) => Promise<{ activityType: string }>>(),
}))

vi.mock('@capacitor/core', () => ({
  Capacitor: {
    getPlatform: () => native.platform,
    isNativePlatform: () => native.platform !== 'web',
  },
  registerPlugin: () => ({ save: native.save }),
}))
vi.mock('@capacitor/filesystem', () => ({
  Directory: { Cache: 'CACHE' },
  Encoding: { UTF8: 'utf8' },
  Filesystem: { writeFile: native.writeFile },
}))
vi.mock('@capacitor/share', () => ({ Share: { share: native.share } }))

import { canShareBackupFile, saveBackupFile, shareBackupFile } from '@/services/backupFileService'

const contents = '{"name":"태광페인트","amount":85000}'

describe('backup file export', () => {
  beforeEach(() => {
    vi.resetAllMocks()
    native.platform = 'android'
    native.save.mockResolvedValue({ cancelled: false })
    native.writeFile.mockResolvedValue({ uri: 'file:///cache/backups/backup.json' })
    native.share.mockResolvedValue({ activityType: 'test.receiver' })
  })

  afterEach(() => {
    vi.restoreAllMocks()
    vi.unstubAllGlobals()
    vi.useRealTimers()
  })

  it('passes the full JSON to the document picker without opening a share sheet', async () => {
    await expect(saveBackupFile('backup.json', contents)).resolves.toBe('saved')
    expect(native.save).toHaveBeenCalledWith({ fileName: 'backup.json', contents })
    expect(native.writeFile).not.toHaveBeenCalled()
    expect(native.share).not.toHaveBeenCalled()
  })

  it('does not report a cancelled document picker as saved', async () => {
    native.save.mockResolvedValue({ cancelled: true })
    await expect(saveBackupFile('backup.json', contents)).resolves.toBe('cancelled')
  })

  it('propagates document write failures without falling back to sharing', async () => {
    native.save.mockRejectedValue(new Error('WRITE_FAILED'))
    await expect(saveBackupFile('backup.json', contents)).rejects.toThrow('WRITE_FAILED')
    expect(native.share).not.toHaveBeenCalled()
  })

  it('shares the UTF-8 JSON as a file attachment', async () => {
    await expect(shareBackupFile('backup.json', contents)).resolves.toBe('opened')
    expect(native.writeFile).toHaveBeenCalledWith(
      expect.objectContaining({
        data: contents,
        encoding: 'utf8',
      }),
    )
    expect(native.share).toHaveBeenCalledWith(
      expect.objectContaining({
        files: ['file:///cache/backups/backup.json'],
      }),
    )
    expect(native.save).not.toHaveBeenCalled()
  })

  it('handles an Android share cancellation as a normal result', async () => {
    native.share.mockRejectedValue(new Error('Share canceled'))
    await expect(shareBackupFile('backup.json', contents)).resolves.toBe('cancelled')
  })

  it('does not confirm sharing when Android returns no selected app', async () => {
    native.share.mockResolvedValue({ activityType: '' })
    await expect(shareBackupFile('backup.json', contents)).resolves.toBe('dismissed')
  })

  it('propagates real share failures', async () => {
    native.share.mockRejectedValue(new Error('Permission denied'))
    await expect(shareBackupFile('backup.json', contents)).rejects.toThrow('Permission denied')
  })

  it('downloads in a browser and keeps the object URL alive until the click is handled', async () => {
    native.platform = 'web'
    vi.useFakeTimers()
    const createObjectURL = vi.fn<(file: Blob) => string>(() => 'blob:test-backup')
    const revokeObjectURL = vi.fn<(url: string) => void>()
    vi.stubGlobal('URL', { createObjectURL, revokeObjectURL })
    const click = vi.spyOn(HTMLAnchorElement.prototype, 'click').mockImplementation(function (
      this: HTMLAnchorElement,
    ) {
      expect(this.download).toBe('backup.json')
      expect(this.isConnected).toBe(true)
      expect(revokeObjectURL).not.toHaveBeenCalled()
    })

    await expect(saveBackupFile('backup.json', contents)).resolves.toBe('downloaded')
    expect(click).toHaveBeenCalledOnce()
    expect(createObjectURL).toHaveBeenCalledWith(expect.any(Blob))
    expect(document.querySelector('a[download]')).toBeNull()
    await vi.runAllTimersAsync()
    expect(revokeObjectURL).toHaveBeenCalledWith('blob:test-backup')
    expect(native.save).not.toHaveBeenCalled()
  })

  it('sends a JSON File through browser sharing instead of a blob URL', async () => {
    native.platform = 'web'
    const share = vi.fn<(data: { files: File[] }) => Promise<void>>().mockResolvedValue(undefined)
    vi.stubGlobal('navigator', { canShare: () => true, share })

    await expect(shareBackupFile('backup.json', contents)).resolves.toBe('opened')
    const file = share.mock.calls[0]![0].files[0] as File
    expect(file.name).toBe('backup.json')
    expect(file.type).toBe('application/json')
    const text = await new Promise((resolve, reject) => {
      const reader = new FileReader()
      reader.onload = () => resolve(reader.result)
      reader.onerror = reject
      reader.readAsText(file)
    })
    expect(text).toBe(contents)
  })

  it('does not silently download when file sharing is unavailable', async () => {
    native.platform = 'web'
    vi.stubGlobal('navigator', {})
    expect(canShareBackupFile()).toBe(false)
    await expect(shareBackupFile('backup.json', contents)).rejects.toThrow('파일 공유를 지원하지')
  })

  it('handles browser share cancellation', async () => {
    native.platform = 'web'
    vi.stubGlobal('navigator', {
      canShare: () => true,
      share: vi.fn<(data: ShareData) => Promise<void>>().mockRejectedValue(new DOMException('Cancelled', 'AbortError')),
    })
    await expect(shareBackupFile('backup.json', contents)).resolves.toBe('cancelled')
  })
})
