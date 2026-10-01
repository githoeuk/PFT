import { describe, expect, it } from 'vitest'

import {
  formatWorkerBankAccount,
  hasWorkerBankAccount,
  maskAccountNumber,
  validateWorkerBankAccount,
} from '@/services/workerBankAccountService'

describe('workerBankAccountService', () => {
  it('masks every digit except the final four digits', () => {
    expect(maskAccountNumber('123-456-789012')).toBe('•••-•••-••9012')
  })

  it('does not expose short account numbers', () => {
    expect(maskAccountNumber('1234')).toBe('••••')
  })

  it('requires all bank account fields when one is provided', () => {
    expect(
      validateWorkerBankAccount({
        bankName: '국민은행',
        accountNumber: '',
        accountHolder: '',
      }),
    ).toContain('모두 입력')
  })

  it('rejects letters in an account number', () => {
    expect(
      validateWorkerBankAccount({
        bankName: '국민은행',
        accountNumber: '123-ABC',
        accountHolder: '홍길동',
      }),
    ).toContain('숫자와 하이픈')
  })

  it('formats a registered account without exposing the full number', () => {
    const account = {
      bankName: '국민은행',
      accountNumber: '123-456-789012',
      accountHolder: '홍길동',
    }

    expect(hasWorkerBankAccount(account)).toBe(true)
    expect(formatWorkerBankAccount(account)).toBe('국민은행 •••-•••-••9012')
  })
})
