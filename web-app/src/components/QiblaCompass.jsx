import { useState, useEffect } from 'react'
import { calculateQiblaDirection } from '../utils/qibla'

const QiblaCompass = ({ location }) => {
  const [qiblaAngle, setQiblaAngle] = useState(0)
  const [compassHeading, setCompassHeading] = useState(0)
  const [supported, setSupported] = useState(true)

  useEffect(() => {
    if (!location) return

    // Calculate Qibla direction
    const angle = calculateQiblaDirection(
      location.latitude,
      location.longitude
    )
    setQiblaAngle(angle)
  }, [location])

  useEffect(() => {
    // Check if device orientation is supported
    if (!window.DeviceOrientationEvent) {
      setSupported(false)
      return
    }

    const handleOrientation = (event) => {
      if (event.alpha !== null) {
        setCompassHeading(event.alpha)
      }
    }

    // Request permission for iOS 13+
    if (typeof DeviceOrientationEvent.requestPermission === 'function') {
      DeviceOrientationEvent.requestPermission()
        .then(permissionState => {
          if (permissionState === 'granted') {
            window.addEventListener('deviceorientation', handleOrientation)
          }
        })
        .catch(console.error)
    } else {
      window.addEventListener('deviceorientation', handleOrientation)
    }

    return () => {
      window.removeEventListener('deviceorientation', handleOrientation)
    }
  }, [])

  const qiblaOffset = qiblaAngle - compassHeading

  return (
    <div className="qibla-container">
      <h2>Qibla Direction</h2>

      {!supported && (
        <div className="alert alert-warning">
          <p>Compass not supported on this device</p>
          <p className="small">Showing Qibla angle from North instead</p>
        </div>
      )}

      <div className="compass-wrapper">
        <div
          className="compass"
          style={{
            transform: `rotate(${-compassHeading}deg)`,
          }}
        >
          {/* Compass Circle */}
          <div className="compass-circle">
            <div className="compass-mark north">N</div>
            <div className="compass-mark east">E</div>
            <div className="compass-mark south">S</div>
            <div className="compass-mark west">W</div>
          </div>

          {/* Qibla Arrow */}
          <div
            className="qibla-arrow"
            style={{
              transform: `rotate(${qiblaAngle}deg)`,
            }}
          >
            <div className="arrow-head">▲</div>
            <div className="arrow-label">Qibla</div>
          </div>
        </div>
      </div>

      <div className="qibla-info">
        <div className="info-card">
          <div className="info-label">Qibla Angle</div>
          <div className="info-value">{qiblaAngle.toFixed(1)}°</div>
        </div>
        <div className="info-card">
          <div className="info-label">Offset</div>
          <div className="info-value">{qiblaOffset.toFixed(1)}°</div>
        </div>
        <div className="info-card">
          <div className="info-label">Compass</div>
          <div className="info-value">
            {supported ? `${compassHeading.toFixed(0)}°` : 'N/A'}
          </div>
        </div>
      </div>

      <div className="instruction">
        <p>📍 <strong>Direction to Mecca (Ka'bah)</strong></p>
        <p className="small">Align the green arrow with your device's top</p>
      </div>
    </div>
  )
}

export default QiblaCompass
