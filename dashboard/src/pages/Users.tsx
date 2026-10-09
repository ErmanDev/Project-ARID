import { useMemo, useState } from 'react'
import { Navigate } from 'react-router-dom'
import { useAuth } from '../auth'
import { AppHeader } from '../components/AppHeader'
import { IconCheck, IconSearchOff, IconUsers } from '../components/icons'
import { Alert, Button, EmptyState, Input, Segmented, Skeleton } from '../components/ui'
import { useMockData } from '../config'
import { writeErrorMessage } from '../errors'
import { setAccountVerified, useUsers } from '../hooks'
import type { UserProfile } from '../types'

type Filter = 'all' | 'pending' | 'admin' | 'field'

const DATE_FORMAT: Intl.DateTimeFormatOptions = {
  month: 'short',
  day: 'numeric',
  year: 'numeric',
}

function formatDate(iso: string | null): string {
  if (!iso) return '—'
  return new Date(iso).toLocaleDateString(undefined, DATE_FORMAT)
}

/** Pending first, then newest registrations. */
function compareAccounts(a: UserProfile, b: UserProfile): number {
  if (a.verified !== b.verified) return a.verified ? 1 : -1
  return (b.createdAt ?? '').localeCompare(a.createdAt ?? '')
}

function Badge({ tone, children }: { tone: 'admin' | 'field' | 'ok' | 'pending'; children: string }) {
  const styles = {
    admin: 'border-primary-200 bg-primary-50 text-primary-ink',
    field: 'border-border bg-sunken text-ink-2',
    ok: 'border-risk-green-edge bg-risk-green-tint text-risk-green-ink',
    pending: 'border-risk-yellow-edge bg-risk-yellow-tint text-risk-yellow-ink',
  }[tone]
  return (
    <span className={`inline-flex items-center rounded-full border px-2 py-0.5 text-xs font-medium ${styles}`}>
      {children}
    </span>
  )
}

function AccountRow({
  account,
  isSelf,
  verifierName,
  busy,
  onChange,
}: {
  account: UserProfile
  isSelf: boolean
  verifierName: string | null
  busy: boolean
  onChange: (verified: boolean) => void
}) {
  const initial = (account.displayName || account.username || '?').charAt(0).toUpperCase()
  return (
    <li className="flex flex-wrap items-center gap-x-4 gap-y-3 px-4 py-3.5">
      <div className="flex min-w-[14rem] flex-1 items-center gap-3">
        <span className="grid size-9 shrink-0 place-items-center rounded-full bg-primary-100 text-sm font-semibold text-primary-ink">
          {initial}
        </span>
        <div className="min-w-0">
          <p className="truncate font-medium text-ink">
            {account.displayName}
            {isSelf ? <span className="ml-2 text-xs font-normal text-muted">(you)</span> : null}
          </p>
          <p className="truncate text-sm text-muted">@{account.username || 'unknown'}</p>
        </div>
      </div>

      <div className="flex flex-wrap items-center gap-2">
        <Badge tone={account.role === 'admin' ? 'admin' : 'field'}>
          {account.role === 'admin' ? 'Admin' : 'Field reporter'}
        </Badge>
        <Badge tone={account.verified ? 'ok' : 'pending'}>
          {account.verified ? 'Verified' : 'Pending'}
        </Badge>
      </div>

      <dl className="flex gap-6 text-sm">
        <div>
          <dt className="text-xs text-muted">Registered</dt>
          <dd className="text-ink-2" data-numeric>{formatDate(account.createdAt)}</dd>
        </div>
        <div>
          <dt className="text-xs text-muted">Reports</dt>
          <dd className="text-ink-2" data-numeric>{account.reportCount}</dd>
        </div>
        {account.verified && account.role === 'admin' ? (
          <div>
            <dt className="text-xs text-muted">Verified by</dt>
            <dd className="max-w-[10rem] truncate text-ink-2">{verifierName ?? '—'}</dd>
          </div>
        ) : null}
      </dl>

      <div className="ml-auto flex w-full justify-end sm:w-auto">
        {isSelf ? null : account.verified ? (
          <Button size="sm" variant="ghost" loading={busy} onClick={() => onChange(false)}>
            Revoke
          </Button>
        ) : (
          <Button
            size="sm"
            variant="primary"
            icon={<IconCheck size={15} />}
            loading={busy}
            onClick={() => onChange(true)}
          >
            Verify
          </Button>
        )}
      </div>
    </li>
  )
}

export function UsersPage() {
  const auth = useAuth()
  const authorized = Boolean(auth.user && auth.isStaff)
  const { users, loading, error } = useUsers(authorized)
  const [filter, setFilter] = useState<Filter>('all')
  const [query, setQuery] = useState('')
  const [busyId, setBusyId] = useState<string | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)

  const counts = useMemo(
    () => ({
      all: users.length,
      pending: users.filter((user) => !user.verified).length,
      admin: users.filter((user) => user.role === 'admin').length,
      field: users.filter((user) => user.role === 'field').length,
    }),
    [users],
  )

  const visible = useMemo(() => {
    const needle = query.trim().toLowerCase()
    return users
      .filter((user) =>
        filter === 'all'
          ? true
          : filter === 'pending'
            ? !user.verified
            : user.role === filter,
      )
      .filter(
        (user) =>
          !needle ||
          user.displayName.toLowerCase().includes(needle) ||
          user.username.toLowerCase().includes(needle),
      )
      .sort(compareAccounts)
  }, [users, filter, query])

  const namesById = useMemo(
    () => new Map(users.map((user) => [user.id, user.displayName])),
    [users],
  )

  if (auth.loading) {
    return <div className="grid h-full place-items-center bg-bg text-muted">Checking access…</div>
  }
  if (!auth.user) return <Navigate to="/login" replace />
  if (!auth.isStaff) return <Navigate to="/denied" replace />

  async function change(account: UserProfile, verified: boolean) {
    if (!auth.user) return
    if (
      !verified &&
      !window.confirm(
        `Revoke access for ${account.displayName} (@${account.username})? They will not be able to sign in until an admin verifies them again.`,
      )
    ) {
      return
    }
    setActionError(null)
    setBusyId(account.id)
    try {
      await setAccountVerified(account.id, verified, auth.user.uid)
    } catch (err) {
      setActionError(writeErrorMessage(err))
    } finally {
      setBusyId(null)
    }
  }

  return (
    <div className="flex min-h-full flex-col bg-bg">
      <AppHeader />
      <main
        id="main-content"
        tabIndex={-1}
        className="mx-auto flex w-full max-w-[1100px] flex-1 flex-col gap-4 px-4 py-4 lg:px-8"
      >
        <div className="analyze-heading">
          <div className="min-w-0">
            <h1>Users</h1>
            <p>
              Everyone who registered. Field reporters are verified when they sign up on the
              mobile app; new admins wait here until an admin verifies them.
            </p>
          </div>
        </div>

        {useMockData ? (
          <Alert tone="info">Demo workspace: verify and revoke are disabled for sample users.</Alert>
        ) : null}
        {counts.pending > 0 ? (
          <Alert tone="warning">
            {counts.pending} {counts.pending === 1 ? 'account is' : 'accounts are'} waiting for
            verification.
          </Alert>
        ) : null}
        {error ? <Alert tone="error">{error}</Alert> : null}
        {actionError ? (
          <Alert tone="error" live>
            {actionError}
          </Alert>
        ) : null}

        <div className="flex flex-wrap items-center gap-3">
          <Segmented<Filter>
            label="Show accounts"
            value={filter}
            onChange={setFilter}
            options={[
              { value: 'all', label: 'All', meta: counts.all },
              { value: 'pending', label: 'Pending', meta: counts.pending },
              { value: 'admin', label: 'Admins', meta: counts.admin },
              { value: 'field', label: 'Field reporters', meta: counts.field },
            ]}
          />
          <div className="min-w-[12rem] flex-1 sm:max-w-xs">
            <Input
              type="search"
              aria-label="Search by name or username"
              placeholder="Search name or username"
              value={query}
              onChange={(event) => setQuery(event.target.value)}
            />
          </div>
        </div>

        <section className="overflow-hidden rounded-panel border border-border bg-surface shadow-sm">
          {loading ? (
            <div className="space-y-3 p-4" aria-hidden="true">
              <Skeleton className="h-12 w-full" />
              <Skeleton className="h-12 w-full" />
              <Skeleton className="h-12 w-full" />
            </div>
          ) : visible.length === 0 ? (
            <EmptyState
              icon={users.length === 0 ? <IconUsers size={18} /> : <IconSearchOff size={18} />}
              title={users.length === 0 ? 'No accounts yet' : 'No matching accounts'}
            >
              {users.length === 0
                ? 'Accounts appear here as soon as someone registers.'
                : 'Try another filter or search.'}
            </EmptyState>
          ) : (
            <ul className="divide-y divide-border" aria-label="Accounts">
              {visible.map((account) => (
                <AccountRow
                  key={account.id}
                  account={account}
                  isSelf={account.id === auth.user?.uid}
                  verifierName={
                    account.verifiedBy ? (namesById.get(account.verifiedBy) ?? null) : null
                  }
                  busy={busyId === account.id}
                  onChange={(verified) => void change(account, verified)}
                />
              ))}
            </ul>
          )}
        </section>
      </main>
    </div>
  )
}
