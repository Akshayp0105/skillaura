import base64
import numpy as np
import cv2
import mediapipe as mp

mp_face_detection = mp.solutions.face_detection
mp_face_mesh = mp.solutions.face_mesh

def analyze_image(base64_str: str) -> str:
    """Analyze a base64 encoded image and return gesture feedback."""
    if not base64_str:
        return ""
    try:
        # Decode base64
        if ',' in base64_str:
            base64_str = base64_str.split(',')[1]
        img_data = base64.b64decode(base64_str)
        nparr = np.frombuffer(img_data, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        if img is None:
            return ""

        # Convert the BGR image to RGB
        RGB_img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        
        feedback = []
        
        # Face detection
        with mp_face_detection.FaceDetection(min_detection_confidence=0.5) as face_detection:
            results = face_detection.process(RGB_img)
            if not results.detections:
                return "\n\n[AI Feedback]: We couldn't detect your face clearly. Please ensure you are in a well-lit room and facing the camera directly."
            elif len(results.detections) > 1:
                return "\n\n[AI Feedback]: Multiple faces detected. Please ensure you are alone in the frame for the interview."
            
        # Facial Landmark Heuristics
        with mp_face_mesh.FaceMesh(static_image_mode=True, max_num_faces=1, min_detection_confidence=0.5) as face_mesh:
            results = face_mesh.process(RGB_img)
            if results.multi_face_landmarks:
                landmarks = results.multi_face_landmarks[0].landmark
                
                # Check for eye contact / head tilt
                # 33 = left eye outer corner, 263 = right eye outer corner
                left_eye = landmarks[33]
                right_eye = landmarks[263]
                
                eye_y_diff = abs(left_eye.y - right_eye.y)
                if eye_y_diff > 0.04:
                    feedback.append("Your head seems a bit tilted; try to keep it level for a more professional posture.")
                else:
                    feedback.append("You maintained good posture and steady eye contact with the camera.")
                    
                # 61 = left mouth corner, 291 = right mouth corner
                # 13 = inner top lip, 14 = inner bottom lip
                left_lip = landmarks[61]
                right_lip = landmarks[291]
                top_lip = landmarks[13]
                bottom_lip = landmarks[14]
                
                mouth_width = abs(left_lip.x - right_lip.x)
                mouth_height = abs(top_lip.y - bottom_lip.y)
                
                # Simple heuristic: if the mouth is wide but relatively closed, it's often a smile
                # If both are large, they might be talking. 
                # Since we take the picture at the end, they should ideally be smiling/relaxed.
                if mouth_width > 0.08 and mouth_height < 0.05:
                    feedback.append("Great job maintaining a warm, confident smile at the end of your response!")
                else:
                    feedback.append("Your expression was focused, but remember to smile occasionally to build better rapport with the interviewer.")
        
        if not feedback:
            return ""
            
        return "\n\n[AI Feedback on Gestures & Posture]: " + " ".join(feedback)
        
    except Exception as e:
        print(f"Gesture analysis error: {e}")
        return ""
