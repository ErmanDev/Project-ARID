import type { UserProfile } from '../types'

/**
 * A ranked list, so it is built as one bordered list with divided rows rather
 * than eight stacked cards. Card-per-row inside an already-carded panel is the
 * nested-card smell, and it wastes vertical space the side panel needs.
 */
export function Leaderboard({ users }: { users: UserProfile[] }) {
  const ranked = [...users].sort((a, b) => b.totalPoints - a.totalPoints).slice(0, 8)

  if (ranked.length === 0) {
    return (
      <p className="rounded-card border border-dashed border-border px-3 py-4 text-center text-sm text-muted">
        No contributor profiles have synced yet. Reporters appear here once the
        mobile app uploads its first batch.
      </p>
    )
  }

  return (
    <ol className="divide-y divide-border overflow-hidden rounded-card border border-border bg-surface shadow-xs">
      {ranked.map((user, index) => (
        <li
          key={user.id}
          className="flex items-center gap-3 px-3 py-2.5 transition-colors duration-(--duration-fast) ease-(--ease-out-quart) hover:bg-panel"
        >
          <span
            data-numeric
            className={`w-4 shrink-0 text-right text-sm ${
              index === 0 ? 'font-semibold text-primary-ink' : 'text-muted'
            }`}
          >
            {index + 1}
          </span>
          <div className="min-w-0 flex-1">
            <div className="truncate text-base font-medium text-ink">
              {user.displayName}
            </div>
            <div data-numeric className="text-xs text-muted">
              {user.reportCount} {user.reportCount === 1 ? 'report' : 'reports'}
            </div>
          </div>
          <div className="shrink-0 text-right">
            <span data-numeric className="text-base font-semibold text-ink">
              {user.totalPoints}
            </span>
            <span className="ml-1 text-xs text-muted">pts</span>
          </div>
        </li>
      ))}
    </ol>
  )
}
