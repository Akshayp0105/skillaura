"""
AI-Driven Resume Content Engine
================================
Generates role-specific, company-aware, ATS-optimized resume content.
Uses a comprehensive knowledge base of roles, companies, and industry patterns
to produce contextual bullet points, summaries, and skill recommendations.
"""

# ─── ROLE KNOWLEDGE BASE ───
# Maps role keywords to: description pattern, key responsibilities, recommended skills, action verbs
ROLE_KB = {
    "frontend": {
        "titles": ["Frontend Developer", "Frontend Engineer", "UI Developer", "Web Developer"],
        "bullets": [
            "Architected and developed responsive web applications using {framework}, serving {users} monthly active users",
            "Implemented pixel-perfect UI components from Figma/Sketch designs, achieving 98% design fidelity across browsers",
            "Optimized front-end performance using code splitting, lazy loading, and memoization, improving Lighthouse scores from {low} to {high}",
            "Built reusable component library with {count}+ components, reducing development time for new features by 40%",
            "Implemented comprehensive unit and integration tests using Jest and React Testing Library, achieving {coverage}% code coverage",
            "Collaborated with UX designers and backend engineers in an Agile environment to deliver features 2 sprints ahead of schedule",
            "Integrated RESTful APIs and GraphQL endpoints, implementing efficient data fetching with caching strategies",
            "Led migration from class-based to functional components with React Hooks, reducing codebase complexity by 30%",
        ],
        "skills_suggest": ["React.js", "JavaScript (ES6+)", "TypeScript", "HTML5", "CSS3", "Redux", "Webpack", "Jest", "Git"],
    },
    "backend": {
        "titles": ["Backend Developer", "Backend Engineer", "Server-Side Developer", "API Developer"],
        "bullets": [
            "Designed and developed scalable RESTful APIs handling {requests} requests/second with sub-100ms response times",
            "Architected microservices-based backend using {framework}, reducing system downtime by 45%",
            "Implemented database optimization strategies including indexing, query optimization, and connection pooling, improving query performance by {perf}%",
            "Built secure authentication and authorization systems using JWT/OAuth2.0, protecting {users}+ user accounts",
            "Designed and implemented event-driven architecture using message queues (RabbitMQ/Kafka) for asynchronous processing",
            "Developed automated CI/CD pipelines reducing deployment time from 4 hours to 15 minutes",
            "Implemented caching strategies using Redis, reducing database load by 60% and improving API response times by 3x",
            "Wrote comprehensive API documentation using Swagger/OpenAPI, improving developer onboarding efficiency by 50%",
        ],
        "skills_suggest": ["Python", "Node.js", "Java", "PostgreSQL", "MongoDB", "Redis", "Docker", "REST APIs", "Git"],
    },
    "fullstack": {
        "titles": ["Full Stack Developer", "Full Stack Engineer", "Software Developer"],
        "bullets": [
            "Developed end-to-end web applications using {frontend_fw} frontend and {backend_fw} backend, serving {users}+ users",
            "Designed and implemented database schemas in {db}, optimizing for read-heavy workloads with 99.9% query reliability",
            "Built real-time features using WebSockets, enabling live collaboration for {users}+ concurrent users",
            "Implemented responsive, mobile-first designs achieving 95+ Google Lighthouse accessibility scores",
            "Deployed and managed applications on cloud platforms ({cloud}), implementing auto-scaling and load balancing",
            "Conducted code reviews for a team of {team_size} developers, maintaining high code quality standards",
            "Integrated third-party APIs (payment gateways, authentication, analytics) reducing development time by 35%",
            "Implemented automated testing pipeline with {coverage}% code coverage, reducing production bugs by 50%",
        ],
        "skills_suggest": ["React.js", "Node.js", "Python", "PostgreSQL", "MongoDB", "AWS", "Docker", "Git", "TypeScript"],
    },
    "mobile": {
        "titles": ["Mobile Developer", "Mobile App Developer", "App Developer"],
        "bullets": [
            "Developed cross-platform mobile applications using {framework} deployed to both iOS and Android app stores",
            "Implemented complex UI animations and transitions achieving 60fps rendering performance on mid-range devices",
            "Integrated native device features (camera, GPS, biometrics, push notifications) enhancing user engagement by 35%",
            "Optimized app performance reducing cold start time by 40% and memory usage by 25%",
            "Implemented offline-first architecture with local data synchronization, ensuring seamless user experience",
            "Published applications with 4.5+ star ratings and {downloads}+ downloads on Google Play Store and App Store",
            "Integrated analytics and crash reporting tools, achieving 99.5% crash-free rate in production",
            "Conducted A/B testing on UI layouts, increasing user retention by 20% through data-driven design decisions",
        ],
        "skills_suggest": ["Flutter", "Dart", "React Native", "Firebase", "REST APIs", "Git", "Kotlin", "Swift"],
    },
    "data_science": {
        "titles": ["Data Scientist", "ML Engineer", "Machine Learning Engineer", "AI Engineer"],
        "bullets": [
            "Developed machine learning models using {framework} achieving {accuracy}% accuracy on classification/regression tasks",
            "Built end-to-end ML pipelines from data ingestion to model deployment, reducing model iteration time by 60%",
            "Performed exploratory data analysis on {size}+ record datasets using Pandas and NumPy, identifying key business insights",
            "Implemented natural language processing solutions using transformers/BERT for text classification and sentiment analysis",
            "Designed and deployed recommendation systems increasing user engagement by 25% and revenue by 15%",
            "Built automated feature engineering pipelines processing {volume} data points daily with 99.9% reliability",
            "Conducted A/B tests and statistical analyses to validate model performance and drive product decisions",
            "Visualized complex data insights using Matplotlib, Seaborn, and Tableau dashboards for stakeholder presentations",
        ],
        "skills_suggest": ["Python", "TensorFlow", "PyTorch", "scikit-learn", "Pandas", "SQL", "Jupyter", "AWS SageMaker"],
    },
    "devops": {
        "titles": ["DevOps Engineer", "Site Reliability Engineer", "Cloud Engineer", "Infrastructure Engineer"],
        "bullets": [
            "Designed and managed cloud infrastructure on {cloud} supporting {services}+ microservices in production",
            "Implemented Infrastructure as Code using Terraform/CloudFormation, reducing provisioning time from days to minutes",
            "Built CI/CD pipelines using Jenkins/GitHub Actions, enabling {deploys}+ deployments per week with zero downtime",
            "Orchestrated containerized applications using Kubernetes, managing {pods}+ pods across multiple clusters",
            "Implemented comprehensive monitoring and alerting using Prometheus, Grafana, and PagerDuty, achieving 99.95% uptime",
            "Automated security scanning and compliance checks in the deployment pipeline, reducing vulnerabilities by 70%",
            "Optimized cloud costs by 40% through right-sizing instances, implementing spot instances, and reserved capacity planning",
            "Managed database replication, backup strategies, and disaster recovery procedures for business-critical systems",
        ],
        "skills_suggest": ["AWS", "Docker", "Kubernetes", "Terraform", "Jenkins", "Linux", "Python", "Prometheus", "Git"],
    },
    "data_analyst": {
        "titles": ["Data Analyst", "Business Analyst", "Analytics Engineer"],
        "bullets": [
            "Analyzed large datasets ({size}+ records) using SQL and Python to derive actionable business insights",
            "Built interactive dashboards and reports using Tableau/Power BI, enabling data-driven decision making for stakeholders",
            "Developed automated ETL pipelines reducing manual data processing time by 80%",
            "Conducted statistical analyses and hypothesis testing to validate business strategies, driving 15% revenue growth",
            "Created predictive models for customer churn and demand forecasting with {accuracy}% accuracy",
            "Collaborated with product and marketing teams to define KPIs and track performance metrics",
            "Documented data dictionary and analysis methodologies, improving team knowledge sharing and reproducibility",
            "Presented findings to C-suite executives, translating complex data into clear, actionable recommendations",
        ],
        "skills_suggest": ["SQL", "Python", "Tableau", "Excel", "Power BI", "Pandas", "Statistics", "ETL"],
    },
    "intern": {
        "titles": ["Software Engineering Intern", "Development Intern", "Tech Intern"],
        "bullets": [
            "Contributed to production codebase under mentorship, implementing {count}+ features used by {users}+ users",
            "Developed and tested {component} modules using {framework}, following team coding standards and best practices",
            "Participated in daily standups, sprint planning, and code reviews in an Agile/Scrum development environment",
            "Built internal tools that automated {task}, saving the team approximately {hours} hours per week",
            "Collaborated with senior engineers to debug and resolve {count}+ production issues during internship period",
            "Documented technical specifications and created onboarding guides for future interns and team members",
            "Presented project demos to stakeholders, receiving commendation for initiative and code quality",
            "Completed internship project {days} ahead of schedule, earning a return offer for full-time position",
        ],
        "skills_suggest": ["Python", "JavaScript", "Git", "SQL", "React", "Node.js", "Agile", "Communication"],
    },
    "qa": {
        "titles": ["QA Engineer", "Test Engineer", "Quality Assurance Engineer", "SDET"],
        "bullets": [
            "Designed and executed {count}+ test cases covering functional, regression, and integration testing scenarios",
            "Developed automated test frameworks using Selenium/Cypress, increasing test coverage from 40% to 90%",
            "Identified and documented {count}+ critical bugs before production release, preventing potential revenue loss",
            "Implemented performance testing using JMeter/Locust, establishing baseline metrics and SLAs",
            "Created comprehensive test plans and test strategies aligned with business requirements and user stories",
            "Integrated automated tests into CI/CD pipeline, reducing regression testing time from 8 hours to 45 minutes",
        ],
        "skills_suggest": ["Selenium", "Python", "Java", "Cypress", "JMeter", "SQL", "Git", "JIRA", "Postman"],
    },
    "product": {
        "titles": ["Product Manager", "Product Owner", "Program Manager"],
        "bullets": [
            "Managed product roadmap for {product}, prioritizing features based on user research and business impact",
            "Conducted user interviews and surveys with {count}+ users to identify pain points and validate solutions",
            "Defined PRDs and user stories for {count}+ features, guiding development teams through successful delivery",
            "Achieved {metric}% increase in user engagement through data-driven A/B testing and iterative design",
            "Coordinated cross-functional teams of {size}+ engineers, designers, and analysts across multiple time zones",
            "Launched {count} major product features increasing monthly active users by {growth}%",
        ],
        "skills_suggest": ["JIRA", "Figma", "SQL", "Analytics", "A/B Testing", "Agile", "Communication", "Strategy"],
    },
}

# ─── COMPANY KNOWLEDGE BASE ───
# Maps company names to: culture keywords, tech stack, what they look for
COMPANY_KB = {
    "google": {
        "culture": ["innovation", "scale", "data-driven", "user-centric"],
        "tech": ["Go", "Python", "Java", "C++", "TensorFlow", "Kubernetes", "GCP", "Protocol Buffers"],
        "values": "Googleyness, problem-solving at scale, algorithmic thinking, and user impact",
        "bullet_mods": [
            "leveraging data-driven approaches aligned with Google's engineering excellence standards",
            "at Google-scale infrastructure serving millions of users globally",
            "following Google's engineering best practices for reliability and performance",
        ],
    },
    "amazon": {
        "culture": ["customer-obsession", "ownership", "dive-deep", "bias-for-action"],
        "tech": ["Java", "Python", "AWS", "DynamoDB", "Lambda", "S3", "React"],
        "values": "Amazon Leadership Principles including Customer Obsession, Ownership, and Bias for Action",
        "bullet_mods": [
            "demonstrating ownership mentality and customer-obsessed product thinking",
            "optimizing for operational excellence in high-availability distributed systems",
            "applying dive-deep analysis to technical problems at Amazon scale",
        ],
    },
    "microsoft": {
        "culture": ["growth-mindset", "inclusive", "enterprise", "cloud-first"],
        "tech": ["C#", ".NET", "Azure", "TypeScript", "React", "Python", "SQL Server"],
        "values": "growth mindset, inclusivity, and enterprise-scale cloud innovation",
        "bullet_mods": [
            "embracing Microsoft's growth mindset culture and collaborative engineering practices",
            "building cloud-native solutions on enterprise-grade Azure infrastructure",
        ],
    },
    "meta": {
        "culture": ["move-fast", "bold", "open", "social-impact"],
        "tech": ["React", "React Native", "Python", "PHP/Hack", "GraphQL", "PyTorch"],
        "values": "moving fast, building social technologies, and thinking at global scale",
        "bullet_mods": [
            "moving fast with high-quality code in Meta's engineering culture",
            "building features reaching billions of users across Meta's family of apps",
        ],
    },
    "apple": {
        "culture": ["design-excellence", "privacy", "innovation", "attention-to-detail"],
        "tech": ["Swift", "Objective-C", "Python", "Machine Learning", "UIKit", "SwiftUI"],
        "values": "design excellence, user privacy, and revolutionary product innovation",
        "bullet_mods": [
            "delivering pixel-perfect experiences with Apple's legendary attention to detail",
            "building privacy-first features aligned with Apple's core values",
        ],
    },
    "flipkart": {
        "culture": ["customer-first", "bold", "scale", "india-focused"],
        "tech": ["Java", "Python", "React", "Node.js", "MySQL", "Redis", "Kafka"],
        "values": "customer-first approach and building technology for India's digital commerce",
        "bullet_mods": [
            "handling high-traffic e-commerce workloads during flash sales and Big Billion Days",
            "building scalable solutions for India's largest e-commerce marketplace",
        ],
    },
    "infosys": {
        "culture": ["learning", "client-service", "consulting", "digital-transformation"],
        "tech": ["Java", "Python", ".NET", "SQL", "SAP", "Cloud", "Agile"],
        "values": "continuous learning, client-service excellence, and digital transformation",
        "bullet_mods": [
            "delivering enterprise consulting solutions for Fortune 500 clients",
            "driving digital transformation projects using Infosys Living Labs innovation",
        ],
    },
    "tcs": {
        "culture": ["client-service", "innovation", "integrity", "global-delivery"],
        "tech": ["Java", "Python", ".NET", "SAP", "Cloud", "SQL", "Angular"],
        "values": "customer-centricity, integrity, and global delivery excellence",
        "bullet_mods": [
            "delivering mission-critical solutions for global enterprise clients",
            "implementing TCS's contextual knowledge model for digital transformation",
        ],
    },
    "wipro": {
        "culture": ["innovation", "sustainability", "integrity", "digital"],
        "tech": ["Java", "Python", ".NET", "Cloud", "AI/ML", "SAP"],
        "values": "spirit of innovation, sustainability, and integrity in digital services",
        "bullet_mods": [
            "contributing to Wipro's HOLMES AI platform for intelligent automation",
            "building sustainable technology solutions for global enterprise clients",
        ],
    },
    "netflix": {
        "culture": ["freedom-responsibility", "high-performance", "innovation"],
        "tech": ["Java", "Python", "React", "Node.js", "AWS", "Kafka", "Cassandra"],
        "values": "freedom and responsibility, with a focus on stunning performance",
        "bullet_mods": [
            "building high-performance streaming infrastructure at Netflix scale",
            "implementing A/B testing frameworks driving content recommendations for 200M+ subscribers",
        ],
    },
}


def _match_role(text: str) -> dict:
    """Match user's role input to the best role in the knowledge base."""
    text_lower = text.lower()
    
    # Direct matches
    role_map = {
        "frontend": "frontend", "front end": "frontend", "front-end": "frontend",
        "ui developer": "frontend", "ui engineer": "frontend", "web developer": "frontend",
        "react developer": "frontend", "angular developer": "frontend", "vue developer": "frontend",
        
        "backend": "backend", "back end": "backend", "back-end": "backend",
        "server": "backend", "api developer": "backend",
        
        "fullstack": "fullstack", "full stack": "fullstack", "full-stack": "fullstack",
        "software engineer": "fullstack", "software developer": "fullstack", "sde": "fullstack",
        "swe": "fullstack",
        
        "mobile": "mobile", "android": "mobile", "ios": "mobile", "flutter": "mobile",
        "react native": "mobile", "app developer": "mobile",
        
        "data scien": "data_science", "ml engineer": "data_science", "machine learning": "data_science",
        "ai engineer": "data_science", "deep learning": "data_science",
        
        "devops": "devops", "sre": "devops", "cloud engineer": "devops", "infrastructure": "devops",
        "platform engineer": "devops",
        
        "data analyst": "data_analyst", "business analyst": "data_analyst", "analytics": "data_analyst",
        
        "intern": "intern", "trainee": "intern", "fresher": "intern",
        
        "qa": "qa", "test": "qa", "quality": "qa", "sdet": "qa",
        
        "product manager": "product", "product owner": "product", "program manager": "product",
    }
    
    for key, role_id in role_map.items():
        if key in text_lower:
            return ROLE_KB[role_id]
    
    # Default to fullstack
    return ROLE_KB["fullstack"]


def _match_company(text: str) -> dict:
    """Match user's company input to the knowledge base."""
    text_lower = text.lower().strip()
    
    for company_key, company_data in COMPANY_KB.items():
        if company_key in text_lower:
            return company_data
    
    # Generic company profile
    return {
        "culture": ["innovation", "teamwork", "quality"],
        "tech": [],
        "values": "innovation, quality engineering, and collaborative teamwork",
        "bullet_mods": [
            "delivering high-quality software solutions in a collaborative team environment",
            "implementing industry best practices for software development lifecycle",
        ],
    }


def generate_smart_bullets(role: str, company: str, skills: list, count: int = 5) -> list:
    """
    AI-like bullet point generator that uses role + company + skills context
    to produce highly relevant, quantified achievement statements.
    """
    import random
    
    role_data = _match_role(role)
    company_data = _match_company(company)
    
    # Template variable replacements
    replacements = {
        "{framework}": "",
        "{frontend_fw}": "React.js",
        "{backend_fw}": "Node.js",
        "{db}": "PostgreSQL",
        "{cloud}": "AWS",
        "{users}": random.choice(["10,000", "50,000", "100,000", "500,000"]),
        "{requests}": random.choice(["5,000", "10,000", "25,000"]),
        "{coverage}": random.choice(["85", "90", "92", "95"]),
        "{accuracy}": random.choice(["89", "92", "94", "96"]),
        "{perf}": random.choice(["40", "55", "65", "70"]),
        "{low}": random.choice(["42", "48", "55"]),
        "{high}": random.choice(["90", "93", "96"]),
        "{count}": random.choice(["5", "8", "10", "12", "15"]),
        "{team_size}": random.choice(["5", "8", "10"]),
        "{size}": random.choice(["100K", "500K", "1M"]),
        "{volume}": random.choice(["50K", "100K", "500K"]),
        "{downloads}": random.choice(["10K", "50K", "100K"]),
        "{services}": random.choice(["10", "15", "20"]),
        "{deploys}": random.choice(["50", "100", "200"]),
        "{pods}": random.choice(["100", "200", "500"]),
        "{hours}": random.choice(["10", "15", "20"]),
        "{days}": random.choice(["5", "7", "10"]),
        "{component}": "core application",
        "{task}": "repetitive reporting workflows",
        "{product}": "the core platform",
        "{metric}": random.choice(["25", "30", "35", "40"]),
        "{growth}": random.choice(["15", "20", "25", "30"]),
    }
    
    # Determine best framework based on skills + role
    skills_lower = [s.lower().strip() for s in skills]
    
    if "react" in skills_lower or "react.js" in skills_lower:
        replacements["{framework}"] = "React.js"
        replacements["{frontend_fw}"] = "React.js"
    elif "angular" in skills_lower:
        replacements["{framework}"] = "Angular"
        replacements["{frontend_fw}"] = "Angular"
    elif "vue" in skills_lower or "vue.js" in skills_lower:
        replacements["{framework}"] = "Vue.js"
        replacements["{frontend_fw}"] = "Vue.js"
    elif "flutter" in skills_lower:
        replacements["{framework}"] = "Flutter/Dart"
    elif "django" in skills_lower:
        replacements["{framework}"] = "Django"
        replacements["{backend_fw}"] = "Django"
    elif "spring" in skills_lower or "java" in skills_lower:
        replacements["{framework}"] = "Spring Boot"
        replacements["{backend_fw}"] = "Spring Boot (Java)"
    elif "express" in skills_lower or "node" in skills_lower or "node.js" in skills_lower:
        replacements["{framework}"] = "Node.js/Express"
        replacements["{backend_fw}"] = "Node.js/Express"
    elif "flask" in skills_lower or "python" in skills_lower:
        replacements["{framework}"] = "Python/Flask"
        replacements["{backend_fw}"] = "Python/Flask"
    else:
        replacements["{framework}"] = "modern frameworks"
    
    # Database from skills
    for db in ["mongodb", "mysql", "postgresql", "dynamodb", "redis"]:
        if db in skills_lower:
            replacements["{db}"] = db.title()
            break
    
    # Cloud from skills
    for cloud in ["aws", "azure", "gcp", "google cloud"]:
        if cloud in skills_lower:
            replacements["{cloud}"] = cloud.upper() if cloud in ["aws", "gcp"] else cloud.title()
            break
    
    # Use company tech if relevant
    if company_data.get("tech"):
        for tech in company_data["tech"]:
            if tech.lower() in skills_lower:
                replacements["{framework}"] = tech
                break
    
    # Select and fill bullet templates
    role_bullets = list(role_data["bullets"])
    random.shuffle(role_bullets)
    
    result = []
    for bullet_template in role_bullets[:count]:
        bullet = bullet_template
        for key, val in replacements.items():
            bullet = bullet.replace(key, val)
        result.append(bullet)
    
    # Add one company-flavored bullet if available
    if company_data.get("bullet_mods") and len(result) > 0:
        mod = random.choice(company_data["bullet_mods"])
        # Append company context to the last bullet
        if len(result) >= 2:
            result.insert(1, f"Demonstrated strong engineering skills, {mod}")
    
    return result[:count]


def generate_smart_summary(name: str, role: str, company: str, skills: list, exp_text: str) -> str:
    """Generate an ATS-optimized, role-aware professional summary."""
    role_data = _match_role(role)
    company_data = _match_company(company)
    
    top_skills = ", ".join(skills[:5]) if skills else "modern software technologies"
    company_values = company_data.get("values", "engineering excellence and innovation")
    
    is_fresher = exp_text.lower().strip() in ["fresher", "no", "none", "skip", "na", "n/a", ""]
    
    if is_fresher:
        return (
            f"Highly motivated and detail-oriented Computer Science graduate with strong foundation in "
            f"{top_skills}. Demonstrated ability to build production-quality software through academic projects "
            f"and personal development. Seeking to contribute as {role} at {company}, leveraging strong "
            f"analytical and problem-solving skills. Passionate about {company_values}. "
            f"Quick learner with excellent communication skills and a growth mindset."
        )
    else:
        return (
            f"Results-driven {role} with proven expertise in {top_skills}. "
            f"Track record of delivering high-quality, scalable solutions in fast-paced environments. "
            f"Skilled at translating business requirements into efficient technical implementations. "
            f"Seeking to bring technical leadership and innovation to {company}, "
            f"where {company_values} align with professional goals. "
            f"Strong collaborator with excellent communication and mentoring abilities."
        )
