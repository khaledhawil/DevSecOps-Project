from flask import Blueprint, request, jsonify
from app.main import db, logger
from app.models import Notification, NotificationTemplate, UserNotificationPreferences
from app.tasks import send_notification_task
from datetime import datetime
import uuid

api_bp = Blueprint('api', __name__, url_prefix='/api/v1')

# Notification endpoints
@api_bp.route('/notifications/send', methods=['POST'])
def send_notification():
    try:
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['user_id', 'type', 'channel', 'message']
        if not all(field in data for field in required_fields):
            return jsonify({
                'error': {
                    'code': 'VALIDATION_ERROR',
                    'message': 'Missing required fields'
                }
            }), 400
        
        # Create notification record
        notification = Notification(
            id=str(uuid.uuid4()),
            user_id=data['user_id'],
            type=data['type'],
            channel=data['channel'],
            subject=data.get('subject'),
            message=data['message'],
            data=data.get('data', {}),
            status='pending'
        )
        
        db.session.add(notification)
        db.session.commit()
        
        # Queue notification for sending
        send_notification_task.delay(notification.id)
        
        logger.info(f'Notification queued: {notification.id}')
        
        return jsonify({
            'success': True,
            'data': notification.to_dict(),
            'message': 'Notification queued successfully'
        }), 201
        
    except Exception as e:
        logger.error(f'Failed to send notification: {e}')
        db.session.rollback()
        return jsonify({
            'error': {
                'code': 'INTERNAL_ERROR',
                'message': 'Failed to send notification'
            }
        }), 500

@api_bp.route('/notifications/<notification_id>', methods=['GET'])
def get_notification(notification_id):
    try:
        notification = Notification.query.get(notification_id)
        
        if not notification:
            return jsonify({
                'error': {
                    'code': 'NOT_FOUND',
                    'message': 'Notification not found'
                }
            }), 404
        
        return jsonify({
            'success': True,
            'data': notification.to_dict()
        })
        
    except Exception as e:
        logger.error(f'Failed to get notification: {e}')
        return jsonify({
            'error': {
                'code': 'INTERNAL_ERROR',
                'message': 'Failed to retrieve notification'
            }
        }), 500

@api_bp.route('/notifications/user/<user_id>', methods=['GET'])
def get_user_notifications(user_id):
    try:
        page = request.args.get('page', 1, type=int)
        limit = request.args.get('limit', 10, type=int)
        
        notifications = Notification.query.filter_by(user_id=user_id)\
            .order_by(Notification.created_at.desc())\
            .paginate(page=page, per_page=limit, error_out=False)
        
        return jsonify({
            'success': True,
            'data': [n.to_dict() for n in notifications.items],
            'pagination': {
                'page': page,
                'limit': limit,
                'total': notifications.total,
                'total_pages': notifications.pages
            }
        })
        
    except Exception as e:
        logger.error(f'Failed to get user notifications: {e}')
        return jsonify({
            'error': {
                'code': 'INTERNAL_ERROR',
                'message': 'Failed to retrieve notifications'
            }
        }), 500

@api_bp.route('/notifications', methods=['GET'])
def list_notifications():
    try:
        page = request.args.get('page', 1, type=int)
        limit = request.args.get('limit', 10, type=int)
        
        notifications = Notification.query\
            .order_by(Notification.created_at.desc())\
            .paginate(page=page, per_page=limit, error_out=False)
        
        return jsonify({
            'success': True,
            'data': [n.to_dict() for n in notifications.items],
            'pagination': {
                'page': page,
                'limit': limit,
                'total': notifications.total,
                'total_pages': notifications.pages
            }
        })
        
    except Exception as e:
        logger.error(f'Failed to list notifications: {e}')
        return jsonify({
            'error': {
                'code': 'INTERNAL_ERROR',
                'message': 'Failed to retrieve notifications'
            }
        }), 500

# Template endpoints
@api_bp.route('/templates', methods=['GET'])
def list_templates():
    try:
        templates = NotificationTemplate.query.filter_by(is_active=True).all()
        
        return jsonify({
            'success': True,
            'data': [t.to_dict() for t in templates]
        })
        
    except Exception as e:
        logger.error(f'Failed to list templates: {e}')
        return jsonify({
            'error': {
                'code': 'INTERNAL_ERROR',
                'message': 'Failed to retrieve templates'
            }
        }), 500

@api_bp.route('/templates/<template_id>', methods=['GET'])
def get_template(template_id):
    try:
        template = NotificationTemplate.query.get(template_id)
        
        if not template:
            return jsonify({
                'error': {
                    'code': 'NOT_FOUND',
                    'message': 'Template not found'
                }
            }), 404
        
        return jsonify({
            'success': True,
            'data': template.to_dict()
        })
        
    except Exception as e:
        logger.error(f'Failed to get template: {e}')
        return jsonify({
            'error': {
                'code': 'INTERNAL_ERROR',
                'message': 'Failed to retrieve template'
            }
        }), 500

# Preferences endpoints
@api_bp.route('/preferences/<user_id>', methods=['GET'])
def get_preferences(user_id):
    try:
        preferences = UserNotificationPreferences.query.filter_by(user_id=user_id).first()
        
        if not preferences:
            return jsonify({
                'error': {
                    'code': 'NOT_FOUND',
                    'message': 'Preferences not found'
                }
            }), 404
        
        return jsonify({
            'success': True,
            'data': preferences.to_dict()
        })
        
    except Exception as e:
        logger.error(f'Failed to get preferences: {e}')
        return jsonify({
            'error': {
                'code': 'INTERNAL_ERROR',
                'message': 'Failed to retrieve preferences'
            }
        }), 500

@api_bp.route('/preferences/<user_id>', methods=['PUT'])
def update_preferences(user_id):
    try:
        data = request.get_json()
        
        preferences = UserNotificationPreferences.query.filter_by(user_id=user_id).first()
        
        if not preferences:
            # Create new preferences
            preferences = UserNotificationPreferences(
                id=str(uuid.uuid4()),
                user_id=user_id
            )
            db.session.add(preferences)
        
        # Update preferences
        if 'email_enabled' in data:
            preferences.email_enabled = data['email_enabled']
        if 'sms_enabled' in data:
            preferences.sms_enabled = data['sms_enabled']
        if 'push_enabled' in data:
            preferences.push_enabled = data['push_enabled']
        if 'frequency' in data:
            preferences.frequency = data['frequency']
        if 'preferences' in data:
            preferences.preferences = data['preferences']
        
        preferences.updated_at = datetime.utcnow()
        
        db.session.commit()
        
        logger.info(f'Preferences updated for user: {user_id}')
        
        return jsonify({
            'success': True,
            'data': preferences.to_dict(),
            'message': 'Preferences updated successfully'
        })
        
    except Exception as e:
        logger.error(f'Failed to update preferences: {e}')
        db.session.rollback()
        return jsonify({
            'error': {
                'code': 'INTERNAL_ERROR',
                'message': 'Failed to update preferences'
            }
        }), 500

def register_routes(app):
    app.register_blueprint(api_bp)
