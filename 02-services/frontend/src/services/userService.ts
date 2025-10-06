import axios, { AxiosInstance } from 'axios'
import { User, ApiResponse } from '@/types'

const API_BASE_URL = import.meta.env.VITE_USER_SERVICE_URL || 'http://localhost:8081'

class UserService {
  private api: AxiosInstance

  constructor() {
    this.api = axios.create({
      baseURL: `${API_BASE_URL}/api/v1`,
      headers: {
        'Content-Type': 'application/json',
      },
    })

    this.api.interceptors.request.use((config) => {
      const token = localStorage.getItem('access_token')
      if (token) {
        config.headers.Authorization = `Bearer ${token}`
      }
      return config
    })
  }

  async getCurrentUser(): Promise<ApiResponse<User>> {
    const response = await this.api.get('/users/profile')
    return response.data
  }

  async updateProfile(data: Partial<User>): Promise<ApiResponse<User>> {
    const response = await this.api.put('/users/profile', data)
    return response.data
  }

  async getUsers(page: number = 0, size: number = 10): Promise<ApiResponse<any>> {
    const response = await this.api.get('/users', {
      params: { page, size },
    })
    return response.data
  }
}

export default new UserService()
