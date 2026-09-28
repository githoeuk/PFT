import type { ErpData } from '@/types/erp'

export interface ErpRepository {
  readonly kind: 'browser' | 'sqlite'
  load(): Promise<ErpData>
  save(data: ErpData): Promise<void>
}
