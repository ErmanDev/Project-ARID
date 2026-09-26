import type { UserProfile } from '../types'

/**
 * Contributor standings for the side rail.
 *
 * Built as one bordered list with divided rows rather than eight stacked
 * cards: card-per-row inside an already-carded panel is the nested-card smell,
 * and it wastes vertical space the side panel needs.
 *
 * Each row carries a proportional bar so the shape of the standings reads
 * before any number does, and the bar is split: the solid part is points the
 * cloud has confirmed, the faint part is points still provisional on someone's
 * phone. That split is the one piece of reward state the sync model actually
 * has, so it earns the ink. Nothing here is invented for decoration - every
 * value comes from the synced `users` document.
 */

/** Ranks 1-3 get a filled marker; the rest keep the same footprint, unfilled. */
function Rank({ index }: { index: number }) {
  const place = index + 1
  const style =
    index === 0
      ? 'bg-primary text-white'
      : index < 3
        ? 'bg-primary-100 text-primary-ink'
        : 'text-muted'
  return (
    <span
      data-numeric
      aria-hidden="true"
      className={`grid size-6 shrink-0 place-items-center rounded-full text-xs font-semibold ${style}`}
    >
      {place}
    </span>
  )
}

export function Leaderboard({ users }: { users: UserProfile[] }) {
  const ranked = [...users]
    .sort((a, b) => b.totalPoints - a.totalPoints)
    .slice(0, 8)

  if (ranked.length === 0) {
    return (
      <p className="rounded-card border border-dashed border-border px-3 py-4 text-center text-sm text-muted">
        No contributor profiles have synced yet. Reporters appear here once the
        mobile app uploads its first batch.
      </p>
    )
  }

  // Bars are scaled to the leader, not to the sum: the question a coordinator
  // asks of this panel is "who is carrying the barangay", not "what fraction
  // of all points is this".
  const leaderPoints = Math.max(...ranked.map((user) => user.totalPoints), 1)
  const communityTotal = users.reduce((sum, user) => sum + user.totalPoints, 0)
  const pending = users.reduce(
    (sum, user) =>
      sum +
      (user.verifiedPoints === null
        ? 0
        : Math.max(0, user.totalPoints - user.verifiedPoints)),
    0,
  )

  return (
    <div className="overflow-hidden rounded-card border border-border bg-surface shadow-xs">
      <div className="flex items-baseline justify-between gap-3 border-b border-border px-3 py-2.5">
        <span className="text-xs font-medium text-muted">Community points</span>
        <span className="flex items-baseline gap-1.5">
          <span data-numeric className="text-lg font-semibold text-ink">
            {communityTotal.toLocaleString()}
          </span>
          {pending > 0 ? (
            <span data-numeric className="text-xs text-muted">
              · {pending.toLocaleString()} pending
            </span>
          ) : null}
        </span>
      </div>

      <ol className="divide-y divide-border">
        {ranked.map((user, index) => {
          const share = (user.totalPoints / leaderPoints) * 100
          const verified = user.verifiedPoints
          const provisional =
            verified === null ? 0 : Math.max(0, user.totalPoints - verified)
          // Portion of this row's own bar that is confirmed.
          const verifiedShare =
            verified === null || user.totalPoints === 0
              ? 100
              : (verified / user.totalPoints) * 100

          return (
            <li
              key={user.id}
              className="px-3 py-2.5 transition-colors duration-(--duration-fast) ease-(--ease-out-quart) hover:bg-panel"
            >
              <div className="flex items-center gap-2.5">
                <Rank index={index} />
                <div className="min-w-0 flex-1">
                  <div className="truncate text-base font-medium text-ink">
                    {user.displayName}
                  </div>
                  <div className="text-xs text-muted">
                    <span data-numeric>{user.reportCount}</span>{" "}
                    {user.reportCount === 1 ? "report" : "reports"}
                    {provisional > 0 ? (
                      <>
                        {" · "}
                        <span data-numeric>{provisional}</span> pending
                      </>
                    ) : null}
                  </div>
                </div>
                <div className="shrink-0 text-right">
                  <span data-numeric className="text-base font-semibold text-ink">
                    {user.totalPoints}
                  </span>
                  <span className="ml-1 text-xs text-muted">pts</span>
                </div>
              </div>

              {/* Full width, on its own line: the bar is only readable as a
                  ranking if every track is the same length. Sharing a row with
                  the variable-width meta text made a 54-point bar render longer
                  than an 86-point one. */}
              <div
                aria-hidden="true"
                className="mt-2 h-1.5 overflow-hidden rounded-full bg-sunken"
              >
                <div
                  className="flex h-full rounded-full transition-[width] duration-(--duration-slow) ease-(--ease-out-quart)"
                  style={{ width: `${share}%` }}
                >
                  <div
                    className="h-full bg-primary"
                    style={{ width: `${verifiedShare}%` }}
                  />
                  <div className="h-full flex-1 bg-primary-soft" />
                </div>
              </div>
            </li>
          )
        })}
      </ol>

      {pending > 0 ? (
        <p className="border-t border-border bg-panel px-3 py-2 text-xs text-muted">
          Pending points are awarded on the reporter's device and confirm once
          their upload reaches the cloud.
        </p>
      ) : null}
    </div>
  )
}
