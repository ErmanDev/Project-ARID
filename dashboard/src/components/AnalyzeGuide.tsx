import { useEffect, useState } from 'react'

const TIPS = [
  {
    title: 'Give the scene some context',
    body: 'Keep the whole container in frame, with a little of the surrounding area visible.',
  },
  {
    title: 'Let the light in',
    body: 'Use a well-lit photo. Avoid deep shadows, glare, and blurry close-ups.',
  },
  {
    title: 'A second angle can help',
    body: 'If an object is partly hidden, take another photo from a clearer angle and analyze it separately.',
  },
]

/**
 * Ari's card. Ari stands in a tinted disc at the top-left of his own card, next
 * to what he is saying, the way a message sits beside its sender. He used to
 * float outside the card beside a tall speech bubble, which left him hanging in
 * empty space; inside the card he is anchored and takes no extra height.
 */
export function AnalyzeGuide({
  status,
  count,
}: {
  status: 'idle' | 'analyzing' | 'complete' | 'error'
  count: number
}) {
  const [tip, setTip] = useState(0)
  const [showTips, setShowTips] = useState(true)

  // Photo tips help before a photo is taken. Once results are in they fold
  // away so the findings get the rail's height; "Show photo tips" reopens them.
  useEffect(() => {
    if (status === 'complete') setShowTips(false)
    if (status === 'idle') setShowTips(true)
  }, [status])

  const message =
    status === 'analyzing'
      ? 'I’m checking your photo. The first analysis can take a little longer while the models load.'
      : status === 'complete'
        ? count > 0
          ? 'Your results are ready. Select a finding to highlight it in the photo, then verify the spot in the field.'
          : 'No matching objects were detected. Try another angle if something looks suspicious; a clear result does not rule out risk.'
        : status === 'error'
          ? 'Let’s try again. Check the message below, then choose a supported photo.'
          : 'Hi, I’m Ari, your photo guide. Start with a clear site photo and I’ll help you understand the next step.'

  return (
    <section
      className="ari-guide rounded-panel border border-border bg-surface shadow-sm"
      aria-labelledby="ari-title"
    >
      <div className="ari-head">
        <span className="ari-stand" aria-hidden="true">
          <img
            className={status === 'analyzing' ? 'ari-avatar is-working' : 'ari-avatar'}
            src="/ari-guide.png"
            alt=""
            width="80"
            height="80"
          />
        </span>
        <div className="min-w-0">
          <h2 id="ari-title" className="ari-name">
            Ari · your field guide
          </h2>
          <p className="ari-message" role="status">
            {message}
          </p>
        </div>
      </div>

      {showTips ? (
        <div id="ari-photo-tips" className="ari-tip" aria-live="polite" aria-atomic="true">
          <h3>{TIPS[tip].title}</h3>
          <p>{TIPS[tip].body}</p>
        </div>
      ) : null}

      <div className="ari-footer">
        <button
          type="button"
          className="guide-toggle"
          aria-expanded={showTips}
          aria-controls="ari-photo-tips"
          onClick={() => setShowTips(!showTips)}
        >
          {showTips ? 'Hide photo tips' : 'Show photo tips'}
        </button>
        {showTips ? (
          <span className="ari-nav">
            <span>
              Tip {tip + 1} of {TIPS.length}
            </span>
            <button
              type="button"
              className="ari-next"
              onClick={() => setTip((tip + 1) % TIPS.length)}
            >
              Next tip <span aria-hidden="true">→</span>
            </button>
          </span>
        ) : null}
      </div>
    </section>
  )
}
