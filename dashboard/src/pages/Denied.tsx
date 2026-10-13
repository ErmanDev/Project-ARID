import { useState } from 'react'
import { Navigate } from 'react-router-dom'
import { dashboardAccessProblem } from '../accounts'
import { useAuth } from '../auth'
import { useMockData } from '../config'
import { IconLock } from '../components/icons'
import { Alert, Button } from '../components/ui'
import { ThemeToggle } from '../components/ThemeToggle'

/**
 * Shown when a signed-in account loses dashboard access mid-session: an admin
 * revoked it, or it is not an admin account. Sign-in itself refuses these
 * accounts, so this page only catches changes made while someone is signed in.
 */
export function DeniedPage() {
  const auth = useAuth()
  const [signingOut, setSigningOut] = useState(false)

  if (!useMockData && auth.user && auth.isStaff) return <Navigate to="/" replace />
  if (!useMockData && !auth.user && !auth.loading) {
    return <Navigate to="/login" replace />
  }

  const profile = auth.profile
  const reason = auth.loading ? null : dashboardAccessProblem(profile)

  async function signOut() {
    setSigningOut(true)
    try {
      await auth.signOut()
    } finally {
      setSigningOut(false)
    }
  }

  return (
    <div className="auth-workspace flex min-h-full items-center justify-center bg-bg px-4 py-10">
      <main className="w-full max-w-[27rem]">
        <div className="mb-3 flex justify-end">
          <ThemeToggle />
        </div>
        <div className="overflow-hidden rounded-panel border border-border bg-surface shadow-md">
          <div className="px-7 pt-8 text-center">
            <span className="relative mx-auto grid size-16 place-items-center">
              <span className="absolute inset-0 rounded-full bg-primary/8" aria-hidden="true" />
              <span
                className="absolute inset-[7px] rounded-full bg-primary/14 ring-1 ring-inset ring-primary/15"
                aria-hidden="true"
              />
              <IconLock size={25} className="relative text-primary-ink" />
            </span>
            <h1 className="mt-4 text-xl font-semibold tracking-tight text-ink">
              No dashboard access
            </h1>
            {profile ? (
              <p className="mx-auto mt-2 max-w-[34ch] text-base text-muted">
                Signed in as <strong className="font-medium text-ink">{profile.displayName}</strong>{' '}
                (@{profile.username}).
              </p>
            ) : null}
          </div>

          <div className="px-7 py-6">
            {reason ? <Alert tone="warning">{reason}</Alert> : null}
            {auth.error ? (
              <Alert tone="error" live className="mt-4">
                {auth.error}
              </Alert>
            ) : null}
            <Button
              variant="primary"
              block
              className="mt-5"
              loading={signingOut}
              onClick={() => void signOut()}
            >
              Sign out
            </Button>
          </div>
        </div>

        <p className="mx-auto mt-4 max-w-[40ch] auth-note text-center text-xs">
          This page updates by itself as soon as an admin verifies the account.
        </p>
      </main>
    </div>
  )
}
