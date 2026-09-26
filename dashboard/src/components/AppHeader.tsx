import type { ReactNode } from 'react'
import { NavLink } from 'react-router-dom'
import { useAuth } from '../auth'
import { useMockData } from '../config'
import { IconPin, IconScan } from './icons'
import { ThemeToggle } from './ThemeToggle'
import { Button } from './ui'

export function AppHeader({ status }: { status?: ReactNode }) {
  const auth = useAuth()
  return (
    <header className="app-header">
      <a className="skip-link" href="#main-content">Skip to content</a>
      <NavLink to="/" className="app-brand" aria-label="A.R.I.D. home">
        <img src="/arid-logo.png" alt="" width="40" height="40" />
        <span><strong>A.R.I.D.</strong><small>Community health, connected.</small></span>
      </NavLink>
      <nav className="app-nav" aria-label="Main navigation">
        <NavLink to="/" end><IconPin size={17} />Monitor</NavLink>
        <NavLink to="/analyze"><IconScan size={17} />Analyze</NavLink>
      </nav>
      <div className="app-header-actions">
        {status ? <div className="app-live-status">{status}</div> : null}
        <ThemeToggle />
        {useMockData ? <span className="demo-badge">Demo workspace</span> : (
          <Button size="sm" variant="ghost" onClick={() => void auth.signOut()}>Sign out</Button>
        )}
      </div>
    </header>
  )
}
