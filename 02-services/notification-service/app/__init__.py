# Notification Service Package
from app.main import app, db
from app.models import Notification, NotificationTemplate, UserNotificationPreferences

__all__ = ['app', 'db', 'Notification', 'NotificationTemplate', 'UserNotificationPreferences']
