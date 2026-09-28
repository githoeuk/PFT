import { describe, expect, it } from 'vitest'

import { isValidPin } from '@/services/pinSecurity'

describe('pinSecurity', () => {
  it('accepts only a four digit PIN', () => {
    expect(isValidPin('1234')).toBe(true)
    expect(isValidPin('123')).toBe(false)
    expect(isValidPin('12a4')).toBe(false)
    expect(isValidPin('12345')).toBe(false)
  })
})
