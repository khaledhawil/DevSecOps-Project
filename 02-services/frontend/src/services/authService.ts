import axios, { AxiosInstance } from 'axios'

const API_BASE_URL = import.meta.env.VITE_AUTH_SERVICE_URL || 'http://localhost:8082'

class AuthService {
  private api: AxiosInstance

  constructor() {
    this.api = axios.create({
      baseURL: `${API_BASE_URL}/api/v1/auth`,
      headers: {
        'Content-Type': 'application/json',
      },
    })

    // Add request interceptor to include token
    this.api.interceptors.request.use((config) => {
      const token = localStorage.getItem('access_token')
      if (token) {
        config.headers.Authorization = `Bearer ${token}`
      }
      return config
    })

    // Add response interceptor for token refresh
    this.api.interceptors.response.use(
      (response) => response,
      async (error) => {
        const originalRequest = error.config
        if (error.response?.status === 401 && !originalRequest._retry) {
          originalRequest._retry = true
          try {
            const refreshToken = localStorage.getItem('refresh_token')
            const response = await axios.post(`${API_BASE_URL}/api/v1/auth/refresh`, {
              refresh_token: refreshToken,
            })
            const { access_token } = response.data.data
            localStorage.setItem('access_token', access_token)
            originalRequest.headers.Authorization = `Bearer ${access_token}`
            return axios(originalRequest)
          } catch (refreshError) {
            localStorage.removeItem('access_token')
            localStorage.removeItem('refresh_token')
            window.location.href = '/login'
            return Promise.reject(refreshError)
          }
        }
        return Promise.reject(error)
      }
    )
  }

  async login(username: string, password: string) {
    const response = await this.api.post('/login', { username, password })
    const { access_token, refresh_token } = response.data.data
    localStorage.setItem('access_token', access_token)
    localStorage.setItem('refresh_token', refresh_token)
    return response.data
  }

  async register(username: string, email: string, password: string) {
    const response = await this.api.post('/register', { username, email, password })
    return response.data
  }

  async logout() {
    const refreshToken = localStorage.getItem('refresh_token')
    try {
      await this.api.post('/logout', { refresh_token: refreshToken })
    } finally {
      localStorage.removeItem('access_token')
      localStorage.removeItem('refresh_token')
    }
  }

  isAuthenticated(): boolean {
    return !!localStorage.getItem('access_token')
  }
}

export default new AuthService()
