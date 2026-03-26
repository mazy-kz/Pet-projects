%-------------------------------------------------------------------------------
%                Identification
%-------------------------------------------------------------------------------
\ProvidesClass{resume_config}[2026 v3.2 resume_config]
\NeedsTeXFormat{LaTeX2e}

\LoadClass[11pt]{article} % Consistent 11pt base size for body text

%-------------------------------------------------------------------------------
%                Packages
%-------------------------------------------------------------------------------
\RequirePackage{geometry}
\RequirePackage[hidelinks]{hyperref}
\RequirePackage{iftex}
\RequirePackage{xcolor}
\RequirePackage[english]{babel}
\RequirePackage{titlesec}
\RequirePackage{enumitem}
\RequirePackage{fontawesome5} % Reintroduced for icons
\RequirePackage{setspace}

% Font setup for both pdfLaTeX and Xe/LuaLaTeX
\ifPDFTeX
\RequirePackage[T1]{fontenc}
\RequirePackage[utf8]{inputenc}
\RequirePackage{helvet}
\renewcommand{\familydefault}{\sfdefault}
\newcommand{\semiboldfont}{\bfseries}
\else
\RequirePackage{fontspec}
\setmainfont{TeX Gyre Heros}
\newfontface\semiboldfont{TeX Gyre Heros Bold}
\fi
\newcommand{\semibold}[1]{{\semiboldfont #1}}

%-------------------------------------------------------------------------------
%                Formatting
%-------------------------------------------------------------------------------
\setlength{\tabcolsep}{0in}
\pagenumbering{gobble}
\pagestyle{empty}
\hypersetup{pageanchor=false}
\raggedbottom
\raggedright

\geometry{
    paper=letterpaper,
    top=0.5in,
    bottom=0.5in,
    left=0.5in,
    right=0.5in
}

% Section Headers: Consistent size and SemiBold weight
\titleformat{\section}%
    {\scshape\raggedright\large\semiboldfont}% 
    {}% 
    {0em}% 
    {}% 
    [\color{black}\titlerule\vspace{-5pt}]
\titlespacing*{\section}{0pt}{-4pt}{6pt}

%-------------------------------------------------------------------------------
%                Custom Commands
%-------------------------------------------------------------------------------

% 1. Header: Balanced with icons and SemiBold name
% Updated Header: Replaced dots with pipes for a sleeker look
\newcommand{\Header}[6]{
    \begin{center}
        {\Huge\semibold{\textsc{#1}}}\\[6pt] 
        \hrule
        \vspace{5pt}
        \textcolor{black}{\small
            \faMapMarker* \ #2 \quad \faPhone* \ #3 \quad \faEnvelope \ \href{mailto:#4}{#4} \quad \faLinkedin \ \href{https://www.linkedin.com/in/#5}{#5} \quad \faGithub \ \href{https://www.github.com/#6}{#6}
        }
        \vspace{5pt}
        \hrule
    \end{center}
    \vspace{-12pt} 
}

% 2. Updated Work Experience: Added space between bullet points for readability
\newcommand{\WorkExperience}[5]{
    \noindent
    \begin{tabular*}{\textwidth}{@{}l @{\extracolsep{\fill}} r}
        \semibold{#1} & \semibold{#3} \\ % Role & Date in SemiBold
        #2 & #4 \\ % Company & Location in Regular
    \end{tabular*}
    
    \begin{itemize}[itemsep=1.5pt, topsep=2pt, leftmargin=1.25em, label={$-$}]
        \small #5 % Body text
    \end{itemize}
    \vspace{6pt} % Space between different job entries
}

% 3. Education: School SemiBold, Degree Regular
\newcommand{\EducationExperience}[4]{
    \noindent
    \begin{tabular*}{\textwidth}{@{}l @{\extracolsep{\fill}} r}
        \semibold{#1} & \semibold{#3} \\ % School & Date in SemiBold
        #2 & #4 \\ % Degree & Location in Regular
    \end{tabular*}
    \vspace{2pt}
}

% Updated Certification & Social Impact: Semibold name and year, Regular provider
\newcommand{\Certification}[3]{
    \noindent
    {\semibold{#1}} $|$ {\normalfont #2} \hfill {\semibold{#3}}\\[5pt] 
}

% Skills command: Flush left with Semibold category
\newcommand{\SkillItem}[2]{
    \noindent % Forces text to the absolute left margin
    {\semibold{#1}:} #2\\[3pt] 
}