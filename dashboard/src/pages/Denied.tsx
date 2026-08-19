import { useAuth } from '../auth'
import { Link } from 'react-router-dom'

export function DeniedPage() {
  const auth = useAuth()
  return (
    <div className="flex min-h-full items-center justify-center bg-background px-4">
      <div className="w-full max-w-md rounded-2xl border border-divider bg-surface p-8">
        <img src="/arid-logo.png" alt="A.R.I.D." className="mb-4 h-14 w-14" />
        <h1 className="text-xl font-semibold text-ink">Access denied</h1>
        <p className="mt-3 text-sm text-muted">
          This dashboard is limited to authorized LGU and health-worker accounts. Ask an admin to
          add your UID to the Firestore <code>staff</code> collection.
        </p>
        {auth.user ? (
          <p className="mt-3 break-all text-xs text-muted">Signed in as {auth.user.uid}</p>
        ) : null}
        <div className="mt-6 flex gap-3">
          <button
            type="button"
            className="rounded-lg bg-primary px-4 py-2 text-sm text-white"
            onClick={() => void auth.signOut()}
          >
            Sign out
          </button>
          <Link to="/login" className="rounded-lg px-4 py-2 text-sm text-primary">
            Back to login
          </Link>
        </div>
      </div>
    </div>
  )
}
