/**
 * Firebase auth errors, translated for the person reading them.
 *
 * The raw SDK message ("Firebase: Error (auth/invalid-credential).") is a
 * developer string. An LGU health worker who mistypes a password should be told
 * what to do next, not handed an error code.
 */

const MESSAGES: Record<string, string> = {
  'auth/invalid-credential':
    'That username and password do not match an account. Check both and try again.',
  'auth/wrong-password':
    'That password is incorrect. Try again, or ask an administrator for help.',
  'auth/user-not-found':
    'No account uses that username. Check it, or register a new account.',
  'auth/invalid-email': 'That username is not valid.',
  'auth/email-already-in-use': 'That username is already taken. Choose another one.',
  'auth/weak-password': 'Use a password with at least 6 characters.',
  'auth/user-disabled':
    'This account has been disabled. Contact an administrator to restore access.',
  'auth/too-many-requests':
    'Too many sign-in attempts. Wait a few minutes before trying again.',
  'auth/network-request-failed':
    'Could not reach the server. Check your internet connection and try again.',
  'auth/operation-not-allowed':
    'Username sign-in is not enabled for the project. Enable Email/Password in Firebase Auth.',
  'auth/api-key-not-valid.-please-pass-a-valid-api-key.':
    'The dashboard has an invalid Firebase API key. Check VITE_FIREBASE_API_KEY in dashboard/.env.',
  'auth/invalid-api-key':
    'The dashboard has an invalid Firebase API key. Check VITE_FIREBASE_API_KEY in dashboard/.env.',
}

function codeOf(error: unknown): string | null {
  if (typeof error === 'object' && error !== null && 'code' in error) {
    const code = (error as { code: unknown }).code
    if (typeof code === 'string') return code
  }
  // Fall back to scraping the message: some wrapped rejections lose `code`.
  const message = error instanceof Error ? error.message : String(error ?? '')
  return /\(([^)]+)\)/.exec(message)?.[1] ?? null
}

/** Display copy for a failed sign-in or registration. */
export function authErrorMessage(error: unknown): string {
  if (error instanceof Error && error.name === 'AccessError') return error.message
  const code = codeOf(error)
  if (code && MESSAGES[code]) return MESSAGES[code]
  return 'Sign-in failed. Try again, or contact an administrator if it keeps happening.'
}

const WRITE_MESSAGES: Record<string, string> = {
  'permission-denied':
    'Your account is not allowed to make this change. Only verified admins can review reports and verify accounts.',
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

const READ_MESSAGES: Record<string, string> = {
  'permission-denied':
    'Your account is not a verified admin, so it cannot read this data. Ask an existing admin to verify you in the Users tab.',
  unavailable:
    'Could not reach Firestore. Check your internet connection and try again.',
  unauthenticated: 'Your session expired. Sign in again to load live reports.',
}

/** Firestore listener failures, phrased for the monitoring dashboard. */
export function readErrorMessage(error: unknown): string {
  const code = codeOf(error)
  if (code && READ_MESSAGES[code]) return READ_MESSAGES[code]
  const message = error instanceof Error ? error.message : String(error ?? '')
  if (/missing or insufficient permissions/i.test(message)) {
    return READ_MESSAGES['permission-denied']
  }
  return 'Could not load live reports. Try signing out and back in, or contact an administrator.'
}
