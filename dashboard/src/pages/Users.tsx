import { useMemo, useState } from 'react'
import { Navigate } from 'react-router-dom'
import { ageFrom } from '../accounts'
import { useAuth } from '../auth'
import { AppHeader } from '../components/AppHeader'
import { IconCheck, IconClose, IconSearchOff, IconUsers } from '../components/icons'
import { Alert, Button, EmptyState, Input, Segmented, Skeleton } from '../components/ui'
import { useMockData } from '../config'
import { writeErrorMessage } from '../errors'
import { deleteAccount, setAccountStatus, useUsers } from '../hooks'
import type { AccountStatus, UserProfile } from '../types'

type Filter = AccountStatus | 'all'

const DATE_FORMAT: Intl.DateTimeFormatOptions = {
  month: 'short',
  day: 'numeric',
  year: 'numeric',
}

function formatDate(iso: string | null): string {
  if (!iso) return '—'
  return new Date(iso).toLocaleDateString(undefined, DATE_FORMAT)
}

/** "YYYY-MM-DD" read as a calendar date, so no time zone shifts the day. */
function formatBirthday(birthDate: string): string {
  const [year, month, day] = birthDate.split('-').map(Number)
  if (!year || !month || !day) return '—'
  return new Date(year, month - 1, day).toLocaleDateString(undefined, DATE_FORMAT)
}

function fullName(account: UserProfile): string {
  const parts = [account.firstName, account.middleName, account.lastName].filter(Boolean)
  return parts.length > 0 ? parts.join(' ') : account.displayName
}

const STATUS_ORDER: Record<AccountStatus, number> = { pending: 0, verified: 1, rejected: 2 }

/** Pending first, then newest registrations. */
function compareAccounts(a: UserProfile, b: UserProfile): number {
  if (a.status !== b.status) return STATUS_ORDER[a.status] - STATUS_ORDER[b.status]
  return (b.createdAt ?? '').localeCompare(a.createdAt ?? '')
}

type BadgeTone = 'admin' | 'staff' | AccountStatus

function Badge({ tone, children }: { tone: BadgeTone; children: string }) {
  const styles: Record<BadgeTone, string> = {
    admin: 'border-primary-200 bg-primary-50 text-primary-ink',
    staff: 'border-border bg-sunken text-ink-2',
    verified: 'border-risk-green-edge bg-risk-green-tint text-risk-green-ink',
    pending: 'border-risk-yellow-edge bg-risk-yellow-tint text-risk-yellow-ink',
    rejected: 'border-risk-red-edge bg-risk-red-tint text-risk-red-ink',
  }
  return (
    <span
      className={`inline-flex items-center rounded-full border px-2 py-0.5 text-xs font-medium ${styles[tone]}`}
    >
      {children}
    </span>
  )
}

const STATUS_LABEL: Record<AccountStatus, string> = {
  pending: 'Pending',
  verified: 'Verified',
  rejected: 'Rejected',
}

type Action = 'verify' | 'reject' | 'revoke' | 'delete'

function AccountRow({
  account,
  isSelf,
  reviewerName,
  busy,
  onAction,
}: {
  account: UserProfile
  isSelf: boolean
  reviewerName: string | null
  busy: Action | null
  onAction: (action: Action) => void
}) {
  const name = fullName(account)
  const age = account.birthDate ? ageFrom(account.birthDate) : null
  const isStaff = account.role === 'staff'

  return (
    <li className="flex flex-wrap items-center gap-x-5 gap-y-3 px-4 py-4">
      <div className="flex min-w-[15rem] flex-1 items-center gap-3">
        <span className="grid size-10 shrink-0 place-items-center rounded-full bg-primary-100 text-sm font-semibold text-primary-ink">
          {name.charAt(0).toUpperCase() || '?'}
        </span>
        <div className="min-w-0">
          <p className="truncate font-medium text-ink">
            {name}
            {isSelf ? <span className="ml-2 text-xs font-normal text-muted">(you)</span> : null}
          </p>
          <p className="truncate text-sm text-muted">@{account.username || 'unknown'}</p>
          <div className="mt-1.5 flex flex-wrap gap-1.5">
            <Badge tone={isStaff ? 'staff' : 'admin'}>{isStaff ? 'Staff' : 'Admin'}</Badge>
            <Badge tone={account.status}>{STATUS_LABEL[account.status]}</Badge>
          </div>
        </div>
      </div>

      <dl className="grid grid-cols-2 gap-x-6 gap-y-2 text-sm sm:flex sm:gap-6">
        {isStaff ? (
          <div>
            <dt className="text-xs text-muted">Birthday</dt>
            <dd className="text-ink-2" data-numeric>
              {account.birthDate ? formatBirthday(account.birthDate) : '—'}
              {age !== null ? <span className="text-muted"> · {age} yrs</span> : null}
            </dd>
          </div>
        ) : null}
        <div>
          <dt className="text-xs text-muted">Registered</dt>
          <dd className="text-ink-2" data-numeric>{formatDate(account.createdAt)}</dd>
        </div>
        {account.status !== 'pending' ? (
          <div>
            <dt className="text-xs text-muted">
              {account.status === 'verified' ? 'Verified by' : 'Rejected by'}
            </dt>
            <dd className="max-w-[11rem] truncate text-ink-2">
              {reviewerName ?? '—'}
              {account.reviewedAt ? (
                <span className="text-muted"> · {formatDate(account.reviewedAt)}</span>
              ) : null}
            </dd>
          </div>
        ) : null}
        {isStaff && account.status === 'verified' ? (
          <div>
            <dt className="text-xs text-muted">Reports</dt>
            <dd className="text-ink-2" data-numeric>{account.reportCount}</dd>
          </div>
        ) : null}
      </dl>

      {isSelf ? null : (
        <div className="ml-auto flex w-full flex-wrap justify-end gap-2 sm:w-auto">
          {account.status !== 'verified' ? (
            <Button
              size="sm"
              variant="primary"
              icon={<IconCheck size={15} />}
              loading={busy === 'verify'}
              disabled={busy !== null}
              onClick={() => onAction('verify')}
            >
              Verify
            </Button>
          ) : null}
          {account.status === 'pending' ? (
            <Button
              size="sm"
              variant="secondary"
              icon={<IconClose size={15} />}
              loading={busy === 'reject'}
              disabled={busy !== null}
              onClick={() => onAction('reject')}
            >
              Reject
            </Button>
          ) : null}
          {account.status === 'verified' ? (
            <Button
              size="sm"
              variant="ghost"
              loading={busy === 'revoke'}
              disabled={busy !== null}
              onClick={() => onAction('revoke')}
            >
              Revoke
            </Button>
          ) : null}
          {account.status === 'rejected' && isStaff ? (
            <Button
              size="sm"
              variant="ghost"
              className="text-risk-red-ink"
              loading={busy === 'delete'}
              disabled={busy !== null}
              onClick={() => onAction('delete')}
            >
              Delete
            </Button>
          ) : null}
        </div>
      )}
    </li>
  )
}

const CONFIRM: Partial<Record<Action, (name: string) => string>> = {
  reject: (name) => `Reject ${name}? They will not be able to sign in. You can still verify or delete the request later.`,
  revoke: (name) => `Revoke access for ${name}? They will be marked Rejected and cannot sign in until verified again.`,
  delete: (name) =>
    `Delete ${name}'s registration? This removes their details from the list. It cannot be undone, but they can register again.`,
}

export function UsersPage() {
  const auth = useAuth()
  const authorized = Boolean(auth.user && auth.isStaff)
  const { users, loading, error } = useUsers(authorized)
  const [filter, setFilter] = useState<Filter>('pending')
  const [query, setQuery] = useState('')
  const [busy, setBusy] = useState<{ id: string; action: Action } | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)

  const counts = useMemo(
    () => ({
      all: users.length,
      pending: users.filter((user) => user.status === 'pending').length,
      verified: users.filter((user) => user.status === 'verified').length,
      rejected: users.filter((user) => user.status === 'rejected').length,
    }),
    [users],
  )

  const visible = useMemo(() => {
    const needle = query.trim().toLowerCase()
    return users
      .filter((user) => filter === 'all' || user.status === filter)
      .filter(
        (user) =>
          !needle ||
          fullName(user).toLowerCase().includes(needle) ||
          user.username.toLowerCase().includes(needle),
      )
      .sort(compareAccounts)
  }, [users, filter, query])

  const namesById = useMemo(
    () => new Map(users.map((user) => [user.id, fullName(user)])),
    [users],
  )

  if (auth.loading) {
    return <div className="grid h-full place-items-center bg-bg text-muted">Checking access…</div>
  }
  if (!auth.user) return <Navigate to="/login" replace />
  if (!auth.isStaff) return <Navigate to="/denied" replace />

  async function run(account: UserProfile, action: Action) {
    if (!auth.user) return
    const confirmText = CONFIRM[action]?.(`${fullName(account)} (@${account.username})`)
    if (confirmText && !window.confirm(confirmText)) return

    setActionError(null)
    setBusy({ id: account.id, action })
    try {
      if (action === 'delete') {
        await deleteAccount(account.id)
      } else {
        await setAccountStatus(
          account.id,
          action === 'verify' ? 'verified' : 'rejected',
          auth.user.uid,
        )
      }
    } catch (err) {
      setActionError(writeErrorMessage(err))
    } finally {
      setBusy(null)
    }
  }

  const emptyTitle =
    users.length === 0
      ? 'No accounts yet'
      : query.trim()
        ? 'No matching accounts'
        : filter === 'pending'
          ? 'No one is waiting'
          : `No ${filter === 'all' ? '' : STATUS_LABEL[filter].toLowerCase()} accounts`

  return (
    <div className="flex min-h-full flex-col bg-bg">
      <AppHeader />
      <main
        id="main-content"
        tabIndex={-1}
        className="mx-auto flex w-full max-w-[1100px] flex-1 flex-col gap-4 px-4 py-4 lg:px-8"
      >
        <div className="page-intro">
          <div className="min-w-0">
            <h1>User Verification</h1>
            <p>
              Staff register on the mobile app and cannot sign in until an admin verifies them
              here. Check each person's details before you verify.
            </p>
          </div>
        </div>

        {useMockData ? (
          <Alert tone="info">Demo workspace: verification is disabled for sample users.</Alert>
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
              { value: 'pending', label: 'Pending', meta: counts.pending },
              { value: 'verified', label: 'Verified', meta: counts.verified },
              { value: 'rejected', label: 'Rejected', meta: counts.rejected },
              { value: 'all', label: 'All', meta: counts.all },
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
              <Skeleton className="h-14 w-full" />
              <Skeleton className="h-14 w-full" />
              <Skeleton className="h-14 w-full" />
            </div>
          ) : visible.length === 0 ? (
            <EmptyState
              icon={query.trim() ? <IconSearchOff size={18} /> : <IconUsers size={18} />}
              title={emptyTitle}
            >
              {users.length === 0 || filter === 'pending'
                ? 'New staff registrations from the mobile app appear here.'
                : 'Try another filter or search.'}
            </EmptyState>
          ) : (
            <ul className="divide-y divide-border" aria-label="Accounts">
              {visible.map((account) => (
                <AccountRow
                  key={account.id}
                  account={account}
                  isSelf={account.id === auth.user?.uid}
                  reviewerName={
                    account.reviewedBy ? (namesById.get(account.reviewedBy) ?? null) : null
                  }
                  busy={busy?.id === account.id ? busy.action : null}
                  onAction={(action) => void run(account, action)}
                />
              ))}
            </ul>
          )}
        </section>
      </main>
    </div>
  )
}
