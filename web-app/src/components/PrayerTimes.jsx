import { useState, useEffect } from 'react'
import { fetchPrayerTimes } from '../services/prayerTimesService'

const PrayerTimes = ({ location }) => {
  const [prayerTimes, setPrayerTimes] = useState(null)
  const [nextPrayer, setNextPrayer] = useState(null)
  const [countdown, setCountdown] = useState('')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  const mainPrayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']

  useEffect(() => {
    if (!location) return

    const loadPrayerTimes = async () => {
      try {
        setLoading(true)
        const times = await fetchPrayerTimes(
          location.latitude,
          location.longitude
        )
        setPrayerTimes(times)
        calculateNextPrayer(times)
        setError(null)
      } catch (err) {
        setError(err.message)
      } finally {
        setLoading(false)
      }
    }

    loadPrayerTimes()
  }, [location])

  useEffect(() => {
    if (!prayerTimes) return

    const timer = setInterval(() => {
      calculateNextPrayer(prayerTimes)
    }, 1000)

    return () => clearInterval(timer)
  }, [prayerTimes])

  const calculateNextPrayer = (times) => {
    const now = new Date()
    const today = now.toDateString()

    for (const prayer of mainPrayers) {
      if (times[prayer]) {
        const prayerTime = new Date(`${today} ${times[prayer]}`)
        if (prayerTime > now) {
          setNextPrayer({ name: prayer, time: times[prayer] })
          updateCountdown(prayerTime)
          return
        }
      }
    }

    // If all prayers passed, next is tomorrow's Fajr
    if (times.Fajr) {
      const tomorrow = new Date(now)
      tomorrow.setDate(tomorrow.getDate() + 1)
      const fajrTime = new Date(`${tomorrow.toDateString()} ${times.Fajr}`)
      setNextPrayer({ name: 'Fajr', time: times.Fajr })
      updateCountdown(fajrTime)
    }
  }

  const updateCountdown = (targetTime) => {
    const now = new Date()
    const diff = targetTime - now

    if (diff <= 0) {
      setCountdown('Now')
      return
    }

    const hours = Math.floor(diff / (1000 * 60 * 60))
    const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60))
    const seconds = Math.floor((diff % (1000 * 60)) / 1000)

    setCountdown(
      hours > 0
        ? `${hours}h ${minutes}m ${seconds}s`
        : `${minutes}m ${seconds}s`
    )
  }

  if (loading) {
    return (
      <div className="loading-container">
        <div className="spinner"></div>
        <p>Loading prayer times...</p>
      </div>
    )
  }

  if (error) {
    return (
      <div className="error-container">
        <p className="error-message">❌ {error}</p>
        <button onClick={() => window.location.reload()}>
          Try Again
        </button>
      </div>
    )
  }

  if (!prayerTimes) {
    return <div className="error-message">No prayer times available</div>
  }

  return (
    <div className="prayer-times-container">
      {/* Next Prayer Card */}
      <div className="next-prayer-card">
        <h2>Next Prayer</h2>
        {nextPrayer && (
          <>
            <div className="prayer-name">{nextPrayer.name}</div>
            <div className="prayer-time">{nextPrayer.time}</div>
            <div className="countdown">{countdown}</div>
          </>
        )}
      </div>

      {/* All Prayer Times */}
      <div className="prayer-times-grid">
        {mainPrayers.map(prayer => (
          <div
            key={prayer}
            className={`prayer-card ${nextPrayer?.name === prayer ? 'next' : ''}`}
          >
            <div className="prayer-icon">
              {prayer === 'Fajr' && '🌅'}
              {prayer === 'Dhuhr' && '☀️'}
              {prayer === 'Asr' && '🌤️'}
              {prayer === 'Maghrib' && '🌆'}
              {prayer === 'Isha' && '🌙'}
            </div>
            <div className="prayer-info">
              <div className="prayer-label">{prayer}</div>
              <div className="prayer-value">
                {prayerTimes[prayer] || '--:--'}
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Additional Times */}
      <div className="additional-times">
        <h3>Additional Times</h3>
        <div className="times-list">
          {['Sunrise', 'Sunset', 'Midnight'].map(time => (
            prayerTimes[time] && (
              <div key={time} className="time-item">
                <span className="time-label">{time}</span>
                <span className="time-value">{prayerTimes[time]}</span>
              </div>
            )
          ))}
        </div>
      </div>
    </div>
  )
}

export default PrayerTimes
