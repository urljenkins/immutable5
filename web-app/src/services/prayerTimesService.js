import axios from 'axios'

const API_BASE_URL = 'https://api.aladhan.com/v1'

/**
 * Fetch prayer times for a specific location
 * @param {number} latitude
 * @param {number} longitude
 * @param {number} method - Calculation method (default: 2)
 * @returns {Promise<Object>} Prayer times object
 */
export const fetchPrayerTimes = async (latitude, longitude, method = 2) => {
  try {
    const timestamp = Math.floor(Date.now() / 1000)
    const url = `${API_BASE_URL}/timings/${timestamp}`

    const response = await axios.get(url, {
      params: {
        latitude,
        longitude,
        method,
      },
      timeout: 10000,
    })

    if (response.data && response.data.data && response.data.data.timings) {
      return response.data.data.timings
    }

    throw new Error('Invalid response format from API')
  } catch (error) {
    if (error.code === 'ECONNABORTED') {
      throw new Error('Request timeout - Please check your internet connection')
    }

    if (error.response) {
      throw new Error(`API Error: ${error.response.status} - ${error.response.statusText}`)
    }

    throw new Error(error.message || 'Failed to fetch prayer times')
  }
}

/**
 * Get available calculation methods
 * @returns {Promise<Array>} List of calculation methods
 */
export const getCalculationMethods = async () => {
  try {
    const response = await axios.get(`${API_BASE_URL}/methods`)
    return response.data.data || []
  } catch (error) {
    console.error('Failed to fetch calculation methods:', error)
    return []
  }
}

/**
 * Cache prayer times in localStorage
 * @param {string} key - Cache key
 * @param {Object} data - Prayer times data
 * @param {number} ttl - Time to live in milliseconds
 */
export const cachePrayerTimes = (key, data, ttl = 24 * 60 * 60 * 1000) => {
  const cacheData = {
    data,
    expiry: Date.now() + ttl,
  }

  try {
    localStorage.setItem(key, JSON.stringify(cacheData))
  } catch (error) {
    console.error('Failed to cache prayer times:', error)
  }
}

/**
 * Get cached prayer times
 * @param {string} key - Cache key
 * @returns {Object|null} Cached data or null if expired/not found
 */
export const getCachedPrayerTimes = (key) => {
  try {
    const cached = localStorage.getItem(key)
    if (!cached) return null

    const { data, expiry } = JSON.parse(cached)

    if (Date.now() > expiry) {
      localStorage.removeItem(key)
      return null
    }

    return data
  } catch (error) {
    console.error('Failed to get cached prayer times:', error)
    return null
  }
}
