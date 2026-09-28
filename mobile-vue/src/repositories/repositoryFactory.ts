import { Capacitor } from '@capacitor/core'

import type { ErpRepository } from '@/repositories/erpRepository'
import { localStorageErpRepository } from '@/repositories/localStorageErpRepository'

export async function createErpRepository(): Promise<ErpRepository> {
  if (!Capacitor.isNativePlatform()) return localStorageErpRepository

  const { CapacitorSqliteErpRepository } = await import('@/repositories/sqliteErpRepository')
  return new CapacitorSqliteErpRepository()
}
