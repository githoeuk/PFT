import { Capacitor } from '@capacitor/core'
import {
  LocalNotifications,
  type LocalNotificationSchema,
} from '@capacitor/local-notifications'

import type { Site } from '@/types/erp'

const REMINDER_DAYS_BEFORE = 3
const SAVED_IDS_KEY = 'pft.site-end-notification-ids'

function readSavedNotificationIds(): number[] {
  try {
    const value = localStorage.getItem(SAVED_IDS_KEY)

    if (!value) {
      return []
    }

    const parsed: unknown = JSON.parse(value)

    if (!Array.isArray(parsed)) {
      return []
    }

    return parsed.filter(
      (item): item is number => typeof item === 'number' && Number.isInteger(item),
    )
  } catch {
    return []
  }
}

function saveNotificationIds(ids: number[]) {
  localStorage.setItem(SAVED_IDS_KEY, JSON.stringify(ids))
}

function createNotificationId(siteId: string): number {
  let hash = 0

  for (let index = 0; index < siteId.length; index += 1) {
    hash = (hash * 31 + siteId.charCodeAt(index)) | 0
  }

  return 1_000_000_000 + Math.abs(hash % 1_000_000_000)
}

function createReminderDate(endDate: string): Date | null {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(endDate)

  if (!match) {
    return null
  }

  const year = Number(match[1])
  const month = Number(match[2])
  const day = Number(match[3])

  const reminderDate = new Date(year, month - 1, day, 9, 0, 0)

  if (
    reminderDate.getFullYear() !== year ||
    reminderDate.getMonth() !== month - 1 ||
    reminderDate.getDate() !== day
  ) {
    return null
  }

  reminderDate.setDate(reminderDate.getDate() - REMINDER_DAYS_BEFORE)

  return reminderDate
}

async function checkNotificationPermission(
  requestPermission: boolean,
): Promise<boolean> {
  const currentPermission = await LocalNotifications.checkPermissions()

  if (currentPermission.display === 'granted') {
    return true
  }

  if (!requestPermission) {
    return false
  }

  const requestedPermission =
    await LocalNotifications.requestPermissions()

  return requestedPermission.display === 'granted'
}

export async function syncSiteEndNotifications(
  sites: Site[],
  requestPermission = false,
): Promise<boolean> {
  if (!Capacitor.isNativePlatform()) {
    return false
  }

  const granted = await checkNotificationPermission(requestPermission)

  if (!granted) {
    return false
  }

  const savedIds = readSavedNotificationIds()

  if (savedIds.length > 0) {
    await LocalNotifications.cancel({
      notifications: savedIds.map((id) => ({ id })),
    })
  }

  const now = new Date()

  const notifications: LocalNotificationSchema[] = sites
    .filter(
      (site) =>
        site.status === 'active' &&
        site.endDate.trim().length > 0,
    )
    .flatMap((site) => {
      const reminderDate = createReminderDate(site.endDate)

      if (!reminderDate || reminderDate <= now) {
        return []
      }

      return [
        {
          id:
            createNotificationId(site.id),
          title:
            '현장 종료 예정',
          body:
            `${site.name} 종료일까지 3일 남았습니다. 정산 내역과 JSON 백업을 확인하세요.`,
          schedule:
            {
              at: reminderDate,
              allowWhileIdle: true,
            },
          autoCancel: true,
          isExactNotification: false,
          extra: {
            siteId: site.id,
          }
        },
      ]
    })

  if (notifications.length > 0) {
    await LocalNotifications.schedule({
      notifications,
    })
  }

  saveNotificationIds(
    notifications.map((notification) => notification.id),
  )

  return true
}
