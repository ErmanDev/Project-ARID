import { IconMonitor, IconMoon, IconSun } from './icons'
import { Segmented, type SegmentOption } from './ui'
import { useTheme, type ThemeMode } from '../theme'

const OPTIONS: SegmentOption<ThemeMode>[] = [
  { value: 'light', label: <IconSun size={15} />, title: 'Light' },
  { value: 'dark', label: <IconMoon size={15} />, title: 'Dark' },
  { value: 'system', label: <IconMonitor size={15} />, title: 'Match system' },
]

/**
 * Three states, not a two-way switch: "system" has to stay reachable, or a user
 * who follows their OS can never get back to it once they touch the control.
 * Icon-only to stay compact in the header; each segment keeps a text label for
 * screen readers and a tooltip for sighted users.
 */
export function ThemeToggle() {
  const { mode, setMode } = useTheme()
  return (
    <Segmented
      label="Colour theme"
      value={mode}
      options={OPTIONS}
      onChange={setMode}
    />
  )
}
