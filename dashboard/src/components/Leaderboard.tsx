import type { UserProfile } from '../types'

export function Leaderboard({ users }: { users: UserProfile[] }) {
  const ranked = [...users].sort((a, b) => b.totalPoints - a.totalPoints).slice(0, 8)
  if (ranked.length === 0) {
    return <p className="text-sm text-muted">No contributor profiles synced yet.</p>
  }
  return (
    <ol className="space-y-2">
      {ranked.map((user, index) => (
        <li
          key={user.id}
          className="flex items-center justify-between rounded-lg border border-divider bg-surface px-3 py-2"
        >
          <div>
            <div className="text-sm font-medium text-ink">
              {index + 1}. {user.displayName}
            </div>
            <div className="text-xs text-muted">{user.reportCount} reports</div>
          </div>
          <div className="text-sm font-semibold text-primary">{user.totalPoints} pts</div>
        </li>
      ))}
    </ol>
  )
}
