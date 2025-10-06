const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const RefreshToken = sequelize.define('RefreshToken', {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    user_id: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: 'users',
        key: 'id'
      }
    },
    token: {
      type: DataTypes.STRING(500),
      allowNull: false,
      unique: true
    },
    expires_at: {
      type: DataTypes.DATE,
      allowNull: false
    },
    created_at: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW
    },
    revoked_at: {
      type: DataTypes.DATE
    },
    ip_address: {
      type: DataTypes.INET
    },
    user_agent: {
      type: DataTypes.TEXT
    }
  }, {
    tableName: 'refresh_tokens',
    timestamps: false,
    indexes: [
      { fields: ['user_id'] },
      { fields: ['token'] },
      { fields: ['expires_at'] }
    ]
  });

  return RefreshToken;
};
