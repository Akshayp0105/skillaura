import os
import smtplib
from email.message import EmailMessage
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

router = APIRouter()

class NotificationRequest(BaseModel):
    email: str
    subject: str
    body: str

@router.post("/send-notification")
async def send_notification(req: NotificationRequest):
    smtp_email = os.getenv("SMTP_EMAIL")
    smtp_password = os.getenv("SMTP_PASSWORD")
    
    if not smtp_email or not smtp_password:
        # Fallback for dev mode
        print(f"--- [DEV MODE NOTIFICATION] ---")
        print(f"To: {req.email}")
        print(f"Subject: {req.subject}")
        print(f"Body: {req.body}")
        print(f"-------------------------------")
        return {"status": "success", "message": "Email logged to console (configure SMTP_EMAIL and SMTP_PASSWORD to send real emails)"}

    try:
        msg = EmailMessage()
        msg.set_content(req.body)
        msg['Subject'] = req.subject
        msg['From'] = smtp_email
        msg['To'] = req.email

        # Using Gmail SMTP servers as default
        with smtplib.SMTP_SSL('smtp.gmail.com', 465) as smtp:
            smtp.login(smtp_email, smtp_password)
            smtp.send_message(msg)

        return {"status": "success", "message": "Email sent"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
