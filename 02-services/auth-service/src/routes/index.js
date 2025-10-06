const express = require('express');
const rateLimit = require('express-rate-limit');
const authController = require('./controllers/authController');
const { validateRegistration, validateLogin, validateRefresh, validatePasswordReset } = require('./middleware/validation');

const router = express.Router();

// Rate limiting
const authLimiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW) || 15 * 60 * 1000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX) || 100
});

// Auth routes
router.post('/auth/register', authLimiter, validateRegistration, authController.register);
router.post('/auth/login', authLimiter, validateLogin, authController.login);
router.post('/auth/refresh', validateRefresh, authController.refresh);
router.post('/auth/logout', authController.logout);
router.get('/auth/verify', authController.verify);
router.post('/auth/forgot-password', authLimiter, authController.forgotPassword);
router.post('/auth/reset-password', validatePasswordReset, authController.resetPassword);

module.exports = router;
