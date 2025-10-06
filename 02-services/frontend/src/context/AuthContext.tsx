import { createContext, useContext, useState, useEffect, ReactNode } from 'react'
import authService from '@/services/authService'
import userService from '@/services/userService'
import { User } from '@/types'

interface AuthContextType {
  user: User | null
  isAuthenticated: boolean
  isLoading: boolean
  login: (username: string, password: string) => Promise<void>
  register: (username: string, email: string, password: string) => Promise<void>
  logout: () => Promise<void>
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    // Check if user is authenticated on mount
    const initAuth = async () => {
      if (authService.isAuthenticated()) {
        try {
          const response = await userService.getCurrentUser()
          if (response.success && response.data) {
            setUser(response.data)
          }
        } catch (error) {
          console.error('Failed to load user:', error)
          localStorage.removeItem('access_token')
          localStorage.removeItem('refresh_token')
        }
      }
      setIsLoading(false)
    }

    initAuth()
  }, [])

  const login = async (username: string, password: string) => {
    const response = await authService.login(username, password)
    if (response.success) {
      const userResponse = await userService.getCurrentUser()
      if (userResponse.success && userResponse.data) {
        setUser(userResponse.data)
      }
    }
  }

  const register = async (username: string, email: string, password: string) => {
    await authService.register(username, email, password)
  }

  const logout = async () => {
    await authService.logout()
    setUser(null)
  }

  const value = {
    user,
    isAuthenticated: !!user,
    isLoading,
    login,
    register,
    logout,
  }

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const context = useContext(AuthContext)
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
}
