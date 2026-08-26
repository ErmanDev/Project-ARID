import type { InferenceSession, Tensor } from 'onnxruntime-web'

export const DETECTION_CLASSES = [
  'Bottle',
  'Coconut-Exocarp',
  'Drain-Inlet',
  'Tire',
  'Vase',
] as const

export type DetectionClass = (typeof DETECTION_CLASSES)[number]

export type Detection = {
  classId: number
  label: DetectionClass
  confidence: number
  x: number
  y: number
  width: number
  height: number
}

export type DetectionResult = {
  detections: Detection[]
  imageWidth: number
  imageHeight: number
  inferenceMs: number
}

const MODEL_URL = '/models/medsam_yolov5s.onnx'
const INPUT_SIZE = 640
const CONFIDENCE_THRESHOLD = 0.25
const IOU_THRESHOLD = 0.45
const MAX_DETECTIONS = 100

type OrtRuntime = typeof import('onnxruntime-web')

let runtimePromise: Promise<OrtRuntime> | null = null
let sessionPromise: Promise<InferenceSession> | null = null

function loadRuntime(): Promise<OrtRuntime> {
  runtimePromise ??= import('onnxruntime-web')
  return runtimePromise
}

function loadSession(): Promise<InferenceSession> {
  if (!sessionPromise) {
    sessionPromise = loadRuntime()
      .then((ort) => {
        // Firebase Hosting does not set cross-origin isolation headers by default.
        // A single WASM thread works consistently without SharedArrayBuffer.
        ort.env.wasm.numThreads = 1
        return ort.InferenceSession.create(MODEL_URL, {
          executionProviders: ['wasm'],
          graphOptimizationLevel: 'all',
        })
      })
      .catch((error: unknown) => {
        sessionPromise = null
        throw error
      })
  }
  return sessionPromise
}

function clamp(value: number, low: number, high: number): number {
  return Math.min(Math.max(value, low), high)
}

function intersectionOverUnion(a: Detection, b: Detection): number {
  const left = Math.max(a.x, b.x)
  const top = Math.max(a.y, b.y)
  const right = Math.min(a.x + a.width, b.x + b.width)
  const bottom = Math.min(a.y + a.height, b.y + b.height)
  const intersection = Math.max(0, right - left) * Math.max(0, bottom - top)
  const union = a.width * a.height + b.width * b.height - intersection
  return union > 0 ? intersection / union : 0
}

function nonMaximumSuppression(candidates: Detection[]): Detection[] {
  const ordered = [...candidates].sort((a, b) => b.confidence - a.confidence)
  const kept: Detection[] = []

  for (const candidate of ordered) {
    const overlaps = kept.some(
      (existing) =>
        existing.classId === candidate.classId &&
        intersectionOverUnion(existing, candidate) > IOU_THRESHOLD,
    )
    if (!overlaps) kept.push(candidate)
    if (kept.length >= MAX_DETECTIONS) break
  }

  return kept
}

async function prepareInput(file: File, ort: OrtRuntime): Promise<{
  tensor: Tensor
  imageWidth: number
  imageHeight: number
  scale: number
  padX: number
  padY: number
}> {
  const bitmap = await createImageBitmap(file)
  try {
    const canvas = document.createElement('canvas')
    canvas.width = INPUT_SIZE
    canvas.height = INPUT_SIZE
    const context = canvas.getContext('2d', { willReadFrequently: true })
    if (!context) throw new Error('Your browser could not prepare the image.')

    const scale = Math.min(INPUT_SIZE / bitmap.width, INPUT_SIZE / bitmap.height)
    const renderedWidth = bitmap.width * scale
    const renderedHeight = bitmap.height * scale
    const padX = (INPUT_SIZE - renderedWidth) / 2
    const padY = (INPUT_SIZE - renderedHeight) / 2

    context.fillStyle = 'rgb(114, 114, 114)'
    context.fillRect(0, 0, INPUT_SIZE, INPUT_SIZE)
    context.drawImage(bitmap, padX, padY, renderedWidth, renderedHeight)

    const rgba = context.getImageData(0, 0, INPUT_SIZE, INPUT_SIZE).data
    const plane = INPUT_SIZE * INPUT_SIZE
    const input = new Float32Array(plane * 3)
    for (let pixel = 0; pixel < plane; pixel += 1) {
      const rgbaOffset = pixel * 4
      input[pixel] = rgba[rgbaOffset] / 255
      input[plane + pixel] = rgba[rgbaOffset + 1] / 255
      input[plane * 2 + pixel] = rgba[rgbaOffset + 2] / 255
    }

    return {
      tensor: new ort.Tensor('float32', input, [1, 3, INPUT_SIZE, INPUT_SIZE]),
      imageWidth: bitmap.width,
      imageHeight: bitmap.height,
      scale,
      padX,
      padY,
    }
  } finally {
    bitmap.close()
  }
}

export async function detectBreedingPlaces(file: File): Promise<DetectionResult> {
  const ort = await loadRuntime()
  const [session, prepared] = await Promise.all([loadSession(), prepareInput(file, ort)])
  const startedAt = performance.now()
  const outputs = await session.run({ [session.inputNames[0]]: prepared.tensor })
  const inferenceMs = performance.now() - startedAt
  const output = outputs[session.outputNames[0]]

  if (!output || output.dims.length !== 3 || output.dims[2] < 10) {
    throw new Error('The detection model returned an unexpected result shape.')
  }

  const data = output.data as Float32Array
  const rows = output.dims[1]
  const columns = output.dims[2]
  const candidates: Detection[] = []

  for (let row = 0; row < rows; row += 1) {
    const offset = row * columns
    const objectness = data[offset + 4]
    if (objectness < CONFIDENCE_THRESHOLD) continue

    let classId = 0
    let classProbability = data[offset + 5]
    for (let index = 1; index < DETECTION_CLASSES.length; index += 1) {
      const probability = data[offset + 5 + index]
      if (probability > classProbability) {
        classId = index
        classProbability = probability
      }
    }

    const confidence = objectness * classProbability
    if (confidence < CONFIDENCE_THRESHOLD) continue

    const centerX = data[offset]
    const centerY = data[offset + 1]
    const boxWidth = data[offset + 2]
    const boxHeight = data[offset + 3]
    const left = clamp(
      (centerX - boxWidth / 2 - prepared.padX) / prepared.scale,
      0,
      prepared.imageWidth,
    )
    const top = clamp(
      (centerY - boxHeight / 2 - prepared.padY) / prepared.scale,
      0,
      prepared.imageHeight,
    )
    const right = clamp(
      (centerX + boxWidth / 2 - prepared.padX) / prepared.scale,
      0,
      prepared.imageWidth,
    )
    const bottom = clamp(
      (centerY + boxHeight / 2 - prepared.padY) / prepared.scale,
      0,
      prepared.imageHeight,
    )

    if (right <= left || bottom <= top) continue
    candidates.push({
      classId,
      label: DETECTION_CLASSES[classId],
      confidence,
      x: left,
      y: top,
      width: right - left,
      height: bottom - top,
    })
  }

  return {
    detections: nonMaximumSuppression(candidates),
    imageWidth: prepared.imageWidth,
    imageHeight: prepared.imageHeight,
    inferenceMs,
  }
}
