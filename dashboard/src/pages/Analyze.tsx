import { useEffect, useRef, useState, type ChangeEvent, type DragEvent } from 'react'
import { Link, Navigate } from 'react-router-dom'
import { useAuth } from '../auth'
import {
  IconAlert,
  IconArrowLeft,
  IconCheck,
  IconImageOff,
  IconScan,
  IconUpload,
} from '../components/icons'
import { Alert, Button, buttonClasses, EmptyState } from '../components/ui'
import { ThemeToggle } from '../components/ThemeToggle'
import {
  detectBreedingPlaces,
  type Detection,
  type DetectionResult,
} from '../services/detection/yolo'

const MAX_FILE_SIZE = 15 * 1024 * 1024
const BOX_COLORS = ['#4a7a8c', '#a06f34', '#64748b', '#b5555a', '#6b9080']

type AnalysisState =
  | { status: 'idle' }
  | { status: 'analyzing' }
  | { status: 'complete'; result: DetectionResult }
  | { status: 'error'; message: string }

function DetectionBox({ detection, result }: { detection: Detection; result: DetectionResult }) {
  const color = BOX_COLORS[detection.classId]
  return (
    <div
      className="pointer-events-none absolute border-2"
      style={{
        borderColor: color,
        left: `${(detection.x / result.imageWidth) * 100}%`,
        top: `${(detection.y / result.imageHeight) * 100}%`,
        width: `${(detection.width / result.imageWidth) * 100}%`,
        height: `${(detection.height / result.imageHeight) * 100}%`,
      }}
    >
      <span
        className="absolute -top-px left-[-2px] -translate-y-full whitespace-nowrap rounded-t px-1.5 py-0.5 text-xs font-semibold text-white shadow-sm"
        style={{ backgroundColor: color }}
      >
        {detection.label} {Math.round(detection.confidence * 100)}%
      </span>
    </div>
  )
}

export function AnalyzePage() {
  const auth = useAuth()
  const inputRef = useRef<HTMLInputElement>(null)
  const [previewUrl, setPreviewUrl] = useState<string | null>(null)
  const [fileName, setFileName] = useState('')
  const [analysis, setAnalysis] = useState<AnalysisState>({ status: 'idle' })
  const [dragging, setDragging] = useState(false)

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

  const result = analysis.status === 'complete' ? analysis.result : null
  const detections = result?.detections ?? []

  return (
    <div className="min-h-full bg-bg">
      <header className="flex flex-wrap items-center justify-between gap-3 border-b border-border bg-surface px-4 py-2.5">
        <div className="flex items-center gap-3">
          <Link to="/" className={buttonClasses('ghost', 'sm')}>
            <IconArrowLeft size={16} />
            Monitor
          </Link>
          <div className="h-6 w-px bg-border" aria-hidden="true" />
          <div>
            <h1 className="text-md font-semibold text-ink">Analyze image</h1>
            <p className="text-xs text-muted">Potential breeding-container detection</p>
          </div>
        </div>
        <ThemeToggle />
      </header>

      <main className="mx-auto grid w-full max-w-7xl gap-5 p-4 lg:grid-cols-[minmax(0,1fr)_360px] lg:p-6">
        <section className="min-w-0 overflow-hidden rounded-panel border border-border bg-surface shadow-sm">
          <div className="flex flex-wrap items-center justify-between gap-3 border-b border-border px-4 py-3">
            <div>
              <h2 className="font-semibold text-ink">Photo inspection</h2>
              <p className="mt-0.5 text-xs text-muted">
                Analysis stays in this browser; the photo is not uploaded.
              </p>
            </div>
            <Button
              variant="primary"
              icon={<IconUpload size={16} />}
              loading={analysis.status === 'analyzing'}
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
            <div className="bg-sunken p-3 sm:p-5">
              <div className="relative mx-auto w-fit max-w-full overflow-hidden rounded-card bg-black shadow-md">
                <img src={previewUrl} alt={fileName} className="block max-h-[68vh] max-w-full" />
                {result
                  ? detections.map((detection, index) => (
                      <DetectionBox
                        key={`${detection.classId}-${index}`}
                        detection={detection}
                        result={result}
                      />
                    ))
                  : null}
                {analysis.status === 'analyzing' ? (
                  <div className="absolute inset-0 grid place-items-center bg-black/55 text-white">
                    <div className="rounded-card bg-black/60 px-4 py-3 text-center backdrop-blur-sm">
                      <IconScan size={24} className="mx-auto mb-2 motion-safe:animate-pulse" />
                      <p className="font-medium">Analyzing image…</p>
                      <p className="mt-1 text-xs text-white/75">The first run also loads the 27 MB model.</p>
                    </div>
                  </div>
                ) : null}
              </div>
            </div>
          ) : (
            <div
              className={`m-4 grid min-h-96 place-items-center rounded-card border-2 border-dashed p-6 transition-colors ${
                dragging ? 'border-primary bg-primary-50' : 'border-border-strong/50 bg-panel'
              }`}
              onDragEnter={() => setDragging(true)}
              onDragLeave={() => setDragging(false)}
              onDragOver={(event) => event.preventDefault()}
              onDrop={handleDrop}
            >
              <div className="text-center">
                <span className="mx-auto mb-4 grid size-12 place-items-center rounded-full bg-primary-50 text-primary">
                  <IconUpload size={22} />
                </span>
                <p className="font-medium text-ink">Drop a site photo here</p>
                <p className="mt-1 text-sm text-muted">or use Choose image · JPG, PNG, WebP · 15 MB max</p>
              </div>
            </div>
          )}
        </section>

        <aside className="space-y-4" aria-label="Analysis results">
          {analysis.status === 'error' ? (
            <Alert tone="error" live icon={<IconAlert size={16} />}>
              {analysis.message}
            </Alert>
          ) : null}

          <section className="rounded-panel border border-border bg-surface p-4 shadow-sm">
            <h2 className="text-sm font-semibold text-ink">Detection result</h2>
            {analysis.status === 'idle' || analysis.status === 'analyzing' ? (
              <EmptyState icon={<IconScan size={20} />} title="Waiting for an image">
                The detector recognizes bottles, coconut exocarps, drain inlets, tires, and vases.
              </EmptyState>
            ) : result && detections.length === 0 ? (
              <EmptyState icon={<IconImageOff size={20} />} title="No target container found">
                Nothing exceeded the 25% confidence threshold. This does not prove the area is risk-free.
              </EmptyState>
            ) : result ? (
              <div className="mt-3 space-y-3">
                <Alert tone="warning" icon={<IconAlert size={16} />}>
                  {detections.length} potential breeding {detections.length === 1 ? 'container' : 'containers'} found.
                </Alert>
                <ul className="divide-y divide-border">
                  {detections.map((detection, index) => (
                    <li key={`${detection.classId}-${index}`} className="flex items-center gap-3 py-2.5">
                      <span
                        className="size-2.5 shrink-0 rounded-full"
                        style={{ backgroundColor: BOX_COLORS[detection.classId] }}
                      />
                      <span className="min-w-0 flex-1 font-medium text-ink">{detection.label}</span>
                      <span data-numeric className="text-sm font-semibold text-ink-2">
                        {Math.round(detection.confidence * 100)}%
                      </span>
                    </li>
                  ))}
                </ul>
                <p className="flex items-center gap-1.5 text-xs text-muted">
                  <IconCheck size={14} />
                  Inference completed in {Math.round(result.inferenceMs)} ms
                </p>
              </div>
            ) : null}
          </section>

          <Alert tone="info">
            A detected container is a <strong>potential breeding place</strong>, not confirmation of stagnant water, larvae, or mosquitoes. Field verification is still required.
          </Alert>

          <section className="rounded-panel border border-border bg-panel p-4 text-sm text-muted">
            <h2 className="font-semibold text-ink">Model details</h2>
            <dl className="mt-3 grid grid-cols-2 gap-x-3 gap-y-2">
              <dt>Architecture</dt><dd className="text-right text-ink-2">YOLOv5s</dd>
              <dt>Input</dt><dd className="text-right text-ink-2">640 × 640</dd>
              <dt>Test mAP@50</dt><dd className="text-right text-ink-2">90.4%</dd>
              <dt>Test mAP@50–95</dt><dd className="text-right text-ink-2">69.0%</dd>
            </dl>
          </section>
        </aside>
      </main>
    </div>
  )
}
