import { useState } from 'react'
import { Navigate } from 'react-router-dom'
import { useAuth } from '../auth'
import { useMockData } from '../config'
import { IconLock, IconRefresh } from '../components/icons'
import { Alert, Button, CopyButton } from '../components/ui'
import { ThemeToggle } from '../components/ThemeToggle'

/**
 * Not an error page — a provisioning-status page.
 *
 * Someone landing here has a working account with no `staff/{uid}` document
 * yet. The page shows which account is signed in (wrong-Google-account is the
 * most common cause), hands over the UID an administrator needs, and re-checks
 * in place instead of forcing a sign-out / sign-in round trip.
 */
export function DeniedPage() {
  const auth = useAuth()
  const [checking, setChecking] = useState(false)
  const [checkedAt, setCheckedAt] = useState<Date | null>(null)
  const [signingOut, setSigningOut] = useState(false)

  // Provisioning may have completed in another tab or since the last render, so
  // an authorized user gets moved on rather than left staring at this page.
  //
  // Skipped under mock data: that mode exists to look at the UI, and the mock
  // session is staff by default, which made this page impossible to open.
  if (!useMockData && auth.user && auth.isStaff) return <Navigate to="/" replace />
  if (!useMockData && !auth.user && !auth.loading) {
    return <Navigate to="/login" replace />
  }

  const uid = auth.user?.uid ?? ''
  const email = auth.user?.email ?? null
  const displayName = auth.user?.displayName ?? null
  const primary = displayName ?? email ?? 'Signed in'

  async function checkAgain() {
    setChecking(true)
    try {
      await auth.recheckStaff()
    } finally {
      setChecking(false)
      setCheckedAt(new Date())
    }
  }

  async function signOut() {
    setSigningOut(true)
    try {
      await auth.signOut()
    } finally {
      setSigningOut(false)
    }
  }

  return (
    <div className="flex min-h-full items-center justify-center bg-bg px-4 py-10">
      <main className="w-full max-w-[27rem]">
        <div className="mb-3 flex justify-end">
          <ThemeToggle />
        </div>
        <div className="overflow-hidden rounded-panel border border-border bg-surface shadow-md">
          {/* Centred header: with the step list gone the card is short enough
              that a left-aligned icon column left the block looking unbalanced. */}
          <div className="px-7 pt-8 text-center">
            {/* Concentric rings instead of a flat tinted disc: gives the mark
                some depth without reaching for glass or a gradient. Primary
                rather than warning-yellow — nothing here has gone wrong. */}
            <span className="relative mx-auto grid size-16 place-items-center">
              <span
                className="absolute inset-0 rounded-full bg-primary/8"
                aria-hidden="true"
              />
              <span
                className="absolute inset-[7px] rounded-full bg-primary/14 ring-1 ring-inset ring-primary/15"
                aria-hidden="true"
              />
              <IconLock size={25} className="relative text-primary-ink" />
            </span>
            <h1 className="mt-4 text-xl font-semibold tracking-tight text-ink">
              Access not enabled yet
            </h1>
            <p className="mx-auto mt-2 max-w-[34ch] text-base text-muted">
              Your sign-in worked. This account is not on the staff list for the
              monitoring dashboard yet — an administrator has to add it.
            </p>
          </div>

          <div className="px-7 py-6">
            {/* Account + UID as one bordered detail block: two facts an
                administrator will ask for, grouped, no nested cards. */}
            <div className="divide-y divide-border overflow-hidden rounded-card border border-border bg-panel">
              <div className="flex items-center gap-3 px-3.5 py-3">
                <span className="grid size-9 shrink-0 place-items-center rounded-full bg-primary-100 text-sm font-semibold text-primary-ink">
                  {primary.charAt(0).toUpperCase()}
                </span>
                <div className="min-w-0 flex-1">
                  <p className="truncate text-base font-medium text-ink">{primary}</p>
                  {displayName && email ? (
                    <p className="truncate text-xs text-muted">{email}</p>
                  ) : null}
                </div>
                <Button
                  size="sm"
                  variant="ghost"
                  loading={signingOut}
                  onClick={() => void signOut()}
                >
                  Switch
                </Button>
              </div>

              <div className="flex items-center gap-3 px-3.5 py-3">
                <div className="min-w-0 flex-1">
                  <p className="text-xs text-muted">Your account UID</p>
                  <code
                    data-numeric
                    className="mt-0.5 block truncate text-sm text-ink-2"
                    title={uid}
                  >
                    {uid}
                  </code>
                </div>
                <CopyButton value={uid} label="Copy" />
              </div>
            </div>

            {auth.error ? (
              <Alert tone="error" live className="mt-4">
                {auth.error}
              </Alert>
            ) : checkedAt ? (
              <Alert tone="warning" live className="mt-4">
                Still not on the staff list, as of{' '}
                {checkedAt.toLocaleTimeString(undefined, {
                  hour: 'numeric',
                  minute: '2-digit',
                })}
                .
              </Alert>
            ) : null}

            <div className="mt-5 flex flex-col gap-2">
              <Button
                variant="primary"
                block
                loading={checking}
                icon={<IconRefresh size={16} />}
                onClick={() => void checkAgain()}
              >
                Check again
              </Button>
              <Button
                variant="secondary"
                block
                disabled={checking}
                loading={signingOut}
                onClick={() => void signOut()}
              >
                Sign out
              </Button>
            </div>
          </div>
        </div>

        <p className="mx-auto mt-4 max-w-[40ch] text-center text-xs text-muted">
          Once your administrator adds the record, use Check again — no need to
          sign out.
        </p>
      </main>
    </div>
  )
}
