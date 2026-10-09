import {
  createContext,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react'
import {
  createUserWithEmailAndPassword,
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut as firebaseSignOut,
  updateProfile,
  type User,
} from 'firebase/auth'
import { doc, getDoc, onSnapshot, serverTimestamp, setDoc } from 'firebase/firestore'
import { firebaseConfigured, getDb, getFirebaseAuth } from './firebase'
import { mockIsStaff, useMockData } from './config'
import { parseUserProfile } from './hooks'
import type { UserProfile } from './types'
import {
  AccessError,
  dashboardAccessProblem,
  normalizeUsername,
  usernameToEmail,
} from './accounts'

type AuthValue = {
  user: User | null
  profile: UserProfile | null
  /** A verified admin: the only kind of account the dashboard serves. */
  isStaff: boolean
  loading: boolean
  configured: boolean
  error: string | null
  signIn: (username: string, password: string) => Promise<void>
  /** Creates an unverified admin account and leaves the visitor signed out. */
  register: (displayName: string, username: string, password: string) => Promise<void>
  signOut: () => Promise<void>
}

const AuthContext = createContext<AuthValue | null>(null)

const MOCK_PROFILE: UserProfile = {
  id: 'mock-admin',
  username: 'admin',
  displayName: 'Demo admin',
  role: 'admin',
  verified: true,
  createdAt: null,
  verifiedAt: null,
  verifiedBy: null,
  totalPoints: 0,
  reportCount: 0,
  verifiedPoints: 0,
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [profile, setProfile] = useState<UserProfile | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (useMockData) {
      setUser({ uid: MOCK_PROFILE.id } as User)
      setProfile({ ...MOCK_PROFILE, verified: mockIsStaff })
      setLoading(false)
      return
    }
    if (!firebaseConfigured) {
      setLoading(false)
      return
    }

    let stopProfile: (() => void) | null = null
    const stopAuth = onAuthStateChanged(getFirebaseAuth(), (next) => {
      stopProfile?.()
      stopProfile = null
      setError(null)
      setUser(next)
      if (!next) {
        setProfile(null)
        setLoading(false)
        return
      }
      setLoading(true)
      // Live, so a verification or a revoke applies without signing out.
      stopProfile = onSnapshot(
        doc(getDb(), 'users', next.uid),
        (snap) => {
          setProfile(snap.exists() ? parseUserProfile(snap.id, snap.data()) : null)
          setLoading(false)
        },
        (err) => {
          setError(err instanceof Error ? err.message : 'Could not load your account')
          setProfile(null)
          setLoading(false)
        },
      )
    })
    return () => {
      stopProfile?.()
      stopAuth()
    }
  }, [])

  const value = useMemo<AuthValue>(
    () => ({
      user,
      profile,
      isStaff: Boolean(user && dashboardAccessProblem(profile) === null),
      loading,
      configured: firebaseConfigured,
      error,
      signIn: async (username, password) => {
        setError(null)
        const auth = getFirebaseAuth()
        const credential = await signInWithEmailAndPassword(
          auth,
          usernameToEmail(username),
          password,
        )
        const snap = await getDoc(doc(getDb(), 'users', credential.user.uid))
        const problem = dashboardAccessProblem(
          snap.exists() ? parseUserProfile(snap.id, snap.data()) : null,
        )
        if (problem) {
          await firebaseSignOut(auth)
          throw new AccessError(problem)
        }
      },
      register: async (displayName, username, password) => {
        setError(null)
        const auth = getFirebaseAuth()
        const normalized = normalizeUsername(username)
        const credential = await createUserWithEmailAndPassword(
          auth,
          usernameToEmail(normalized),
          password,
        )
        try {
          await updateProfile(credential.user, { displayName })
          await setDoc(doc(getDb(), 'users', credential.user.uid), {
            username: normalized,
            displayName,
            role: 'admin',
            verified: false,
            createdAt: serverTimestamp(),
            updatedAt: serverTimestamp(),
            totalPoints: 0,
            verifiedPoints: 0,
            reportCount: 0,
          })
        } catch (err) {
          // Without a profile the account is unusable; free the username.
          await credential.user.delete().catch(() => undefined)
          throw err
        } finally {
          await firebaseSignOut(auth)
        }
      },
      signOut: async () => {
        if (useMockData) return
        if (firebaseConfigured) await firebaseSignOut(getFirebaseAuth())
      },
    }),
    [user, profile, loading, error],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth(): AuthValue {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used within AuthProvider')
  return ctx
}
