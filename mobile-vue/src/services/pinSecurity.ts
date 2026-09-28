const PIN_STORAGE_KEY = 'pft.security.pin.v1'
const PBKDF2_ITERATIONS = 150_000

interface StoredPin {
  salt: string
  hash: string
  iterations: number
}

const bytesToBase64 = (bytes: Uint8Array): string =>
  btoa(String.fromCharCode(...bytes))

const base64ToBytes = (value: string): Uint8Array =>
  Uint8Array.from(atob(value), (character) => character.charCodeAt(0))

const derivePinHash = async (
  pin: string,
  salt: Uint8Array,
  iterations: number,
): Promise<Uint8Array> => {
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(pin),
    'PBKDF2',
    false,
    ['deriveBits'],
  )
  const bits = await crypto.subtle.deriveBits(
    { name: 'PBKDF2', hash: 'SHA-256', salt: salt as BufferSource, iterations },
    key,
    256,
  )
  return new Uint8Array(bits)
}

const hashesMatch = (left: Uint8Array, right: Uint8Array): boolean => {
  if (left.length !== right.length) return false

  let difference = 0
  for (let index = 0; index < left.length; index += 1) {
    difference |= left[index]! ^ right[index]!
  }
  return difference === 0
}

const readStoredPin = (): StoredPin | undefined => {
  const serialized = window.localStorage.getItem(PIN_STORAGE_KEY)
  if (!serialized) return undefined

  try {
    const candidate = JSON.parse(serialized) as Partial<StoredPin>
    if (
      typeof candidate.salt !== 'string' ||
      typeof candidate.hash !== 'string' ||
      typeof candidate.iterations !== 'number'
    ) {
      return undefined
    }
    return candidate as StoredPin
  } catch {
    return undefined
  }
}

export const isValidPin = (pin: string): boolean => /^\d{4}$/.test(pin)

export const isPinConfigured = (): boolean => readStoredPin() !== undefined

export const savePin = async (pin: string): Promise<void> => {
  if (!isValidPin(pin)) throw new Error('PIN은 숫자 4자리여야 합니다')

  const salt = crypto.getRandomValues(new Uint8Array(16))
  const hash = await derivePinHash(pin, salt, PBKDF2_ITERATIONS)
  const storedPin: StoredPin = {
    salt: bytesToBase64(salt),
    hash: bytesToBase64(hash),
    iterations: PBKDF2_ITERATIONS,
  }
  window.localStorage.setItem(PIN_STORAGE_KEY, JSON.stringify(storedPin))
}

export const verifyPin = async (pin: string): Promise<boolean> => {
  if (!isValidPin(pin)) return false

  const storedPin = readStoredPin()
  if (!storedPin) return false

  const actualHash = await derivePinHash(
    pin,
    base64ToBytes(storedPin.salt),
    storedPin.iterations,
  )
  return hashesMatch(actualHash, base64ToBytes(storedPin.hash))
}
