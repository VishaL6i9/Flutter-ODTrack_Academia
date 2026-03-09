import logging
from app.models.od_request import ODRequest
from app.models.user import User
from app.core.enums import ODStatus

logger = logging.getLogger(__name__)

class EmailService:
    async def send_notification(self, subject: str, body: str, to_email: str) -> bool:
        """
        Mock email sending service. In production, connect via aiosmtplib.
        """
        try:
            logger.info("--------------------------------------------------")
            logger.info(f"EMAIL MOCK SENT TO: {to_email}")
            logger.info(f"SUBJECT: {subject}")
            logger.info(f"BODY:\n{body}")
            logger.info("--------------------------------------------------")
            return True
        except Exception as e:
            logger.error(f"Failed to send mock email: {e}")
            return False
            
    async def send_od_submission_email(self, student: User, od_request: ODRequest, staff: list[User]) -> None:
        """
        Notify appropriate staff/coordinators that an OD has been submitted.
        """
        subject = f"New OD Request Submitted by {student.name} ({student.register_number})"
        body = f"""
        Dear Staff,
        
        A new OD Request has been submitted by {student.name} ({student.register_number}) for date {od_request.date}.
        Reason: {od_request.reason}
        Periods: {od_request.periods}
        
        Please log into ODTrack Academia to review.
        """
        # Send to all relevant staff
        for member in staff:
            if member.email:
                await self.send_notification(subject, body, member.email)

    async def send_od_status_update_email(self, student: User, od_request: ODRequest) -> None:
        """
        Notify student of approval or rejection.
        """
        subject = f"OD Request Status Updated: {od_request.status.upper()}"
        body = f"""
        Dear {student.name},
        
        Your OD Request for date {od_request.date} has been marked as {od_request.status}.
        """
        if od_request.status == ODStatus.REJECTED and od_request.rejection_reason:
             body += f"\nReason for rejection: {od_request.rejection_reason}"
             
        if student.email:
            await self.send_notification(subject, body, student.email)

email_service = EmailService()
