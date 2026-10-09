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

/** Returns a problem with the username, or null when it is usable. */
export function usernameProblem(value: string): string | null {
  const username = normalizeUsername(value)
  if (username.length < 3) return 'Use at least 3 characters.'
  if (username.length > 30) return 'Use 30 characters or fewer.'
  if (!/^[a-z0-9][a-z0-9._-]*$/.test(username)) {
    return 'Use letters, numbers, dots, dashes, or underscores, starting with a letter or number.'
  }
  return null
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
    return 'This account has no A.R.I.D. profile. Register again or contact an administrator.'
  }
  if (profile.role !== 'admin') {
    return 'This is a field reporter account. Field reporters sign in on the A.R.I.D. mobile app.'
  }
  if (!profile.verified) {
    return 'Your admin account is waiting for verification. An existing admin has to verify it in the Users tab before you can sign in.'
  }
  return null
}
