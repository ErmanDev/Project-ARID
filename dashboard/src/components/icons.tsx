/**
 * One icon family, one grid, one stroke weight. Inline so the dashboard keeps
 * zero icon dependencies and every glyph inherits currentColor.
 *
 * All icons are 24x24 viewBox, 1.75 stroke, round caps/joins, and render at
 * 16px (`sm`) or 18px (default) so they optically match 13-14px label text.
 */

type IconProps = {
  size?: number
  className?: string
}

function Svg({
  size = 18,
  className,
  children,
}: IconProps & { children: React.ReactNode }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={1.75}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
      focusable="false"
      className={className}
    >
      {children}
    </svg>
  )
}

export function IconPin(props: IconProps) {
  return (
    <Svg {...props}>
      <path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 1 1 16 0Z" />
      <circle cx="12" cy="10" r="2.75" />
    </Svg>
  )
}

export function IconLayers(props: IconProps) {
  return (
    <Svg {...props}>
      <path d="M12 3 3 8l9 5 9-5-9-5Z" />
      <path d="m3 14 9 5 9-5" />
    </Svg>
  )
}

export function IconHeat(props: IconProps) {
  return (
    <Svg {...props}>
      <circle cx="12" cy="12" r="2" />
      <circle cx="12" cy="12" r="6" strokeOpacity="0.6" />
      <circle cx="12" cy="12" r="9.5" strokeOpacity="0.3" />
    </Svg>
  )
}

export function IconHotspot(props: IconProps) {
  return (
    <Svg {...props}>
      <circle cx="12" cy="12" r="3.25" />
      <path d="M12 3v2.25M12 18.75V21M3 12h2.25M18.75 12H21M5.6 5.6l1.6 1.6M16.8 16.8l1.6 1.6M18.4 5.6l-1.6 1.6M7.2 16.8l-1.6 1.6" />
    </Svg>
  )
}

export function IconClose(props: IconProps) {
  return (
    <Svg {...props}>
      <path d="M18 6 6 18M6 6l12 12" />
    </Svg>
  )
}

export function IconCheck(props: IconProps) {
  return (
    <Svg {...props}>
      <path d="m4.5 12.5 5 5 10-11" />
    </Svg>
  )
}

export function IconAlert(props: IconProps) {
  return (
    <Svg {...props}>
      <path d="M12 3.5 2.5 20h19L12 3.5Z" />
      <path d="M12 9.5v4.25" />
      <circle cx="12" cy="17" r=".9" fill="currentColor" stroke="none" />
    </Svg>
  )
}

export function IconInfo(props: IconProps) {
  return (
    <Svg {...props}>
      <circle cx="12" cy="12" r="9" />
      <path d="M12 11v5.5" />
      <circle cx="12" cy="7.75" r=".9" fill="currentColor" stroke="none" />
    </Svg>
  )
}

export function IconOffline(props: IconProps) {
  return (
    <Svg {...props}>
      <path d="M2 4l20 16" />
      <path d="M5 12.5a10 10 0 0 1 3.2-2.15M2.5 8.5a14 14 0 0 1 4-2.6M17.8 13.3A10 10 0 0 0 21 12.5M21.5 8.5a14 14 0 0 0-9.9-3.4" />
      <path d="M8.5 16a5.5 5.5 0 0 1 3.5-1.5" />
      <circle cx="12" cy="19.5" r=".9" fill="currentColor" stroke="none" />
    </Svg>
  )
}

export function IconImageOff(props: IconProps) {
  return (
    <Svg {...props}>
      <path d="M3.5 4.5h17v15h-17z" />
      <path d="m4 17 4.5-5 3 3.25" />
      <path d="M14 13.5 16.5 11l4 4.5" />
      <circle cx="15" cy="8.5" r="1.25" />
    </Svg>
  )
}

export function IconChevronDown(props: IconProps) {
  return (
    <Svg {...props}>
      <path d="m6 9.5 6 6 6-6" />
    </Svg>
  )
}

export function IconTrendUp(props: IconProps) {
  return (
    <Svg {...props}>
      <path d="M4 17 10 11l4 4 6-6" />
      <path d="M15 9h5v5" />
    </Svg>
  )
}

export function IconTrendDown(props: IconProps) {
  return (
    <Svg {...props}>
      <path d="M4 7l6 6 4-4 6 6" />
      <path d="M15 15h5v-5" />
    </Svg>
  )
}

export function IconTrendFlat(props: IconProps) {
  return (
    <Svg {...props}>
      <path d="M4 12h16" />
    </Svg>
  )
}

export function IconCopy(props: IconProps) {
  return (
    <Svg {...props}>
      <rect x="9" y="9" width="11.5" height="11.5" rx="2.25" />
      <path d="M15 6.25V5.5a2 2 0 0 0-2-2H5.5a2 2 0 0 0-2 2V13a2 2 0 0 0 2 2h.75" />
    </Svg>
  )
}

export function IconRefresh(props: IconProps) {
  return (
    <Svg {...props}>
      <path d="M20 12a8 8 0 1 1-2.6-5.9" />
      <path d="M20.5 3.5V9H15" />
    </Svg>
  )
}

export function IconMail(props: IconProps) {
  return (
    <Svg {...props}>
      <rect x="2.75" y="5" width="18.5" height="14" rx="2.25" />
      <path d="m3.5 7 8.5 6 8.5-6" />
    </Svg>
  )
}

/** Closed padlock with a keyhole. Reads as "locked, pending" not "rejected". */
export function IconLock(props: IconProps) {
  return (
    <Svg {...props}>
      <rect x="4" y="10.5" width="16" height="10.5" rx="2.5" />
      <path d="M7.75 10.5V7.75a4.25 4.25 0 0 1 8.5 0v2.75" />
      <circle cx="12" cy="15" r="1.35" />
      <path d="M12 16.35v1.6" />
    </Svg>
  )
}

export function IconShield(props: IconProps) {
  return (
    <Svg {...props}>
      <path d="M12 2.75 4.5 5.5v6.25c0 5 3.4 8 7.5 9.5 4.1-1.5 7.5-4.5 7.5-9.5V5.5L12 2.75Z" />
      <path d="m8.75 12 2.25 2.25 4.25-4.5" />
    </Svg>
  )
}

export function IconSearchOff(props: IconProps) {
  return (
    <Svg {...props}>
      <circle cx="10.5" cy="10.5" r="6.75" />
      <path d="m15.5 15.5 4.75 4.75" />
      <path d="M8 10.5h5" />
    </Svg>
  )
}

/** Google's four-colour mark. Fixed brand colours, not themeable. */
export function IconGoogle({ size = 18, className }: IconProps) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 18 18"
      aria-hidden="true"
      focusable="false"
      className={className}
    >
      <path
        fill="#4285F4"
        d="M17.64 9.2c0-.64-.06-1.25-.16-1.84H9v3.48h4.84a4.14 4.14 0 0 1-1.8 2.72v2.26h2.91c1.7-1.57 2.69-3.88 2.69-6.62Z"
      />
      <path
        fill="#34A853"
        d="M9 18c2.43 0 4.47-.8 5.96-2.18l-2.91-2.26c-.81.54-1.84.86-3.05.86-2.34 0-4.32-1.58-5.03-3.7H.96v2.34A9 9 0 0 0 9 18Z"
      />
      <path
        fill="#FBBC05"
        d="M3.97 10.72a5.41 5.41 0 0 1 0-3.44V4.94H.96a9 9 0 0 0 0 8.12l3.01-2.34Z"
      />
      <path
        fill="#EA4335"
        d="M9 3.58c1.32 0 2.5.45 3.44 1.35l2.58-2.59C13.46.89 11.43 0 9 0A9 9 0 0 0 .96 4.94l3.01 2.34C4.68 5.16 6.66 3.58 9 3.58Z"
      />
    </svg>
  )
}

/** Indeterminate progress. Rotation is suppressed under reduced motion. */
export function IconSpinner({ size = 18, className }: IconProps) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      aria-hidden="true"
      focusable="false"
      className={`motion-safe:animate-spin ${className ?? ''}`}
    >
      <circle
        cx="12"
        cy="12"
        r="9"
        stroke="currentColor"
        strokeWidth="2.25"
        strokeOpacity="0.25"
      />
      <path
        d="M21 12a9 9 0 0 0-9-9"
        stroke="currentColor"
        strokeWidth="2.25"
        strokeLinecap="round"
      />
    </svg>
  )
}

export function IconSun(props: IconProps) {
  return (
    <Svg {...props}>
      <circle cx="12" cy="12" r="4" />
      <path d="M12 2.5v2M12 19.5v2M2.5 12h2M19.5 12h2M5.2 5.2l1.4 1.4M17.4 17.4l1.4 1.4M18.8 5.2l-1.4 1.4M6.6 17.4l-1.4 1.4" />
    </Svg>
  )
}

export function IconMoon(props: IconProps) {
  return (
    <Svg {...props}>
      <path d="M20 14.2A8.2 8.2 0 0 1 9.8 4 8.5 8.5 0 1 0 20 14.2Z" />
    </Svg>
  )
}

export function IconMonitor(props: IconProps) {
  return (
    <Svg {...props}>
      <rect x="2.75" y="4" width="18.5" height="12.5" rx="2" />
      <path d="M8.5 20.5h7M12 16.5v4" />
    </Svg>
  )
}

export function IconUpload(props: IconProps) {
  return (
    <Svg {...props}>
      <path d="M12 16V4M7.5 8.5 12 4l4.5 4.5" />
      <path d="M4 14.5V19a1.5 1.5 0 0 0 1.5 1.5h13A1.5 1.5 0 0 0 20 19v-4.5" />
    </Svg>
  )
}

export function IconScan(props: IconProps) {
  return (
    <Svg {...props}>
      <path d="M8 3H5a2 2 0 0 0-2 2v3M16 3h3a2 2 0 0 1 2 2v3M21 16v3a2 2 0 0 1-2 2h-3M8 21H5a2 2 0 0 1-2-2v-3" />
      <circle cx="12" cy="12" r="3.25" />
    </Svg>
  )
}

export function IconArrowLeft(props: IconProps) {
  return (
    <Svg {...props}>
      <path d="m10 6-6 6 6 6M4 12h16" />
    </Svg>
  )
}
