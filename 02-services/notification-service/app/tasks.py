import os
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from celery import Celery
from app.main import db, logger
from app.models import Notification
from datetime import datetime

# Initialize Celery
celery = Celery(
    'tasks',
    broker=os.getenv('CELERY_BROKER_URL', 'redis://localhost:6379/0'),
    backend=os.getenv('CELERY_RESULT_BACKEND', 'redis://localhost:6379/0')
)

celery.conf.update(
    task_serializer='json',
    accept_content=['json'],
    result_serializer='json',
    timezone='UTC',
    enable_utc=True,
    task_track_started=True,
    task_time_limit=300,
    task_soft_time_limit=240
)

@celery.task(bind=True, max_retries=3)
def send_notification_task(self, notification_id):
    """Send notification asynchronously"""
    try:
        from app.main import app
        
        with app.app_context():
            notification = Notification.query.get(notification_id)
            
            if not notification:
                logger.error(f'Notification not found: {notification_id}')
                return
            
            logger.info(f'Processing notification: {notification_id}, channel: {notification.channel}')
            
            # Send based on channel
            if notification.channel == 'email':
                send_email(notification)
            elif notification.channel == 'sms':
                send_sms(notification)
            elif notification.channel == 'push':
                send_push(notification)
            else:
                logger.error(f'Unknown channel: {notification.channel}')
                notification.status = 'failed'
                notification.error_message = f'Unknown channel: {notification.channel}'
                db.session.commit()
                return
            
            # Update notification status
            notification.status = 'sent'
            notification.sent_at = datetime.utcnow()
            db.session.commit()
            
            logger.info(f'Notification sent successfully: {notification_id}')
            
    except Exception as e:
        logger.error(f'Failed to send notification {notification_id}: {e}')
        
        try:
            with app.app_context():
                notification = Notification.query.get(notification_id)
                notification.status = 'failed'
                notification.error_message = str(e)
                notification.retry_count += 1
                db.session.commit()
        except:
            pass
        
        # Retry if not exceeded max retries
        if self.request.retries < self.max_retries:
            raise self.retry(exc=e, countdown=60 * (self.request.retries + 1))

def send_email(notification):
    """Send email notification"""
    try:
        smtp_host = os.getenv('SMTP_HOST', 'localhost')
        smtp_port = int(os.getenv('SMTP_PORT', 1025))
        smtp_user = os.getenv('SMTP_USER', '')
        smtp_password = os.getenv('SMTP_PASSWORD', '')
        smtp_from = os.getenv('SMTP_FROM', 'noreply@devsecops.local')
        
        # Create message
        msg = MIMEMultipart('alternative')
        msg['Subject'] = notification.subject or 'Notification'
        msg['From'] = smtp_from
        msg['To'] = notification.data.get('email', 'user@example.com')
        
        # Add message body
        text_part = MIMEText(notification.message, 'plain')
        msg.attach(text_part)
        
        # Send email
        with smtplib.SMTP(smtp_host, smtp_port) as server:
            if smtp_user and smtp_password:
                server.login(smtp_user, smtp_password)
            server.send_message(msg)
        
        logger.info(f'Email sent to {msg["To"]}')
        
    except Exception as e:
        logger.error(f'Failed to send email: {e}')
        raise

def send_sms(notification):
    """Send SMS notification"""
    # TODO: Implement Twilio integration
    logger.info(f'SMS sending (mock): {notification.message}')
    pass

def send_push(notification):
    """Send push notification"""
    # TODO: Implement FCM integration
    logger.info(f'Push notification sending (mock): {notification.message}')
    pass
