const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { User, RefreshToken, PasswordResetToken, EmailVerificationToken, LoginAuditLog } = require('../models');
const { logger } = require('../utils/logger');
const redis = require('../utils/redis');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';
const JWT_ACCESS_EXPIRATION = parseInt(process.env.JWT_ACCESS_EXPIRATION) || 900; // 15 minutes
const JWT_REFRESH_EXPIRATION = parseInt(process.env.JWT_REFRESH_EXPIRATION) || 86400; // 24 hours
const BCRYPT_ROUNDS = parseInt(process.env.BCRYPT_ROUNDS) || 10;

// Register new user
exports.register = async (req, res) => {
  try {
    const { email, username, password, first_name, last_name, phone } = req.body;

    // Check if user already exists
    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) {
      return res.status(409).json({
        error: {
          code: 'EMAIL_EXISTS',
          message: 'Email already registered'
        }
      });
    }

    // Check if username exists
    const existingUsername = await User.findOne({ where: { username } });
    if (existingUsername) {
      return res.status(409).json({
        error: {
          code: 'USERNAME_EXISTS',
          message: 'Username already taken'
        }
      });
    }

    // Hash password
    const password_hash = await bcrypt.hash(password, BCRYPT_ROUNDS);

    // Create user
    const user = await User.create({
      email,
      username,
      password_hash,
      first_name,
      last_name,
      phone,
      is_active: true,
      is_verified: false,
      role: 'user'
    });

    // Create email verification token
    const verificationToken = crypto.randomBytes(32).toString('hex');
    await EmailVerificationToken.create({
      user_id: user.id,
      token: verificationToken,
      expires_at: new Date(Date.now() + 24 * 60 * 60 * 1000) // 24 hours
    });

    // TODO: Send verification email

    logger.info(`User registered: ${user.id}`);

    res.status(201).json({
      success: true,
      message: 'User registered successfully. Please verify your email.',
      data: {
        id: user.id,
        email: user.email,
        username: user.username
      }
    });
  } catch (error) {
    logger.error('Registration error:', error);
    res.status(500).json({
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to register user'
      }
    });
  }
};

// Login user
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;
    const ipAddress = req.ip;
    const userAgent = req.get('User-Agent');

    // Find user
    const user = await User.findOne({ where: { email } });
    
    if (!user) {
      // Log failed attempt
      await LoginAuditLog.create({
        email,
        success: false,
        ip_address: ipAddress,
        user_agent: userAgent,
        failure_reason: 'User not found'
      });

      return res.status(401).json({
        error: {
          code: 'INVALID_CREDENTIALS',
          message: 'Invalid email or password'
        }
      });
    }

    // Verify password
    const isPasswordValid = await bcrypt.compare(password, user.password_hash);
    
    if (!isPasswordValid) {
      // Log failed attempt
      await LoginAuditLog.create({
        user_id: user.id,
        email,
        success: false,
        ip_address: ipAddress,
        user_agent: userAgent,
        failure_reason: 'Invalid password'
      });

      return res.status(401).json({
        error: {
          code: 'INVALID_CREDENTIALS',
          message: 'Invalid email or password'
        }
      });
    }

    // Check if user is active
    if (!user.is_active) {
      return res.status(403).json({
        error: {
          code: 'ACCOUNT_DISABLED',
          message: 'Account is disabled'
        }
      });
    }

    // Generate tokens
    const accessToken = jwt.sign(
      { user_id: user.id, email: user.email, role: user.role },
      JWT_SECRET,
      { expiresIn: JWT_ACCESS_EXPIRATION }
    );

    const refreshToken = jwt.sign(
      { user_id: user.id, type: 'refresh' },
      JWT_SECRET,
      { expiresIn: JWT_REFRESH_EXPIRATION }
    );

    // Store refresh token
    await RefreshToken.create({
      user_id: user.id,
      token: refreshToken,
      expires_at: new Date(Date.now() + JWT_REFRESH_EXPIRATION * 1000),
      ip_address: ipAddress,
      user_agent: userAgent
    });

    // Update last login
    await user.update({ last_login_at: new Date() });

    // Log successful login
    await LoginAuditLog.create({
      user_id: user.id,
      email,
      success: true,
      ip_address: ipAddress,
      user_agent: userAgent
    });

    logger.info(`User logged in: ${user.id}`);

    res.json({
      success: true,
      data: {
        user: {
          id: user.id,
          email: user.email,
          username: user.username,
          first_name: user.first_name,
          last_name: user.last_name,
          role: user.role,
          is_verified: user.is_verified
        },
        access_token: accessToken,
        refresh_token: refreshToken,
        expires_in: JWT_ACCESS_EXPIRATION
      }
    });
  } catch (error) {
    logger.error('Login error:', error);
    res.status(500).json({
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Login failed'
      }
    });
  }
};

// Refresh access token
exports.refresh = async (req, res) => {
  try {
    const { refresh_token } = req.body;

    if (!refresh_token) {
      return res.status(400).json({
        error: {
          code: 'MISSING_TOKEN',
          message: 'Refresh token required'
        }
      });
    }

    // Verify refresh token
    let decoded;
    try {
      decoded = jwt.verify(refresh_token, JWT_SECRET);
    } catch (error) {
      return res.status(401).json({
        error: {
          code: 'INVALID_TOKEN',
          message: 'Invalid or expired refresh token'
        }
      });
    }

    // Check if token exists in database
    const tokenRecord = await RefreshToken.findOne({
      where: { token: refresh_token, user_id: decoded.user_id }
    });

    if (!tokenRecord) {
      return res.status(401).json({
        error: {
          code: 'TOKEN_NOT_FOUND',
          message: 'Refresh token not found'
        }
      });
    }

    // Check if token is revoked or expired
    if (tokenRecord.revoked_at || new Date(tokenRecord.expires_at) < new Date()) {
      return res.status(401).json({
        error: {
          code: 'TOKEN_EXPIRED',
          message: 'Refresh token expired or revoked'
        }
      });
    }

    // Get user
    const user = await User.findByPk(decoded.user_id);
    if (!user || !user.is_active) {
      return res.status(401).json({
        error: {
          code: 'USER_NOT_FOUND',
          message: 'User not found or inactive'
        }
      });
    }

    // Generate new access token
    const accessToken = jwt.sign(
      { user_id: user.id, email: user.email, role: user.role },
      JWT_SECRET,
      { expiresIn: JWT_ACCESS_EXPIRATION }
    );

    logger.info(`Token refreshed for user: ${user.id}`);

    res.json({
      success: true,
      data: {
        access_token: accessToken,
        expires_in: JWT_ACCESS_EXPIRATION
      }
    });
  } catch (error) {
    logger.error('Token refresh error:', error);
    res.status(500).json({
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to refresh token'
      }
    });
  }
};

// Logout user
exports.logout = async (req, res) => {
  try {
    const { refresh_token } = req.body;

    if (refresh_token) {
      // Revoke refresh token
      await RefreshToken.update(
        { revoked_at: new Date() },
        { where: { token: refresh_token } }
      );
    }

    logger.info('User logged out');

    res.json({
      success: true,
      message: 'Logged out successfully'
    });
  } catch (error) {
    logger.error('Logout error:', error);
    res.status(500).json({
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Logout failed'
      }
    });
  }
};

// Verify JWT token
exports.verify = async (req, res) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');

    if (!token) {
      return res.status(400).json({
        error: {
          code: 'MISSING_TOKEN',
          message: 'Token required'
        }
      });
    }

    const decoded = jwt.verify(token, JWT_SECRET);

    res.json({
      success: true,
      data: {
        valid: true,
        user_id: decoded.user_id,
        email: decoded.email,
        role: decoded.role
      }
    });
  } catch (error) {
    res.status(401).json({
      error: {
        code: 'INVALID_TOKEN',
        message: 'Invalid or expired token'
      }
    });
  }
};

// Forgot password
exports.forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;

    const user = await User.findOne({ where: { email } });
    
    if (!user) {
      // Don't reveal if email exists
      return res.json({
        success: true,
        message: 'If the email exists, a password reset link has been sent'
      });
    }

    // Create reset token
    const resetToken = crypto.randomBytes(32).toString('hex');
    await PasswordResetToken.create({
      user_id: user.id,
      token: resetToken,
      expires_at: new Date(Date.now() + 60 * 60 * 1000) // 1 hour
    });

    // TODO: Send password reset email

    logger.info(`Password reset requested for user: ${user.id}`);

    res.json({
      success: true,
      message: 'If the email exists, a password reset link has been sent'
    });
  } catch (error) {
    logger.error('Forgot password error:', error);
    res.status(500).json({
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to process password reset'
      }
    });
  }
};

// Reset password
exports.resetPassword = async (req, res) => {
  try {
    const { token, password } = req.body;

    // Find token
    const resetToken = await PasswordResetToken.findOne({
      where: { token, used_at: null }
    });

    if (!resetToken) {
      return res.status(400).json({
        error: {
          code: 'INVALID_TOKEN',
          message: 'Invalid or expired reset token'
        }
      });
    }

    // Check if token expired
    if (new Date(resetToken.expires_at) < new Date()) {
      return res.status(400).json({
        error: {
          code: 'TOKEN_EXPIRED',
          message: 'Reset token has expired'
        }
      });
    }

    // Hash new password
    const password_hash = await bcrypt.hash(password, BCRYPT_ROUNDS);

    // Update user password
    await User.update(
      { password_hash },
      { where: { id: resetToken.user_id } }
    );

    // Mark token as used
    await resetToken.update({ used_at: new Date() });

    // Revoke all refresh tokens
    await RefreshToken.update(
      { revoked_at: new Date() },
      { where: { user_id: resetToken.user_id } }
    );

    logger.info(`Password reset for user: ${resetToken.user_id}`);

    res.json({
      success: true,
      message: 'Password reset successfully'
    });
  } catch (error) {
    logger.error('Reset password error:', error);
    res.status(500).json({
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to reset password'
      }
    });
  }
};
