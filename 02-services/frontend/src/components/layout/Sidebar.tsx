import { Link, useLocation } from 'react-router-dom'
import { FiHome, FiUsers, FiBell, FiBarChart2, FiUser } from 'react-icons/fi'

export default function Sidebar() {
  const location = useLocation()

  const links = [
    { to: '/dashboard', icon: FiHome, label: 'Dashboard' },
    { to: '/users', icon: FiUsers, label: 'Users' },
    { to: '/notifications', icon: FiBell, label: 'Notifications' },
    { to: '/analytics', icon: FiBarChart2, label: 'Analytics' },
    { to: '/profile', icon: FiUser, label: 'Profile' },
  ]

  return (
    <aside className="w-64 bg-white dark:bg-gray-800 border-r border-gray-200 dark:border-gray-700">
      <div className="p-6">
        <h1 className="text-2xl font-bold text-primary-600">DevSecOps</h1>
      </div>
      <nav className="mt-6">
        {links.map((link) => {
          const isActive = location.pathname === link.to
          return (
            <Link
              key={link.to}
              to={link.to}
              className={`flex items-center px-6 py-3 text-sm font-medium transition-colors ${
                isActive
                  ? 'bg-primary-50 dark:bg-primary-900/20 text-primary-600 dark:text-primary-400 border-r-4 border-primary-600'
                  : 'text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700'
              }`}
            >
              <link.icon className="mr-3 h-5 w-5" />
              {link.label}
            </Link>
          )
        })}
      </nav>
    </aside>
  )
}
