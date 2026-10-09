import { useState, type FormEvent } from 'react'
import { Navigate } from 'react-router-dom'
import { usernameProblem } from '../accounts'
import { useAuth } from '../auth'
import { authErrorMessage } from '../errors'
import { IconCheck } from '../components/icons'
import { Alert, Button, Field, Input } from '../components/ui'
import { ThemeToggle } from '../components/ThemeToggle'

type Mode = 'signIn' | 'register'

const MIN_PASSWORD = 6

export function LoginPage() {
  const auth = useAuth()
  const [mode, setMode] = useState<Mode>('signIn')
  const [busy, setBusy] = useState(false)
  const [message, setMessage] = useState<string | null>(null)
  const [notice, setNotice] = useState<string | null>(null)
  const [displayName, setDisplayName] = useState('')
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [confirm, setConfirm] = useState('')
  const [attempted, setAttempted] = useState(false)

  if (auth.user && auth.isStaff) return <Navigate to="/" replace />

  const registering = mode === 'register'
  const errors = {
    displayName:
      registering && displayName.trim().length < 2 ? 'Enter your full name.' : undefined,
    username: username.trim()
      ? registering
        ? (usernameProblem(username) ?? undefined)
        : undefined
      : 'Enter your username.',
    password: !password
      ? 'Enter your password.'
      : registering && password.length < MIN_PASSWORD
        ? `Use at least ${MIN_PASSWORD} characters.`
        : undefined,
    confirm: registering && confirm !== password ? 'The passwords do not match.' : undefined,
  }
  const shown = (error: string | undefined) => (attempted ? error : undefined)

  function switchMode(next: Mode) {
    setMode(next)
    setMessage(null)
    setAttempted(false)
    setPassword('')
    setConfirm('')
    if (next === 'register') setNotice(null)
  }

  async function submit(event: FormEvent) {
    event.preventDefault()
    setAttempted(true)
    setMessage(null)
    if (Object.values(errors).some(Boolean)) return

    setBusy(true)
    try {
      if (registering) {
        await auth.register(displayName.trim(), username, password)
        switchMode('signIn')
        setNotice(
          'Account created. An existing admin has to verify it in the Users tab before you can sign in.',
        )
      } else {
        setNotice(null)
        await auth.signIn(username, password)
      }
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
          <h1 className="mt-2 text-2xl font-semibold tracking-tight text-ink">
            {registering ? 'Create an admin account.' : 'Welcome back.'}
          </h1>
          <p className="mt-1.5 text-base text-muted">
            {registering
              ? 'New admin accounts need to be verified by an existing admin before they can sign in.'
              : 'Sign in to monitor reports, inspect potential breeding sites, and manage accounts.'}
          </p>

          {!auth.configured ? (
            <Alert tone="warning" className="mt-6">
              This workspace is not connected yet. Ask your administrator to complete sign-in setup.
            </Alert>
          ) : (
            <form className="mt-6 space-y-4" noValidate onSubmit={(event) => void submit(event)}>
              {notice ? (
                <Alert tone="notice" icon={<IconCheck size={16} />} live>
                  {notice}
                </Alert>
              ) : null}
              {message ? (
                <Alert tone="error" live>
                  {message}
                </Alert>
              ) : null}

              {registering ? (
                <Field id="displayName" label="Full name" error={shown(errors.displayName)}>
                  {(props) => (
                    <Input
                      {...props}
                      autoComplete="name"
                      value={displayName}
                      onChange={(event) => setDisplayName(event.target.value)}
                    />
                  )}
                </Field>
              ) : null}

              <Field
                id="username"
                label="Username"
                hint={registering ? 'Letters, numbers, dots, dashes, or underscores.' : undefined}
                error={shown(errors.username)}
              >
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

              <Field
                id="password"
                label="Password"
                hint={registering ? `At least ${MIN_PASSWORD} characters.` : undefined}
                error={shown(errors.password)}
              >
                {(props) => (
                  <Input
                    {...props}
                    type="password"
                    autoComplete={registering ? 'new-password' : 'current-password'}
                    value={password}
                    onChange={(event) => setPassword(event.target.value)}
                  />
                )}
              </Field>

              {registering ? (
                <Field id="confirm" label="Confirm password" error={shown(errors.confirm)}>
                  {(props) => (
                    <Input
                      {...props}
                      type="password"
                      autoComplete="new-password"
                      value={confirm}
                      onChange={(event) => setConfirm(event.target.value)}
                    />
                  )}
                </Field>
              ) : null}

              <Button type="submit" variant="primary" block loading={busy} disabled={busy}>
                {registering ? 'Create account' : 'Sign in'}
              </Button>

              <p className="text-center text-sm text-muted">
                {registering ? 'Already have an account?' : 'New admin?'}{' '}
                <button
                  type="button"
                  className="font-medium text-primary-ink underline-offset-2 hover:underline"
                  onClick={() => switchMode(registering ? 'signIn' : 'register')}
                >
                  {registering ? 'Sign in' : 'Create an account'}
                </button>
              </p>
            </form>
          )}
        </div>

        <p className="mt-4 px-1 auth-note text-center text-xs">
          For LGU and health-office admins. Field reporters sign in on the A.R.I.D. mobile app.
        </p>
      </main>
    </div>
  )
}
