# Frontend (React + TypeScript)

A modern web application built with React, TypeScript, and TailwindCSS for the DevSecOps platform.

## Overview

The frontend application provides a user interface for authentication, user management, dashboard, analytics, and notifications.

## Technology Stack

- **Framework**: React 18
- **Language**: TypeScript 5
- **Styling**: TailwindCSS 3
- **State Management**: React Context API
- **HTTP Client**: Axios
- **Routing**: React Router 6
- **Build Tool**: Vite
- **Icons**: React Icons

## Features

- ✅ User authentication (login, register, logout)
- ✅ Dashboard with statistics
- ✅ User profile management
- ✅ Notifications center
- ✅ Analytics visualization
- ✅ Responsive design
- ✅ Dark mode support
- ✅ Protected routes
- ✅ Error handling
- ✅ Loading states

## Project Structure

```
frontend/
├── public/                 # Static files
├── src/
│   ├── components/        # Reusable components
│   │   ├── auth/         # Authentication components
│   │   ├── common/       # Common components
│   │   ├── dashboard/    # Dashboard components
│   │   └── layout/       # Layout components
│   ├── context/          # React Context providers
│   ├── hooks/            # Custom React hooks
│   ├── pages/            # Page components
│   ├── services/         # API services
│   ├── types/            # TypeScript types
│   ├── utils/            # Utility functions
│   ├── App.tsx           # Main App component
│   └── main.tsx          # Entry point
├── Dockerfile            # Production Docker image
├── Dockerfile.dev        # Development Docker image
├── nginx.conf            # Nginx configuration
├── package.json          # Dependencies
├── tsconfig.json         # TypeScript configuration
├── tailwind.config.js    # TailwindCSS configuration
└── vite.config.ts        # Vite configuration
```

## Environment Variables

```bash
VITE_API_BASE_URL=http://localhost:8080
VITE_USER_SERVICE_URL=http://localhost:8081
VITE_AUTH_SERVICE_URL=http://localhost:8082
VITE_NOTIFICATION_SERVICE_URL=http://localhost:8083
VITE_ANALYTICS_SERVICE_URL=http://localhost:8084
```

## Local Development

### Prerequisites
- Node.js 18 or later
- npm or yarn

### Setup

1. **Install dependencies**:
```bash
npm install
```

2. **Set environment variables**:
```bash
cp .env.example .env.local
# Edit .env.local with your configuration
```

3. **Run the application**:
```bash
npm run dev
```

The application will be available at `http://localhost:3000`.

### Testing

```bash
npm run test
npm run test:coverage
```

### Building

```bash
npm run build
```

## Docker

### Development

```bash
docker build -f Dockerfile.dev -t frontend:dev .
docker run -p 3000:3000 frontend:dev
```

### Production

```bash
docker build -t frontend:latest .
docker run -p 80:80 frontend:latest
```

## Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run preview` - Preview production build
- `npm run lint` - Run ESLint
- `npm run type-check` - TypeScript type checking

## Pages

- `/` - Landing page
- `/login` - Login page
- `/register` - Registration page
- `/dashboard` - User dashboard (protected)
- `/profile` - User profile (protected)
- `/users` - User management (protected)
- `/notifications` - Notifications center (protected)
- `/analytics` - Analytics page (protected)

## Security Features

- JWT token management
- Protected routes
- XSS prevention
- CSRF protection
- Secure HTTP headers
- Input validation

## License

MIT License
