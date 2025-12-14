import { BrowserRouter as Router, Routes, Route } from 'react-router-dom'
import Home from '@/pages/Home'
import Terms from '@/pages/Terms'
import Privacy from '@/pages/Privacy'
import Security from '@/pages/Security'
import LogoTest from '@/pages/LogoTest'

function App() {
  return (
    <Router>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/terms" element={<Terms />} />
        <Route path="/privacy" element={<Privacy />} />
        <Route path="/security" element={<Security />} />
        <Route path="/logo-test" element={<LogoTest />} />
      </Routes>
    </Router>
  )
}

export default App
