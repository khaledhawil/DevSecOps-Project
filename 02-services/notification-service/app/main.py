import os
import logging
from flask import Flask
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Initialize Flask app
app = Flask(__name__)

# Configuration
app.config['SQLALCHEMY_DATABASE_URI'] = f"postgresql://{os.getenv('DB_USER')}:{os.getenv('DB_PASSWORD')}@{os.getenv('DB_HOST')}:{os.getenv('DB_PORT')}/{os.getenv('DB_NAME')}"
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'dev-secret-key')

# Initialize extensions
db = SQLAlchemy(app)
CORS(app)

# Configure logging
logging.basicConfig(
    level=getattr(logging, os.getenv('LOG_LEVEL', 'INFO')),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Import routes after app initialization
from app.routes import register_routes
register_routes(app)

# Health check routes
@app.route('/health', methods=['GET'])
def health():
    return {'status': 'healthy', 'service': 'notification-service', 'version': '1.0.0'}

@app.route('/health/ready', methods=['GET'])
def health_ready():
    try:
        # Check database connection
        db.session.execute('SELECT 1')
        
        return {
            'status': 'healthy',
            'service': 'notification-service',
            'version': '1.0.0',
            'checks': {
                'database': 'healthy'
            }
        }
    except Exception as e:
        logger.error(f'Health check failed: {e}')
        return {
            'status': 'unhealthy',
            'service': 'notification-service',
            'version': '1.0.0',
            'checks': {
                'database': 'unhealthy'
            }
        }, 503

@app.route('/health/live', methods=['GET'])
def health_live():
    return {'status': 'alive', 'service': 'notification-service', 'version': '1.0.0'}

if __name__ == '__main__':
    port = int(os.getenv('PORT', 8083))
    debug = os.getenv('FLASK_DEBUG', '0') == '1'
    
    logger.info(f'Starting Notification Service on port {port}')
    app.run(host='0.0.0.0', port=port, debug=debug)
