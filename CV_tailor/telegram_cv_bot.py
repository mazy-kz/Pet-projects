import os
import re
import subprocess
from pathlib import Path
from shutil import which

from google import genai
from playwright.async_api import async_playwright
from telegram import Update
from telegram.ext import Application, ContextTypes, MessageHandler, filters


BASE_DIR = Path(__file__).resolve().parent
TEMPLATE_TEX = BASE_DIR / "main.tex"
OUTPUT_DIR = BASE_DIR / "output"

TELEGRAM_TOKEN = os.getenv("TELEGRAM_TOKEN")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
MODEL_ID = os.getenv("GEMINI_MODEL", "gemini-3-flash-preview")

client: genai.Client | None = None


def get_client() -> genai.Client:
    """Create the Gemini client lazily so startup errors stay readable."""
    global client

    if client is None:
        if not GEMINI_API_KEY:
            raise RuntimeError("Missing GEMINI_API_KEY environment variable.")
        client = genai.Client(api_key=GEMINI_API_KEY)

    return client


def validate_startup() -> None:
    """Fail fast with simple messages when required local setup is missing."""
    missing = []

    if not TELEGRAM_TOKEN:
        missing.append("TELEGRAM_TOKEN")
    if not GEMINI_API_KEY:
        missing.append("GEMINI_API_KEY")
    if not TEMPLATE_TEX.exists():
        missing.append(str(TEMPLATE_TEX))

    if missing:
        raise RuntimeError(f"Missing required setup: {', '.join(missing)}")


def slugify(value: str) -> str:
    """Turn the extracted company name into a folder-safe slug."""
    cleaned = re.sub(r"[^a-zA-Z0-9]+", "_", value.strip().lower())
    cleaned = cleaned.strip("_")
    return cleaned[:60] or "unknown_company"


def clean_model_text(text: str) -> str:
    """Strip markdown fences and extra whitespace from model output."""
    cleaned = text.strip()
    for tag in ("```latex", "```tex", "```"):
        cleaned = cleaned.replace(tag, "")
    return cleaned.strip()


def read_template() -> str:
    return TEMPLATE_TEX.read_text(encoding="utf-8")


def find_pdflatex() -> str | None:
    """Prefer the fresh user-installed MiKTeX binary over whatever is first on PATH."""
    local_app_data = os.getenv("LOCALAPPDATA", "")
    preferred = Path(local_app_data) / "Programs" / "MiKTeX" / "miktex" / "bin" / "x64" / "pdflatex.exe"
    if preferred.exists():
        return str(preferred)
    return which("pdflatex")


def extract_company_name(job_text: str) -> str:
    """Ask Gemini for the likely company name, then keep the answer compact."""
    prompt = f"""
Extract the hiring company name from the job posting text below.
Return only the company name.
If the company name is unclear, return Unknown Company.

JOB POSTING:
{job_text[:3000]}
""".strip()

    response = get_client().models.generate_content(model=MODEL_ID, contents=prompt)
    if not response.text:
        return "Unknown Company"

    company_name = clean_model_text(response.text).strip("\"'")
    return company_name or "Unknown Company"


def build_tailoring_prompt(job_text: str, original_latex: str) -> str:
    """Give the model clear rules so it tailors without breaking the CV story."""
    return f"""
You are tailoring a LaTeX CV to match a target job description.

Your goal is to make the CV more relevant while keeping the candidate believable.
Use the entire CV as context, even for sections you are not allowed to edit.

TARGET JOB DESCRIPTION:
{job_text[:15000]}

ALLOWED CHANGES:
1. You may update only the values inside \\SkillItem{{...}}{{...}}.
2. You may update only the \\item bullet points inside each Work Experience entry.

STRICT DO NOT TOUCH RULES:
1. Do not change company names, job titles, dates, locations, section headings, macros, or formatting.
2. Do not change contact details, education, certifications, or any text outside skills and work experience bullets.
3. Keep the same number of bullets for each role.
4. Preserve valid LaTeX syntax and output only raw LaTeX.

WORK EXPERIENCE CONSISTENCY RULES:
1. Every rewritten bullet must fit the exact role title, seniority, company context, and timeline already shown for that role.
2. Do not rewrite a role into a different profession. Keep the duties believable for that position.
3. Make the bullets feel connected to the rest of the CV. They should support the same overall professional story across summary, skills, education, certifications, and other roles.
4. Use recurring themes, tools, and business language only when they make sense across the full CV.
5. Prioritize achievements that match the target job, but do not copy the job description line by line.
6. Do not invent experience that would contradict the other sections or make the candidate sound inconsistent.
7. Keep bullets concise, concrete, and outcome-focused.

SKILLS CONSISTENCY RULES:
1. Update skills to better match the target job, but only with capabilities supported by the existing CV.
2. The skills section should reinforce the same themes that appear in the rewritten experience bullets.
3. Do not add random tools or specialties that are not believable from the rest of the CV.

FINAL CHECK BEFORE YOU ANSWER:
- Are the rewritten bullets aligned with each exact job title?
- Do the bullets still sound like the same person from top to bottom?
- Do the skills and experience support each other?
- Is every non-allowed field unchanged?
- Is the output valid LaTeX with no markdown fences?

ORIGINAL LATEX:
{original_latex}
""".strip()


async def scrape_job(url: str) -> str:
    """Scrape the visible text from a job posting page."""
    async with async_playwright() as playwright:
        browser = await playwright.chromium.launch(headless=True)
        page = await browser.new_page()
        try:
            await page.goto(url, wait_until="networkidle", timeout=60000)
            return await page.inner_text("body")
        except Exception as exc:
            return f"Error scraping: {exc}"
        finally:
            await browser.close()


async def handle_job_link(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Scrape the job post, tailor the CV, build the PDF, and send it back."""
    del context

    if update.message is None or update.message.text is None:
        return

    url = update.message.text.strip()
    if not url.startswith(("http://", "https://")):
        return

    await update.message.reply_text("Scraping job description...")
    job_text = await scrape_job(url)
    if job_text.startswith("Error scraping:"):
        await update.message.reply_text(job_text)
        return

    original_latex = read_template()
    company_name = extract_company_name(job_text)
    company_slug = slugify(company_name)

    company_output_dir = OUTPUT_DIR / company_slug
    company_output_dir.mkdir(parents=True, exist_ok=True)

    await update.message.reply_text(f"Tailoring CV for {company_name} with {MODEL_ID}...")
    prompt = build_tailoring_prompt(job_text, original_latex)
    response = get_client().models.generate_content(model=MODEL_ID, contents=prompt)

    if not response.text:
        await update.message.reply_text("The AI did not return any LaTeX.")
        return

    tailored_latex = clean_model_text(response.text)
    tex_filename = f"cv_{company_slug}.tex"
    pdf_filename = f"cv_{company_slug}.pdf"
    tex_path = company_output_dir / tex_filename
    pdf_path = company_output_dir / pdf_filename

    tex_path.write_text(tailored_latex, encoding="utf-8")

    await update.message.reply_text(f"Compiling PDF in output/{company_slug}...")
    pdflatex = find_pdflatex()
    if not pdflatex:
        await update.message.reply_text("pdflatex was not found. Install MiKTeX first.")
        return

    try:
        subprocess.run(
            [pdflatex, "-interaction=nonstopmode", "-halt-on-error", tex_filename],
            cwd=company_output_dir,
            capture_output=True,
            text=True,
            check=True,
        )
    except FileNotFoundError:
        await update.message.reply_text("pdflatex is not installed or is not on PATH.")
        return
    except subprocess.CalledProcessError as exc:
        error_text = (exc.stderr or exc.stdout).strip()
        await update.message.reply_text(
            f"Build failed (code {exc.returncode}).\n{error_text[:500]}"
        )
        return

    if not pdf_path.exists():
        await update.message.reply_text("Compilation finished, but the PDF was not created.")
        return

    with pdf_path.open("rb") as pdf_file:
        await update.message.reply_document(
            document=pdf_file,
            filename=pdf_filename,
            caption=f"Tailored CV ready for {company_name}.",
        )


def main() -> None:
    """Start the Telegram bot."""
    validate_startup()

    app = Application.builder().token(TELEGRAM_TOKEN).build()
    app.add_handler(MessageHandler(filters.TEXT & (~filters.COMMAND), handle_job_link))

    print("CV tailor bot is running.")
    print(f"Model: {MODEL_ID}")
    print("Waiting for job links in Telegram...")

    app.run_polling()


if __name__ == "__main__":
    main()
