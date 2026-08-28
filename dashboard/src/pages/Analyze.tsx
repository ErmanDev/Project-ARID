import { useEffect, useRef, useState, type ChangeEvent, type DragEvent } from 'react'
import { Link, Navigate } from 'react-router-dom'
import { useAuth } from '../auth'
import {
  IconAlert,
  IconArrowLeft,
  IconCheck,
  IconImageOff,
  IconInfo,
  IconMosquito,
  IconScan,
  IconUpload,
} from '../components/icons'
import { Alert, Button, buttonClasses, EmptyState, Skeleton } from '../components/ui'
import { ThemeToggle } from '../components/ThemeToggle'
import {
  detectBreedingPlaces,
  DETECTION_CLASSES,
  type Detection,
  type DetectionResult,
} from '../services/detection/yolo'

const MAX_FILE_SIZE = 15 * 1024 * 1024

/**
 * One hue per class, indexed by classId. These sit on photographs rather than
 * on a token surface, so they run more saturated than the app palette and are
 * spaced far enough apart in hue to stay separable when boxes overlap.
 */
const BOX_COLORS = ['#3d8ea8', '#c9832b', '#7a72e6', '#d05a60', '#4fa27a']

type AnalysisState =
  | { status: 'idle' }
  | { status: 'analyzing' }
  | { status: 'complete'; result: DetectionResult }
  | { status: 'error'; message: string }

function formatBytes(bytes: number): string {
  return bytes >= 1024 * 1024
    ? `${(bytes / (1024 * 1024)).toFixed(1)} MB`
    : `${Math.max(1, Math.round(bytes / 1024))} KB`
}

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
        className={`absolute left-[-2px] flex items-center gap-1 whitespace-nowrap rounded-[5px] px-1.5 py-0.5 text-xs font-semibold text-white shadow-sm ${
          labelInside ? 'top-1 ml-1' : '-top-1 -translate-y-full'
        }`}
        style={{ backgroundColor: color }}
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
  const [previewUrl, setPreviewUrl] = useState<string | null>(null)
  const [fileName, setFileName] = useState('')
  const [fileSize, setFileSize] = useState(0)
  const [analysis, setAnalysis] = useState<AnalysisState>({ status: 'idle' })
  const [dragging, setDragging] = useState(false)
  const [hovered, setHovered] = useState<number | null>(null)

  useEffect(
    () => () => {
      if (previewUrl) URL.revokeObjectURL(previewUrl)
    },
    [previewUrl],
  )

  async function analyze(file: File) {
    if (!file.type.startsWith('image/')) {
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
    setFileSize(file.size)
    setHovered(null)
    setAnalysis({ status: 'analyzing' })
    try {
      const result = await detectBreedingPlaces(file)
      setAnalysis({ status: 'complete', result })
    } catch (error) {
      const message = error instanceof Error ? error.message : 'The image could not be analyzed.'
      setAnalysis({ status: 'error', message })
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

  if (auth.loading) {
    return <div className="grid h-full place-items-center bg-bg text-muted">Checking access…</div>
  }
  if (!auth.user) return <Navigate to="/login" replace />
  if (!auth.isStaff) return <Navigate to="/denied" replace />

  const analyzing = analysis.status === 'analyzing'
  const result = analysis.status === 'complete' ? analysis.result : null
  const detections = result?.detections ?? []
  const topConfidence = detections.reduce((best, item) => Math.max(best, item.confidence), 0)

  return (
    <div className="min-h-full bg-bg">
      {/* Sticky, so the way back to Monitor survives a tall photo. */}
      <header className="sticky top-0 z-[var(--z-sticky)] border-b border-border bg-surface/85 backdrop-blur-md">
        <div className="mx-auto flex w-full max-w-7xl flex-wrap items-center justify-between gap-3 px-4 py-2.5 lg:px-6">
          <div className="flex min-w-0 items-center gap-3">
            <Link to="/" className={buttonClasses('ghost', 'sm')}>
              <IconArrowLeft size={16} />
              Monitor
            </Link>
            <div className="h-6 w-px bg-border" aria-hidden="true" />
            <div className="min-w-0">
              <h1 className="flex items-center gap-2 text-md font-semibold text-ink">
                Analyze image
                <span className="hidden rounded-full border border-border bg-panel px-2 py-0.5 text-xs font-medium text-muted sm:inline">
                  On-device
                </span>
              </h1>
              <p className="truncate text-xs text-muted">
                Potential mosquito breeding-spot detection
              </p>
            </div>
          </div>
          <ThemeToggle />
        </div>
      </header>

      <main className="mx-auto grid w-full max-w-7xl gap-5 p-4 lg:grid-cols-[minmax(0,1fr)_380px] lg:p-6">
        {/* -------------------------------------------------------- stage */}
        <section className="min-w-0 overflow-hidden rounded-panel border border-border bg-surface shadow-sm">
          <div className="flex flex-wrap items-center justify-between gap-x-4 gap-y-3 border-b border-border px-4 py-3">
            <div className="min-w-0">
              <h2 className="font-semibold text-ink">Photo inspection</h2>
              {previewUrl ? (
                <p className="mt-0.5 flex min-w-0 items-center gap-1.5 text-xs text-muted">
                  <span className="max-w-[22ch] truncate font-medium text-ink-2 sm:max-w-[36ch]">
                    {fileName}
                  </span>
                  <span aria-hidden="true">·</span>
                  <span data-numeric>{formatBytes(fileSize)}</span>
                  {result ? (
                    <>
                      <span aria-hidden="true">·</span>
                      <span data-numeric>
                        {result.imageWidth} × {result.imageHeight}
                      </span>
                    </>
                  ) : null}
                </p>
              ) : (
                <p className="mt-0.5 text-xs text-muted">
                  Analysis stays in this browser; the photo is not uploaded.
                </p>
              )}
            </div>
            <Button
              variant={previewUrl ? 'secondary' : 'primary'}
              icon={<IconUpload size={16} />}
              loading={analyzing}
              onClick={() => inputRef.current?.click()}
            >
              {previewUrl ? 'Choose another' : 'Choose image'}
            </Button>
            <input
              ref={inputRef}
              type="file"
              accept="image/jpeg,image/png,image/webp"
              className="sr-only"
              onChange={handleFile}
            />
          </div>

          {previewUrl ? (
            <div className="arid-stage-grid bg-sunken p-3 sm:p-5">
              <div className="relative mx-auto w-fit max-w-full overflow-hidden rounded-card bg-black shadow-md ring-1 ring-black/10">
                <img src={previewUrl} alt={fileName} className="block max-h-[68vh] max-w-full" />
                {result
                  ? detections.map((detection, index) => (
                      <DetectionBox
                        key={`${detection.classId}-${index}`}
                        detection={detection}
                        result={result}
                        index={index}
                        active={hovered === index}
                        dimmed={hovered !== null && hovered !== index}
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
                          The first run also loads the 27 MB model.
                        </p>
                      </div>
                    </div>
                  </div>
                ) : null}
              </div>

              {/* Legend appears only where there are boxes to explain. */}
              {result && detections.length > 0 ? (
                <ul className="mx-auto mt-4 flex w-fit max-w-full flex-wrap justify-center gap-x-4 gap-y-1.5">
                  {Array.from(new Set(detections.map((item) => item.classId))).map((classId) => (
                    <li key={classId} className="flex items-center gap-1.5 text-xs text-muted">
                      <span
                        className="size-2.5 rounded-[3px]"
                        style={{ backgroundColor: BOX_COLORS[classId] ?? BOX_COLORS[0] }}
                      />
                      {DETECTION_CLASSES[classId]}
                    </li>
                  ))}
                </ul>
              ) : null}
            </div>
          ) : (
            <div
              className={`m-4 grid min-h-96 place-items-center rounded-card border-2 border-dashed p-6 transition-[background-color,border-color,transform] duration-(--duration-base) ease-(--ease-out-quart) ${
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
                  or use <span className="font-medium text-ink-2">Choose image</span> · JPG, PNG,
                  WebP · 15 MB max
                </p>

                <div className="mt-6 border-t border-border pt-5">
                  <p className="text-xs font-medium uppercase tracking-wide text-muted">Detects</p>
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
          )}
        </section>

        {/* ------------------------------------------------------ results */}
        <aside className="space-y-4" aria-label="Analysis results">
          {analysis.status === 'error' ? (
            <Alert tone="error" live icon={<IconAlert size={16} />}>
              {analysis.message}
            </Alert>
          ) : null}

          <section className="overflow-hidden rounded-panel border border-border bg-surface shadow-sm">
            <div className="flex items-center justify-between gap-3 border-b border-border px-4 py-3">
              <h2 className="text-sm font-semibold text-ink">Detection result</h2>
              {/* Only the all-clear needs a badge here; a positive count is
                  carried by the tinted strip directly below, and two yellow
                  pills stacked would just be the same number twice. */}
              {result && detections.length === 0 ? (
                <span
                  data-numeric
                  className="rounded-full bg-risk-green-tint px-2 py-0.5 text-xs font-semibold text-risk-green-ink"
                >
                  0 found
                </span>
              ) : null}
            </div>

            {analyzing ? (
              // Content-shaped wait, so the panel holds its size instead of jumping.
              <div className="space-y-3 p-4" aria-live="polite" aria-busy="true">
                <span className="sr-only">Analyzing image</span>
                <Skeleton className="h-14 w-full" />
                <Skeleton className="h-9 w-full" />
                <Skeleton className="h-9 w-4/5" />
                <Skeleton className="h-9 w-3/5" />
              </div>
            ) : analysis.status === 'idle' || analysis.status === 'error' ? (
              <EmptyState icon={<IconScan size={20} />} title="Waiting for an image">
                The detector recognizes bottles, coconut exocarps, drain inlets, tires, and vases.
              </EmptyState>
            ) : result && detections.length === 0 ? (
              <EmptyState icon={<IconImageOff size={20} />} title="No potential breeding spot found">
                Nothing exceeded the 25% confidence threshold. This does not prove the area is
                risk-free.
              </EmptyState>
            ) : result ? (
              <div>
                {/* Summary strip: the three numbers worth reading first. Each
                    tile is tinted by what it means, not for decoration — the
                    finding is a warning, the score is the model speaking, the
                    timing is a completed run. Every pair is a token tint with
                    its matching `-ink`, so contrast holds in both themes.
                    gap-px over the border colour draws the hairlines without
                    a divider that would cut through the tints. */}
                <dl className="grid grid-cols-3 gap-px border-b border-border bg-border">
                  <div className="bg-alert-tint px-3 py-3 text-center">
                    <dd data-numeric className="text-xl font-semibold text-alert-ink">
                      {detections.length}
                    </dd>
                    <dt className="mt-0.5 text-xs text-alert-ink">Potential spots</dt>
                  </div>
                  <div className="bg-primary-50 px-3 py-3 text-center">
                    <dd data-numeric className="text-xl font-semibold text-primary-ink">
                      {Math.round(topConfidence * 100)}%
                    </dd>
                    <dt className="mt-0.5 text-xs text-primary-ink">Top score</dt>
                  </div>
                  <div className="bg-risk-green-tint px-3 py-3 text-center">
                    <dd data-numeric className="text-xl font-semibold text-risk-green-ink">
                      {Math.round(result.inferenceMs)}
                      <span className="ml-0.5 text-sm font-medium opacity-75">ms</span>
                    </dd>
                    <dt className="mt-0.5 text-xs text-risk-green-ink">Inference</dt>
                  </div>
                </dl>

                <div className="p-4">
                  {/* The headline finding. Deliberately not the shared Alert:
                      that strip is sized for a one-line aside, and this is the
                      sentence the operator reads first. The tile above gives
                      the number at a glance, so this one carries the meaning
                      and the caveat rather than repeating a bare count. */}
                  <div
                    role="status"
                    className="flex items-start gap-3 rounded-card border border-alert-edge bg-alert-tint p-3.5"
                  >
                    <span className="grid size-9 shrink-0 place-items-center rounded-full bg-alert-solid text-white shadow-xs">
                      <IconMosquito size={20} />
                    </span>
                    <div className="min-w-0">
                      <p className="text-base font-semibold text-alert-ink">
                        {detections.length} potential mosquito breeding{' '}
                        {detections.length === 1 ? 'spot' : 'spots'} found
                      </p>
                      <p className="mt-1 text-xs text-alert-ink/90">
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
                          className={`rounded-control px-2 py-2 transition-colors duration-(--duration-fast) ease-(--ease-out-quart) ${
                            hovered === index ? 'bg-sunken' : ''
                          }`}
                        >
                          <div className="flex items-center gap-2.5">
                            <span
                              data-numeric
                              className="grid size-5 shrink-0 place-items-center rounded-[5px] text-xs font-semibold text-white"
                              style={{ backgroundColor: color }}
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
                        </li>
                      )
                    })}
                  </ul>

                  <p className="mt-3 flex items-center gap-1.5 border-t border-border pt-3 text-xs text-muted">
                    <IconCheck size={14} />
                    Inference completed in {Math.round(result.inferenceMs)} ms
                  </p>
                </div>
              </div>
            ) : null}
          </section>

          <Alert tone="info" icon={<IconInfo size={16} />}>
            A detection is a <strong>potential mosquito breeding spot</strong>, not confirmation of
            stagnant water, larvae, or mosquitoes. Field verification is still required.
          </Alert>

          <section className="rounded-panel border border-border bg-panel p-4 text-sm text-muted">
            <h2 className="text-sm font-semibold text-ink">Model details</h2>
            <dl className="mt-3 space-y-1.5">
              {[
                ['Architecture', 'YOLOv5s'],
                ['Input', '640 × 640'],
                ['Test mAP@50', '90.4%'],
                ['Test mAP@50–95', '69.0%'],
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
          </section>
        </aside>
      </main>
    </div>
  )
}
