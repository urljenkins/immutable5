/**
 * Calculate Qibla direction from a given location
 * @param {number} latitude - User's latitude
 * @param {number} longitude - User's longitude
 * @returns {number} Qibla angle in degrees from North
 */
export const calculateQiblaDirection = (latitude, longitude) => {
  // Kaaba coordinates
  const KAABA_LAT = 21.4225
  const KAABA_LNG = 39.8262

  const toRadians = (degrees) => degrees * (Math.PI / 180)
  const toDegrees = (radians) => radians * (180 / Math.PI)

  const lat1 = toRadians(latitude)
  const lat2 = toRadians(KAABA_LAT)
  const lng1 = toRadians(longitude)
  const lng2 = toRadians(KAABA_LNG)

  const deltaLng = lng2 - lng1

  const y = Math.sin(deltaLng)
  const x = Math.cos(lat1) * Math.tan(lat2) - Math.sin(lat1) * Math.cos(deltaLng)

  let bearing = toDegrees(Math.atan2(y, x))

  // Normalize to 0-360 degrees
  bearing = (bearing + 360) % 360

  return bearing
}

/**
 * Get distance to Kaaba in kilometers
 * @param {number} latitude - User's latitude
 * @param {number} longitude - User's longitude
 * @returns {number} Distance in kilometers
 */
export const getDistanceToKaaba = (latitude, longitude) => {
  const KAABA_LAT = 21.4225
  const KAABA_LNG = 39.8262
  const EARTH_RADIUS = 6371 // km

  const toRadians = (degrees) => degrees * (Math.PI / 180)

  const lat1 = toRadians(latitude)
  const lat2 = toRadians(KAABA_LAT)
  const deltaLat = toRadians(KAABA_LAT - latitude)
  const deltaLng = toRadians(KAABA_LNG - longitude)

  const a =
    Math.sin(deltaLat / 2) * Math.sin(deltaLat / 2) +
    Math.cos(lat1) * Math.cos(lat2) *
    Math.sin(deltaLng / 2) * Math.sin(deltaLng / 2)

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

  return EARTH_RADIUS * c
}

/**
 * Get compass direction name from angle
 * @param {number} angle - Angle in degrees
 * @returns {string} Direction name (N, NE, E, SE, S, SW, W, NW)
 */
export const getDirectionName = (angle) => {
  const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW']
  const index = Math.round(angle / 45) % 8
  return directions[index]
}
