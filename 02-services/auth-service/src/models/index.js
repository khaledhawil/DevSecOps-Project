const { Sequelize } = require('sequelize');

const sequelize = new Sequelize({
  dialect: 'postgres',
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'devsecops',
  username: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres123',
  logging: process.env.NODE_ENV === 'development' ? console.log : false,
  pool: {
    max: 25,
    min: 0,
    acquire: 30000,
    idle: 10000
  },
  dialectOptions: {
    ssl: process.env.DB_SSL === 'true' ? {
      require: true,
      rejectUnauthorized: false
    } : false
  }
});

const User = require('./user')(sequelize);
const RefreshToken = require('./refreshToken')(sequelize);
const PasswordResetToken = require('./passwordResetToken')(sequelize);
const EmailVerificationToken = require('./emailVerificationToken')(sequelize);
const LoginAuditLog = require('./loginAuditLog')(sequelize);

// Define associations
User.hasMany(RefreshToken, { foreignKey: 'user_id', as: 'refreshTokens' });
RefreshToken.belongsTo(User, { foreignKey: 'user_id' });

User.hasMany(PasswordResetToken, { foreignKey: 'user_id', as: 'passwordResetTokens' });
PasswordResetToken.belongsTo(User, { foreignKey: 'user_id' });

User.hasMany(EmailVerificationToken, { foreignKey: 'user_id', as: 'emailVerificationTokens' });
EmailVerificationToken.belongsTo(User, { foreignKey: 'user_id' });

User.hasMany(LoginAuditLog, { foreignKey: 'user_id', as: 'loginAudits' });
LoginAuditLog.belongsTo(User, { foreignKey: 'user_id' });

module.exports = {
  sequelize,
  User,
  RefreshToken,
  PasswordResetToken,
  EmailVerificationToken,
  LoginAuditLog
};
