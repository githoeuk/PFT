import type { PayrollSettlementStatus } from '@/types/erp'

export const validatePayrollSettlement = (
  status: PayrollSettlementStatus,
  paidDate: string,
): string => {
  if (status === 'paid' && !paidDate) {
    return '지급 완료 상태는 지급일을 입력해야 합니다'
  }

  return ''
}

export const hasPayrollAmountMismatch = (
  status: PayrollSettlementStatus,
  settledAmount: number,
  currentAmount: number,
): boolean => status === 'paid' && settledAmount !== currentAmount
