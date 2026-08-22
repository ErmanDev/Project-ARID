import {
  createContext,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react'
import {
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signInWithPopup,
  signOut as firebaseSignOut,
  type User,
} from 'firebase/auth'
import { doc, getDoc } from 'firebase/firestore'
import {
  allowAnyAuth,
  firebaseConfigured,
  getDb,
  getFirebaseAuth,
  googleProvider,
} from './firebase'
import { mockIsStaff, useMockData } from './config'

type AuthValue = {
  user: User | null
  isStaff: boolean
  loading: boolean
  configured: boolean
  error: string | null
  signInEmail: (email: string, password: string) => Promise<void>
  signInGoogle: () => Promise<void>
  signOut: () => Promise<void>
  /**
   * Re-runs the staff lookup for the current user and returns the result.
   * Lets someone waiting on provisioning poll for it, instead of having to
   * sign out and back in to pick up a `staff/{uid}` document that now exists.
   */
  recheckStaff: () => Promise<boolean>
}

const AuthContext = createContext<AuthValue | null>(null)

async function resolveStaff(uid: string): Promise<boolean> {
  if (allowAnyAuth) return true
  const snap = await getDoc(doc(getDb(), 'staff', uid))
  return snap.exists()
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [isStaff, setIsStaff] = useState(false)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (useMockData) {
      setUser({ uid: 'mock-staff', email: 'staff@arid.local' } as User)
      setIsStaff(mockIsStaff)
      setLoading(false)
      return
    }
    if (!firebaseConfigured) {
      setLoading(false)
      return
    }
    const unsub = onAuthStateChanged(getFirebaseAuth(), async (next) => {
      setError(null)
      if (!next) {
        setUser(null)
        setIsStaff(false)
        setLoading(false)
        return
      }
      try {
        const staff = await resolveStaff(next.uid)
        setUser(next)
        setIsStaff(staff)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Could not verify staff access')
        setUser(next)
        setIsStaff(false)
      } finally {
        setLoading(false)
      }
    })
    return unsub
  }, [])

  const value = useMemo<AuthValue>(
    () => ({
      user,
      isStaff,
      loading,
      configured: firebaseConfigured,
      error,
      signInEmail: async (email, password) => {
        setError(null)
        await signInWithEmailAndPassword(getFirebaseAuth(), email, password)
      },
      signInGoogle: async () => {
        setError(null)
        await signInWithPopup(getFirebaseAuth(), googleProvider)
      },
      signOut: async () => {
        if (useMockData) return
        if (firebaseConfigured) await firebaseSignOut(getFirebaseAuth())
      },
      recheckStaff: async () => {
        // Honours the mock flag so "Check again" tells the truth in mock mode.
        if (useMockData) return mockIsStaff
        if (!user) return false
        setError(null)
        try {
          const staff = await resolveStaff(user.uid)
          setIsStaff(staff)
          return staff
        } catch (err) {
          setError(
            err instanceof Error ? err.message : 'Could not verify staff access',
          )
          return false
        }
      },
    }),
    [user, isStaff, loading, error],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth(): AuthValue {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used within AuthProvider')
  return ctx
}
