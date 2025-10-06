export interface User {
  id: string
  username: string
  email: string
  role: string
  created_at: string
  updated_at: string
}

export interface AuthTokens {
  access_token: string
  refresh_token: string
  token_type: string
  expires_in: number
}

export interface LoginRequest {
  username: string
  password: string
}

export interface RegisterRequest {
  username: string
  email: string
  password: string
}

export interface ApiResponse<T> {
  success: boolean
  data?: T
  message?: string
  error?: {
    code: string
    message: string
  }
}

export interface Event {
  id: string
  user_id: string
  event_type: string
  event_name: string
  properties: Record<string, any>
  created_at: string
}

export interface UserStatistics {
  id: string
  user_id: string
  total_events: number
  total_page_views: number
  total_sessions: number
  last_active_at: string
  first_seen_at: string
}

export interface Notification {
  id: string
  user_id: string
  type: string
  channel: string
  subject: string
  message: string
  status: string
  sent_at: string | null
  read_at: string | null
  created_at: string
}
