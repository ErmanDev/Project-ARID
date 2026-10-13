import { useState, type FormEvent } from 'react'
import { Navigate } from 'react-router-dom'
import { useAuth } from '../auth'
import { authErrorMessage } from '../errors'
import { Alert, Button, Field, Input } from '../components/ui'
import { ThemeToggle } from '../components/ThemeToggle'

/**
 * Admin sign-in. There is no registration here: admin accounts are created
 * with tool/create_admin.js, and staff register on the mobile app.
 */
export function LoginPage() {
  const auth = useAuth()
  const [busy, setBusy] = useState(false)
  const [message, setMessage] = useState<string | null>(null)
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [attempted, setAttempted] = useState(false)

  if (auth.user && auth.isStaff) return <Navigate to="/" replace />

  const errors = {
    username: username.trim() ? undefined : 'Enter your username.',
    password: password ? undefined : 'Enter your password.',
  }
  const shown = (error: string | undefined) => (attempted ? error : undefined)

  async function submit(event: FormEvent) {
    event.preventDefault()
    setAttempted(true)
    setMessage(null)
    if (errors.username || errors.password) return

    setBusy(true)
    try {
      await auth.signIn(username, password)
    } catch (err) {
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
          <p className="eyebrow mt-6">A.R.I.D. admin workspace</p>
          <h1 className="mt-2 text-2xl font-semibold tracking-tight text-ink">Welcome back.</h1>
          <p className="mt-1.5 text-base text-muted">
            Sign in to monitor reports, inspect potential breeding sites, and verify staff accounts.
          </p>

          {!auth.configured ? (
            <Alert tone="warning" className="mt-6">
              This workspace is not connected yet. Ask your administrator to complete sign-in setup.
            </Alert>
          ) : (
            <form className="mt-6 space-y-4" noValidate onSubmit={(event) => void submit(event)}>
              {message ? (
                <Alert tone="error" live>
                  {message}
                </Alert>
              ) : null}

              <Field id="username" label="Username" error={shown(errors.username)}>
                {(props) => (
                  <Input
                    {...props}
                    autoComplete="username"
                    autoCapitalize="none"
                    spellCheck={false}
                    value={username}
                    onChange={(event) => setUsername(event.target.value)}
                  />
                )}
              </Field>

              <Field id="password" label="Password" error={shown(errors.password)}>
                {(props) => (
                  <Input
                    {...props}
                    type="password"
                    autoComplete="current-password"
                    value={password}
                    onChange={(event) => setPassword(event.target.value)}
                  />
                )}
              </Field>

              <Button type="submit" variant="primary" block loading={busy} disabled={busy}>
                Sign in
              </Button>
            </form>
          )}
        </div>

        <p className="mt-4 px-1 auth-note text-center text-xs">
          For LGU and health-office admins. Staff register and sign in on the A.R.I.D. mobile app.
        </p>
      </main>
    </div>
  )
}
