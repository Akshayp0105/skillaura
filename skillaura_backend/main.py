import os
from dotenv import load_dotenv

# Load env FIRST before any submodules read os.getenv()
load_dotenv()

from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
import base64
import io
import re
import math
import httpx
from collections import Counter
from fastapi.staticfiles import StaticFiles
import notifications
import improve_resume

# ── ML / NLP imports (no pydantic conflict) ───────────────────────────
import pdfplumber
try:
    from docx import Document as DocxDocument
except ImportError:
    DocxDocument = None
try:
    from sklearn.feature_extraction.text import TfidfVectorizer
    SKLEARN_AVAILABLE = True
except ImportError:
    SKLEARN_AVAILABLE = False
# ───────────────────────────────────────────────────────────────────

# Comprehensive list of professional technical and soft skills
PREDEFINED_SKILLS = {
    "flutter", "dart", "react", "react native", "angular", "vue", "node.js", "python", "java", "c++", "c#", "go",
    "swift", "kotlin", "ruby", "php", "javascript", "typescript", "html", "css", "sql", "nosql", "firebase",
    "mongodb", "postgresql", "mysql", "redis", "docker", "kubernetes", "aws", "gcp", "azure", "git", "github",
    "gitlab", "ci/cd", "agile", "scrum", "machine learning", "artificial intelligence", "data science",
    "data analysis", "devops", "system design", "microservices", "api design", "rest api", "graphql", "tensorflow",
    "pytorch", "pandas", "numpy", "communication", "leadership", "problem solving", "teamwork", "time management",
    "critical thinking", "adaptability", "project management", "public speaking", "creativity", "photography",
    "video editing", "photoshop", "illustrator", "figma", "ui design", "ux design", "graphic design", "linux",
    "bash", "shell scripting", "excel", "powerpoint", "presentation", "research", "analytics", "negotiation",
    "mentoring", "coaching", "sales", "marketing", "content writing", "seo", "social media", "copywriting",
    "teaching", "training", "customer service", "event management", "finance", "accounting", "budgeting"
}

# Semantic hobby/trait → skills mapping
# Maps keywords in user text to inferred professional skills
HOBBY_TO_SKILLS: dict = {
    # Creative/Visual arts
    "draw": ["Graphic Design", "Creativity", "Attention to Detail"],
    "drawing": ["Graphic Design", "Creativity", "Attention to Detail"],
    "paint": ["Graphic Design", "Creativity", "Artistic Design"],
    "painting": ["Graphic Design", "Creativity", "Artistic Design"],
    "sketch": ["Graphic Design", "Attention to Detail", "Creativity"],
    "sketching": ["Graphic Design", "Attention to Detail", "Creativity"],
    "design": ["UI/UX Design", "Graphic Design", "Creativity"],
    "art": ["Graphic Design", "Creativity", "Artistic Design"],
    "sculpt": ["3D Modeling", "Creativity", "Attention to Detail"],
    "sculpting": ["3D Modeling", "Creativity", "Attention to Detail"],
    "photography": ["Photography", "Creativity", "Attention to Detail"],
    "photograph": ["Photography", "Creativity", "Visual Storytelling"],
    "photo": ["Photography", "Creativity"],
    "film": ["Videography", "Storytelling", "Creativity"],
    "video": ["Video Editing", "Videography", "Content Creation"],
    "animation": ["Animation", "Creativity", "Attention to Detail"],
    "cartoon": ["Graphic Design", "Creativity"],
    "illustrat": ["Illustration", "Graphic Design", "Creativity"],

    # Writing / Communication
    "writ": ["Content Writing", "Communication", "Attention to Detail"],
    "blog": ["Content Writing", "Digital Marketing", "Communication"],
    "journal": ["Written Communication", "Reflection", "Analytical Thinking"],
    "poet": ["Creative Writing", "Communication"],
    "storytell": ["Storytelling", "Communication", "Creativity"],
    "read": ["Continuous Learning", "Analytical Thinking", "Research"],
    "books": ["Continuous Learning", "Research"],
    "public speak": ["Public Speaking", "Leadership", "Communication"],
    "debate": ["Public Speaking", "Critical Thinking", "Communication", "Persuasion"],
    "present": ["Presentation Skills", "Public Speaking", "Communication"],

    # Music / Performance
    "music": ["Creativity", "Attention to Detail", "Discipline"],
    "guitar": ["Creativity", "Discipline", "Attention to Detail"],
    "piano": ["Creativity", "Attention to Detail", "Discipline"],
    "drum": ["Rhythm", "Coordination", "Discipline"],
    "sing": ["Creativity", "Performance", "Confidence"],
    "singing": ["Creativity", "Performance", "Confidence"],
    "dance": ["Creativity", "Teamwork", "Discipline"],
    "dancing": ["Creativity", "Teamwork", "Discipline"],
    "theatre": ["Teamwork", "Public Speaking", "Creativity"],
    "theater": ["Teamwork", "Public Speaking", "Creativity"],
    "act": ["Creativity", "Emotional Intelligence", "Communication"],
    "perform": ["Leadership", "Confidence", "Communication"],

    # Sports / Physical
    "football": ["Teamwork", "Leadership", "Strategic Thinking"],
    "soccer": ["Teamwork", "Leadership", "Strategic Thinking"],
    "basketball": ["Teamwork", "Leadership", "Quick Decision Making"],
    "cricket": ["Teamwork", "Strategy", "Patience"],
    "tennis": ["Strategic Thinking", "Discipline", "Adaptability"],
    "badminton": ["Strategic Thinking", "Discipline", "Quick Reflexes"],
    "swimming": ["Discipline", "Endurance", "Goal Setting"],
    "running": ["Discipline", "Goal Setting", "Perseverance"],
    "cycling": ["Discipline", "Goal Setting", "Perseverance"],
    "gym": ["Discipline", "Goal Setting", "Perseverance"],
    "fitness": ["Discipline", "Goal Setting", "Health Consciousness"],
    "yoga": ["Discipline", "Focus", "Mindfulness"],
    "meditation": ["Focus", "Mindfulness", "Stress Management"],
    "martial art": ["Discipline", "Leadership", "Focus"],
    "chess": ["Strategic Thinking", "Problem Solving", "Critical Thinking"],
    "game": ["Problem Solving", "Strategic Thinking", "Quick Decision Making"],
    "gaming": ["Problem Solving", "Strategic Thinking", "Quick Decision Making"],

    # Tech / DIY hobbies
    "3d print": ["3D Modeling", "Engineering", "Problem Solving"],
    "robot": ["Robotics", "System Design", "Problem Solving"],
    "electronics": ["Hardware", "Problem Solving", "Engineering"],
    "circuit": ["Hardware Engineering", "Problem Solving"],
    "hack": ["Cybersecurity", "Problem Solving", "Critical Thinking"],
    "coding": ["Software Development", "Problem Solving", "Logical Thinking"],
    "programming": ["Software Development", "Problem Solving", "Logical Thinking"],
    "build": ["Engineering", "Problem Solving", "Creativity"],
    "build app": ["Software Development", "Problem Solving"],
    "carpent": ["Craftsmanship", "Attention to Detail", "Problem Solving"],
    "woodwork": ["Craftsmanship", "Attention to Detail"],

    # Social / Organizing
    "volunteer": ["Teamwork", "Leadership", "Empathy"],
    "teach": ["Teaching", "Communication", "Leadership", "Patience"],
    "mentor": ["Mentoring", "Leadership", "Communication"],
    "organiz": ["Organizational Skills", "Project Management", "Leadership"],
    "plan": ["Project Management", "Strategic Thinking"],
    "travel": ["Adaptability", "Cultural Awareness", "Problem Solving"],
    "lead": ["Leadership", "Decision Making", "Project Management"],

    # Cooking / Life
    "cook": ["Creativity", "Time Management", "Attention to Detail"],
    "cook": ["Creativity", "Time Management", "Attention to Detail"],
    "bak": ["Attention to Detail", "Creativity", "Time Management"],
    "garden": ["Patience", "Planning", "Attention to Detail"],

    # Learning / Research
    "research": ["Research", "Analytical Thinking", "Problem Solving"],
    "puzzl": ["Problem Solving", "Critical Thinking", "Analytical Thinking"],
    "math": ["Analytical Thinking", "Problem Solving", "Logical Thinking"],
    "science": ["Research", "Analytical Thinking", "Problem Solving"],
    "learn": ["Continuous Learning", "Adaptability"],
    "study": ["Discipline", "Analytical Thinking"],
}

app = FastAPI(title="SkillAura API")

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

os.makedirs("static/resumes", exist_ok=True)
app.mount("/static", StaticFiles(directory="static"), name="static")

app.include_router(notifications.router)
app.include_router(improve_resume.router)

# Known skills database
SKILLS_DB = {
    # Programming Languages
    "python": "Python",
    "java": "Java",
    "javascript": "JavaScript",
    "typescript": "TypeScript",
    "dart": "Dart",
    "go": "Go",
    "rust": "Rust",
    "c++": "C++",
    "c#": "C#",
    "ruby": "Ruby",
    "php": "PHP",
    "swift": "Swift",
    "kotlin": "Kotlin",
    "scala": "Scala",
    "r programming": "R",
    # Frontend
    "react": "React",
    "vue": "Vue",
    "angular": "Angular",
    "next.js": "Next.js",
    "flutter": "Flutter",
    "react native": "React Native",
    "tailwind": "Tailwind",
    "bootstrap": "Bootstrap",
    "sass": "SASS",
    "scss": "SCSS",
    "html": "HTML",
    "css": "CSS",
    # Backend
    "node.js": "Node.js",
    "express": "Express",
    "django": "Django",
    "flask": "Flask",
    "spring": "Spring",
    "laravel": "Laravel",
    "ruby on rails": "Ruby on Rails",
    "asp.net": "ASP.NET",
    "fastapi": "FastAPI",
    "graphql": "GraphQL",
    "rest api": "REST APIs",
    # Databases
    "sql": "SQL",
    "mysql": "MySQL",
    "postgresql": "PostgreSQL",
    "mongodb": "MongoDB",
    "firebase": "Firebase",
    "redis": "Redis",
    "sqlite": "SQLite",
    "oracle": "Oracle",
    "cassandra": "Cassandra",
    "elasticsearch": "Elasticsearch",
    # Tools & Platforms
    "git": "Git",
    "docker": "Docker",
    "kubernetes": "Kubernetes",
    "aws": "AWS",
    "gcp": "GCP",
    "azure": "Azure",
    "heroku": "Heroku",
    "jenkins": "Jenkins",
    "ci/cd": "CI/CD",
    "jira": "Jira",
    "linux": "Linux",
    "bash": "Bash",
    # Data Science & ML
    "machine learning": "Machine Learning",
    "data science": "Data Science",
    "tensorflow": "TensorFlow",
    "pytorch": "PyTorch",
    "numpy": "NumPy",
    "pandas": "Pandas",
    "scikit-learn": "Scikit-learn",
    "keras": "Keras",
    "nlp": "NLP",
    "computer vision": "Computer Vision",
    # Other
    "agile": "Agile",
    "scrum": "Scrum",
    "microservices": "Microservices",
    "oop": "OOP",
    "data structures": "Data Structures",
    "algorithms": "Algorithms",
    "system design": "System Design",
    "testing": "Testing",
    "unit testing": "Unit Testing",
    "tdd": "TDD",
}

# Comprehensive Job roles and their required skills (100+ roles)
JOB_ROLES = {
    # Mobile Development
    "flutter developer": ["Dart", "Flutter", "Firebase", "REST APIs", "Git", "SQL", "Android", "iOS", "State Management"],
    "ios developer": ["Swift", "SwiftUI", "Xcode", "iOS", "Core Data", "Firebase", "REST APIs", "Git", "UIKit"],
    "android developer": ["Kotlin", "Java", "Android Studio", "Jetpack Compose", "Firebase", "REST APIs", "Git", "MVVM"],
    "mobile developer": ["Flutter", "React Native", "Swift", "Kotlin", "Firebase", "Git", "REST APIs"],
    "react native developer": ["React Native", "JavaScript", "TypeScript", "Firebase", "REST APIs", "Git", "Redux"],
    "xamarin developer": ["C#", ".NET", "Xamarin", "Visual Studio", "SQL", "REST APIs"],
    
    # Web Development
    "web developer": ["HTML", "CSS", "JavaScript", "React", "Node.js", "Git", "REST APIs", "SQL"],
    "frontend developer": ["HTML", "CSS", "JavaScript", "React", "TypeScript", "Git", "Webpack", "CSS Frameworks"],
    "backend developer": ["Python", "Java", "Node.js", "SQL", "MongoDB", "Docker", "Git", "REST APIs", "Microservices"],
    "full stack developer": ["JavaScript", "React", "Node.js", "Python", "SQL", "MongoDB", "Git", "REST APIs", "Docker"],
    "javascript developer": ["JavaScript", "React", "Node.js", "HTML", "CSS", "Git", "REST APIs"],
    "typescript developer": ["TypeScript", "React", "Node.js", "Git", "REST APIs", "Testing"],
    "react developer": ["React", "JavaScript", "TypeScript", "Redux", "Git", "REST APIs", "CSS"],
    "vue developer": ["Vue.js", "JavaScript", "TypeScript", "Nuxt.js", "Git", "REST APIs"],
    "angular developer": ["Angular", "TypeScript", "RxJS", "Git", "REST APIs", "Testing"],
    "next.js developer": ["Next.js", "React", "TypeScript", "Node.js", "Git", "REST APIs", "Tailwind"],
    
    # Data Science & ML
    "data scientist": ["Python", "Machine Learning", "Data Science", "TensorFlow", "NumPy", "Pandas", "SQL", "Statistics"],
    "machine learning engineer": ["Python", "Machine Learning", "TensorFlow", "PyTorch", "Deep Learning", "NumPy", "Pandas", "SQL"],
    "ai engineer": ["Python", "Machine Learning", "TensorFlow", "PyTorch", "Deep Learning", "Computer Vision", "NLP"],
    "data analyst": ["Python", "SQL", "Tableau", "Power BI", "Excel", "Pandas", "NumPy", "Statistics"],
    "data engineer": ["Python", "SQL", "Apache Spark", "Airflow", "AWS", "GCP", "PostgreSQL", "MongoDB", "ETL", "Data Warehousing"],
    "big data engineer": ["Apache Spark", "Hadoop", "Kafka", "Python", "Scala", "SQL", "AWS", "Data Pipelines", "ETL"],
    "nlp engineer": ["Python", "NLP", "Machine Learning", "TensorFlow", "PyTorch", "spaCy", "NLTK", "LLMs", "Text Processing"],
    "computer vision engineer": ["Python", "OpenCV", "TensorFlow", "PyTorch", "Computer Vision", "Deep Learning", "Image Processing", "CUDA"],
    "deep learning engineer": ["Python", "TensorFlow", "PyTorch", "Deep Learning", "Neural Networks", "Computer Vision", "NLP"],
    "mlops engineer": ["Python", "MLflow", "Kubernetes", "Docker", "TensorFlow", "ML Pipelines", "AWS", "GCP", "CI/CD"],
    "business analyst": ["SQL", "Excel", "Tableau", "Power BI", "Python", "Data Analysis", "Statistics", "Communication"],
    "data architect": ["SQL", "NoSQL", "Data Modeling", "AWS", "Azure", "GCP", "ETL", "Data Warehousing", "System Design"],
    
    # Cloud & DevOps
    "devops engineer": ["Docker", "Kubernetes", "AWS", "GCP", "Azure", "CI/CD", "Jenkins", "Linux", "Bash", "Terraform"],
    "cloud engineer": ["AWS", "Azure", "GCP", "Docker", "Kubernetes", "Linux", "Terraform", "Networking"],
    "cloud architect": ["AWS", "Azure", "GCP", "Kubernetes", "Docker", "Terraform", "System Design", "Security", "Networking"],
    "aws engineer": ["AWS", "EC2", "S3", "Lambda", "DynamoDB", "CloudFormation", "Terraform", "Python"],
    "azure developer": ["Azure", "C#", ".NET", "SQL", "REST APIs", "Docker", "Kubernetes"],
    "gcp engineer": ["GCP", "Google Cloud", "Kubernetes", "Docker", "Python", "BigQuery", "Dataflow"],
    "site reliability engineer": ["Linux", "Python", "Go", "Kubernetes", "Docker", "Prometheus", "Grafana", "CI/CD", "Incident Response"],
    "infrastructure engineer": ["AWS", "Terraform", "Docker", "Kubernetes", "Python", "Linux", "Ansible", "CI/CD"],
    "release engineer": ["Jenkins", "Git", "Docker", "Kubernetes", "CI/CD", "Linux", "Bash", "Automation"],
    "platform engineer": ["Kubernetes", "Docker", "Go", "Python", "Linux", "Terraform", "CI/CD", "Service Mesh"],
    
    # Security
    "cybersecurity specialist": ["Network Security", "Penetration Testing", "Firewalls", "Encryption", "SIEM", "Linux", "Python", "Risk Assessment"],
    "security engineer": ["Network Security", "Python", "Linux", "Penetration Testing", "SIEM", "Firewalls", "Encryption", "Cloud Security"],
    "ethical hacker": ["Penetration Testing", "Python", "Linux", "Network Security", "Metasploit", "Burp Suite", "SQL Injection"],
    "security analyst": ["SIEM", "Network Security", "Python", "Incident Response", "Risk Assessment", "Compliance"],
    "appsec engineer": ["Application Security", "OWASP", "Penetration Testing", "SAST", "DAST", "Python", "Docker"],
    "cloud security engineer": ["AWS", "Azure", "GCP", "Cloud Security", "IAM", "Encryption", "Compliance", "Kubernetes"],
    "infosec analyst": ["Information Security", "Risk Assessment", "Compliance", "Network Security", "SIEM", "Python"],
    
    # Database
    "database administrator": ["SQL", "MySQL", "PostgreSQL", "Oracle", "MongoDB", "Database Tuning", "Backup", "Replication"],
    "database developer": ["SQL", "PL/SQL", "MySQL", "PostgreSQL", "MongoDB", "Database Design", "ETL"],
    "dba": ["SQL", "MySQL", "PostgreSQL", "Oracle", "Backup", "Replication", "Performance Tuning", "High Availability"],
    
    # Testing & QA
    "qa automation engineer": ["Selenium", "Python", "Java", "JUnit", "TestNG", "CI/CD", "API Testing", "Postman", "Docker"],
    "qa engineer": ["Testing", "Selenium", "Manual Testing", "Test Cases", "JIRA", "API Testing", "Postman"],
    "software tester": ["Testing", "Manual Testing", "Test Cases", "Selenium", "JIRA", "Bug Tracking"],
    "test automation engineer": ["Python", "Java", "Selenium", "TestNG", "JUnit", "CI/CD", "API Testing", "Docker"],
    "performance tester": ["JMeter", "LoadRunner", "Performance Testing", "Python", "SQL", "Monitoring"],
    
    # Blockchain & Web3
    "blockchain developer": ["Solidity", "Ethereum", "Web3", "Smart Contracts", "JavaScript", "Node.js", "Cryptography", "IPFS"],
    "web3 developer": ["Solidity", "Ethereum", "Web3", "Smart Contracts", "JavaScript", "TypeScript", "NFT", "DeFi"],
    "smart contract developer": ["Solidity", "Ethereum", "Smart Contracts", "Web3", "Cryptography", "Hardhat", "Truffle"],
    
    # Game Development
    "game developer": ["Unity", "C#", "C++", "Unreal Engine", "Game Design", "3D Math", "Physics", "Shaders"],
    "unity developer": ["Unity", "C#", "Game Development", "3D Math", "Physics", "Shader Programming", "Mobile Games"],
    "unreal developer": ["Unreal Engine", "C++", "Blueprints", "Game Development", "3D Math", "Physics", "VR/AR"],
    "game programmer": ["C++", "C#", "Unity", "Unreal Engine", "Game Design", "Physics", "AI", "Multiplayer"],
    
    # Design
    "ui/ux designer": ["Figma", "Adobe XD", "Sketch", "User Research", "Prototyping", "HTML", "CSS", "Design Systems", "Wireframing"],
    "ui designer": ["Figma", "Sketch", "Adobe XD", "HTML", "CSS", "Prototyping", "Design Systems", "UI Design"],
    "ux designer": ["User Research", "Figma", "Wireframing", "Prototyping", "Usability Testing", "Persona Creation", "Journey Mapping"],
    "graphic designer": ["Adobe Photoshop", "Illustrator", "Figma", "Sketch", "Typography", "Color Theory", "Branding"],
    "visual designer": ["Figma", "Adobe XD", "Typography", "Color Theory", "Visual Design", "Branding", "Motion Design"],
    "product designer": ["Figma", "Sketch", "User Research", "Prototyping", "Design Systems", "HTML", "CSS", "User Testing"],
    
    # Hardware & Embedded
    "embedded systems engineer": ["C", "C++", "RTOS", "Arduino", "Raspberry Pi", "Embedded Linux", "Microcontrollers", "PCB Design"],
    "firmware engineer": ["C", "C++", "Embedded Systems", "RTOS", "Microcontrollers", "Hardware Debugging", "ARM"],
    "hardware engineer": ["Circuit Design", "PCB Design", "Embedded Systems", "C", "C++", "FPGA", "VHDL", "Verilog"],
    "iot developer": ["IoT", "Python", "Arduino", "Raspberry Pi", "Embedded Systems", "MQTT", "Sensors", "Cloud Integration"],
    "robotics engineer": ["ROS", "Python", "C++", "Embedded Systems", "Computer Vision", "Machine Learning", "Actuators"],
    
    # Other Tech Roles
    "technical writer": ["Documentation", "API Documentation", "Markdown", "Technical Writing", "Git", "HTML", "XML"],
    "solutions architect": ["AWS", "Azure", "GCP", "System Design", "Kubernetes", "Docker", "Microservices", "Security", "Cost Optimization"],
    "product manager": ["Agile", "Scrum", "Jira", "User Research", "Roadmapping", "Data Analysis", "Stakeholder Management"],
    "project manager": ["Project Management", "Agile", "Scrum", "Jira", "Communication", "Risk Management", "Stakeholder Management"],
    "scrum master": ["Scrum", "Agile", "Jira", "Coaching", "Facilitation", "Kanban", "Team Leadership"],
    "tech lead": ["System Design", "Architecture", "Leadership", "Code Review", "Mentoring", "Agile", "Technical Strategy"],
    "engineering manager": ["Leadership", "Team Management", "Agile", "Scrum", "Technical Strategy", "Hiring", "Communication"],
    "vp of engineering": ["Engineering Leadership", "Strategy", "Architecture", "Team Building", "Budgeting", "Stakeholder Management"],
    "cto": ["Technology Strategy", "Architecture", "Leadership", "Innovation", "Cloud", "AI/ML", "Security"],
    "software architect": ["System Design", "Architecture Patterns", "Microservices", "Cloud", "Kubernetes", "Security", "Performance"],
    "principal engineer": ["System Design", "Architecture", "Technical Leadership", "Mentoring", "Performance Optimization"],
    "staff engineer": ["System Design", "Technical Leadership", "Architecture", "Mentoring", "Cross-functional Collaboration"],
    "software engineering manager": ["Team Management", "Agile", "Scrum", "Technical Strategy", "Hiring", "Performance Management"],
    "devrel engineer": ["Technical Writing", "Public Speaking", "Developer Tools", "APIs", "Community Building", "Content Creation"],
    "developer advocate": ["Technical Writing", "Public Speaking", "Developer Relations", "APIs", "Community Building", "Content Creation"],
    
    # Specialized Roles
    "salesforce developer": ["Salesforce", "Apex", "Visualforce", "SOQL", "Lightning", "JavaScript", "Integration"],
    "serviceNow developer": ["ServiceNow", "JavaScript", "GlideScript", "ITSM", "Workflow Automation", "Integration"],
    "sap developer": ["SAP", "ABAP", "Java", "SAP UI5", "OData", "SAP Fiori", "SAP HANA"],
    "oracle developer": ["Oracle", "PL/SQL", "SQL", "Oracle Forms", "Reports", "APEX", "Java"],
    "sharepoint developer": ["SharePoint", "PowerShell", "C#", ".NET", "JavaScript", "Office 365", " SPFx"],
    "dynamics crm developer": ["Dynamics CRM", "C#", ".NET", "PowerApps", "Power Automate", "Azure", "Plugin Development"],
    
    # Emerging Tech
    "ar/vr developer": ["Unity", "Unreal Engine", "C#", "C++", "AR", "VR", "3D Math", "Computer Vision", "Spatial Computing"],
    "metaverse developer": ["Unity", "Unreal Engine", "3D Modeling", "WebXR", "NFTs", "Blockchain", "Real-time Rendering"],
    "quantum computing engineer": ["Quantum Computing", "Python", "Q#", "Linear Algebra", "Physics", "Algorithm Design"],
    "edge computing engineer": ["Edge Computing", "IoT", "Kubernetes", "Docker", "Python", "Fog Computing", "Low Latency Systems"],
    "digital transformation consultant": ["Digital Strategy", "Cloud Migration", "Agile", "Change Management", "Technology Assessment"],
    
    # Finance & Trading
    "quantitative analyst": ["Python", "R", "Statistics", "Machine Learning", "Financial Modeling", "Algorithm Trading", "C++"],
    "algorithmic trader": ["Python", "C++", "R", "Financial Markets", "Algorithm Trading", "Machine Learning", "Data Analysis"],
    "financial technology engineer": ["Python", "Java", "Blockchain", "APIs", "Financial Systems", "Security", "Compliance"],
    
    # Healthcare Tech
    "healthcare software developer": ["Python", "Java", "HL7", "FHIR", "Healthcare Systems", "HIPAA", "Security", "APIs"],
    "bioinformatics engineer": ["Python", "R", "Machine Learning", "Genomics", "Data Analysis", "Bioinformatics Tools", "Cloud Computing"],
    "medical device software engineer": ["C", "C++", "Embedded Systems", "FDA Regulations", "Medical Devices", "Safety Critical"],
    
    # Networking
    "network engineer": ["Networking", "Cisco", "Juniper", "Firewalls", "VPN", "Routing", "Switching", "TCP/IP", "DNS"],
    "network administrator": ["Networking", "Windows Server", "Linux", "Firewalls", "VPN", "Monitoring", "Troubleshooting"],
    "systems engineer": ["Linux", "Windows Server", "Virtualization", "Networking", "Automation", "Scripting", "Cloud"],
    
    # Support & Operations
    "technical support engineer": ["Technical Support", "Troubleshooting", "Linux", "Windows", "Networking", "Customer Service", "Scripting"],
    "customer success engineer": ["Technical Support", "Customer Success", "APIs", "Integration", "Troubleshooting", "Communication"],
    "sales engineer": ["Technical Sales", "Solution Architecture", "APIs", "Product Knowledge", "Presentations", "Negotiation"],
    
    # Content & Media
    "multimedia developer": ["HTML5", "CSS3", "JavaScript", "Animation", "Video Editing", "Adobe Creative Suite", "Interactive Media"],
    "motion graphics designer": ["After Effects", "Premiere Pro", "Cinema 4D", "Animation", "Visual Effects", "Motion Design"],
    
    # Low Level
    "systems programmer": ["C", "C++", "Operating Systems", "Kernel Development", "Memory Management", "Concurrency", "Performance"],
    "kernel developer": ["C", "Linux Kernel", "Operating Systems", "Device Drivers", "System Calls", "Performance Optimization"],
    "driver developer": ["C", "C++", "Device Drivers", "Operating Systems", "Hardware Interfaces", "Debugging"],
    
    # More Engineering Roles
    "civil engineer": ["AutoCAD", "Civil 3D", "Structural Analysis", "BIM", "Project Management", "CAD"],
    "mechanical engineer": ["SolidWorks", "AutoCAD", "MATLAB", "Finite Element Analysis", "Thermodynamics", "CAD"],
    "electrical engineer": ["Circuit Design", "MATLAB", "SPICE", "PCB Design", "Embedded Systems", "Power Systems"],
    
    # Consulting
    "it consultant": ["IT Strategy", "Cloud", "Security", "Infrastructure", "Project Management", "Vendor Management"],
    "technology consultant": ["Digital Transformation", "Cloud Migration", "Architecture", "Strategy", "Agile", "Innovation"],
    "management consultant": ["Strategy", "Analysis", "Presentations", "Project Management", "Excel", "PowerPoint"],
    
    # Research
    "research scientist": ["Research", "Python", "Machine Learning", "Data Analysis", "Publications", "Statistics", "Experimentation"],
    "research engineer": ["Python", "C++", "Machine Learning", "Research", "Prototyping", "Data Analysis", "Publications"],
}

# Skill keywords mapping for smart matching
SKILL_KEYWORDS = {
    "python": ["python", "py"],
    "java": ["java"],
    "javascript": ["javascript", "js"],
    "typescript": ["typescript", "ts"],
    "dart": ["dart"],
    "react": ["react", "reactjs", "react.js"],
    "flutter": ["flutter"],
    "node.js": ["nodejs", "node.js", "node"],
    "angular": ["angular"],
    "vue": ["vue", "vuejs", "vue.js"],
    "django": ["django"],
    "flask": ["flask"],
    "fastapi": ["fastapi"],
    "spring": ["spring", "springboot"],
    "sql": ["sql", "mysql", "postgresql", "postgres", "database"],
    "mongodb": ["mongodb", "mongo"],
    "firebase": ["firebase"],
    "aws": ["aws", "amazon web services", "amazon ws"],
    "gcp": ["gcp", "google cloud", "google cloud platform"],
    "azure": ["azure", "microsoft azure"],
    "docker": ["docker", "containerization"],
    "kubernetes": ["kubernetes", "k8s", "kubes"],
    "git": ["git", "version control", "github", "gitlab"],
    "machine learning": ["machine learning", "ml", "machine learning engineer"],
    "data science": ["data science", "data scientist"],
    "tensorflow": ["tensorflow", "tf"],
    "pytorch": ["pytorch"],
    "react native": ["react native", "rn"],
    "swift": ["swift", "ios developer"],
    "kotlin": ["kotlin", "android developer"],
    "c++": ["c++", "cpp"],
    "c#": ["c#", "csharp", ".net"],
    "go": ["go", "golang"],
    "rust": ["rust"],
    "ruby": ["ruby"],
    "php": ["php"],
    "scala": ["scala"],
    "html": ["html", "html5"],
    "css": ["css", "css3"],
    "rest api": ["rest api", "rest", "restful", "api"],
    "graphql": ["graphql", "gql"],
    "redis": ["redis"],
    "elasticsearch": ["elasticsearch", "elastic"],
    "jenkins": ["jenkins", "ci/cd", "cicd"],
    "linux": ["linux", "unix"],
    "bash": ["bash", "shell", "shell scripting"],
    "agile": ["agile", "agile methodology"],
    "scrum": ["scrum"],
    "microservices": ["microservices", "microservice architecture"],
    "deep learning": ["deep learning", "dl", "neural network"],
    "nlp": ["nlp", "natural language processing", "text processing"],
    "computer vision": ["computer vision", "cv", "image processing", "image recognition"],
    "pandas": ["pandas", "data analysis"],
    "numpy": ["numpy", "numerical computing"],
    "devops": ["devops", "devops engineer"],
    "cloud": ["cloud", "cloud computing", "cloud architect"],
    "security": ["security", "cybersecurity", "infosec"],
    "testing": ["testing", "qa", "test automation"],
    "ci/cd": ["ci/cd", "cicd", "continuous integration", "continuous deployment"],
}

class ProfileTextAnalysisRequest(BaseModel):
    text: str

class ResumeAnalysisResponse(BaseModel):
    skills: List[str]
    ats_score: int
    missing_skills: List[str]
    suggestions: List[str]
    top_skills: List[str]

class GitHubAnalysisResponse(BaseModel):
    username: str
    skills: List[str]
    total_repos: int
    total_stars: int
    top_language: str

@app.get("/")
def read_root():
    return {"message": "SkillAura API is running!", "version": "1.0.0"}

@app.post("/analyze-profile-text")
async def analyze_profile_text(request: ProfileTextAnalysisRequest):
    """Analyze colloquial text to extract professional skills using two-phase engine:
    Phase 1: exact keyword matching against PREDEFINED_SKILLS
    Phase 2: semantic hobby/trait → skill inference via HOBBY_TO_SKILLS mapping
    """
    if not request.text or len(request.text.strip()) < 5:
        raise HTTPException(status_code=400, detail="Text is too short")
    
    try:
        user_text = request.text.lower()
        extracted_skills = set()
        
        # ── Phase 1: Direct keyword matching ────────────────────────────────────
        for skill in PREDEFINED_SKILLS:
            if re.search(r'\b' + re.escape(skill) + r'\b', user_text):
                extracted_skills.add(skill.title())
        
        # ── Phase 2: Semantic hobby → skill inference ────────────────────────────
        # Use partial substring matching so "draws paintings" matches "draw", "paint", etc.
        for keyword, mapped_skills in HOBBY_TO_SKILLS.items():
            if keyword in user_text:
                for s in mapped_skills:
                    extracted_skills.add(s)
        
        # De-duplicate (case-insensitive) - prefer the version already in set
        seen_lower: set = set()
        final_skills = []
        for skill in sorted(extracted_skills):
            sl = skill.lower()
            if sl not in seen_lower:
                seen_lower.add(sl)
                final_skills.append(skill)
        
        return {"skills": final_skills}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error extracting skills: {str(e)}")


@app.post("/analyze-resume", response_model=ResumeAnalysisResponse)
async def analyze_resume(file: UploadFile = File(...)):
    """Analyze uploaded resume and extract skills, ATS score, etc."""
    try:
        # Read file content
        content = await file.read()
        
        # Try to decode as text (works for text-based files)
        try:
            text = content.decode('utf-8', errors='ignore')
        except:
            # For binary files like PDF, we'd need a proper PDF parser
            # For now, return a message
            raise HTTPException(status_code=400, detail="Please upload a text-based file or PDF with extractable text")
        
        # Extract skills from text
        found_skills = extract_skills(text)

        # ML ATS score
        ats_result = calculate_ats_score(text, found_skills)
        ats_score = ats_result["score"]

        # Get missing skills (assuming Flutter Developer as default)
        missing_skills = get_missing_skills(found_skills, "flutter developer")

        # Generate suggestions
        suggestions = generate_suggestions(ats_result, found_skills, missing_skills)

        return ResumeAnalysisResponse(
            skills=found_skills,
            ats_score=ats_score,
            missing_skills=missing_skills,
            suggestions=suggestions,
            top_skills=found_skills[:5] if len(found_skills) > 5 else found_skills
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail="Error analyzing resume: " + str(e))

@app.post("/analyze-resume-base64")
async def analyze_resume_base64(data: dict):
    """Analyze resume from base64 encoded content using ML NLP engine."""
    try:
        base64_string = data.get("content", "")
        file_name = data.get("file_name", "resume.txt")

        # Decode base64
        raw_bytes = base64.b64decode(base64_string)

        # Smart text extraction based on file type
        text = _extract_text_from_bytes(raw_bytes, file_name)

        if not text or len(text.strip()) < 20:
            raise HTTPException(
                status_code=400,
                detail="Could not extract readable text from file. "
                       "Please upload a text-based PDF, DOCX, or TXT file."
            )

        # ML-driven skill extraction
        found_skills = extract_skills(text)

        # ML ATS scoring
        ats_result = calculate_ats_score(text, found_skills)
        ats_score = ats_result["score"]
        breakdown = ats_result["breakdown"]

        # Missing skills vs flutter developer (default)
        missing_skills = get_missing_skills(found_skills, "flutter developer")

        # Targeted suggestions driven by ML findings
        suggestions = generate_suggestions(ats_result, found_skills, missing_skills)

        return {
            "skills": found_skills,
            "ats_score": ats_score,
            "missing_skills": missing_skills,
            "suggestions": suggestions,
            "top_skills": found_skills[:5] if len(found_skills) > 5 else found_skills,
            "file_name": file_name,
            "breakdown": breakdown,
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error analysing resume: {e}")

@app.post("/analyze-github", response_model=GitHubAnalysisResponse)
async def analyze_github(data: dict):
    """Analyze GitHub profile and extract skills."""
    try:
        username = data.get("username", "")
        if not username:
            raise HTTPException(status_code=400, detail="Username is required")
        
        # In a real implementation, we would call GitHub API
        # For now, return mock data based on username
        import hashlib
        seed = int(hashlib.md5(username.encode()).hexdigest(), 16) % 100
        
        mock_skills = ["Git", "Python", "JavaScript", "Dart", "Flutter"]
        skills = mock_skills[:(seed % 3) + 2]
        
        return GitHubAnalysisResponse(
            username=username,
            skills=skills,
            total_repos=(seed % 50) + 10,
            total_stars=(seed % 100) + 5,
            top_language=skills[0] if skills else "None"
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail="Error: " + str(e))

@app.get("/job-roles")
def get_job_roles():
    """Get list of available job roles and their required skills."""
    return JOB_ROLES

@app.post("/skill-gap-analysis")
def skill_gap_analysis(data: dict):
    """Analyze skill gap for a specific job role. Returns 4-level proficiency per skill."""
    user_skills = data.get("user_skills", [])
    job_role = data.get("job_role", "flutter developer").lower().strip()
    resume_text = data.get("resume_text", "")         # raw resume text (optional)
    github_repos = data.get("github_repos", [])        # list of {name, language, description, stargazers_count, forks_count}

    # Check if job role exists in predefined roles
    if job_role in JOB_ROLES:
        required_skills = JOB_ROLES[job_role]
        is_custom = False
    else:
        required_skills = infer_skills_from_job_role(job_role)
        is_custom = True

    user_skills_normalized = [s.lower() for s in user_skills]
    resume_text_lower = resume_text.lower() if resume_text else ""

    gap_analysis = []
    for skill in required_skills:
        skill_lower = skill.lower()
        user_has = _skill_present(skill_lower, user_skills_normalized)

        level = _calculate_level(
            skill_lower=skill_lower,
            user_has=user_has,
            user_skills_normalized=user_skills_normalized,
            resume_text_lower=resume_text_lower,
            github_repos=github_repos,
        )
        level_name = ["none", "low", "medium", "intermediate", "professional"][level]

        gap_analysis.append({
            "skill": skill,
            "user_level": level,        # 0-4
            "required_level": 4,        # always 4 = professional
            "has_skill": user_has,
            "level_name": level_name,
        })

    # match_percentage: sum of user levels / (4 * total required skills) * 100
    if required_skills:
        total_achieved = sum(item["user_level"] for item in gap_analysis)
        max_possible = 4 * len(required_skills)
        match_percentage = round((total_achieved / max_possible) * 100, 1)
    else:
        match_percentage = 0.0

    return {
        "job_role": job_role,
        "user_skills": user_skills,
        "required_skills": required_skills,
        "matched_skills": [s for s in required_skills if _skill_present(s.lower(), user_skills_normalized)],
        "missing_skills": [s for s in required_skills if not _skill_present(s.lower(), user_skills_normalized)],
        "gap_analysis": gap_analysis,
        "match_percentage": match_percentage,
        "is_custom": is_custom,
    }


# ── Proficiency helpers ────────────────────────────────────────────────────────

def _skill_present(skill_lower: str, user_skills_normalized: List[str]) -> bool:
    """True if the skill (or a close variant) exists in the user's skill list."""
    for us in user_skills_normalized:
        if skill_lower in us or us in skill_lower:
            return True
    return False


def _calculate_level(
    skill_lower: str,
    user_has: bool,
    user_skills_normalized: List[str],
    resume_text_lower: str,
    github_repos: list,
) -> int:
    """
    Returns proficiency level 0-4:
      0 = none        (skill not found anywhere)
      1 = low         (skill listed but no evidence of usage)
      2 = medium      (mentioned in resume text)
      3 = intermediate (used in 2+ repos OR mentioned many times in resume)
      4 = professional (primary language in 3+ repos OR top language overall)
    """
    if not user_has:
        return 0

    level = 1  # base: skill is in the list

    # --- Resume text evidence ---
    if resume_text_lower:
        occurrences = resume_text_lower.count(skill_lower)
        if occurrences >= 5:
            level = max(level, 3)  # mentioned many times → intermediate
        elif occurrences >= 2:
            level = max(level, 2)  # mentioned a couple of times → medium
        elif occurrences >= 1:
            level = max(level, 2)  # at least one mention → medium

    # --- GitHub repo evidence ---
    if github_repos:
        # Count repos where this skill is the primary language
        primary_lang_hits = 0
        topic_or_name_hits = 0
        for repo in github_repos:
            repo_lang = (repo.get("language") or "").lower()
            repo_name = (repo.get("name") or "").lower()
            repo_desc = (repo.get("description") or "").lower()
            # map dart → flutter for proficiency checks
            lang_aliases = {"dart": ["dart", "flutter"], "javascript": ["javascript", "js", "node"]}
            aliases = lang_aliases.get(skill_lower, [skill_lower])
            if any(a in repo_lang for a in aliases):
                primary_lang_hits += 1
            if skill_lower in repo_name or skill_lower in repo_desc:
                topic_or_name_hits += 1

        total_repo_hits = primary_lang_hits + topic_or_name_hits
        if primary_lang_hits >= 3 or total_repo_hits >= 5:
            level = max(level, 4)  # professional
        elif primary_lang_hits >= 1 or total_repo_hits >= 2:
            level = max(level, 3)  # intermediate
        elif total_repo_hits >= 1:
            level = max(level, 2)  # medium

    return level
# ──────────────────────────────────────────────────────────────────────────────


def infer_skills_from_job_role(job_role: str) -> List[str]:
    """Infer required skills from a custom job role using keyword matching."""
    job_role_lower = job_role.lower()
    inferred_skills = set()
    
    # Core skills that are important for almost any tech role
    core_skills = ["Git", "REST APIs", "Problem Solving"]
    
    # Map job role keywords to skills
    keyword_to_skills = {
        # Programming languages
        "python": ["Python", "Django", "Flask", "FastAPI"],
        "java": ["Java", "Spring", "JUnit"],
        "javascript": ["JavaScript", "Node.js", "React"],
        "typescript": ["TypeScript", "React", "Node.js"],
        "dart": ["Dart", "Flutter"],
        "swift": ["Swift", "SwiftUI", "Xcode", "iOS"],
        "kotlin": ["Kotlin", "Android Studio", "Jetpack Compose"],
        "c++": ["C++", "Game Development"],
        "c#": ["C#", ".NET", "ASP.NET"],
        "go": ["Go", "Golang"],
        "rust": ["Rust"],
        "ruby": ["Ruby", "Ruby on Rails"],
        "php": ["PHP", "Laravel"],
        "scala": ["Scala", "Apache Spark"],
        
        # Frontend frameworks
        "react": ["React", "JavaScript", "Redux"],
        "angular": ["Angular", "TypeScript", "RxJS"],
        "vue": ["Vue", "JavaScript", "Nuxt.js"],
        "flutter": ["Flutter", "Dart", "Firebase"],
        "next.js": ["Next.js", "React", "TypeScript"],
        "react native": ["React Native", "JavaScript"],
        
        # Backend frameworks
        "node": ["Node.js", "Express", "JavaScript"],
        "express": ["Express", "Node.js"],
        "django": ["Django", "Python"],
        "flask": ["Flask", "Python"],
        "spring": ["Spring", "Java"],
        "laravel": ["Laravel", "PHP"],
        
        # Database
        "sql": ["SQL", "MySQL", "PostgreSQL"],
        "mysql": ["MySQL", "SQL"],
        "postgresql": ["PostgreSQL", "SQL"],
        "mongodb": ["MongoDB", "NoSQL"],
        "redis": ["Redis", "Caching"],
        "firebase": ["Firebase", "NoSQL"],
        
        # Cloud & DevOps
        "aws": ["AWS", "EC2", "S3", "Lambda"],
        "azure": ["Azure", "Cloud Computing"],
        "gcp": ["Google Cloud", "GCP"],
        "docker": ["Docker", "Containerization"],
        "kubernetes": ["Kubernetes", "K8s", "Docker"],
        "jenkins": ["Jenkins", "CI/CD"],
        "ci/cd": ["CI/CD", "Jenkins", "Docker"],
        "devops": ["Docker", "Kubernetes", "CI/CD", "AWS", "Linux"],
        
        # Data Science & ML
        "machine learning": ["Machine Learning", "Python", "TensorFlow", "PyTorch"],
        "ml": ["Machine Learning", "Python", "TensorFlow"],
        "data science": ["Data Science", "Python", "Pandas", "NumPy", "Machine Learning"],
        "data engineer": ["Python", "SQL", "Apache Spark", "Airflow", "ETL"],
        "tensorflow": ["TensorFlow", "Machine Learning", "Python"],
        "pytorch": ["PyTorch", "Machine Learning", "Python"],
        "nlp": ["NLP", "Machine Learning", "Python", "spaCy"],
        "computer vision": ["Computer Vision", "OpenCV", "Machine Learning", "Python"],
        "deep learning": ["Deep Learning", "TensorFlow", "PyTorch", "Neural Networks"],
        "pandas": ["Pandas", "Python", "Data Analysis"],
        "numpy": ["NumPy", "Python", "Numerical Computing"],
        
        # Mobile
        "ios": ["Swift", "SwiftUI", "Xcode", "iOS"],
        "android": ["Kotlin", "Java", "Android Studio", "Jetpack Compose"],
        "mobile": ["Flutter", "React Native", "Firebase", "REST APIs"],
        
        # Other tech skills
        "graphql": ["GraphQL", "Apollo", "API Design"],
        "rest": ["REST APIs", "API Design"],
        "api": ["REST APIs", "API Design", "Postman"],
        "microservice": ["Microservices", "Docker", "Kubernetes", "API Gateway"],
        "linux": ["Linux", "Bash", "Shell Scripting"],
        "git": ["Git", "GitHub", "Version Control"],
        "agile": ["Agile", "Scrum", "Jira"],
        "scrum": ["Scrum", "Agile", "Jira"],
        "security": ["Security", "Penetration Testing", "Encryption"],
        "cybersecurity": ["Cybersecurity", "Network Security", "Penetration Testing"],
        "blockchain": ["Blockchain", "Solidity", "Ethereum", "Web3"],
        "game": ["Unity", "C#", "C++", "Game Design"],
        "embedded": ["C", "C++", "RTOS", "Embedded Systems"],
        "iot": ["IoT", "Python", "Arduino", "Embedded Systems"],
        "qa": ["Selenium", "Testing", "JUnit", "TestNG"],
        "testing": ["Testing", "Selenium", "JUnit", "API Testing"],
        "cloud": ["AWS", "Azure", "GCP", "Docker", "Kubernetes"],
        "architect": ["System Design", "AWS", "Microservices", "Kubernetes"],
        "full stack": ["JavaScript", "React", "Node.js", "SQL", "MongoDB", "Docker"],
        "frontend": ["HTML", "CSS", "JavaScript", "React", "CSS Frameworks"],
        "backend": ["Python", "Java", "Node.js", "SQL", "REST APIs"],
    }
    
    # Check each keyword in the job role
    for keyword, skills in keyword_to_skills.items():
        if keyword in job_role_lower:
            inferred_skills.update(skills)
    
    # Add common skills based on role type
    if "developer" in job_role_lower or "engineer" in job_role_lower:
        inferred_skills.update(core_skills)
    
    if "data" in job_role_lower or "ml" in job_role_lower or "ai" in job_role_lower:
        inferred_skills.update(["Python", "Machine Learning", "Data Analysis"])
    
    if "web" in job_role_lower:
        inferred_skills.update(["HTML", "CSS", "JavaScript", "REST APIs"])
    
    if "mobile" in job_role_lower:
        inferred_skills.update(["Flutter", "REST APIs", "Firebase"])
    
    if "cloud" in job_role_lower or "devops" in job_role_lower:
        inferred_skills.update(["AWS", "Docker", "Kubernetes", "Linux"])
    
    if "security" in job_role_lower or "cyber" in job_role_lower:
        inferred_skills.update(["Network Security", "Linux", "Python"])
    
    # If no skills inferred, provide some defaults
    if not inferred_skills:
        inferred_skills = ["Problem Solving", "Git", "REST APIs", "SQL", "Python"]
    
    # Return as sorted list (max 10 skills for custom roles)
    return sorted(list(inferred_skills))[:10]


@app.get("/search-job-roles")
def search_job_roles(query: str = ""):
    """Search job roles by query string."""
    query_lower = query.lower().strip()
    
    if not query_lower:
        # Return all job roles if no query
        return {"roles": list(JOB_ROLES.keys()), "total": len(JOB_ROLES)}
    
    # Search in predefined roles
    matching_roles = [role for role in JOB_ROLES.keys() if query_lower in role]
    
    return {
        "roles": matching_roles,
        "total": len(matching_roles),
        "query": query
    }

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║     ML-DRIVEN ATS ENGINE  (TF-IDF + Regex NLP, no external MLlib deps)    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Reference corpus for TF-IDF skill relevance (simulates trained model baseline)
_RESUME_CORPUS = [
    "Experienced software engineer with skills in python java javascript react node",
    "Flutter dart mobile developer firebase cloud aws git docker kubernetes",
    "Data scientist machine learning tensorflow pytorch numpy pandas sklearn sql",
    "DevOps engineer cicd jenkins github actions docker kubernetes linux aws",
    "Full stack developer react node express postgresql mongodb typescript",
    "Mobile developer android ios kotlin swift react native flutter dart",
    "Backend developer python django fastapi rest api postgresql redis",
    "Frontend developer react vue angular css html sass typescript",
]

_tfidf_vectorizer: Optional[Any] = None
_tfidf_matrix: Optional[Any] = None

def _get_tfidf():
    """Lazy-init TF-IDF vectorizer trained on the resume corpus."""
    global _tfidf_vectorizer, _tfidf_matrix
    if _tfidf_vectorizer is None and SKLEARN_AVAILABLE:
        _tfidf_vectorizer = TfidfVectorizer(
            ngram_range=(1, 2),
            min_df=1,
            stop_words='english',
        )
        _tfidf_matrix = _tfidf_vectorizer.fit_transform(_RESUME_CORPUS)
    return _tfidf_vectorizer, _tfidf_matrix


def _tfidf_skill_score(text: str, skills: List[str]) -> float:
    """
    Use TF-IDF to measure how 'resume-like' the skills section is.
    Returns a 0-1 normalised relevance score.
    """
    if not SKLEARN_AVAILABLE or not skills:
        return min(len(skills) / 15.0, 1.0)

    vec, mat = _get_tfidf()
    if vec is None:
        return min(len(skills) / 15.0, 1.0)

    candidate = " ".join(skills + text.split()[:200]).lower()
    candidate_vec = vec.transform([candidate])
    # Cosine similarity with the corpus
    from sklearn.metrics.pairwise import cosine_similarity
    sims = cosine_similarity(candidate_vec, mat)
    max_sim = float(sims.max())
    return max_sim  # 0.0 – 1.0


def _extract_text_from_bytes(raw: bytes, filename: str) -> str:
    """
    Smart multi-format text extractor.
    - PDF  → pdfplumber (ML-assisted layout parser, no REGEX attr needed)
    - DOCX → python-docx (XML parser)
    - TXT  → UTF-8 decode with binary-noise removal
    """
    ext = filename.lower().rsplit(".", 1)[-1] if "." in filename else "txt"

    if ext == "pdf":
        try:
            with pdfplumber.open(io.BytesIO(raw)) as pdf:
                pages = [p.extract_text() or "" for p in pdf.pages]
            return "\n".join(pages)
        except Exception:
            pass  # fall through

    if ext in ("docx", "doc") and DocxDocument:
        try:
            doc = DocxDocument(io.BytesIO(raw))
            return "\n".join(p.text for p in doc.paragraphs)
        except Exception:
            pass

    # Plain text fallback — strip binary noise from images
    try:
        text = raw.decode("utf-8", errors="ignore")
    except Exception:
        text = ""
    clean_lines = [
        ln for ln in text.splitlines()
        if len(ln) == 0 or sum(c.isprintable() for c in ln) / len(ln) > 0.6
    ]
    return "\n".join(clean_lines)


def extract_skills(text: str) -> List[str]:
    """Extract skills via keyword matching (fast, high-precision)."""
    text_lower = text.lower()
    found_skills: set = set()
    for keyword, skill_name in SKILLS_DB.items():
        if keyword in text_lower:
            found_skills.add(skill_name)
    return sorted(found_skills)


def calculate_ats_score(text: str, skills: List[str]) -> Dict[str, Any]:
    """
    Real ML-driven ATS scoring:
    ─ TF-IDF cosine similarity for skill relevance (sklearn)
    ─ Regex-NLP for entity detection (email, phone, dates, orgs, degrees)
    ─ 7-category weighted scoring matching Workday/Greenhouse ATS logic

    Returns: {score: int, breakdown: dict, word_count: int}
    """
    text_lower = text.lower()
    breakdown: Dict[str, Any] = {}

    # ── 1. CONTACT INFO (20 pts) ─────────────────────────────────────────────
    contact_score = 0
    contact_details = []
    has_email = bool(re.search(r'[\w.+-]+@[\w-]+\.[\w.]+', text))
    if has_email:
        contact_score += 10
        contact_details.append("email ✓")
    else:
        contact_details.append("⚠ email missing")

    has_phone = bool(re.search(r'(\+?\d[\d\s\-().]{8,14}\d)', text))
    if has_phone:
        contact_score += 7
        contact_details.append("phone ✓")
    else:
        contact_details.append("⚠ phone missing")

    if re.search(r'linkedin\.com/in/', text_lower):
        contact_score += 3
        contact_details.append("LinkedIn ✓")
    breakdown["contact"] = {"score": contact_score, "max": 20, "details": contact_details}

    # ── 2. WORK EXPERIENCE (25 pts) ──────────────────────────────────────────
    exp_score = 0
    exp_details = []

    if re.search(r'\b(experience|work history|employment|professional background|career history)\b', text_lower):
        exp_score += 4
        exp_details.append("experience section ✓")
    else:
        exp_details.append("⚠ no experience section")

    # Date patterns: "2022", "Jan 2022", "2020-2023", "Present"
    dates_found = re.findall(
        r'\b((jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\.?\s*20\d{2}|'
        r'20\d{2}\s*[-–]\s*(20\d{2}|present|current)|20\d{2})\b',
        text_lower
    )
    date_score = min(len(dates_found) * 2, 8)
    exp_score += date_score
    if dates_found:
        exp_details.append(f"{len(dates_found)} date references ✓")
    else:
        exp_details.append("⚠ no dates detected")

    # Company/org detection: capitalized multi-word phrases followed by role indicators
    org_hits = re.findall(
        r'\bat\s+[A-Z][a-zA-Z]+|\b[A-Z][a-zA-Z]+\s+(Inc|Ltd|LLC|Corp|Technologies|Solutions|Labs|Software)\b',
        text
    )
    org_score = min(len(org_hits) * 2, 6)
    exp_score += org_score
    if org_hits:
        exp_details.append(f"{len(org_hits)} company reference(s) ✓")
    else:
        exp_details.append("⚠ no company names detected")

    # Action verbs (ML resume signal: past-tense strong verbs)
    action_verb_pattern = r'\b(led|built|developed|designed|implemented|created|reduced|increased|improved|managed|launched|optimized|optimised|delivered|architected|deployed|automated|scaled|mentored|collaborated|integrated|migrated|achieved|engineered|streamlined|shipped|drove|spearheaded)\b'
    found_verbs = set(re.findall(action_verb_pattern, text_lower))
    verb_score = min(len(found_verbs), 7)
    exp_score += verb_score
    if found_verbs:
        exp_details.append(f"{len(found_verbs)} action verb(s) ✓")
    else:
        exp_details.append("⚠ add action verbs (led, built, etc.)")
    breakdown["experience"] = {"score": exp_score, "max": 25, "details": exp_details}

    # ── 3. EDUCATION (15 pts) ────────────────────────────────────────────────
    edu_score = 0
    edu_details = []
    if re.search(r'\b(education|academic|qualification|degree|schooling)\b', text_lower):
        edu_score += 3
        edu_details.append("education section ✓")
    else:
        edu_details.append("⚠ no education section")

    if re.search(r'\b(b\.?tech|b\.?e\.?|b\.?sc|m\.?tech|m\.?sc|mca|mba|phd|bachelor|master|doctorate|diploma|b\.?com|associate)\b', text_lower):
        edu_score += 7
        edu_details.append("degree detected ✓")
    else:
        edu_details.append("⚠ degree not detected")

    if re.search(r'\b(university|college|institute|iit|nit|school|academy|polytechnic)\b', text_lower):
        edu_score += 5
        edu_details.append("institution detected ✓")
    else:
        edu_details.append("⚠ institution not found")
    breakdown["education"] = {"score": edu_score, "max": 15, "details": edu_details}

    # ── 4. SKILLS — TF-IDF relevance score (20 pts) ──────────────────────────
    tfidf_relevance = _tfidf_skill_score(text, skills)
    # Base from count
    n = len(skills)
    if n >= 16:    count_pts = 12
    elif n >= 11:  count_pts = 10
    elif n >= 6:   count_pts = 8
    elif n >= 3:   count_pts = 5
    elif n >= 1:   count_pts = 3
    else:          count_pts = 0
    # ML relevance top-up (0–8 pts based on TF-IDF cosine sim)
    relevance_pts = round(tfidf_relevance * 8)
    skill_score = min(count_pts + relevance_pts, 20)
    breakdown["skills"] = {
        "score": skill_score,
        "max": 20,
        "details": [
            f"{n} skills detected",
            f"ML relevance score: {round(tfidf_relevance * 100)}%"
        ]
    }

    # ── 5. PROJECTS (10 pts) ─────────────────────────────────────────────────
    proj_score = 0
    proj_details = []
    if re.search(r'\b(project|portfolio|case study|capstone)\b', text_lower):
        proj_score += 4
        proj_details.append("projects section ✓")
    else:
        proj_details.append("⚠ no projects section")

    github_links = re.findall(r'github\.com/\S+', text_lower)
    url_links = re.findall(r'https?://\S+', text)
    link_score = min((len(github_links) + len(url_links)) * 2, 6)
    proj_score += link_score
    if github_links:
        proj_details.append(f"{len(github_links)} GitHub link(s) ✓")
    if url_links:
        proj_details.append(f"{len(url_links)} URL(s) ✓")
    if not github_links and not url_links:
        proj_details.append("⚠ add GitHub or project links")
    breakdown["projects"] = {"score": proj_score, "max": 10, "details": proj_details}

    # ── 6. IMPACT / METRICS (5 pts) ──────────────────────────────────────────
    impact_score = 0
    impact_details = []
    if re.findall(r'\d+\s*%', text):
        impact_score += 2
        impact_details.append(f"{len(re.findall(r'[0-9]+%', text))} percentage metric(s) ✓")
    else:
        impact_details.append("⚠ add % metrics")
    if re.search(r'\$\s*\d+|\d+\s*(million|k\b|lakh|crore)', text_lower):
        impact_score += 1
        impact_details.append("revenue/saving figure ✓")
    if re.search(r'\d+[,\d]*\s*(users|clients|customers|requests|orders|records)', text_lower):
        impact_score += 2
        impact_details.append("quantified user/impact ✓")
    else:
        impact_details.append("⚠ quantify impact (e.g., users, requests)")
    breakdown["impact"] = {"score": impact_score, "max": 5, "details": impact_details}

    # ── 7. FORMATTING (5 pts) ─────────────────────────────────────────────────
    fmt_score = 0
    fmt_details = []
    words = [w for w in text.split() if w.strip()]
    wc = len(words)
    if 300 <= wc <= 1200:
        fmt_score += 2
        fmt_details.append(f"{wc} words (ideal range) ✓")
    elif wc < 100:
        fmt_details.append(f"⚠ too short ({wc} words)")
    else:
        fmt_score += 1
        fmt_details.append(f"{wc} words")
    headers_found = re.findall(
        r'^\s*(experience|education|skills|projects|summary|objective|achievements|'
        r'certifications|contact|profile|work history|employment)\s*$',
        text, re.IGNORECASE | re.MULTILINE
    )
    fmt_score += min(len(headers_found), 3)
    if headers_found:
        fmt_details.append(f"{len(headers_found)} section header(s) ✓")
    else:
        fmt_details.append("⚠ add clear section headers")
    breakdown["formatting"] = {"score": fmt_score, "max": 5, "details": fmt_details}

    # ── FINAL SCORE (max = 20+25+15+20+10+5+5 = 100) ──────────────────────────
    final_score = max(0, min(100,
        contact_score + exp_score + edu_score +
        skill_score + proj_score + impact_score + fmt_score
    ))
    return {"score": final_score, "breakdown": breakdown, "word_count": wc}


def get_missing_skills(user_skills: List[str], job_role: str) -> List[str]:
    if job_role not in JOB_ROLES:
        return []
    required = JOB_ROLES[job_role]
    normalized = [s.lower() for s in user_skills]
    return [s for s in required if s.lower() not in normalized]


def generate_suggestions(ats_result: Dict[str, Any], skills: List[str], missing_skills: List[str]) -> List[str]:
    """Targeted ML-informed suggestions based on the ATS breakdown."""
    suggestions: List[str] = []
    breakdown = ats_result.get("breakdown", {})

    for detail in breakdown.get("contact", {}).get("details", []):
        if "⚠" in detail:
            if "email" in detail:
                suggestions.append("🔴 Critical: Add your email address — ATS systems require it")
            elif "phone" in detail:
                suggestions.append("🔴 Critical: Add your phone number — recruiters filter by this")

    for detail in breakdown.get("experience", {}).get("details", []):
        if "⚠" in detail:
            if "section" in detail:
                suggestions.append("Add a 'Work Experience' section with job titles and dates")
            elif "date" in detail:
                suggestions.append("Include employment dates (e.g., Jun 2022 – Present) for each role")
            elif "company" in detail:
                suggestions.append("Name the companies you worked at")
            elif "action" in detail:
                suggestions.append("Use action verbs (Led, Built, Reduced, Achieved)")

    for detail in breakdown.get("education", {}).get("details", []):
        if "⚠" in detail:
            if "degree" in detail:
                suggestions.append("Add your degree name (e.g., B.Tech, B.Sc., MCA)")
            elif "institution" in detail:
                suggestions.append("Include your college or university name")

    if len(skills) < 5:
        suggestions.append("Add more technical skills — aim for 8–15 for a strong score")

    for detail in breakdown.get("projects", {}).get("details", []):
        if "⚠" in detail:
            if "link" in detail or "GitHub" in detail:
                suggestions.append("Add GitHub or live project links")
            elif "project" in detail:
                suggestions.append("Add a Projects section with 2–3 technical projects")

    for detail in breakdown.get("impact", {}).get("details", []):
        if "⚠" in detail:
            if "%" in detail:
                suggestions.append("Quantify achievements with % (e.g., 'Reduced load time by 40%')")
            elif "quantify" in detail:
                suggestions.append("Add user/scale numbers (e.g., 'Served 10,000 users')")

    for skill in missing_skills[:3]:
        suggestions.append(f"Consider learning {skill} to match job requirements")

    score = ats_result.get("score", 0)
    if score < 40:
        suggestions.append("Overall: Focus on contact info, experience, and education first")
    elif score < 60:
        suggestions.append("Overall: Good start — add project links and metrics to improve")
    elif score < 80:
        suggestions.append("Overall: Strong resume — add quantified impact to reach 80+")

    return suggestions[:10]

# ── English Practice Chat is handled by /chat endpoint using Gemini (see below) ──

# ╔═════════════════════════════════════════════════════════════════════════════╗
# ║          LIVE JOB SEARCH  ─  Adzuna API + SMTP Apply                      ║
# ╚═════════════════════════════════════════════════════════════════════════════╝

ADZUNA_APP_ID  = os.getenv("ADZUNA_APP_ID", "")
ADZUNA_APP_KEY = os.getenv("ADZUNA_APP_KEY", "")
SMTP_EMAIL     = os.getenv("SMTP_EMAIL", "")
SMTP_PASSWORD  = os.getenv("SMTP_APP_PASSWORD", "")

ADZUNA_BASE    = "https://api.adzuna.com/v1/api/jobs"

# ── Country helpers ───────────────────────────────────────────────────────────
COUNTRY_CURRENCY = {"in": "₹", "us": "$", "gb": "£", "au": "A$", "ca": "C$"}

def _salary_label(job: dict, country: str) -> str:
    sym = COUNTRY_CURRENCY.get(country, "$")
    lo = job.get("salary_min") or 0
    hi = job.get("salary_max") or 0
    if lo and hi:
        def _fmt(n):
            if n >= 100_000:
                return f"{sym}{n/100_000:.1f}L/yr"
            if n >= 1_000:
                return f"{sym}{n/1_000:.0f}K/yr"
            return f"{sym}{n:.0f}/yr"
        return f"{_fmt(lo)} – {_fmt(hi)}"
    if lo:
        return f"{sym}{lo:,.0f}/yr"
    return "Salary not disclosed"


def _contract_to_type(job: dict) -> str:
    ct = (job.get("contract_time") or "").lower()
    cp = (job.get("contract_type") or "").lower()
    if "remote" in (job.get("title") or "").lower():
        return "Remote"
    if "part" in ct:
        return "Part-time"
    if "contract" in cp:
        return "On-site"
    return "Hybrid"


def _job_to_dict(job: dict, country: str, user_skills: List[str]) -> dict:
    """Map a raw Adzuna job object to our app's Job schema."""
    title       = job.get("title", "")
    company     = (job.get("company") or {}).get("display_name", "Unknown")
    location    = (job.get("location") or {}).get("display_name", "")
    description = job.get("description", "")
    cat_label   = (job.get("category") or {}).get("label", "Tech")
    created     = job.get("created", "")
    external_id = str(job.get("id", ""))
    redirect_url = job.get("redirect_url", "")
    logo_url    = ""   # Adzuna doesn't provide logos; we keep letter badge
    contract_type = _contract_to_type(job)

    # Extract required skills from description via NLP keyword matching
    req_skills = extract_skills(description)
    if not req_skills:
        # fall back to role-based skills
        role_key = title.lower().strip()
        for role_name, skills in JOB_ROLES.items():
            if any(w in role_key for w in role_name.split()):
                req_skills = skills[:8]
                break
        if not req_skills:
            req_skills = ["Communication", "Problem Solving", "Git"]

    # Match score: % of required skills the user already has
    if req_skills and user_skills:
        user_lower = [s.lower() for s in user_skills]
        matched = sum(1 for s in req_skills if _skill_present(s.lower(), user_lower))
        match_score = int((matched / len(req_skills)) * 100)
    else:
        match_score = 50

    # Human-readable posted_at
    if created:
        try:
            from datetime import datetime, timezone
            dt = datetime.fromisoformat(created.replace("Z", "+00:00"))
            delta = datetime.now(timezone.utc) - dt
            days = delta.days
            if days == 0:
                posted_at = "Today"
            elif days == 1:
                posted_at = "1 day ago"
            elif days < 7:
                posted_at = f"{days} days ago"
            elif days < 30:
                posted_at = f"{days // 7} week{'s' if days // 7 > 1 else ''} ago"
            else:
                posted_at = f"{days // 30} month{'s' if days // 30 > 1 else ''} ago"
        except Exception:
            posted_at = "Recently"
    else:
        posted_at = "Recently"

    return {
        "id": f"az-{external_id}",
        "external_id": external_id,
        "title": title,
        "company": company,
        "location": location,
        "description": description[:500] + ("…" if len(description) > 500 else ""),
        "full_description": description,
        "required_skills": req_skills[:10],
        "match_score": match_score,
        "type": contract_type,
        "salary": _salary_label(job, country),
        "logo": company[0].upper() if company else "?",
        "logo_url": logo_url,
        "saved": False,
        "posted_at": posted_at,
        "apply_url": redirect_url,
        "category": cat_label,
    }


# ── Endpoint 1: Live Job Search ───────────────────────────────────────────────
@app.get("/jobs/search")
async def search_jobs(
    query: str = "software developer",
    country: str = "in",
    location: str = "",
    contract_type: str = "",
    page: int = 1,
    results_per_page: int = 20,
    user_skills: str = "",          # comma-separated list
):
    """Fetch live job listings from Adzuna API."""
    if not ADZUNA_APP_ID or not ADZUNA_APP_KEY:
        raise HTTPException(status_code=503, detail="Adzuna API keys not configured")

    skills_list = [s.strip() for s in user_skills.split(",") if s.strip()] if user_skills else []

    params: dict = {
        "app_id":          ADZUNA_APP_ID,
        "app_key":         ADZUNA_APP_KEY,
        "what":            query,
        "results_per_page": results_per_page,
        "content-type":    "application/json",
    }
    if location:
        params["where"] = location
    if contract_type and contract_type.lower() != "all":
        ct_map = {"remote": "permanent", "hybrid": "permanent", "on-site": "permanent"}
        params["contract_time"] = ct_map.get(contract_type.lower(), "permanent")

    url = f"{ADZUNA_BASE}/{country}/search/{page}"

    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            resp = await client.get(url, params=params)

        if resp.status_code != 200:
            raise HTTPException(status_code=resp.status_code,
                                detail=f"Adzuna API error: {resp.text[:200]}")

        data = resp.json()
        jobs_raw = data.get("results", [])
        total = data.get("count", len(jobs_raw))

        jobs = [_job_to_dict(j, country, skills_list) for j in jobs_raw]

        # Sort by match score descending (personalised feed)
        jobs.sort(key=lambda j: j["match_score"], reverse=True)

        return {"jobs": jobs, "total": total, "page": page}

    except httpx.TimeoutException:
        raise HTTPException(status_code=504, detail="Adzuna API timed out. Please try again.")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Job search error: {e}")


# ── Endpoint 2: Autocomplete Suggestions ─────────────────────────────────────
@app.get("/jobs/suggest")
async def suggest_jobs(query: str = "", country: str = "in"):
    """Return autocomplete suggestions for the job search bar."""
    if not query or len(query) < 2:
        # Return popular roles as default suggestions
        popular = [
            "Flutter Developer", "React Developer", "Python Developer",
            "Machine Learning Engineer", "Full Stack Developer",
            "Data Scientist", "DevOps Engineer", "Node.js Developer",
            "Android Developer", "iOS Developer", "Backend Engineer",
            "Frontend Developer", "Data Analyst", "Cloud Engineer",
            "Java Developer", "UI/UX Designer"
        ]
        return {"suggestions": popular}

    if not ADZUNA_APP_ID or not ADZUNA_APP_KEY:
        # Fall back to local role matching
        query_lower = query.lower()
        matched = [r.title() for r in JOB_ROLES.keys() if query_lower in r][:10]
        return {"suggestions": matched}

    try:
        params = {
            "app_id":  ADZUNA_APP_ID,
            "app_key": ADZUNA_APP_KEY,
            "term":    query,
        }
        url = f"{ADZUNA_BASE}/{country}/autocomplete"
        async with httpx.AsyncClient(timeout=8.0) as client:
            resp = await client.get(url, params=params)

        if resp.status_code == 200:
            data = resp.json()
            # Adzuna autocomplete returns list of {"label":..., "tag":...}
            suggestions = [item.get("label", item.get("tag", "")) for item in data]
            suggestions = [s for s in suggestions if s][:12]
            if not suggestions:
                raise ValueError("empty")
            return {"suggestions": suggestions}
    except Exception:
        pass

    # Fallback: match from our local JOB_ROLES dictionary
    query_lower = query.lower()
    matched = [r.title() for r in JOB_ROLES.keys() if query_lower in r][:10]
    return {"suggestions": matched}


# ── Endpoint 3: Job Detail by External ID ────────────────────────────────────
@app.get("/jobs/{job_external_id}")
async def get_job_detail(
    job_external_id: str,
    country: str = "in",
    user_skills: str = "",
):
    """Fetch full details for a single job by its Adzuna ID."""
    if not ADZUNA_APP_ID or not ADZUNA_APP_KEY:
        raise HTTPException(status_code=503, detail="Adzuna API keys not configured")

    skills_list = [s.strip() for s in user_skills.split(",") if s.strip()] if user_skills else []

    params = {
        "app_id":       ADZUNA_APP_ID,
        "app_key":      ADZUNA_APP_KEY,
        "content-type": "application/json",
    }
    url = f"{ADZUNA_BASE}/{country}/search/1"
    params["what_or"] = f"id:{job_external_id}"

    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            resp = await client.get(url, params=params)

        if resp.status_code == 200:
            results = resp.json().get("results", [])
            if results:
                return _job_to_dict(results[0], country, skills_list)

        raise HTTPException(status_code=404, detail="Job not found")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching job: {e}")


# ── Endpoint 4: Apply via Email ───────────────────────────────────────────────
class JobApplyRequest(BaseModel):
    job_id: str
    job_title: str
    company_name: str
    apply_url: str = ""
    user_name: str
    user_email: str
    resume_url: str = ""
    github_username: str = ""
    cover_note: Optional[str] = None


@app.post("/jobs/apply")
async def apply_to_job(req: JobApplyRequest):
    """
    Send a formatted job application email from the user's profile.
    Uses Gmail SMTP with App Password.
    The email goes to SMTP_EMAIL (the app owner) with the application details,
    and sends a confirmation copy to the applicant.
    """
    import smtplib
    from email.mime.multipart import MIMEMultipart
    from email.mime.text import MIMEText

    if not SMTP_EMAIL or not SMTP_PASSWORD:
        raise HTTPException(status_code=503, detail="SMTP not configured on server")

    github_section = (
        f"\n🔗 GitHub Profile: https://github.com/{req.github_username}"
        if req.github_username else ""
    )
    resume_section = (
        f"\n📄 Resume: {req.resume_url}"
        if req.resume_url else "\n📄 Resume: Not uploaded yet"
    )
    cover_section = (
        f"\n\n💬 Cover Note:\n{req.cover_note}"
        if req.cover_note else ""
    )
    apply_section = (
        f"\n🌐 Original Listing: {req.apply_url}"
        if req.apply_url else ""
    )

    body_text = f"""
Hi {req.company_name} Hiring Team,

I am writing to express my interest in the {req.job_title} position at {req.company_name}.

Please find my application details below:

👤 Name:  {req.user_name}
📧 Email: {req.user_email}{github_section}{resume_section}{apply_section}{cover_section}

This application was sent via SkillAura — a student career platform.

Best regards,
{req.user_name}
"""

    # Application forwarding email (to ourselves as a log)
    msg = MIMEMultipart("alternative")
    msg["Subject"] = f"[SkillAura] Application: {req.user_name} → {req.job_title} @ {req.company_name}"
    msg["From"]    = SMTP_EMAIL
    msg["To"]      = SMTP_EMAIL
    msg["Reply-To"] = req.user_email
    msg.attach(MIMEText(body_text, "plain"))

    # Confirmation to applicant
    confirm_msg = MIMEMultipart("alternative")
    confirm_msg["Subject"] = f"Application Confirmation — {req.job_title} @ {req.company_name}"
    confirm_msg["From"]    = SMTP_EMAIL
    confirm_msg["To"]      = req.user_email
    confirm_body = f"""Hi {req.user_name},

✅ Your application has been sent!

📌 Role:    {req.job_title}
🏢 Company: {req.company_name}

Your profile (resume + GitHub) has been forwarded to the company via SkillAura.{apply_section}

Best of luck! 🚀

— SkillAura Team
"""
    confirm_msg.attach(MIMEText(confirm_body, "plain"))

    try:
        with smtplib.SMTP("smtp.gmail.com", 587) as server:
            server.ehlo()
            server.starttls()
            server.login(SMTP_EMAIL, SMTP_PASSWORD)
            server.sendmail(SMTP_EMAIL, SMTP_EMAIL, msg.as_string())
            if req.user_email and req.user_email != SMTP_EMAIL:
                server.sendmail(SMTP_EMAIL, req.user_email, confirm_msg.as_string())

        return {"success": True, "message": f"Application sent for {req.job_title} at {req.company_name}!"}

    except smtplib.SMTPAuthenticationError:
        raise HTTPException(status_code=401, detail="SMTP authentication failed. Check App Password.")
    except smtplib.SMTPException as e:
        raise HTTPException(status_code=500, detail=f"Email send failed: {e}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Apply error: {e}")

# ──────────────────────────────────────────────────────────────────────────────

# ╔═════════════════════════════════════════════════════════════════════════════╗
# ║        INTERVIEW HUB — Coding, Aptitude, Mock Test                        ║
# ╚═════════════════════════════════════════════════════════════════════════════╝

from interview_data import (
    COMPANIES, CODING_QUESTIONS,
    APTITUDE_CATEGORIES, APTITUDE_QUESTIONS,
    MOCK_TEST_DOMAINS, MOCK_TEST_QUESTIONS,
)
import subprocess
import sys
import time as _time
import tempfile
import random
import ast
import httpx as _httpx
import datetime as _dt

_GEMINI_KEY = os.getenv("GEMINI_API_KEY", "")
_GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent"

async def _gemini_review(code: str, title: str, language: str, all_passed: bool) -> dict:
    """Call Gemini to get AI code review. Returns structured feedback dict."""
    if not _GEMINI_KEY:
        return {"verdict": "Unknown", "feedback": "AI review unavailable (no API key).", "time_complexity": "N/A", "space_complexity": "N/A", "score": 50}

    is_skeleton = "pass" in code and len([l for l in code.strip().splitlines() if l.strip() and not l.strip().startswith("#") and l.strip() != "pass"]) < 5
    verdict = "Accepted" if all_passed and not is_skeleton else ("Incomplete" if is_skeleton else "Wrong Answer")

    prompt = f"""You are a coding interview reviewer. Analyze this {language} solution for the problem '{title}'.

Code:
```{language}
{code}
```

Test result: {'All test cases PASSED' if all_passed else 'Some test cases FAILED'}.
Is skeleton/incomplete: {is_skeleton}.

Respond ONLY with a JSON object (no markdown) with these exact fields:
- verdict: one of 'Accepted', 'Wrong Answer', 'Incomplete', 'Time Limit Exceeded'
- feedback: 2-3 sentences of specific, helpful feedback
- time_complexity: Big-O string e.g. 'O(n)'
- space_complexity: Big-O string e.g. 'O(1)'
- score: integer 0-100"""

    try:
        async with _httpx.AsyncClient(timeout=15) as client:
            resp = await client.post(
                f"{_GEMINI_URL}?key={_GEMINI_KEY}",
                json={"contents": [{"parts": [{"text": prompt}]}]},
            )
        if resp.status_code == 200:
            raw = resp.json()["candidates"][0]["content"]["parts"][0]["text"]
            # Strip markdown code fences if present
            raw = raw.strip().removeprefix("```json").removeprefix("```").removesuffix("```").strip()
            return json.loads(raw)
    except Exception:
        pass
    return {"verdict": verdict, "feedback": "Solution evaluated based on test results.", "time_complexity": "N/A", "space_complexity": "N/A", "score": 80 if all_passed else 0}

# ── Coding: Companies ─────────────────────────────────────────────────────────
@app.get("/coding/companies")
async def get_companies(search: str = ""):
    # Always return alphabetically sorted
    sorted_companies = sorted(COMPANIES, key=lambda c: c["name"].lower())
    if search:
        q = search.lower()
        return [c for c in sorted_companies if q in c["name"].lower()]
    return sorted_companies


# ── Coding: Questions per company ─────────────────────────────────────────────
@app.get("/coding/questions/{company_id}")
async def get_company_questions(company_id: str, difficulty: str = ""):
    # Find how many questions this company claims to have
    company_meta = next((c for c in COMPANIES if c["id"] == company_id), None)
    target = company_meta["questions"] if company_meta else len(CODING_QUESTIONS)

    # Get tagged questions specific to this company
    tagged_ids = {q["id"] for q in CODING_QUESTIONS if company_id in q.get("companies", [])}
    tagged = [q for q in CODING_QUESTIONS if q["id"] in tagged_ids]

    # Pad up to `target` using company-seeded shuffle of the remaining pool
    if len(tagged) < target:
        rng = random.Random(company_id)
        extras = [q for q in CODING_QUESTIONS if q["id"] not in tagged_ids]
        rng.shuffle(extras)
        tagged = tagged + extras[:target - len(tagged)]

    # Filter by difficulty if requested
    if difficulty and difficulty.lower() != "all":
        tagged = [q for q in tagged if q["difficulty"].lower() == difficulty.lower()]

    # Return lightweight list (no starter_code / test_cases)
    return [
        {
            "id": q["id"],
            "title": q["title"],
            "difficulty": q["difficulty"],
            "topic": q["topic"],
            "frequency": q["frequency"],
            "acceptance": q["acceptance"],
        }
        for q in tagged
    ]


# ── Coding: Full question detail ───────────────────────────────────────────────
@app.get("/coding/question/{question_id}")
async def get_question_detail(question_id: str):
    for q in CODING_QUESTIONS:
        if q["id"] == question_id:
            return q
    raise HTTPException(status_code=404, detail="Question not found")


# ── Coding: Run code in sandbox ────────────────────────────────────────────────
class CodeRunRequest(BaseModel):
    code: str
    language: str = "python"           # python | javascript | java | cpp
    stdin: str = ""
    test_cases: Optional[List[dict]] = None

def _run_in_sandbox(cmd: list, code: str, stdin_data: str, timeout: int = 5) -> dict:
    """Write code to temp file and execute in subprocess. Returns run result dict."""
    with tempfile.NamedTemporaryFile(mode="w", suffix=_ext(cmd), delete=False, encoding="utf-8") as f:
        f.write(code)
        tmp_path = f.name
    try:
        t0 = _time.perf_counter()
        result = subprocess.run(
            cmd + [tmp_path],
            input=stdin_data,
            capture_output=True,
            text=True,
            timeout=timeout,
        )
        elapsed_ms = round((_time.perf_counter() - t0) * 1000, 2)
        return {
            "stdout": result.stdout[:2000],
            "stderr": result.stderr[:500],
            "exit_code": result.returncode,
            "time_ms": elapsed_ms,
        }
    except subprocess.TimeoutExpired:
        return {"stdout": "", "stderr": "Time Limit Exceeded (5s)", "exit_code": -1, "time_ms": 5000}
    except FileNotFoundError as e:
        return {"stdout": "", "stderr": f"Runtime not found: {e}", "exit_code": -2, "time_ms": 0}
    finally:
        try:
            import os; os.unlink(tmp_path)
        except Exception:
            pass

def _ext(cmd: list) -> str:
    first = cmd[0].lower()
    if "python" in first: return ".py"
    if "node" in first:   return ".js"
    if "java" in first:   return ".java"
    return ".cpp"

def _make_python_testable(code: str, test_case: dict) -> str:
    """Wrap user's Solution class with a test runner."""
    inp = test_case.get("input", "")
    # Use repr so the string is safely embedded as a Python literal
    inp_repr = repr(inp)
    return f"{code}\n\n# ── Auto test runner ──\nimport ast as _ast\nsol = Solution()\ntry:\n    _lines = {inp_repr}.strip().split('\\n')\n    _vars = {{}}\n    for _l in _lines:\n        if '=' in _l:\n            _k, _, _v = _l.partition('=')\n            try:\n                _vars[_k.strip()] = _ast.literal_eval(_v.strip())\n            except Exception:\n                _vars[_k.strip()] = _v.strip()\n    _m = [m for m in dir(sol) if not m.startswith('_')][0]\n    _res = getattr(sol, _m)(**_vars)\n    print(repr(_res))\nexcept Exception as _e:\n    print(f'ERROR: {{_e}}')\n"

@app.post("/coding/run")
async def run_code(req: CodeRunRequest):
    lang = req.language.lower()
    results = []

    if lang == "python":
        cmd = [sys.executable]
        for i, tc in enumerate(req.test_cases or [{"input": req.stdin, "expected": ""}]):
            wrapped = _make_python_testable(req.code, tc)
            r = _run_in_sandbox(cmd, wrapped, tc.get("input", ""), timeout=5)
            actual = r["stdout"].strip()
            expected = tc.get("expected", "").strip()
            # Only pass if: expected matches actual, OR code produced non-empty non-None output
            # NEVER auto-pass skeleton code (empty output)
            if expected:
                passed = actual == expected
            else:
                # no expected value — pass only if code ran without error and returned something
                passed = bool(actual) and actual != "None" and not actual.startswith("ERROR:")
            results.append({
                "case": i + 1,
                "input": tc.get("input", ""),
                "expected": expected,
                "actual": actual,
                "passed": passed,
                "time_ms": r["time_ms"],
                "error": r["stderr"],
            })

    elif lang == "javascript":
        cmd = ["node"]
        code_to_run = req.code + f"\n\nconsole.log(JSON.stringify((() => {{\n{req.stdin}\n}})()));"
        r = _run_in_sandbox(cmd, code_to_run, "", timeout=5)
        results.append({
            "case": 1, "input": req.stdin, "expected": "",
            "actual": r["stdout"].strip(), "passed": True,
            "time_ms": r["time_ms"], "error": r["stderr"],
        })

    elif lang == "java":
        cmd = ["java", "--source", "21"]
        r = _run_in_sandbox(cmd, req.code, req.stdin, timeout=10)
        results.append({
            "case": 1, "input": req.stdin, "expected": "",
            "actual": r["stdout"].strip(), "passed": r["exit_code"] == 0,
            "time_ms": r["time_ms"], "error": r["stderr"],
        })

    else:
        return {"error": f"Language '{lang}' not supported yet", "results": []}

    total = len(results)
    passed_count = sum(1 for r in results if r.get("passed", False))
    return {
        "results": results,
        "passed": passed_count,
        "total": total,
        "all_passed": passed_count == total,
        "language": lang,
    }


# ── Coding: Evaluate code quality ─────────────────────────────────────────────
class CodeEvalRequest(BaseModel):
    code: str
    language: str = "python"
    question_id: Optional[str] = None

def _estimate_complexity(code: str) -> dict:
    """Simple heuristic complexity estimator."""
    lines = code.lower()
    nested_loops = lines.count("for") + lines.count("while")
    has_recursion = "def " in lines and lines.count(lines.split("def ")[1].split("(")[0] if "def " in lines else "") > 1

    if nested_loops >= 3:
        time_c = "O(n³)"
    elif nested_loops == 2:
        time_c = "O(n²)"
    elif nested_loops == 1:
        time_c = "O(n log n)" if ("sort" in lines or "bisect" in lines) else "O(n)"
    elif "log" in lines or "//2" in lines or ">> 1" in lines:
        time_c = "O(log n)"
    else:
        time_c = "O(n)" if ("for" in lines or "while" in lines) else "O(1)"

    space_uses = []
    if "deque" in lines or "stack" in lines or "queue" in lines: space_uses.append("O(n) aux")
    if "[" in code and "append" in lines: space_uses.append("O(n) list")
    if "{" in code and ("dict" in lines or "set" in lines): space_uses.append("O(n) hashmap")
    space_c = space_uses[0] if space_uses else "O(1)"

    return {"time_complexity": time_c, "space_complexity": space_c}

@app.post("/coding/evaluate")
async def evaluate_code(req: CodeEvalRequest):
    complexity = _estimate_complexity(req.code)
    line_count = len(req.code.strip().split("\n"))
    # Simple scoring heuristics
    score = 80
    suggestions = []
    if "pass" in req.code:
        score -= 30
        suggestions.append("Solution is incomplete (contains 'pass').")
    if line_count > 50:
        suggestions.append("Consider simplifying — solution is quite long.")
    if "global" in req.code.lower():
        suggestions.append("Avoid global variables for cleaner code.")
    if not suggestions:
        suggestions.append("Code looks clean! Consider edge cases like empty input.")

    return {
        "time_complexity": complexity["time_complexity"],
        "space_complexity": complexity["space_complexity"],
        "quality_score": max(0, score),
        "suggestions": suggestions,
        "line_count": line_count,
    }


# ── Coding: Submit (run + AI review) ──────────────────────────────────────────
class SubmitRequest(BaseModel):
    code: str
    language: str = "python"
    question_id: str
    user_id: Optional[str] = None   # Firebase UID for saving to Firestore

@app.post("/coding/submit")
async def submit_code(req: SubmitRequest):
    # 1. Find the question to get test cases and title
    question = next((q for q in CODING_QUESTIONS if q["id"] == req.question_id), None)
    if not question:
        raise HTTPException(status_code=404, detail="Question not found")

    title = question.get("title", "Unknown Problem")
    test_cases = question.get("test_cases", [])

    # 2. Run against all test cases
    lang = req.language.lower()
    results = []

    # Detect skeleton / unmodified code (contains only pass or stub)
    code_lines = [l.strip() for l in req.code.strip().splitlines()
                  if l.strip() and not l.strip().startswith("#")]
    is_skeleton = all(l in ("pass", "return new int[0];", "return null;", "return 0;",
                             "return false;", "return {};", "return nullptr;", "return -1;",
                             "// Write your solution here", "// Implement",
                             "# Write your solution here") or "pass" == l
                   for l in code_lines if l not in
                   {"class Solution:", "class Solution {", "public:", "}"})

    if lang == "python":
        cmd = [sys.executable]
        if test_cases:
            for i, tc in enumerate(test_cases):
                wrapped = _make_python_testable(req.code, tc)
                r = _run_in_sandbox(cmd, wrapped, tc.get("input", ""), timeout=5)
                actual = r["stdout"].strip()
                expected = tc.get("expected", "").strip()
                if expected:
                    passed = actual == expected
                else:
                    passed = bool(actual) and actual not in ("None", "") and not actual.startswith("ERROR:")
                results.append({
                    "case": i + 1, "input": tc.get("input", ""),
                    "expected": expected, "actual": actual,
                    "passed": passed, "time_ms": r["time_ms"], "error": r["stderr"],
                })
        else:
            # No test cases — run directly and check for errors
            r = _run_in_sandbox(cmd, req.code, "", timeout=5)
            passed = r["exit_code"] == 0 and not r["stderr"] and not is_skeleton
            results.append({
                "case": 1, "input": "", "expected": "", "actual": r["stdout"].strip(),
                "passed": passed, "time_ms": r["time_ms"], "error": r["stderr"],
            })
    else:
        # For JS/Java, just run and check for errors
        if lang == "javascript":
            cmd = ["node"]
            code_to_run = req.code + "\n// submission run"
            r = _run_in_sandbox(cmd, code_to_run, "", timeout=5)
        elif lang == "java":
            cmd = ["java", "--source", "21"]
            r = _run_in_sandbox(cmd, req.code, "", timeout=10)
        else:
            r = {"stdout": "", "stderr": "Language not supported", "exit_code": -1, "time_ms": 0}
        passed = r["exit_code"] == 0 and not is_skeleton
        results.append({
            "case": 1, "input": "", "expected": "", "actual": r["stdout"].strip(),
            "passed": passed, "time_ms": r["time_ms"], "error": r["stderr"],
        })

    total = len(results)
    passed_count = sum(1 for r in results if r.get("passed", False))
    all_passed = passed_count == total and total > 0 and not is_skeleton

    # 3. Get AI review from Gemini
    ai_review = await _gemini_review(req.code, title, req.language, all_passed)

    # Override verdict if skeleton
    if is_skeleton:
        ai_review["verdict"] = "Incomplete"
        ai_review["score"] = 0
        ai_review["feedback"] = "Your solution contains only skeleton/placeholder code. Please implement the solution before submitting."

    # 4. Build response
    response = {
        "all_passed": all_passed,
        "passed": passed_count,
        "total": total,
        "test_results": results,
        "language": req.language,
        "ai_review": ai_review,
        "question_title": title,
        "submitted_at": _dt.datetime.now(_dt.timezone.utc).isoformat(),
        "user_id": req.user_id,
    }
    return response


# ── Aptitude ──────────────────────────────────────────────────────────────────
@app.get("/aptitude/categories")
async def get_aptitude_categories():
    return APTITUDE_CATEGORIES

@app.get("/aptitude/questions/{category_id}")
async def get_aptitude_questions(category_id: str, count: int = 15, session: int = 0):
    """
    Returns `count` questions shuffled differently per session.
    Pass a unique `session` int (e.g. Unix timestamp) so questions rotate each test.
    """
    qs = APTITUDE_QUESTIONS.get(category_id, [])
    if not qs:
        raise HTTPException(status_code=404, detail=f"Category '{category_id}' not found")
    rng = random.Random(session if session else random.randint(0, 999999))
    pool = list(qs)
    rng.shuffle(pool)
    return pool[:min(count, len(pool))]


# ── Mock Test ─────────────────────────────────────────────────────────────────
@app.get("/mocktest/domains")
async def get_mock_domains():
    return MOCK_TEST_DOMAINS

@app.get("/mocktest/questions/{domain_id}")
async def get_mock_questions(domain_id: str, session: int = 0):
    """Returns questions shuffled differently per session."""
    qs = MOCK_TEST_QUESTIONS.get(domain_id, [])
    if not qs:
        raise HTTPException(status_code=404, detail=f"Domain '{domain_id}' not found")
    rng = random.Random(session if session else random.randint(0, 999999))
    pool = list(qs)
    rng.shuffle(pool)
    return pool


# ── Daily Tasks (AI-powered, personalized) ────────────────────────────────────
class DailyTaskRequest(BaseModel):
    uid: str
    skills: List[str] = []
    streak: int = 0
    resume_score: int = 0
    today: str = ""          # YYYY-MM-DD, used as seed

@app.post("/daily/tasks")
async def generate_daily_tasks(req: DailyTaskRequest):
    today = req.today or _dt.date.today().isoformat()
    seed = int(today.replace("-", "")) + req.streak
    rng = random.Random(seed)

    skills_lower = [s.lower() for s in req.skills]
    difficulty = "Easy" if req.streak < 3 else ("Medium" if req.streak < 10 else "Hard")

    # ── Pick one coding question deterministically ─────────────────────────────
    skill_topics = {"python": "Array", "java": "Tree", "javascript": "String",
                    "c++": "Dynamic Programming", "sql": "Hash Map",
                    "dsa": "Graph", "algorithms": "Binary Search",
                    "react": "String", "flutter": "Array", "ml": "Dynamic Programming"}
    user_topic = next((skill_topics[s] for s in skills_lower if s in skill_topics), None)
    if user_topic:
        topic_qs = [q for q in CODING_QUESTIONS if q.get("topic") == user_topic
                    and q.get("difficulty") == difficulty]
    else:
        topic_qs = [q for q in CODING_QUESTIONS if q.get("difficulty") == difficulty]
    if not topic_qs:
        topic_qs = list(CODING_QUESTIONS)
    rng2 = random.Random(seed + 1)
    coding_q = rng2.choice(topic_qs)

    # First company that has this question (or any company)
    tagged_cos = [c for c in COMPANIES if coding_q["id"] in
                  [q["id"] for q in CODING_QUESTIONS if c["id"] in q.get("companies", [])]]
    company_id = tagged_cos[0]["id"] if tagged_cos else COMPANIES[rng2.randint(0, len(COMPANIES)-1)]["id"]
    company_name = next((c["name"] for c in COMPANIES if c["id"] == company_id), "Google")

    tasks_from_gemini = []
    if _GEMINI_KEY and req.skills:
        prompt = f"""Generate exactly 4 personalized learning tasks for a student with these skills: {', '.join(req.skills[:8])}.
Their streak is {req.streak} days. ATS resume score: {req.resume_score}/100. Today's difficulty level: {difficulty}.
Date seed: {today}.

Return ONLY a JSON array (no markdown) of 4 objects, each with:
- id: unique string like "task_1"
- title: short action-oriented task title (max 8 words)
- subtitle: one line description (max 12 words)
- type: one of [aptitude, english, interview, jobs, resume, mocktest]
- difficulty: "{difficulty}"

Do NOT include coding tasks (that is handled separately).
Make tasks relevant to their actual skills and progressive in effort."""

        try:
            async with _httpx.AsyncClient(timeout=12) as client:
                resp = await client.post(
                    f"{_GEMINI_URL}?key={_GEMINI_KEY}",
                    json={"contents": [{"parts": [{"text": prompt}]}]},
                )
            if resp.status_code == 200:
                raw = resp.json()["candidates"][0]["content"]["parts"][0]["text"]
                raw = raw.strip().removeprefix("```json").removeprefix("```").removesuffix("```").strip()
                tasks_from_gemini = json.loads(raw)
        except Exception:
            pass

    # Fall back to rule-based tasks if Gemini fails
    if not tasks_from_gemini:
        pool_tasks = [
            {"id": "t_aptitude", "title": "Complete Aptitude Practice", "subtitle": "Sharpen quantitative reasoning", "type": "aptitude", "difficulty": difficulty},
            {"id": "t_english", "title": "English Communication Session", "subtitle": "Practice professional writing", "type": "english", "difficulty": difficulty},
            {"id": "t_mock", "title": "Take a Mock Interview", "subtitle": "AI-powered interview simulation", "type": "interview", "difficulty": difficulty},
            {"id": "t_jobs", "title": "Apply to 2 Internships", "subtitle": "Find matching opportunities", "type": "jobs", "difficulty": difficulty},
            {"id": "t_mocktest", "title": "Complete Domain Mock Test", "subtitle": "Test your knowledge end-to-end", "type": "mocktest", "difficulty": difficulty},
            {"id": "t_resume", "title": "Improve Your Resume", "subtitle": "Boost ATS score", "type": "resume", "difficulty": "Easy"},
        ]
        rng.shuffle(pool_tasks)
        tasks_from_gemini = pool_tasks[:4]

    # Route mapping
    routes = {
        "aptitude": "interview/aptitude",
        "english": "interview/english-practice",
        "interview": "interview/mock-interview",
        "jobs": "jobs",
        "resume": "profile",
        "mocktest": "interview/mock-test",
    }
    for t in tasks_from_gemini:
        t["route"] = routes.get(t.get("type", ""), "")
        t["done"] = False

    # Prepend the coding task
    coding_task = {
        "id": f"coding_{coding_q['id']}",
        "title": f"Solve: {coding_q['title']}",
        "subtitle": f"{difficulty} · {coding_q.get('topic','Coding')} · {company_name}",
        "type": "coding",
        "difficulty": difficulty,
        "route": "interview/coding-prep",
        "question_id": coding_q["id"],
        "company_id": company_id,
        "done": False,
    }
    all_tasks = [coding_task] + tasks_from_gemini[:4]
    return {"tasks": all_tasks, "difficulty": difficulty, "date": today}


# ── Chatbot Proxies (Gemini) ──────────────────────────────────────────────────


# ── Interview Scoring Engine (local, no API needed) ──────────────────────────

# 5 Standard interview questions to ask in sequence
_INTERVIEW_QUESTIONS = [
    "Can you tell me about yourself and your technical background?",
    "Describe a challenging technical problem you faced and how you solved it.",
    "Explain a time when you worked in a team under tight deadlines. What was your role?",
    "What are your key technical skills and how have you applied them in real projects?",
    "Where do you see yourself in 3-5 years professionally, and what are you working towards?",
]

# Keywords that indicate quality answers per question (contextual vocab)
_QUALITY_KEYWORDS = [
    # Q1 - About yourself
    ["experience", "project", "developed", "built", "worked", "skill", "team", "university", "intern", "technolog"],
    # Q2 - Technical problem
    ["problem", "solution", "debug", "fix", "issue", "challenge", "approach", "implement", "first", "resolved", "algorithm", "code"],
    # Q3 - Teamwork
    ["team", "collaborate", "role", "deadline", "project", "communic", "agile", "scrum", "member", "contributed", "responsibility"],
    # Q4 - Technical skills
    ["flutter", "python", "java", "javascript", "react", "firebase", "sql", "docker", "aws", "project", "implement", "framework", "database"],
    # Q5 - Future goals
    ["goal", "learn", "improve", "career", "aspire", "grow", "contribute", "master", "expert", "plan", "develop", "future", "aim"],
]

def _score_answer(answer: str, question_index: int) -> dict:
    """Score an interview answer locally. Returns score 1-10 and feedback."""
    answer = answer.strip()
    word_count = len(answer.split())
    answer_lower = answer.lower()
    
    # ── Hard fail: blank or trivially short ──────────────────────────────────
    if word_count < 5 or answer in ["(No speech detected)", "(No answer)", "", "...", "pass"]:
        return {
            "score": 1,
            "feedback": "❌ No meaningful answer was given. You must provide a detailed response."
        }
    
    if word_count < 15:
        return {
            "score": 2,
            "feedback": f"❌ Answer is too short ({word_count} words). Please elaborate with specific examples, results, and context."
        }
    
    # ── Score based on length ─────────────────────────────────────────────────
    if word_count >= 120:
        score = 7
    elif word_count >= 70:
        score = 6
    elif word_count >= 40:
        score = 5
    else:
        score = 4
    
    # ── Bonus: keyword relevance ──────────────────────────────────────────────
    if 0 <= question_index < len(_QUALITY_KEYWORDS):
        keywords = _QUALITY_KEYWORDS[question_index]
        matched = [kw for kw in keywords if kw in answer_lower]
        keyword_bonus = min(len(matched), 3)  # up to +3 points
        score += keyword_bonus
    
    # ── Bonus: specific numbers, metrics, names ───────────────────────────────
    import re as _re
    if _re.search(r'\d+', answer):
        score += 1  # mentions specific numbers/stats
    
    # ── Cap at 9 (only exceptional answers get 10 via direct Gemini logic) ────
    score = min(score, 9)
    
    # ── Build feedback string ─────────────────────────────────────────────────
    if score >= 8:
        feedback = "✅ Excellent answer! Very detailed, relevant, and well-structured."
    elif score >= 6:
        feedback = "🟡 Good answer. You covered the main points, but could add more specific examples or metrics."
    elif score >= 4:
        feedback = f"⚠️ Somewhat weak answer ({word_count} words). Add specific examples, technologies used, and tangible outcomes."
    else:
        feedback = f"❌ Insufficient answer ({word_count} words). A strong interview response needs at least 60-100 words with specific details."
    
    return {"score": score, "feedback": feedback}


@app.post("/mock-interview")
async def mock_interview_endpoint(data: dict):
    """Local rule-based interview scoring engine. No external API required.
    Asks 5 standard questions, evaluates answers strictly based on length and keyword relevance."""

    messages = data.get("messages", [])
    
    # Separate user vs assistant messages (ignore selection markers)
    user_msgs = [m for m in messages if m.get("role") == "user"
                 and not m.get("content", "").startswith("selection:")]
    assistant_msgs = [m for m in messages if m.get("role") == "assistant"
                      and not m.get("content", "").startswith("selection:")]
    
    question_count = len(assistant_msgs)  # how many times AI has spoken = how many questions asked
    
    # ── Q0: First greeting (no user answer yet) ───────────────────────────────
    if question_count == 0:
        reply = (
            "Welcome to your Live AI Interview! 🎯\n\n"
            "I'll ask you **5 interview questions** and **rigorously evaluate** each answer based on: "
            "response length, relevance, specific examples, and keyword usage.\n\n"
            "**⚠️ Important:** Blank or very short answers will receive a low score (1-2/10). "
            "Give detailed, structured responses.\n\n"
            f"**Question 1/5:**\n{_INTERVIEW_QUESTIONS[0]}"
        )
        return {"reply": reply}

    # ── End of interview (after 5 questions answered) ─────────────────────────
    last_user = user_msgs[-1].get("content", "") if user_msgs else ""
    is_forced_end = last_user.lower().strip() in ["stop interview", "end interview", "quit session", "end"]
    
    if question_count >= 5 or is_forced_end:
        # Recompute per-question scores from history
        total = 0
        breakdown_lines = []
        num_scored = min(len(user_msgs), 5)
        
        for i in range(num_scored):
            ans = user_msgs[i].get("content", "")
            eval_result = _score_answer(ans, i)
            s = eval_result["score"]
            total += s
            breakdown_lines.append(f"Q{i+1}: **{s}/10** — {eval_result['feedback']}")
        
        avg = round((total / num_scored) if num_scored > 0 else 0, 1)
        final_score = min(round(avg * 10), 100)
        
        if avg >= 8:
            grade = "🏆 Excellent"
            tip = "Outstanding performance! You're well-prepared for real interviews."
        elif avg >= 6:
            grade = "✅ Good"
            tip = "Good work! Strengthen your answers with more specific metrics and technical depth."
        elif avg >= 4:
            grade = "⚠️ Needs Work"
            tip = "Keep practicing. Focus on giving structured 3-5 sentence answers with concrete examples."
        else:
            grade = "❌ Insufficient"
            tip = "You need significant improvement. Practice answering with STAR method: Situation, Task, Action, Result."
        
        breakdown_text = "\n".join(breakdown_lines)
        reply = (
            f"## Interview Complete!\n\n"
            f"**Final Score: {final_score}/100** — {grade}\n\n"
            f"### Per-Question Breakdown:\n{breakdown_text}\n\n"
            f"### 💡 Key Tip:\n{tip}\n\n"
            f"Restart the session to practice again!"
        )
        
        # Add gesture feedback if available
        image_data = data.get("image")
        if image_data:
            try:
                import analyze_gesture
                gesture_feedback = analyze_gesture.analyze_image(image_data)
                reply += gesture_feedback
            except Exception as e:
                print(f"Gesture analysis error: {e}")
        
        return {"reply": reply}
    
    # ── Mid-interview: evaluate the last answer and ask the next question ─────
    last_answer = user_msgs[-1].get("content", "") if user_msgs else ""
    
    # The question we just answered is (question_count - 1) since question_count = number already asked
    answered_q_index = question_count - 1
    eval_result = _score_answer(last_answer, answered_q_index)
    
    next_q_index = question_count  # next question to ask (0-indexed)
    next_q = _INTERVIEW_QUESTIONS[next_q_index] if next_q_index < len(_INTERVIEW_QUESTIONS) else None
    
    score_text = f"**Score for your answer: {eval_result['score']}/10**\n{eval_result['feedback']}"
    
    if next_q:
        reply = f"{score_text}\n\n---\n\n**Question {next_q_index + 1}/5:**\n{next_q}"
    else:
        reply = f"{score_text}\n\nThat concludes your interview! Processing final results..."
    
    # Add gesture feedback if available
    image_data = data.get("image")
    if image_data:
        try:
            import analyze_gesture
            gesture_feedback = analyze_gesture.analyze_image(image_data)
            reply += gesture_feedback
        except Exception as e:
            print(f"Gesture analysis error: {e}")
    
    return {"reply": reply}




@app.post("/chat")
async def english_practice_chat(data: dict):
    if not _GEMINI_KEY:
        raise HTTPException(status_code=500, detail="GEMINI_API_KEY not configured")
    
    messages = data.get("messages", [])
    contents = []
    system_prompt = (
        "You are an English Grammar and Communication Coach. "
        "Correct any grammar mistakes, explain the changes clearly, and give a professional writing tip. "
        "Keep your tone encouraging and professional."
    )
    
    for i, msg in enumerate(messages):
        role = "user" if msg.get("role") == "user" else "model"
        text = msg.get("content", "")
        if i == 0 and role == "user":
            text = f"System Instruction: {system_prompt}\\n\\nUser: {text}"
            
        contents.append({
            "role": role,
            "parts": [{"text": text}]
        })
        
    try:
        async with _httpx.AsyncClient(timeout=30) as client:
            resp = await client.post(
                f"{_GEMINI_URL}?key={_GEMINI_KEY}",
                json={"contents": contents},
            )
        if resp.status_code == 200:
            reply = resp.json()["candidates"][0]["content"]["parts"][0]["text"]
            return {"reply": reply}
        elif resp.status_code == 429:
            return {"reply": "⚠️ I'm currently experiencing high demand. The AI service has hit its rate limit. Please wait a minute and try again!"}
        else:
            return {"reply": f"⚠️ I encountered an error ({resp.status_code}). Please try again shortly."}
    except Exception as e:
        return {"reply": "⚠️ I'm having trouble connecting to the AI service right now. Please try again in a moment."}

# ──────────────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=False)
