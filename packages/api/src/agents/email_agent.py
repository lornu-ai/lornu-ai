import os
import logging
import resend

logger = logging.getLogger(__name__)

class EmailAgent:
    def __init__(self):
        self.api_key = os.getenv("RESEND_API_KEY")
        if self.api_key:
            resend.api_key = self.api_key
            self.enabled = True
        else:
            logger.warning("RESEND_API_KEY not set. Email functionality disabled.")
            self.enabled = False

        self.contact_to = os.getenv("CONTACT_EMAIL", "contact@lornu.ai")

    def send_contact_email(self, name: str, email: str, message: str) -> bool:
        """
        Sends a contact form email using Resend.
        """
        if not self.enabled:
            logger.error("Attempted to send email but Resend is not enabled.")
            return False

        try:
            params = {
                "from": "LornuAI Contact Form <noreply@lornu.ai>",
                "to": [self.contact_to],
                "subject": f"New Contact Message from {name}",
                "reply_to": email,
                "html": f"""
                    <h2>New Contact Form Submission</h2>
                    <p><strong>Name:</strong> {name}</p>
                    <p><strong>Email:</strong> {email}</p>
                    <p><strong>Message:</strong></p>
                    <p>{message}</p>
                """,
            }

            r = resend.Emails.send(params)
            logger.info(f"Email sent successfully: {r.get('id')}")
            return True

        except Exception as e:
            logger.error(f"Failed to send email: {e}")
            return False
