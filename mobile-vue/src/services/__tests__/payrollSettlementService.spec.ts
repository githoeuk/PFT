import { describe, expect, it } from 'vitest'

import {
  hasPayrollAmountMismatch,
  validatePayrollSettlement,
} from '@/services/payrollSettlementService'

describe('payrollSettlementService', () => {
  it('requires a paid date when a settlement is paid', () => {
    expect(validatePayrollSettlement('paid', '')).toBe('지급 완료 상태는 지급일을 입력해야 합니다')
  })

  it('allows unpaid settlements without a paid date', () => {
    expect(validatePayrollSettlement('unpaid', '')).toBe('')
  })

  it('detects a changed amount after payment', () => {
    expect(hasPayrollAmountMismatch('paid', 180_000, 200_000)).toBe(true)
  })

  it('does not report an amount mismatch before payment', () => {
    expect(hasPayrollAmountMismatch('unpaid', 180_000, 200_000)).toBe(false)
  })
})
