import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom'
import { AuthProvider } from './auth'
import { DeniedPage } from './pages/Denied'
import { LoginPage } from './pages/Login'
import { MonitorPage } from './pages/Monitor'

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route path="/denied" element={<DeniedPage />} />
          <Route path="/" element={<MonitorPage />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  )
}
