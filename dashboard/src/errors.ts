/**
 * Firebase auth errors, translated for the person reading them.
 *
 * The raw SDK message ("Firebase: Error (auth/invalid-credential).") is a
 * developer string. An LGU health worker who mistypes a password should be told
 * what to do next, not handed an error code.
 */

const MESSAGES: Record<string, string> = {
  'auth/invalid-credential':
    'That email and password do not match an account. Check both and try again.',
  'auth/wrong-password':
    'That password is incorrect. Try again, or ask an administrator to reset it.',
  'auth/user-not-found':
    'No staff account uses that email. Check the address, or ask an administrator to create one.',
  'auth/invalid-email': 'That does not look like a valid email address.',
  'auth/user-disabled':
    'This account has been disabled. Contact an administrator to restore access.',
  'auth/too-many-requests':
    'Too many sign-in attempts. Wait a few minutes before trying again.',
  'auth/network-request-failed':
    'Could not reach the server. Check your internet connection and try again.',
  'auth/popup-blocked':
    'Your browser blocked the Google sign-in window. Allow pop-ups for this site, then retry.',
  'auth/account-exists-with-different-credential':
    'This email is already registered with a different sign-in method. Try email and password.',
  'auth/operation-not-allowed':
    'This sign-in method is not enabled for the project. Ask an administrator to enable it in Firebase Auth.',
  'auth/api-key-not-valid.-please-pass-a-valid-api-key.':
    'The dashboard has an invalid Firebase API key. Check VITE_FIREBASE_API_KEY in dashboard/.env.',
  'auth/invalid-api-key':
    'The dashboard has an invalid Firebase API key. Check VITE_FIREBASE_API_KEY in dashboard/.env.',
}

/** Cancelling a popup is a choice, not a failure. These produce no message. */
const SILENT = new Set([
  'auth/popup-closed-by-user',
  'auth/cancelled-popup-request',
  'auth/user-cancelled',
])

function codeOf(error: unknown): string | null {
  if (typeof error === 'object' && error !== null && 'code' in error) {
    const code = (error as { code: unknown }).code
    if (typeof code === 'string') return code
  }
  // Fall back to scraping the message: some wrapped rejections lose `code`.
  const message = error instanceof Error ? error.message : String(error ?? '')
  return /\(([^)]+)\)/.exec(message)?.[1] ?? null
}

/**
 * Returns display copy, or `null` when the error should be shown as nothing at
 * all (a deliberately dismissed popup).
 */
export function authErrorMessage(error: unknown): string | null {
  const code = codeOf(error)
  if (code && SILENT.has(code)) return null
  if (code && MESSAGES[code]) return MESSAGES[code]
  return 'Sign-in failed. Try again, or contact an administrator if it keeps happening.'
}

const WRITE_MESSAGES: Record<string, string> = {
  'permission-denied':
    'Your account is not allowed to change review status. Ask an administrator to check the Firestore rules.',
  unavailable:
    'Could not reach Firestore. The change was not saved — check your connection and try again.',
  'not-found': 'This report no longer exists in Firestore.',
  unauthenticated: 'Your session expired. Sign in again to save this change.',
}

/** Firestore write failures, phrased so the operator knows if it saved. */
export function writeErrorMessage(error: unknown): string {
  const code = codeOf(error)
  if (code && WRITE_MESSAGES[code]) return WRITE_MESSAGES[code]
  return 'Could not save the review status. The change was not applied — try again.'
}
