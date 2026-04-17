# SkillAura  
AI-Powered Career Guidance & Resume Intelligence Platform  

SkillAura is an intelligent career guidance platform that helps students understand their skills, improve their resumes, and discover relevant internship and job opportunities using Artificial Intelligence and Natural Language Processing.

---

## Live Demo  

Frontend (Vercel): https://skillaura-h2l7.vercel.app  
Backend (Render): https://skillaura.onrender.com  

---

## Overview  

SkillAura addresses a common problem faced by students and beginners — the lack of clarity in career direction and skill development.

Traditional platforms rely on keyword-based matching, which often results in inaccurate or irrelevant recommendations. SkillAura uses AI and NLP techniques to analyze resumes and user inputs in a more meaningful way, providing personalized and context-aware career guidance.

---

## Problem Statement  

Many students face challenges such as:

- Lack of clarity about their skills and strengths  
- Poorly structured resumes  
- Irrelevant internship or job recommendations  
- Difficulty identifying skill gaps  
- Scattered interview preparation resources  

---

## Solution  

SkillAura provides a unified system that:

- Extracts skills from resumes, GitHub profiles, or text input  
- Evaluates resume quality and provides improvement suggestions  
- Identifies missing skills required for specific roles  
- Recommends relevant internships and job opportunities  
- Supports interview preparation  
- Tracks career progress over time  

---

## Core Features  

### Skill Extraction  
Uses NLP techniques to extract technical and soft skills from resumes and user inputs.

### Resume Evaluation  
Analyzes structure, content, and relevance to generate a resume score and improvement suggestions.

### Internship and Job Recommendation  
Matches user skills with industry requirements using semantic similarity.

### Skill Gap Analysis  
Identifies missing skills required for target roles and suggests areas for improvement.

### Interview Preparation  
Provides structured guidance for technical and HR interviews.

### Progress Tracking  
Tracks improvements in skills, resume quality, and career readiness.

---

## System Architecture  

The platform follows a multi-layer architecture:

- Frontend: Flutter application  
- Backend: FastAPI server  
- AI Layer: NLP-based processing and analysis  
- Database: Firebase Firestore  

The system integrates modules such as skill analysis, resume evaluation, recommendation engine, and progress tracking. :contentReference[oaicite:0]{index=0}  

---

## Tech Stack  

Frontend  
- Flutter  
- Dart  
- JavaScript  

Backend  
- Python  
- FastAPI  

Database  
- Firebase Firestore  

AI / NLP  
- Resume parsing  
- Semantic similarity models  

Tools  
- Git  
- GitHub  
- VS Code  

---

## Deployment  

Frontend  
- Built using Flutter Web  
- Deployed as a static site on Vercel  

Backend  
- FastAPI-based API service  
- Deployed on Render  

---

## Installation and Setup  

### Clone Repository  

```bash
git clone https://github.com/Akshayp0105/skillaura.git
cd skillaura
```

## Backend Setup
```
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
python main.py
```
## Frontend Setup
```
cd skillaura
flutter run
```
## Build for Web (Deployment)
```
flutter build web
```
## Screenshots
<img width="1919" height="885" alt="Screenshot 2026-04-17 130632" src="https://github.com/user-attachments/assets/efcacc8f-979e-4c9f-abd6-4e002e82f829" />

<img width="1893" height="813" alt="Screenshot 2026-04-17 130746" src="https://github.com/user-attachments/assets/962c7bc1-aae6-4ad5-8be2-39407b85a3ae" />

<img width="1919" height="890" alt="Screenshot 2026-04-17 130759" src="https://github.com/user-attachments/assets/9f1b6133-a49d-4000-9131-44f614dcb489" />

## Results
-Accurate skill extraction using NLP
-Effective resume scoring system
-Relevant internship and job recommendations
-Fast API response using FastAPI
-User-friendly interface
The system improves career readiness and helps students make informed decisions.

## Future Enhancements
-Advanced recommendation systems using deep learning
-Gamification features (progress tracking, achievements)
-Multi-language support
-Real-time job market integration
-Scalable analytics for career prediction

## Author  

Akshay P  

Built and engineered the  SkillAura platform as an end-to-end solution, covering UI/UX design, backend development, and AI/NLP integration.

## Conclusion
SkillAura bridges the gap between student skills and industry expectations by providing intelligent, data-driven career guidance. It enables users to understand their abilities, improve continuously, and align with real-world opportunities.
