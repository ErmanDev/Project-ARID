import { useEffect, useRef, useState, type ChangeEvent, type DragEvent } from 'react'
import { Navigate } from 'react-router-dom'
import { useAuth } from '../auth'
import {
  IconAlert,
  IconCheck,
  IconImageOff,
  IconInfo,
  IconMosquito,
  IconRefresh,
  IconScan,
  IconUpload,
} from '../components/icons'
import { Alert, Button, EmptyState, Skeleton } from '../components/ui'
import { AppHeader } from '../components/AppHeader'
import { AnalyzeGuide } from '../components/AnalyzeGuide'
import { AnalyzeStats, AnalyzeStatsSkeleton } from '../components/AnalyzeStats'
import {
  detectBreedingPlaces,
  DETECTION_CLASSES,
  type Detection,
  type DetectionResult,
} from '../services/detection/yolo'
import { classifyBreedingSite, type ClassificationResult } from '../services/detection/classifier'

const MAX_FILE_SIZE = 15 * 1024 * 1024

/**
 * One hue per class, indexed by classId. These sit on photographs rather than
 * on a token surface, so they run more saturated than the app palette and are
 * spaced far enough apart in hue to stay separable when boxes overlap.
 */
const BOX_COLORS = ['#00a9cc', '#e08a1e', '#8b7bf0', '#e0555f', '#3fb488']

/**
 * Label ink for a detection chip.
 *
 * The chip is filled with its class colour, and white text on those fills ran
 * 2.6-3.9:1 — under AA at every class, in this palette and in the one before
 * it. Choosing the ink from the fill's own luminance clears 5:1 on all five
 * while leaving the boxes as vivid as they need to be over a photograph.
 */
function labelInk(hex: string): string {
  const n = parseInt(hex.slice(1), 16)
  const channels = [(n >> 16) & 255, (n >> 8) & 255, n & 255].map((value) => {
    const v = value / 255
    return v <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4
  })
  const luminance =
    0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2]
  return luminance > 0.19 ? '#0b1220' : '#ffffff'
}

type AnalysisState =
  | { status: 'idle' }
  | { status: 'analyzing' }
  | { status: 'complete'; result: DetectionResult; verdict: ClassificationResult | null }
  | { status: 'error'; message: string }

/* ---------------------------------------------------------------- overlay */

function DetectionBox({
  detection,
  result,
  index,
  active,
  dimmed,
}: {
  detection: Detection
  result: DetectionResult
  index: number
  active: boolean
  dimmed: boolean
}) {
  const color = BOX_COLORS[detection.classId] ?? BOX_COLORS[0]
  const top = (detection.y / result.imageHeight) * 100
  // A box that starts near the top edge has no room for a label above it, so
  // the chip drops inside rather than being clipped by the frame.
  const labelInside = top < 7

  return (
    <div
      className="pointer-events-none absolute rounded-[5px] border-2 transition-[opacity,box-shadow] duration-(--duration-base) ease-(--ease-out-quart)"
      style={{
        borderColor: color,
        opacity: dimmed ? 0.3 : 1,
        boxShadow: active
          ? `0 0 0 2px ${color}66, 0 0 0 9999px rgba(0,0,0,0.3)`
          : '0 1px 6px rgba(0,0,0,0.45)',
        left: `${(detection.x / result.imageWidth) * 100}%`,
        top: `${top}%`,
        width: `${(detection.width / result.imageWidth) * 100}%`,
        height: `${(detection.height / result.imageHeight) * 100}%`,
      }}
    >
      <span
        className={`absolute left-[-2px] flex items-center gap-1 whitespace-nowrap rounded-[5px] px-1.5 py-0.5 text-xs font-semibold shadow-sm ${
          labelInside ? 'top-1 ml-1' : '-top-1 -translate-y-full'
        }`}
        style={{ backgroundColor: color, color: labelInk(color) }}
      >
        <span data-numeric className="opacity-75">
          {index + 1}
        </span>
        {detection.label}
        <span data-numeric className="opacity-90">
          {Math.round(detection.confidence * 100)}%
        </span>
      </span>
    </div>
  )
}

/* ------------------------------------------------------------------- page */

export function AnalyzePage() {
  const auth = useAuth()
  const inputRef = useRef<HTMLInputElement>(null)
  const requestRef = useRef(0)
  const [previewUrl, setPreviewUrl] = useState<string | null>(null)
  const [fileName, setFileName] = useState('')
  const [analysis, setAnalysis] = useState<AnalysisState>({ status: 'idle' })
  const [dragging, setDragging] = useState(false)
  const [hovered, setHovered] = useState<number | null>(null)
  const [selected, setSelected] = useState<number | null>(null)

  useEffect(
    () => () => {
      if (previewUrl) URL.revokeObjectURL(previewUrl)
    },
    [previewUrl],
  )

  async function analyze(file: File) {
    const request = ++requestRef.current
    if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.type)) {
      setAnalysis({ status: 'error', message: 'Choose a JPG, PNG, or WebP image.' })
      return
    }
    if (file.size > MAX_FILE_SIZE) {
      setAnalysis({ status: 'error', message: 'Choose an image smaller than 15 MB.' })
      return
    }

    if (previewUrl) URL.revokeObjectURL(previewUrl)
    setPreviewUrl(URL.createObjectURL(file))
    setFileName(file.name)
    setHovered(null)
    setSelected(null)
    setAnalysis({ status: 'analyzing' })
    try {
      // The classifier is best-effort: if it fails, the YOLO result still shows.
      const [result, verdict] = await Promise.all([
        detectBreedingPlaces(file),
        classifyBreedingSite(file).catch(() => null),
      ])
      if (request === requestRef.current) setAnalysis({ status: 'complete', result, verdict })
    } catch (error) {
      const message = error instanceof Error ? error.message : 'The image could not be analyzed.'
      if (request === requestRef.current) setAnalysis({ status: 'error', message })
    }
  }

  function handleFile(event: ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0]
    if (file) void analyze(file)
    event.target.value = ''
  }

  function handleDrop(event: DragEvent<HTMLDivElement>) {
    event.preventDefault()
    setDragging(false)
    const file = event.dataTransfer.files[0]
    if (file) void analyze(file)
  }

  function reset() {
    requestRef.current += 1
    setPreviewUrl(null)
    setFileName('')
    setHovered(null)
    setSelected(null)
    setAnalysis({ status: 'idle' })
  }

  if (auth.loading) {
    return <div className="grid h-full place-items-center bg-bg text-muted">Checking access…</div>
  }
  if (!auth.user) return <Navigate to="/login" replace />
  if (!auth.isStaff) return <Navigate to="/denied" replace />

  const analyzing = analysis.status === 'analyzing'
  const result = analysis.status === 'complete' ? analysis.result : null
  const verdict = analysis.status === 'complete' ? analysis.verdict : null
  const detections = result?.detections ?? []
  const activeDetection = hovered ?? selected

  const step = result ? 2 : analyzing ? 1 : 0

  return (
    // On desktop the workspace is exactly one screen tall: the photo shrinks to
    // the room it has and the results rail scrolls internally, so the whole
    // inspection - photo, verdict, findings, guide - is visible at once.
    <div className="analyze-page flex min-h-full flex-col bg-bg">
      <AppHeader />
      <main
        id="main-content"
        tabIndex={-1}
        className="analysis-workspace mx-auto flex w-full max-w-[1520px] min-h-0 flex-1 flex-col gap-4 px-4 py-4 lg:px-8"
      >
        <div className="analyze-heading">
          <div className="min-w-0">
            <h1>A clearer picture. A safer community.</h1>
            <p>Find potential mosquito breeding spots in a photo, one inspection at a time.</p>
          </div>
          <div className="analyze-heading-aside">
            <ol className="analysis-steps" aria-label="Analysis progress">
              {['Choose a photo', 'Analyze the scene', 'Review findings'].map((label, index) => (
                <li
                  key={label}
                  className={index <= step ? 'is-active' : ''}
                  aria-current={index === step ? 'step' : undefined}
                >
                  <span>{index < step ? <IconCheck size={13} /> : index + 1}</span>
                  {label}
                </li>
              ))}
            </ol>
            <span className="privacy-badge">
              <IconCheck size={15} />
              Photos stay on your device
            </span>
          </div>
        </div>

        <div className="analyze-grid">
          {/* --------------------------------------------------- stage column */}
          <section className="analyze-stage overflow-hidden rounded-panel border border-border bg-surface shadow-sm">
            <div className="flex flex-wrap items-center gap-x-4 gap-y-2 border-b border-border px-4 py-3">
              <div className="min-w-0 mr-auto">
                <h2 className="font-semibold text-ink">Photo inspection</h2>
                {previewUrl ? null : (
                  <p className="mt-0.5 text-xs text-muted">
                    Analysis stays in this browser; the photo is not uploaded.
                  </p>
                )}
              </div>

              {/* The headline answers sit in the header of the photo they
                  describe, as one line of chips rather than two tall tiles. */}
              {analyzing ? <AnalyzeStatsSkeleton /> : null}
              {result ? <AnalyzeStats count={detections.length} verdict={verdict} /> : null}

              <div className="flex flex-wrap items-center gap-2">
                {previewUrl ? (
                  <Button variant="soft" icon={<IconRefresh size={16} />} onClick={reset}>
                    Start over
                  </Button>
                ) : null}
                <Button
                  variant={previewUrl ? 'secondary' : 'primary'}
                  icon={<IconUpload size={16} />}
                  loading={analyzing}
                  onClick={() => inputRef.current?.click()}
                >
                  {previewUrl ? 'Choose another' : 'Choose image'}
                </Button>
              </div>
              <input
                ref={inputRef}
                type="file"
                accept="image/jpeg,image/png,image/webp"
                className="sr-only"
                tabIndex={-1}
                aria-label="Choose a site photo"
                onChange={handleFile}
              />
            </div>

            {previewUrl ? (
              <div className="analyze-stage-body arid-stage-grid bg-sunken">
                {/* A size container: the photo is capped by the space left in
                    the screen, not by a fixed vh guess. */}
                <div className="analyze-photo-fit">
                  <div className="relative w-fit overflow-hidden rounded-card bg-black shadow-md ring-1 ring-black/10">
                    <img src={previewUrl} alt={fileName} className="analyze-photo block" />
                    {result
                      ? detections.map((detection, index) => (
                          <DetectionBox
                            key={`${detection.classId}-${index}`}
                            detection={detection}
                            result={result}
                            index={index}
                            active={activeDetection === index}
                            dimmed={activeDetection !== null && activeDetection !== index}
                          />
                        ))
                      : null}

                    {analyzing ? (
                      <div className="absolute inset-0 overflow-hidden bg-black/55">
                        {/* One moving element — a sweep down the frame, not a spinner farm. */}
                        <div
                          aria-hidden="true"
                          className="arid-scanline absolute inset-x-0 top-0 h-24 bg-gradient-to-b from-transparent via-white/25 to-transparent motion-reduce:hidden"
                        />
                        <div className="absolute inset-0 grid place-items-center px-4 text-white">
                          <div className="rounded-card border border-white/15 bg-black/55 px-5 py-4 text-center backdrop-blur-sm">
                            <IconScan size={26} className="mx-auto mb-2 motion-safe:animate-pulse" />
                            <p className="font-medium">Analyzing image…</p>
                            <p className="mt-1 text-xs text-white/75">
                              Keep this tab open. The first analysis may take a little longer.
                            </p>
                          </div>
                        </div>
                      </div>
                    ) : null}
                  </div>
                </div>
              </div>
            ) : (
              <div className="analyze-stage-body p-4">
                <div
                  className={`upload-zone grid h-full place-items-center rounded-card border-2 border-dashed p-6 transition-[background-color,border-color,transform] duration-(--duration-base) ease-(--ease-out-quart) ${
                    dragging
                      ? 'scale-[0.995] border-primary bg-primary-50'
                      : 'arid-stage-grid border-border-strong/45 bg-panel'
                  }`}
                  onDragEnter={() => setDragging(true)}
                  onDragLeave={() => setDragging(false)}
                  onDragOver={(event) => event.preventDefault()}
                  onDrop={handleDrop}
                >
                  <div className="max-w-sm text-center">
                    <span
                      className={`mx-auto mb-4 grid size-14 place-items-center rounded-full text-primary transition-colors duration-(--duration-base) ${
                        dragging ? 'bg-primary-100' : 'bg-primary-50'
                      }`}
                    >
                      <IconUpload size={24} />
                    </span>
                    <p className="text-lg font-semibold text-ink">
                      {dragging ? 'Drop to analyze' : 'Drop a site photo here'}
                    </p>
                    <p className="mt-1.5 text-sm text-muted">
                      or use <span className="font-medium text-ink-2">Choose image</span> · JPG,
                      PNG, WebP · 15 MB max
                    </p>
                    <Button
                      className="mt-5"
                      variant="primary"
                      icon={<IconUpload size={16} />}
                      onClick={() => inputRef.current?.click()}
                    >
                      Browse photos
                    </Button>
                    <p className="mt-3 text-xs text-muted">
                      No upload. No photo storage. Just a local analysis.
                    </p>

                    <div className="mt-6 border-t border-border pt-5">
                      <p className="text-xs font-medium text-muted">Detects</p>
                      <ul className="mt-2.5 flex flex-wrap justify-center gap-1.5">
                        {DETECTION_CLASSES.map((label, classId) => (
                          <li
                            key={label}
                            className="flex items-center gap-1.5 rounded-full border border-border bg-surface px-2.5 py-1 text-xs font-medium text-ink-2 shadow-xs"
                          >
                            <span
                              className="size-2 rounded-full"
                              style={{ backgroundColor: BOX_COLORS[classId] }}
                            />
                            {label}
                          </li>
                        ))}
                      </ul>
                    </div>
                  </div>
                </div>
              </div>
            )}
          </section>

          {/* ------------------------------------------------------ results */}
          <aside className="analyze-rail" aria-label="Analysis results">
            <AnalyzeGuide status={analysis.status} count={detections.length} />
            {analysis.status === 'error' ? (
              <Alert tone="error" live icon={<IconAlert size={16} />}>
                {analysis.message}
              </Alert>
            ) : null}

            <section className="analyze-results overflow-hidden rounded-panel border border-border bg-surface shadow-sm">
              <div className="flex shrink-0 items-center justify-between gap-3 border-b border-border px-4 py-3">
                <h2 className="text-sm font-semibold text-ink">Detection result</h2>
                {result && detections.length === 0 ? (
                  <span
                    data-numeric
                    className="rounded-full bg-risk-green-tint px-2 py-0.5 text-xs font-semibold text-risk-green-ink"
                  >
                    0 found
                  </span>
                ) : null}
              </div>

              {/* Only this body scrolls, so a photo with many boxes never
                  pushes the rest of the workspace off screen. */}
              <div className="analyze-results-body">
                {analyzing ? (
                  <div className="space-y-3 p-4" aria-live="polite" aria-busy="true">
                    <span className="sr-only">Analyzing image</span>
                    <Skeleton className="h-14 w-full" />
                    <Skeleton className="h-9 w-full" />
                    <Skeleton className="h-9 w-4/5" />
                  </div>
                ) : analysis.status === 'idle' || analysis.status === 'error' ? (
                  <EmptyState icon={<IconScan size={20} />} title="Waiting for an image">
                    The detector recognizes bottles, coconut exocarps, drain inlets, tires, and
                    vases.
                  </EmptyState>
                ) : result && detections.length === 0 ? (
                  <EmptyState icon={<IconImageOff size={20} />} title="No potential breeding spot found">
                    Nothing exceeded the 25% confidence threshold. This does not prove the area is
                    risk-free.
                  </EmptyState>
                ) : result ? (
                  <div className="p-4">
                    <div
                      role="status"
                      className="flex items-start gap-3 rounded-card border border-alert-edge bg-alert-tint p-3"
                    >
                      <span className="grid size-8 shrink-0 place-items-center rounded-full bg-alert-solid text-white shadow-xs">
                        <IconMosquito size={18} />
                      </span>
                      <div className="min-w-0">
                        <p className="font-semibold text-alert-ink">
                          {detections.length} potential mosquito breeding{' '}
                          {detections.length === 1 ? 'spot' : 'spots'} found
                        </p>
                        <p className="mt-0.5 text-xs text-alert-ink/90">
                          Each box marks a container that can hold standing water. Inspect on site
                          before clearing.
                        </p>
                      </div>
                    </div>

                    <ul className="mt-3 space-y-1">
                      {detections.map((detection, index) => {
                        const color = BOX_COLORS[detection.classId] ?? BOX_COLORS[0]
                        const percent = Math.round(detection.confidence * 100)
                        return (
                          <li
                            key={`${detection.classId}-${index}`}
                            // Hover mirrors the row onto its box. An aid only —
                            // every value here is also printed on the overlay.
                            onMouseEnter={() => setHovered(index)}
                            onMouseLeave={() => setHovered(null)}
                            className={`rounded-control transition-colors duration-(--duration-fast) ease-(--ease-out-quart) ${
                              activeDetection === index ? 'bg-sunken' : ''
                            }`}
                          >
                            <button
                              type="button"
                              className="w-full rounded-control px-2 py-2 text-left"
                              aria-pressed={selected === index}
                              aria-label={`Highlight ${detection.label} ${index + 1}, ${percent}% confidence`}
                              onClick={() => setSelected(selected === index ? null : index)}
                              onFocus={() => setHovered(index)}
                              onBlur={() => setHovered(null)}
                            >
                              <div className="flex items-center gap-2.5">
                                <span
                                  data-numeric
                                  className="grid size-5 shrink-0 place-items-center rounded-[5px] text-xs font-semibold"
                                  style={{ backgroundColor: color, color: labelInk(color) }}
                                >
                                  {index + 1}
                                </span>
                                <span className="min-w-0 flex-1 truncate font-medium text-ink">
                                  {detection.label}
                                </span>
                                <span data-numeric className="text-sm font-semibold text-ink-2">
                                  {percent}%
                                </span>
                              </div>
                              <div
                                className="ml-[1.875rem] mt-1.5 h-1 overflow-hidden rounded-full bg-sunken"
                                aria-hidden="true"
                              >
                                <div
                                  className="h-full rounded-full transition-[width] duration-(--duration-slow) ease-(--ease-out-quart)"
                                  style={{ width: `${percent}%`, backgroundColor: color }}
                                />
                              </div>
                            </button>
                          </li>
                        )
                      })}
                    </ul>

                    <p className="mt-3 flex items-center gap-1.5 border-t border-border pt-3 text-xs text-muted">
                      <IconCheck size={14} />
                      Inference completed in {Math.round(result.inferenceMs)} ms
                    </p>
                  </div>
                ) : null}
              </div>

              {/* The caveat and the model facts belong to the result, so they
                  close its card instead of standing as two more boxes. */}
              <div className="shrink-0 border-t border-border bg-panel px-4 py-3 text-xs text-muted">
                <p className="flex gap-2">
                  <IconInfo size={15} className="mt-px shrink-0 text-primary-ink" />
                  <span>
                    A detection is a{' '}
                    <strong className="font-semibold text-ink-2">potential breeding spot</strong>,
                    not confirmation of stagnant water, larvae, or mosquitoes. Verify in the field.
                  </span>
                </p>
                <details className="mt-2 pl-[23px]">
                  <summary className="font-semibold text-ink-2">About this analysis</summary>
                  <dl className="mt-2 space-y-1">
                    {[
                      ['Architecture', 'YOLOv5s'],
                      ['Input', '640 × 640'],
                      ['Test mAP@50', '90.7%'],
                      ['Test mAP@50–95', '68.3%'],
                    ].map(([term, value]) => (
                      <div key={term} className="flex items-baseline gap-3">
                        <dt className="shrink-0">{term}</dt>
                        {/* Leader rule, so term and value stay readable as a pair. */}
                        <span className="h-px min-w-4 flex-1 bg-border" aria-hidden="true" />
                        <dd data-numeric className="shrink-0 font-medium text-ink-2">
                          {value}
                        </dd>
                      </div>
                    ))}
                  </dl>
                </details>
              </div>
            </section>
          </aside>
        </div>
      </main>
    </div>
  )
}
