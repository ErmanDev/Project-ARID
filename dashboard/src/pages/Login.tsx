import { useState, type FormEvent } from 'react'
import { Navigate } from 'react-router-dom'
import { useAuth } from '../auth'

export function LoginPage() {
  const auth = useAuth()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [busy, setBusy] = useState(false)
  const [message, setMessage] = useState<string | null>(null)

  if (auth.user && auth.isStaff) return <Navigate to="/" replace />
  if (auth.user && !auth.isStaff) return <Navigate to="/denied" replace />

  async function onSubmit(event: FormEvent) {
    event.preventDefault()
    setBusy(true)
    setMessage(null)
    try {
      await auth.signInEmail(email, password)
    } catch (err) {
      setMessage(err instanceof Error ? err.message : 'Sign-in failed')
    } finally {
      setBusy(false)
    }
  }

  async function onGoogle() {
    setBusy(true)
    setMessage(null)
    try {
      await auth.signInGoogle()
    } catch (err) {
      setMessage(err instanceof Error ? err.message : 'Google sign-in failed')
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="flex min-h-full items-center justify-center bg-background px-4">
      <div className="w-full max-w-md rounded-2xl border border-divider bg-surface p-8 shadow-sm">
        <img
          src="/arid-logo.png"
          alt="A.R.I.D."
          className="h-16 w-16"
        />
        <p className="mt-4 text-sm font-medium text-primary">A.R.I.D. monitoring</p>
        <h1 className="mt-1 text-2xl font-semibold text-ink">Staff sign-in</h1>
        <p className="mt-2 text-sm text-muted">
          For LGU and health-worker accounts. Field capture stays on the mobile app.
        </p>
        {!auth.configured ? (
          <p className="mt-6 rounded-lg border border-divider bg-background p-3 text-sm text-muted">
            Firebase is not configured. Copy <code>dashboard/.env.example</code> to{' '}
            <code>dashboard/.env</code> with the same project the mobile app uses.
          </p>
        ) : (
          <form className="mt-6 space-y-3" onSubmit={onSubmit}>
            <input
              className="w-full rounded-lg border border-divider px-3 py-2 text-sm"
              type="email"
              required
              placeholder="Work email"
              value={email}
              onChange={(event) => setEmail(event.target.value)}
            />
            <input
              className="w-full rounded-lg border border-divider px-3 py-2 text-sm"
              type="password"
              required
              placeholder="Password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
            />
            {message ? <p className="text-sm text-ink">{message}</p> : null}
            <button
              type="submit"
              disabled={busy}
              className="w-full rounded-lg bg-primary py-2.5 text-sm font-medium text-white disabled:opacity-60"
            >
              {busy ? 'Signing in…' : 'Sign in'}
            </button>
            <button
              type="button"
              disabled={busy}
              onClick={() => void onGoogle()}
              className="w-full rounded-lg border border-primary py-2.5 text-sm font-medium text-primary disabled:opacity-60"
            >
              Continue with Google
            </button>
          </form>
        )}
      </div>
    </div>
  )
}
