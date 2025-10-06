const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const LoginAuditLog = sequelize.define('LoginAuditLog', {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    user_id: {
      type: DataTypes.UUID,
      references: {
        model: 'users',
        key: 'id'
      }
    },
    email: {
      type: DataTypes.STRING(255)
    },
    success: {
      type: DataTypes.BOOLEAN,
      allowNull: false
    },
    ip_address: {
      type: DataTypes.INET
    },
    user_agent: {
      type: DataTypes.TEXT
    },
    failure_reason: {
      type: DataTypes.STRING(255)
    },
    created_at: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW
    }
  }, {
    tableName: 'login_audit_log',
    timestamps: false,
    indexes: [
      { fields: ['user_id'] },
      { fields: ['created_at'] },
      { fields: ['success'] }
    ]
  });

  return LoginAuditLog;
};
