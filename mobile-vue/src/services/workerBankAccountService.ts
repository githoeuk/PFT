import type { Worker } from '@/types/erp'

export type WorkerBankAccount = Pick<Worker, 'bankName' | 'accountNumber' | 'accountHolder'>

export const hasWorkerBankAccount = (account: WorkerBankAccount): boolean =>
  Boolean(account.bankName || account.accountNumber || account.accountHolder)

export const validateWorkerBankAccount = (account: WorkerBankAccount): string => {
  if (!hasWorkerBankAccount(account)) return ''

  if (!account.bankName || !account.accountNumber || !account.accountHolder) {
    return '계좌정보를 입력하려면 은행명, 계좌번호, 예금주를 모두 입력해야 합니다'
  }

  if (!/^[0-9-]+$/.test(account.accountNumber)) {
    return '계좌번호는 숫자와 하이픈만 입력할 수 있습니다'
  }

  return ''
}

export const maskAccountNumber = (accountNumber: string): string => {
  const digitCount = (accountNumber.match(/\d/g) ?? []).length
  const visibleDigits = digitCount > 4 ? 4 : 0
  let digitsToMask = digitCount - visibleDigits

  return accountNumber.replace(/\d/g, (digit) => {
    if (digitsToMask <= 0) return digit
    digitsToMask -= 1
    return '•'
  })
}

export const formatWorkerBankAccount = (account: WorkerBankAccount): string => {
  if (!hasWorkerBankAccount(account)) return '계좌 미등록'

  const bankName = account.bankName || '은행 미지정'
  const accountNumber = account.accountNumber
    ? maskAccountNumber(account.accountNumber)
    : '계좌번호 미등록'
  return `${bankName} ${accountNumber}`
}
