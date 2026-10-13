import type { UserProfile } from './types'

/**
 * Accounts sign in with a username. Firebase Auth needs an email, so each
 * username maps to `<username>@arid.local`, the same as the mobile app. No mail
 * is ever sent to that address.
 */
export const USERNAME_DOMAIN = 'arid.local'

export function normalizeUsername(value: string): string {
  return value.trim().toLowerCase()
}

export function usernameToEmail(value: string): string {
  return `${normalizeUsername(value)}@${USERNAME_DOMAIN}`
}

/** Thrown when the password was right but the account may not use the dashboard. */
export class AccessError extends Error {
  constructor(message: string) {
    super(message)
    this.name = 'AccessError'
  }
}

/** Why a signed-in profile cannot use the dashboard, or null when it can. */
export function dashboardAccessProblem(profile: UserProfile | null): string | null {
  if (!profile) {
    return 'This account has no A.R.I.D. profile. Contact an administrator.'
  }
  if (profile.role !== 'admin') {
    return 'This is a staff account. Staff sign in on the A.R.I.D. mobile app.'
  }
  if (profile.status !== 'verified') {
    return 'This admin account is not active. Contact another administrator.'
  }
  return null
}

/** Whole years between a "YYYY-MM-DD" birthday and today, or null if invalid. */
export function ageFrom(birthDate: string, today = new Date()): number | null {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(birthDate)
  if (!match) return null
  const [year, month, day] = match.slice(1).map(Number)
  let age = today.getFullYear() - year
  const beforeBirthday =
    today.getMonth() + 1 < month || (today.getMonth() + 1 === month && today.getDate() < day)
  if (beforeBirthday) age -= 1
  return age
}
