import firebase_admin
from firebase_admin import credentials, messaging
from app.core.logging import logger
from app.core.config import get_settings

settings = get_settings()

class FCMService:
    def __init__(self):
        self._is_initialized = False
        try:
            # Check if default app exists, otherwise initialize it
            firebase_admin.get_app()
            self._is_initialized = True
        except ValueError:
            # In a real environment, you'd load the secure JSON cert here.
            # E.g. cred = credentials.Certificate('path/to/serviceAccountKey.json')
            # firebase_admin.initialize_app(cred)
            # For demonstration without physical keys, we initialize an empty app
            # which might fail actual sends, but tests the logic.
            logger.warning("Initializing FCM without explicit credentials for Sandbox")
            try:
                firebase_admin.initialize_app()
                self._is_initialized = True
            except Exception as e:
                logger.error(f"Failed to boot FCM context natively: {e}")

    async def send_notification(self, token: str, title: str, body: str, data: dict = None) -> bool:
        """
        Sends a Push Notification exclusively through FCM to the targeted device token.
        """
        if not self._is_initialized or not token:
            logger.warning(f"Skipping FCM Push to '{token}'. Service uninitialized.")
            return False

        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=data if data else {},
            token=token,
        )

        try:
            response = messaging.send(message)
            logger.info(f"Successfully sent FCM notification: {response}")
            return True
        except Exception as e:
            logger.error(f"FCM Notification Delivery Failed to {token}: {str(e)}")
            return False

fcm_service = FCMService()
