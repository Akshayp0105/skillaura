import os
import json
import uuid
import traceback

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Dict, Optional

# Document Generation
from fpdf import FPDF
from docx import Document

# AI Content Engine
from resume_ai_engine import generate_smart_bullets, generate_smart_summary, _match_role

router = APIRouter()

GENERATED_FILES_DIR = "static/resumes"
os.makedirs(GENERATED_FILES_DIR, exist_ok=True)

class ChatMessage(BaseModel):
    role: str
    content: str

class ImproveResumeRequest(BaseModel):
    uid: str
    messages: List[ChatMessage]

# ─── 10 Professional ATS Resume Templates ───
RESUME_TEMPLATES = [
    {"id": "classic",   "name": "Classic Professional", "accent": (0, 51, 102),   "header_bg": (0, 51, 102)},
    {"id": "modern",    "name": "Modern Teal",          "accent": (0, 128, 128),  "header_bg": (0, 128, 128)},
    {"id": "executive", "name": "Executive Gold",       "accent": (139, 90, 43),  "header_bg": (51, 51, 51)},
    {"id": "minimal",   "name": "Clean Minimal",        "accent": (80, 80, 80),   "header_bg": (60, 60, 60)},
    {"id": "tech",      "name": "Tech Blue",            "accent": (30, 100, 200), "header_bg": (25, 55, 109)},
    {"id": "creative",  "name": "Creative Red",         "accent": (180, 40, 40),  "header_bg": (140, 30, 30)},
    {"id": "academic",  "name": "Academic Green",       "accent": (0, 100, 60),   "header_bg": (0, 80, 50)},
    {"id": "startup",   "name": "Startup Purple",       "accent": (100, 50, 150), "header_bg": (80, 40, 120)},
    {"id": "corporate", "name": "Corporate Navy",       "accent": (0, 40, 85),    "header_bg": (0, 30, 70)},
    {"id": "elegant",   "name": "Elegant Charcoal",     "accent": (50, 50, 50),   "header_bg": (40, 40, 40)},
]

def _safe(text: str) -> str:
    if not isinstance(text, str):
        text = str(text)
    return text.encode('ascii', 'replace').decode('ascii')


# ─── Professional PDF Generator ───

def generate_pdf(data: dict, filename: str, template: dict = None) -> str:
    import random
    if template is None:
        template = random.choice(RESUME_TEMPLATES)

    pdf = FPDF()
    pdf.add_page()
    pdf.set_auto_page_break(auto=True, margin=15)
    
    accent = template["accent"]
    header_bg = template["header_bg"]
    
    # ── Header Block with colored background ──
    pdf.set_fill_color(*header_bg)
    pdf.rect(0, 0, 210, 42, 'F')
    
    # Name (white on dark header)
    pdf.set_y(8)
    pdf.set_font("Helvetica", 'B', 24)
    pdf.set_text_color(255, 255, 255)
    pdf.cell(w=0, h=12, text=_safe(data.get("name", "").upper()), align='C')
    pdf.ln(14)
    
    # Contact row
    pdf.set_font("Helvetica", '', 9)
    pdf.set_text_color(220, 220, 220)
    contact_parts = []
    if data.get("email"):
        contact_parts.append(_safe(data["email"]))
    if data.get("phone"):
        contact_parts.append(_safe(data["phone"]))
    if data.get("linkedin"):
        contact_parts.append(_safe(data["linkedin"]))
    if data.get("github"):
        contact_parts.append(_safe(data["github"]))
    if data.get("portfolio"):
        contact_parts.append(_safe(data["portfolio"]))
    contact_line = "  |  ".join(contact_parts)
    pdf.cell(w=0, h=6, text=contact_line, align='C')
    pdf.ln(14)
    
    # Reset text to black
    pdf.set_text_color(0, 0, 0)
    y_after_header = pdf.get_y()
    
    def _section_header(title):
        pdf.ln(3)
        pdf.set_font("Helvetica", 'B', 11)
        pdf.set_text_color(*accent)
        pdf.cell(w=0, h=7, text=title.upper())
        pdf.ln(8)
        pdf.set_draw_color(*accent)
        pdf.set_line_width(0.6)
        pdf.line(10, pdf.get_y(), 200, pdf.get_y())
        pdf.ln(4)
    
    # ── Professional Summary ──
    if data.get("summary"):
        _section_header("Professional Summary")
        pdf.set_font("Helvetica", '', 9)
        pdf.set_text_color(40, 40, 40)
        pdf.multi_cell(w=0, h=4.5, text=_safe(data["summary"]))
    
    # ── Work Experience ──
    if data.get("experience"):
        _section_header("Work Experience")
        for exp in data["experience"]:
            pdf.set_font("Helvetica", 'B', 10)
            pdf.set_text_color(0, 0, 0)
            title = _safe(exp.get("title", ""))
            company = _safe(exp.get("company", ""))
            # Title and company on same line, date right-aligned
            pdf.cell(w=140, h=6, text=f"{title} | {company}")
            pdf.set_font("Helvetica", 'I', 9)
            pdf.set_text_color(100, 100, 100)
            pdf.cell(w=0, h=6, text=_safe(exp.get("date", "")), align='R')
            pdf.ln(7)
            
            pdf.set_font("Helvetica", '', 9)
            pdf.set_text_color(40, 40, 40)
            for bullet in exp.get("bullets", []):
                pdf.cell(w=5, h=4.5, text="")  # indent
                pdf.multi_cell(w=0, h=4.5, text="- " + _safe(bullet))
                pdf.ln(0.5)
            pdf.ln(2)
    
    # ── Education ──
    if data.get("education"):
        _section_header("Education")
        for edu in data["education"]:
            pdf.set_font("Helvetica", 'B', 10)
            pdf.set_text_color(0, 0, 0)
            degree = _safe(edu.get("degree", ""))
            school = _safe(edu.get("school", ""))
            pdf.cell(w=140, h=6, text=f"{degree}")
            pdf.set_font("Helvetica", 'I', 9)
            pdf.set_text_color(100, 100, 100)
            pdf.cell(w=0, h=6, text=_safe(edu.get("date", "")), align='R')
            pdf.ln(6)
            pdf.set_font("Helvetica", '', 9)
            pdf.set_text_color(60, 60, 60)
            pdf.cell(w=0, h=5, text=school)
            pdf.ln(4)
            if edu.get("gpa"):
                pdf.set_font("Helvetica", 'I', 9)
                pdf.cell(w=0, h=5, text=f"GPA: {_safe(edu['gpa'])}")
                pdf.ln(5)
            pdf.ln(1)
    
    # ── Technical Skills ──
    if data.get("skills"):
        _section_header("Technical Skills")
        pdf.set_font("Helvetica", '', 9)
        pdf.set_text_color(40, 40, 40)
        if isinstance(data["skills"], list):
            # Group skills nicely
            skills_text = _safe("  |  ".join(data["skills"]))
        else:
            skills_text = _safe(str(data["skills"]))
        pdf.multi_cell(w=0, h=5, text=skills_text)
    
    # ── Projects ──
    if data.get("projects"):
        _section_header("Projects")
        for proj in data["projects"]:
            pdf.set_font("Helvetica", 'B', 10)
            pdf.set_text_color(0, 0, 0)
            pdf.cell(w=0, h=6, text=_safe(proj.get("name", "")))
            pdf.ln(6)
            pdf.set_font("Helvetica", '', 9)
            pdf.set_text_color(40, 40, 40)
            pdf.multi_cell(w=0, h=4.5, text="- " + _safe(proj.get("description", "")))
            pdf.ln(2)
    
    # ── Certifications ──
    if data.get("certifications"):
        _section_header("Certifications")
        pdf.set_font("Helvetica", '', 9)
        pdf.set_text_color(40, 40, 40)
        for cert in data["certifications"]:
            pdf.cell(w=0, h=5, text="- " + _safe(cert))
            pdf.ln(5)

    filepath = os.path.join(GENERATED_FILES_DIR, f"{filename}.pdf")
    pdf.output(filepath)
    return f"/static/resumes/{filename}.pdf"


def generate_docx(data: dict, filename: str) -> str:
    doc = Document()
    
    doc.add_heading(data.get("name", ""), 0)
    contact_parts = []
    for key in ["email", "phone", "linkedin", "github", "portfolio"]:
        if data.get(key):
            contact_parts.append(data[key])
    doc.add_paragraph(" | ".join(contact_parts))
    
    if data.get("summary"):
        doc.add_heading("Professional Summary", level=1)
        doc.add_paragraph(data["summary"])
        
    if data.get("experience"):
        doc.add_heading("Work Experience", level=1)
        for exp in data["experience"]:
            p = doc.add_paragraph()
            p.add_run(f"{exp.get('title', '')} | {exp.get('company', '')}").bold = True
            doc.add_paragraph(exp.get("date", ""), style='Intense Quote')
            for bullet in exp.get("bullets", []):
                doc.add_paragraph(bullet, style='List Bullet')

    if data.get("education"):
        doc.add_heading("Education", level=1)
        for edu in data["education"]:
            doc.add_paragraph(f"{edu.get('degree', '')} - {edu.get('school', '')} ({edu.get('date', '')})")
            if edu.get("gpa"):
                doc.add_paragraph(f"GPA: {edu['gpa']}")

    if data.get("skills"):
        doc.add_heading("Technical Skills", level=1)
        if isinstance(data["skills"], list):
            doc.add_paragraph(" | ".join(data["skills"]))
        else:
            doc.add_paragraph(str(data["skills"]))
    
    if data.get("projects"):
        doc.add_heading("Projects", level=1)
        for proj in data["projects"]:
            p = doc.add_paragraph()
            p.add_run(proj.get("name", "")).bold = True
            doc.add_paragraph(proj.get("description", ""), style='List Bullet')
    
    if data.get("certifications"):
        doc.add_heading("Certifications", level=1)
        for cert in data["certifications"]:
            doc.add_paragraph(cert, style='List Bullet')

    filepath = os.path.join(GENERATED_FILES_DIR, f"{filename}.docx")
    doc.save(filepath)
    return f"/static/resumes/{filename}.docx"


# ─── Multi-Step Conversation Engine ───
# Each session stores collected data keyed by uid

_session_data = {}  # uid -> dict of collected resume fields

STEPS = [
    {"key": "name",           "question": "Let's build your professional resume! First, what is your **full name**?"},
    {"key": "email",          "question": "Great! What is your **email address**?"},
    {"key": "phone",          "question": "What is your **phone number**? (with country code, e.g., +91 9876543210)"},
    {"key": "linkedin",       "question": "Do you have a **LinkedIn profile URL**? (type 'skip' if you don't have one)"},
    {"key": "target_role",    "question": "What **role** are you applying for? (e.g., 'Software Engineer', 'Frontend Developer')"},
    {"key": "target_company", "question": "Which **company** are you targeting? (e.g., 'Google', 'Amazon', 'TCS')"},
    {"key": "education",      "question": "Tell me about your **education**. Please provide:\n**Degree, College/University, Year** (e.g., 'B.Tech CSE, VIT University, 2021-2025')\n\nYou can add multiple entries separated by semicolons (;)"},
    {"key": "experience",     "question": "Do you have any **work experience or internships**? If yes, provide:\n**Title, Company, Duration** (e.g., 'Frontend Intern, Infosys, Jun 2024 - Aug 2024')\n\nType 'fresher' if you have no experience. Separate multiple entries with semicolons (;)"},
    {"key": "skills",         "question": "List your **technical skills** separated by commas:\n(e.g., 'Python, React, AWS, SQL, Git, Docker')"},
    {"key": "projects",       "question": "Mention 1-2 **notable projects** with a brief description:\n(e.g., 'E-Commerce App - Built a full-stack shopping platform using React and Node.js')\n\nSeparate multiple projects with semicolons (;). Type 'skip' to skip."},
    {"key": "certifications",  "question": "Any **certifications**? (e.g., 'AWS Cloud Practitioner, Google IT Support')\n\nType 'skip' if none."},
]


def _get_step_index(uid: str) -> int:
    """Get current step for this user session."""
    if uid not in _session_data:
        _session_data[uid] = {"_step": 0}
    return _session_data[uid].get("_step", 0)


def _store_answer(uid: str, key: str, value: str):
    """Store user answer for a step."""
    if uid not in _session_data:
        _session_data[uid] = {"_step": 0}
    _session_data[uid][key] = value.strip()
    _session_data[uid]["_step"] = _session_data[uid].get("_step", 0) + 1


def _parse_education(text: str) -> list:
    """Parse education entries from user text."""
    entries = [e.strip() for e in text.split(";") if e.strip()]
    result = []
    for entry in entries:
        parts = [p.strip() for p in entry.split(",")]
        edu = {
            "degree": parts[0] if len(parts) > 0 else entry,
            "school": parts[1] if len(parts) > 1 else "",
            "date":   parts[2] if len(parts) > 2 else "",
        }
        if len(parts) > 3:
            edu["gpa"] = parts[3]
        result.append(edu)
    return result if result else [{"degree": text, "school": "", "date": ""}]


def _parse_experience(text: str, skills: list, role: str = "", company: str = "") -> list:
    """Parse experience entries and generate AI-driven bullet points."""
    if text.lower().strip() in ["fresher", "no", "none", "skip", "na", "n/a"]:
        bullets = generate_smart_bullets(role or "intern", company or "", skills, count=5)
        return [{
            "title": "Software Development (Academic Projects)",
            "company": "University / Personal Projects",
            "date": "2024 - Present",
            "bullets": bullets
        }]
    
    entries = [e.strip() for e in text.split(";") if e.strip()]
    result = []
    for entry in entries:
        parts = [p.strip() for p in entry.split(",")]
        # Use the specific entry title for bullet generation if it mentions a role
        entry_role = parts[0] if len(parts) > 0 else role
        entry_company = parts[1] if len(parts) > 1 else company
        
        bullets = generate_smart_bullets(
            role=entry_role,
            company=entry_company,
            skills=skills,
            count=5
        )
        
        exp = {
            "title":   parts[0] if len(parts) > 0 else entry,
            "company": parts[1] if len(parts) > 1 else "",
            "date":    parts[2] if len(parts) > 2 else "",
            "bullets": bullets
        }
        result.append(exp)
    return result if result else [{"title": text, "company": "", "date": "", "bullets": generate_smart_bullets(role, company, skills)}]


def _parse_projects(text: str) -> list:
    if text.lower().strip() in ["skip", "no", "none", "na", "n/a"]:
        return []
    entries = [e.strip() for e in text.split(";") if e.strip()]
    result = []
    for entry in entries:
        parts = entry.split(" - ", 1)
        result.append({
            "name": parts[0].strip(),
            "description": parts[1].strip() if len(parts) > 1 else parts[0].strip()
        })
    return result


def _parse_certifications(text: str) -> list:
    if text.lower().strip() in ["skip", "no", "none", "na", "n/a"]:
        return []
    return [c.strip() for c in text.split(",") if c.strip()]


def _build_resume_data(uid: str) -> dict:
    """Build the final resume data from collected session info."""
    sd = _session_data.get(uid, {})
    
    skills = [s.strip() for s in sd.get("skills", "").split(",") if s.strip()]
    role = sd.get("target_role", "Software Developer")
    company = sd.get("target_company", "")
    
    experience_text = sd.get("experience", "fresher")
    exp_years = ""
    if experience_text.lower().strip() not in ["fresher", "no", "none", "skip"]:
        exp_years = "1+"  # Default assumption
    else:
        exp_years = "fresher"
    
    education = _parse_education(sd.get("education", ""))
    experience = _parse_experience(experience_text, skills, role, company)
    projects = _parse_projects(sd.get("projects", "skip"))
    certifications = _parse_certifications(sd.get("certifications", "skip"))
    
    # AI-driven summary generation
    summary = generate_smart_summary(
        name=sd.get("name", ""),
        role=role,
        company=company,
        skills=skills,
        exp_text=experience_text
    )
    
    # Get AI skill suggestions for the role
    role_data = _match_role(role)
    suggested_skills = role_data.get("skills_suggest", [])
    # Merge user skills with suggested ones (user's first)
    all_skills = list(dict.fromkeys(skills + [s for s in suggested_skills if s.lower() not in [sk.lower() for sk in skills]]))
    
    return {
        "name": sd.get("name", ""),
        "email": sd.get("email", ""),
        "phone": sd.get("phone", ""),
        "linkedin": sd.get("linkedin", "") if sd.get("linkedin", "").lower() != "skip" else "",
        "summary": summary,
        "experience": experience,
        "education": education,
        "skills": all_skills,
        "projects": projects,
        "certifications": certifications,
    }


@router.post("/improve-resume")
async def improve_resume(req: ImproveResumeRequest):
    try:
        uid = req.uid or "default"
        
        # Filter out system context messages
        user_messages = [m for m in req.messages if m.role == "user" and not m.content.startswith("System Context:")]
        
        # Get the last user message
        last_msg = user_messages[-1].content.strip() if user_messages else ""
        
        # Initialize session if needed
        if uid not in _session_data:
            _session_data[uid] = {"_step": 0}
        
        # Check if user wants to restart
        if last_msg.lower() in ["restart", "start over", "reset", "new"]:
            _session_data[uid] = {"_step": 0}
            return {
                "reply": "Session reset! " + STEPS[0]["question"],
                "pdf_url": None,
                "docx_url": None
            }
        
        step = _session_data[uid].get("_step", 0)
        
        # If we haven't started yet (first message), start the flow
        if step == 0 and len(user_messages) <= 1:
            # Check if skills were pre-loaded from profile
            for m in req.messages:
                if m.role == "user" and m.content.startswith("System Context:"):
                    if "skills are:" in m.content:
                        skills_part = m.content.split("skills are:")[1].split(".")[0].strip()
                        _session_data[uid]["_profile_skills"] = skills_part
            
            _session_data[uid]["_step"] = 0
            return {
                "reply": "Welcome to the **Basic Resume Builder**! I'll collect your information step by step and generate an industry-level, ATS-optimized resume.\n\n" + STEPS[0]["question"],
                "pdf_url": None,
                "docx_url": None
            }
        
        # Store the answer for current step
        if step < len(STEPS):
            current_key = STEPS[step]["key"]
            _store_answer(uid, current_key, last_msg)
            
            # Auto-fill skills from profile if skills step and user provided less than 3
            if current_key == "skills" and len(last_msg.split(",")) < 3:
                profile_skills = _session_data[uid].get("_profile_skills", "")
                if profile_skills:
                    _session_data[uid]["skills"] = last_msg + ", " + profile_skills if last_msg.lower() != "skip" else profile_skills
            
            new_step = _session_data[uid].get("_step", 0)
            
            # If there are more steps, ask the next question
            if new_step < len(STEPS):
                next_q = STEPS[new_step]["question"]
                progress = f"[{new_step}/{len(STEPS)}]"
                return {
                    "reply": f"Got it! {progress}\n\n{next_q}",
                    "pdf_url": None,
                    "docx_url": None
                }
            else:
                # All data collected! Generate resume
                resume_data = _build_resume_data(uid)
                
                import random
                template = random.choice(RESUME_TEMPLATES)
                file_id = str(uuid.uuid4())
                
                try:
                    pdf_url = generate_pdf(resume_data, file_id, template)
                    docx_url = generate_docx(resume_data, file_id)
                    
                    reply = (f"Your professional ATS-optimized resume has been generated using the **{template['name']}** template!\n\n"
                             f"**Name:** {resume_data['name']}\n"
                             f"**Target Role:** {_session_data[uid].get('target_role', '')}\n"
                             f"**Target Company:** {_session_data[uid].get('target_company', '')}\n\n"
                             f"Download your resume using the buttons below.\n\n"
                             f"**ATS Tips:**\n"
                             f"- Customize bullet points with specific metrics from your real work\n"
                             f"- Add keywords from the job description\n"
                             f"- Keep your resume to 1 page for under 5 years experience\n\n"
                             f"Type **'restart'** to create another resume with different details.")
                    
                    # Reset session for next use
                    _session_data[uid] = {"_step": 0}
                    
                    return {
                        "reply": reply,
                        "pdf_url": pdf_url,
                        "docx_url": docx_url
                    }
                except Exception as e:
                    traceback.print_exc()
                    return {
                        "reply": f"Error generating resume documents: {str(e)}. Please try again.",
                        "pdf_url": None,
                        "docx_url": None
                    }
        else:
            # Session completed, user is asking something else
            if any(kw in last_msg.lower() for kw in ["generate", "create", "make", "build", "another", "new", "restart"]):
                _session_data[uid] = {"_step": 0}
                return {
                    "reply": "Starting a new resume! " + STEPS[0]["question"],
                    "pdf_url": None,
                    "docx_url": None
                }
            
            return {
                "reply": "Your resume has already been generated! Type **'restart'** to create a new one with different details.",
                "pdf_url": None,
                "docx_url": None
            }
        
    except Exception as e:
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))
