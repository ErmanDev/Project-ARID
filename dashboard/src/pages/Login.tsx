import { useState } from 'react'
import { Navigate } from 'react-router-dom'
import { useAuth } from '../auth'
import { authErrorMessage } from '../errors'
import { IconGoogle } from '../components/icons'
import { Alert, Button } from '../components/ui'
import { ThemeToggle } from '../components/ThemeToggle'

export function LoginPage() {
  const auth = useAuth()
  const [busy, setBusy] = useState(false)
  const [message, setMessage] = useState<string | null>(null)

  if (auth.user && auth.isStaff) return <Navigate to="/" replace />
  if (auth.user && !auth.isStaff) return <Navigate to="/denied" replace />

  async function signInWithGoogle() {
    setBusy(true)
    setMessage(null)
    try {
      await auth.signInGoogle()
    } catch (err) {
      // null means "the user cancelled" — nothing worth showing them.
      setMessage(authErrorMessage(err))
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="auth-workspace flex min-h-full items-center justify-center bg-bg px-4 py-10">
      <main className="w-full max-w-[26rem]">
        <div className="mb-3 flex justify-end">
          <ThemeToggle />
        </div>
        <div className="rounded-panel border border-border bg-surface p-7 shadow-md">
          <img src="/arid-logo.png" alt="" className="size-12" />
          <p className="eyebrow mt-6">A.R.I.D. staff workspace</p>
          <h1 className="mt-2 text-2xl font-semibold tracking-tight text-ink">
            Welcome back.
          </h1>
          <p className="mt-1.5 text-base text-muted">
            A clearer view of your community starts here. Sign in to monitor reports and inspect potential breeding sites.
          </p>

          {!auth.configured ? (
            <Alert tone="warning" className="mt-6">
              This workspace is not connected yet. Ask your administrator to complete sign-in setup.
            </Alert>
          ) : (
            <div className="mt-6 space-y-4">
              {message ? (
                <Alert tone="error" live>
                  {message}
                </Alert>
              ) : null}

              <Button
                variant="primary"
                block
                icon={<IconGoogle size={16} />}
                loading={busy}
                disabled={busy}
                onClick={() => void signInWithGoogle()}
              >
                Continue with Google
              </Button>
            </div>
          )}
        </div>

        <p className="mt-4 px-1 auth-note text-center text-xs">
          For authorized LGU and health-worker accounts. Need access? Contact your administrator.
        </p>
      </main>
    </div>
  )
}
