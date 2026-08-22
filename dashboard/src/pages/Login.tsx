import { useState, type FormEvent } from 'react'
import { Navigate } from 'react-router-dom'
import { useAuth } from '../auth'
import { authErrorMessage } from '../errors'
import { IconGoogle } from '../components/icons'
import { Alert, Button, Field, Input } from '../components/ui'
import { ThemeToggle } from '../components/ThemeToggle'

export function LoginPage() {
  const auth = useAuth()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [busy, setBusy] = useState<'email' | 'google' | null>(null)
  const [message, setMessage] = useState<string | null>(null)

  if (auth.user && auth.isStaff) return <Navigate to="/" replace />
  if (auth.user && !auth.isStaff) return <Navigate to="/denied" replace />

  async function run(kind: 'email' | 'google', action: () => Promise<void>) {
    setBusy(kind)
    setMessage(null)
    try {
      await action()
    } catch (err) {
      // null means "the user cancelled" — nothing worth showing them.
      setMessage(authErrorMessage(err))
    } finally {
      setBusy(null)
    }
  }

  function onSubmit(event: FormEvent) {
    event.preventDefault()
    void run('email', () => auth.signInEmail(email, password))
  }

  return (
    <div className="flex min-h-full items-center justify-center bg-bg px-4 py-10">
      <main className="w-full max-w-[26rem]">
        <div className="mb-3 flex justify-end">
          <ThemeToggle />
        </div>
        <div className="rounded-panel border border-border bg-surface p-7 shadow-md">
          <img src="/arid-logo.png" alt="" className="size-12" />
          <h1 className="mt-4 text-xl font-semibold tracking-tight text-ink">
            Staff sign-in
          </h1>
          <p className="mt-1.5 text-base text-muted">
            A.R.I.D. breeding-site monitoring for LGU and health-worker accounts.
            Field capture stays on the mobile app.
          </p>

          {!auth.configured ? (
            <Alert tone="warning" className="mt-6">
              Firebase is not configured. Copy{' '}
              <code>dashboard/.env.example</code> to <code>dashboard/.env</code>{' '}
              using the same project as the mobile app.
            </Alert>
          ) : (
            <form className="mt-6 space-y-4" onSubmit={onSubmit} noValidate>
              <Field label="Work email" id="login-email">
                {(props) => (
                  <Input
                    {...props}
                    type="email"
                    required
                    autoComplete="email"
                    autoFocus
                    placeholder="you@lgu.gov.ph"
                    value={email}
                    onChange={(event) => setEmail(event.target.value)}
                  />
                )}
              </Field>

              <Field label="Password" id="login-password">
                {(props) => (
                  <Input
                    {...props}
                    type="password"
                    required
                    autoComplete="current-password"
                    value={password}
                    onChange={(event) => setPassword(event.target.value)}
                  />
                )}
              </Field>

              {message ? (
                <Alert tone="error" live>
                  {message}
                </Alert>
              ) : null}

              <div className="space-y-2.5 pt-1">
                <Button
                  type="submit"
                  variant="primary"
                  block
                  loading={busy === 'email'}
                  disabled={busy !== null}
                >
                  Sign in
                </Button>
                <Button
                  variant="secondary"
                  block
                  icon={<IconGoogle size={16} />}
                  loading={busy === 'google'}
                  disabled={busy !== null}
                  onClick={() => void run('google', auth.signInGoogle)}
                >
                  Continue with Google
                </Button>
              </div>
            </form>
          )}
        </div>

        <p className="mt-4 px-1 text-center text-xs text-muted">
          Access requires a <code>staff</code> record in Firestore. Ask an
          administrator if sign-in succeeds but the dashboard denies you.
        </p>
      </main>
    </div>
  )
}
