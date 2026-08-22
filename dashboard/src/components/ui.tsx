/**
 * Shared control vocabulary for the dashboard.
 *
 * The rule this file exists to enforce: one button shape, one input shape, one
 * focus treatment, one disabled treatment, everywhere. Every interactive
 * primitive here ships default / hover / focus-visible / active / disabled and,
 * where it can be async, loading.
 */

import {
  useEffect,
  useState,
  forwardRef,
  useId,
  type ButtonHTMLAttributes,
  type InputHTMLAttributes,
  type ReactNode,
  type SelectHTMLAttributes,
} from 'react'
import {
  IconAlert,
  IconCheck,
  IconChevronDown,
  IconCopy,
  IconInfo,
  IconSpinner,
} from './icons'

/* ------------------------------------------------------------------ Button */

type ButtonVariant = 'primary' | 'secondary' | 'ghost'
type ButtonSize = 'sm' | 'md'

const BUTTON_BASE =
  'tap relative inline-flex items-center justify-center gap-2 rounded-control font-medium ' +
  'transition-[background-color,border-color,color,box-shadow] duration-(--duration-fast) ' +
  'ease-(--ease-out-quart) select-none disabled:pointer-events-none disabled:opacity-55'

const BUTTON_VARIANT: Record<ButtonVariant, string> = {
  primary:
    'bg-primary text-white shadow-xs hover:bg-primary-600 active:bg-primary-700',
  secondary:
    'border border-border-strong/70 bg-surface text-ink shadow-xs ' +
    'hover:border-border-strong hover:bg-sunken active:bg-sunken/80',
  ghost: 'text-primary-ink hover:bg-primary-50 active:bg-primary-100',
}

const BUTTON_SIZE: Record<ButtonSize, string> = {
  sm: 'h-8 px-2.5 text-sm',
  md: 'h-10 px-4 text-base',
}

/**
 * For elements that must not be a <button> — a router <Link>, an <a> — so they
 * can share the exact button vocabulary without nesting interactive elements.
 */
export function buttonClasses(
  variant: ButtonVariant = 'secondary',
  size: ButtonSize = 'md',
): string {
  return `${BUTTON_BASE} ${BUTTON_VARIANT[variant]} ${BUTTON_SIZE[size]}`
}

type ButtonProps = ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: ButtonVariant
  size?: ButtonSize
  loading?: boolean
  block?: boolean
  icon?: ReactNode
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  function Button(
    {
      variant = 'secondary',
      size = 'md',
      loading = false,
      block = false,
      icon,
      children,
      className = '',
      disabled,
      type = 'button',
      ...rest
    },
    ref,
  ) {
    return (
      <button
        ref={ref}
        type={type}
        disabled={disabled || loading}
        aria-busy={loading || undefined}
        className={`${BUTTON_BASE} ${BUTTON_VARIANT[variant]} ${BUTTON_SIZE[size]} ${
          block ? 'w-full' : ''
        } ${className}`}
        {...rest}
      >
        {/* Label keeps its box while busy so the button never changes width. */}
        <span
          className={`inline-flex items-center gap-2 ${loading ? 'invisible' : ''}`}
        >
          {icon}
          {children}
        </span>
        {loading ? (
          <span className="absolute inset-0 grid place-items-center">
            <IconSpinner size={size === 'sm' ? 14 : 16} />
          </span>
        ) : null}
      </button>
    )
  },
)

/* ------------------------------------------------------------------- Field */

/**
 * Every input gets a real, visible <label>. Placeholder-as-label fails for
 * screen readers and disappears the moment the user starts typing.
 */
export function Field({
  label,
  hint,
  error,
  children,
  id,
}: {
  label: string
  hint?: string
  error?: string
  id: string
  children: (props: {
    id: string
    'aria-describedby': string | undefined
    'aria-invalid': true | undefined
  }) => ReactNode
}) {
  const hintId = hint ? `${id}-hint` : undefined
  const errorId = error ? `${id}-error` : undefined
  const describedBy = [hintId, errorId].filter(Boolean).join(' ') || undefined

  return (
    <div className="space-y-1.5">
      <label htmlFor={id} className="block text-sm font-medium text-ink-2">
        {label}
      </label>
      {children({
        id,
        'aria-describedby': describedBy,
        'aria-invalid': error ? true : undefined,
      })}
      {hint && !error ? (
        <p id={hintId} className="text-xs text-muted">
          {hint}
        </p>
      ) : null}
      {error ? (
        <p id={errorId} className="text-xs font-medium text-risk-red-ink">
          {error}
        </p>
      ) : null}
    </div>
  )
}

const CONTROL_BASE =
  'w-full rounded-control border bg-surface px-3 text-base text-ink ' +
  'transition-[border-color,box-shadow] duration-(--duration-fast) ease-(--ease-out-quart) ' +
  'disabled:cursor-not-allowed disabled:bg-sunken disabled:text-muted'

export const Input = forwardRef<HTMLInputElement, InputHTMLAttributes<HTMLInputElement>>(
  function Input({ className = '', ...rest }, ref) {
    return (
      <input
        ref={ref}
        className={`${CONTROL_BASE} h-10 border-border-strong/70 hover:border-border-strong aria-invalid:border-risk-red-solid ${className}`}
        {...rest}
      />
    )
  },
)

/** Native select, deliberately. Custom dropdowns here would be reinvention. */
export function Select({
  label,
  className = '',
  children,
  ...rest
}: SelectHTMLAttributes<HTMLSelectElement> & { label: string }) {
  const id = useId()
  return (
    // Shrinkable and grow-to-fill on narrow viewports so a row of selects wraps
    // instead of pushing the document sideways; natural width from `sm` up.
    <div className="min-w-0 flex-1 basis-36 md:flex-none md:basis-auto">
      <label htmlFor={id} className="sr-only">
        {label}
      </label>
      <div className="relative">
        <select
          id={id}
          className={`tap h-9 w-full appearance-none rounded-control border border-border-strong/70 bg-surface pl-3 pr-8 text-base text-ink shadow-xs transition-colors duration-(--duration-fast) ease-(--ease-out-quart) hover:border-border-strong ${className}`}
          {...rest}
        >
          {children}
        </select>
        <IconChevronDown
          size={16}
          className="pointer-events-none absolute right-2 top-1/2 -translate-y-1/2 text-muted"
        />
      </div>
    </div>
  )
}

/* -------------------------------------------------------------- Segmented */

export type SegmentOption<T extends string> = {
  value: T
  label: ReactNode
  /** Rendered right-aligned in a dimmer weight. For counts. */
  meta?: ReactNode
  title?: string
}

/**
 * Single-select segmented control. Real radiogroup semantics, so arrow keys
 * and screen readers behave the way users expect from a filter.
 */
export function Segmented<T extends string>({
  options,
  value,
  onChange,
  label,
  className = '',
}: {
  options: SegmentOption<T>[]
  value: T
  onChange: (value: T) => void
  label: string
  className?: string
}) {
  return (
    <div
      role="radiogroup"
      aria-label={label}
      className={`inline-flex items-center gap-0.5 rounded-control border border-border bg-sunken p-0.5 shadow-xs ${className}`}
    >
      {options.map((option) => {
        const selected = option.value === value
        return (
          <button
            key={option.value}
            type="button"
            role="radio"
            aria-checked={selected}
            title={option.title}
            aria-label={option.title}
            onClick={() => onChange(option.value)}
            className={`tap focus-inset inline-flex items-center gap-1.5 rounded-[calc(var(--radius-control)-2px)] px-2.5 py-1 text-sm font-medium transition-[background-color,color,box-shadow] duration-(--duration-fast) ease-(--ease-out-quart) ${
              selected
                ? 'bg-surface text-ink shadow-xs'
                : 'text-muted hover:text-ink-2 active:bg-surface/60'
            }`}
          >
            {option.label}
            {option.meta !== undefined ? (
              <span
                data-numeric
                className={selected ? 'text-ink-2' : 'text-muted/80'}
              >
                {option.meta}
              </span>
            ) : null}
          </button>
        )
      })}
    </div>
  )
}

/** Independent on/off, for map layers. Toggle semantics, not radio. */
export function LayerToggle({
  pressed,
  onChange,
  icon,
  children,
  count,
}: {
  pressed: boolean
  onChange: (next: boolean) => void
  icon: ReactNode
  children: ReactNode
  count?: number
}) {
  return (
    <button
      type="button"
      aria-pressed={pressed}
      onClick={() => onChange(!pressed)}
      className={`tap inline-flex items-center gap-1.5 rounded-control border px-2.5 py-1.5 text-sm font-medium transition-[background-color,border-color,color] duration-(--duration-fast) ease-(--ease-out-quart) ${
        pressed
          ? 'border-primary-200 bg-primary-50 text-primary-ink hover:bg-primary-100'
          : 'border-border bg-surface text-muted hover:border-border-strong/60 hover:text-ink-2'
      }`}
    >
      <span className={pressed ? 'text-primary' : 'text-muted'}>{icon}</span>
      {children}
      {count !== undefined && count > 0 ? (
        <span data-numeric className="text-xs text-muted">
          {count}
        </span>
      ) : null}
    </button>
  )
}

/* -------------------------------------------------------------- Feedback */

type AlertTone = 'info' | 'notice' | 'warning' | 'error'

const ALERT_TONE: Record<AlertTone, { box: string; icon: string }> = {
  info: {
    box: 'border-primary-200 bg-primary-50 text-primary-ink',
    icon: 'text-primary',
  },
  notice: {
    box: 'border-risk-green-edge bg-risk-green-tint text-risk-green-ink',
    icon: 'text-risk-green-solid',
  },
  warning: {
    box: 'border-risk-yellow-edge bg-risk-yellow-tint text-risk-yellow-ink',
    icon: 'text-risk-yellow-solid',
  },
  error: {
    box: 'border-risk-red-edge bg-risk-red-tint text-risk-red-ink',
    icon: 'text-risk-red-solid',
  },
}

export function Alert({
  tone = 'info',
  icon,
  children,
  live = false,
  className = '',
}: {
  tone?: AlertTone
  icon?: ReactNode
  children: ReactNode
  /** Announce to assistive tech when it appears mid-session. */
  live?: boolean
  className?: string
}) {
  const style = ALERT_TONE[tone]
  return (
    <div
      role={live ? 'alert' : undefined}
      className={`flex items-start gap-2.5 rounded-control border px-3 py-2 text-sm ${style.box} ${className}`}
    >
      <span className={`mt-px shrink-0 ${style.icon}`}>
        {icon ?? (tone === 'info' ? <IconInfo size={16} /> : <IconAlert size={16} />)}
      </span>
      <div className="min-w-0 [&_code]:rounded [&_code]:bg-black/5 [&_code]:px-1 [&_code]:py-0.5 [&_code]:text-xs">
        {children}
      </div>
    </div>
  )
}

/** Section label for the side panel. Consistent altitude for every group. */
export function SectionHeading({
  children,
  aside,
}: {
  children: ReactNode
  aside?: ReactNode
}) {
  return (
    <div className="mb-2.5 flex items-baseline justify-between gap-3">
      <h2 className="text-sm font-semibold text-ink">{children}</h2>
      {aside ? <div className="text-xs text-muted">{aside}</div> : null}
    </div>
  )
}

/**
 * Copy-to-clipboard with confirmation in place. The label swaps to "Copied" for
 * a moment and announces politely; a silent copy leaves people clicking twice.
 */
export function CopyButton({
  value,
  label = 'Copy',
  size = 'sm',
  variant = 'secondary',
}: {
  value: string
  label?: string
  size?: ButtonSize
  variant?: ButtonVariant
}) {
  const [state, setState] = useState<'idle' | 'copied' | 'failed'>('idle')

  useEffect(() => {
    if (state === 'idle') return
    const id = window.setTimeout(() => setState('idle'), 2000)
    return () => window.clearTimeout(id)
  }, [state])

  async function copy() {
    try {
      await navigator.clipboard.writeText(value)
      setState('copied')
    } catch {
      // Clipboard access can be blocked outright; say so rather than no-op.
      setState('failed')
    }
  }

  return (
    <Button
      size={size}
      variant={variant}
      onClick={() => void copy()}
      icon={state === 'copied' ? <IconCheck size={15} /> : <IconCopy size={15} />}
    >
      <span aria-live="polite">
        {state === 'copied' ? 'Copied' : state === 'failed' ? 'Press Ctrl+C' : label}
      </span>
    </Button>
  )
}

/** Content-shaped placeholder. Never a centred spinner inside a panel. */
export function Skeleton({ className = '' }: { className?: string }) {
  return (
    <div
      className={`motion-safe:animate-pulse rounded-md bg-border/70 ${className}`}
    />
  )
}

/** Empty state that teaches the interface rather than saying "no data". */
export function EmptyState({
  icon,
  title,
  children,
}: {
  icon: ReactNode
  title: string
  children?: ReactNode
}) {
  return (
    <div className="flex flex-col items-center px-4 py-6 text-center">
      <span className="mb-3 grid size-10 place-items-center rounded-full bg-sunken text-muted">
        {icon}
      </span>
      <p className="text-base font-medium text-ink">{title}</p>
      {children ? (
        <p className="mt-1 max-w-[38ch] text-sm text-muted">{children}</p>
      ) : null}
    </div>
  )
}
