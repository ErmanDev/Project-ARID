import type * as tf from '@tensorflow/tfjs'

/** Order matches `labels` in public/models/arid-classifier/metadata.json. */
export const CLASSIFIER_LABELS = ['Breeding', 'Non Breeding'] as const

export type ClassifierLabel = (typeof CLASSIFIER_LABELS)[number]

export type ClassificationResult = {
  label: ClassifierLabel
  confidence: number
  /** Probability per class, indexed like CLASSIFIER_LABELS. */
  probabilities: number[]
}

const MODEL_URL = '/models/arid-classifier/model.json'
const INPUT_SIZE = 224

type TfRuntime = typeof import('@tensorflow/tfjs')

// TensorFlow.js is ~1.3 MB minified, so it is loaded on first use only,
// mirroring how yolo.ts lazy-loads onnxruntime-web.
let runtimePromise: Promise<TfRuntime> | null = null
let modelPromise: Promise<tf.LayersModel> | null = null

function loadRuntime(): Promise<TfRuntime> {
  runtimePromise ??= import('@tensorflow/tfjs')
  return runtimePromise
}

function loadModel(): Promise<tf.LayersModel> {
  if (!modelPromise) {
    modelPromise = loadRuntime()
      .then((runtime) => runtime.loadLayersModel(MODEL_URL))
      .catch((error: unknown) => {
        modelPromise = null
        throw error
      })
  }
  return modelPromise
}

/**
 * Runs the Teachable Machine breeding-site classifier on a photo.
 * This is the same model the mobile app ships as arid_model.tflite,
 * exported in TensorFlow.js format.
 */
export async function classifyBreedingSite(file: File): Promise<ClassificationResult> {
  const [runtime, model] = await Promise.all([loadRuntime(), loadModel()])
  const bitmap = await createImageBitmap(file)
  try {
    const scores = runtime.tidy(() => {
      const input = runtime.browser
        .fromPixels(bitmap)
        .resizeBilinear([INPUT_SIZE, INPUT_SIZE])
        .toFloat()
        // Teachable Machine models expect pixels normalized to [-1, 1].
        .div(127.5)
        .sub(1)
        .expandDims(0)
      return model.predict(input) as tf.Tensor
    })
    try {
      const probabilities = Array.from(await scores.data())
      let best = 0
      for (let index = 1; index < CLASSIFIER_LABELS.length; index += 1) {
        if (probabilities[index] > probabilities[best]) best = index
      }
      return {
        label: CLASSIFIER_LABELS[best],
        confidence: probabilities[best],
        probabilities,
      }
    } finally {
      scores.dispose()
    }
  } finally {
    bitmap.close()
  }
}
