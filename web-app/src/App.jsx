import { useState, useEffect } from 'react'
import PrayerTimes from './components/PrayerTimes'
import QiblaCompass from './components/QiblaCompass'
import DuasCollection from './components/DuasCollection'
import Navigation from './components/Navigation'
import { getCurrentLocation } from './utils/location'
import './styles/App.css'

function App() {
  const [currentView, setCurrentView] = useState('prayer-times')
  const [location, setLocation] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  useEffect(() => {
    // Get user's location on mount
    getCurrentLocation()
      .then(coords => {
        setLocation(coords)
        setLoading(false)
      })
      .catch(err => {
        setError(err.message)
        setLoading(false)
        // Use default location (London) if geolocation fails
        setLocation({ latitude: 51.5074, longitude: -0.1278 })
      })
  }, [])

  const renderView = () => {
    if (loading) {
      return (
        <div className="loading-container">
          <div className="spinner"></div>
          <p>Getting your location...</p>
        </div>
      )
    }

    switch (currentView) {
      case 'prayer-times':
        return <PrayerTimes location={location} />
      case 'qibla':
        return <QiblaCompass location={location} />
      case 'duas':
        return <DuasCollection />
      default:
        return <PrayerTimes location={location} />
    }
  }

  return (
    <div className="app">
      <header className="app-header">
        <h1>🕌 Immutable5</h1>
        <p className="subtitle">Islamic Prayer Times & Resources</p>
      </header>

      {error && (
        <div className="alert alert-warning">
          <p>⚠️ {error}</p>
          <p className="small">Using default location (London, UK)</p>
        </div>
      )}

      <Navigation currentView={currentView} onViewChange={setCurrentView} />

      <main className="app-main">
        {renderView()}
      </main>

      <footer className="app-footer">
        <p>Prayer times calculated using Aladhan API</p>
        <p className="small">
          Location: {location ? `${location.latitude.toFixed(2)}, ${location.longitude.toFixed(2)}` : 'Unknown'}
        </p>
      </footer>
    </div>
  )
}

export default App
