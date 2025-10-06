import { useAuth } from '@/context/AuthContext'
import { FiUsers, FiBell, FiActivity, FiTrendingUp } from 'react-icons/fi'

export default function Dashboard() {
  const { user } = useAuth()

  const stats = [
    { name: 'Total Users', value: '1,234', icon: FiUsers, color: 'bg-blue-500' },
    { name: 'Notifications', value: '567', icon: FiBell, color: 'bg-green-500' },
    { name: 'Events', value: '8,910', icon: FiActivity, color: 'bg-purple-500' },
    { name: 'Growth', value: '+12.5%', icon: FiTrendingUp, color: 'bg-orange-500' },
  ]

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Dashboard</h1>
        <p className="mt-2 text-gray-600 dark:text-gray-400">
          Welcome back, {user?.username}! Here's what's happening today.
        </p>
      </div>

      <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
        {stats.map((stat) => (
          <div key={stat.name} className="card">
            <div className="flex items-center">
              <div className={`${stat.color} rounded-lg p-3`}>
                <stat.icon className="h-6 w-6 text-white" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-600 dark:text-gray-400">
                  {stat.name}
                </p>
                <p className="text-2xl font-semibold text-gray-900 dark:text-white">
                  {stat.value}
                </p>
              </div>
            </div>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <div className="card">
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
            Recent Activity
          </h3>
          <div className="space-y-4">
            <div className="flex items-center justify-between py-2 border-b border-gray-200 dark:border-gray-700">
              <span className="text-sm text-gray-600 dark:text-gray-400">User registered</span>
              <span className="text-xs text-gray-500">2 minutes ago</span>
            </div>
            <div className="flex items-center justify-between py-2 border-b border-gray-200 dark:border-gray-700">
              <span className="text-sm text-gray-600 dark:text-gray-400">Notification sent</span>
              <span className="text-xs text-gray-500">15 minutes ago</span>
            </div>
            <div className="flex items-center justify-between py-2 border-b border-gray-200 dark:border-gray-700">
              <span className="text-sm text-gray-600 dark:text-gray-400">Event tracked</span>
              <span className="text-xs text-gray-500">1 hour ago</span>
            </div>
          </div>
        </div>

        <div className="card">
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
            System Status
          </h3>
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-sm text-gray-600 dark:text-gray-400">User Service</span>
              <span className="px-2 py-1 text-xs font-semibold text-green-800 bg-green-100 rounded-full">
                Healthy
              </span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-sm text-gray-600 dark:text-gray-400">Auth Service</span>
              <span className="px-2 py-1 text-xs font-semibold text-green-800 bg-green-100 rounded-full">
                Healthy
              </span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-sm text-gray-600 dark:text-gray-400">Notification Service</span>
              <span className="px-2 py-1 text-xs font-semibold text-green-800 bg-green-100 rounded-full">
                Healthy
              </span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-sm text-gray-600 dark:text-gray-400">Analytics Service</span>
              <span className="px-2 py-1 text-xs font-semibold text-green-800 bg-green-100 rounded-full">
                Healthy
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
