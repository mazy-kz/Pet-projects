import os
import asyncio
import shutil
import subprocess
from telegram import Update
from telegram.ext import Application, MessageHandler, filters, ContextTypes
from playwright.async_api import async_playwright
from google import genai

# CONFIGURATION
TELEGRAM_TOKEN = "Telegram_Bot_Token_Here"
GEMINI_API_KEY = GEMINI_API_KEY"
LATEX_FILE = "main.tex"

# ... (TELEGRAM_TOKEN and GEMINI_API_KEY variables here) ...

# Initialize the Gemini 3 Client
client = genai.Client(api_key=GEMINI_API_KEY)
MODEL_ID = "gemini-3-flash-preview"

# Local file naming
TEMPLATE_TEX = "main.tex"
CONFIG_FILE = "resume_config.cls"

async def scrape_job(url: str) -> str:
    """Scrapes the text content of a job posting URL."""
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page()
        try:
            await page.goto(url, wait_until="networkidle", timeout=60000)
            content = await page.inner_text("body")
            return str(content)
        except Exception as e:
            return f"Error scraping: {e}"
        finally:
            await browser.close()

async def handle_job_link(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Main logic: Scrape -> Tailor -> Create Folder -> Build -> Send."""
    if update.message is None or update.message.text is None:
        return

    url = str(update.message.text)
    if "http" not in url:
        return

    await update.message.reply_text("🔍 Scraping job description...")
    job_text = await scrape_job(url)
    
    # 1. Get Company Name for organization
    name_resp = client.models.generate_content(
        model=MODEL_ID, 
        contents=f"Output only the 1-word company name from this text: {job_text[:1000]}"
    )
    company = name_resp.text.strip().lower().replace(" ", "_") if name_resp.text else "unknown_company"
    
    # 2. Create directory and copy configuration
    folder_path = os.path.join(os.getcwd(), company)
    os.makedirs(folder_path, exist_ok=True)
    
    if os.path.exists(CONFIG_FILE):
        shutil.copy(CONFIG_FILE, os.path.join(folder_path, CONFIG_FILE))
    else:
        await update.message.reply_text(f"⚠️ Error: {CONFIG_FILE} not found in root folder.")
        return

    # 3. Read the template
    try:
        with open(TEMPLATE_TEX, "r", encoding="utf-8") as f:
            original_latex = f.read()
    except FileNotFoundError:
        await update.message.reply_text(f"⚠️ Error: {TEMPLATE_TEX} not found.")
        return

    # 4. Tailor content using Gemini 3
    system_instruction = rf"""
    Tailor the provided LaTeX CV for this Job Description:
    {job_text}
    
    STRICT CONSTRAINTS:
    1. Update ONLY the 'Skills' section (the values inside \SkillItem).
    2. Update ONLY the bullet points (\item) in 'Work Experience'.
    3. DO NOT change company names, job titles, dates, or locations.
    4. Maintain all LaTeX syntax. Output ONLY the raw LaTeX code.
    
    ORIGINAL LATEX:
    {original_latex}
    """

    await update.message.reply_text(f"🤖 Tailoring for {company.upper()} using {MODEL_ID}...")
    response = client.models.generate_content(model=MODEL_ID, contents=system_instruction)
    
    if not response.text:
        await update.message.reply_text("❌ AI failed to generate LaTeX code.")
        return

    # Clean the response from markdown formatting
    tailored_latex = response.text
    for tag in ["```latex", "```tex", "```"]:
        tailored_latex = tailored_latex.replace(tag, "")
    tailored_latex = tailored_latex.strip()

    # 5. Save the new .tex in the company folder
    tex_filename = f"cv_{company}.tex"
    pdf_filename = f"cv_{company}.pdf"
    tex_path = os.path.join(folder_path, tex_filename)
    
    with open(tex_path, "w", encoding="utf-8") as f:
        f.write(tailored_latex)

    await update.message.reply_text(f"🛠️ Compiling PDF in /{company}...")
    try:
        # 6. Build PDF using TinyTeX inside the specific folder
        build_process = subprocess.run(
            ["pdflatex", "-interaction=nonstopmode", tex_filename], 
            cwd=folder_path, 
            capture_output=True,
            text=True,
            check=True
        )
        
        pdf_path = os.path.join(folder_path, pdf_filename)
        if os.path.exists(pdf_path):
            with open(pdf_path, "rb") as pdf_file:
                await update.message.reply_document(
                    document=pdf_file, 
                    filename=pdf_filename,
                    caption=f"Successfully tailored for {company.capitalize()}!"
                )
        else:
            await update.message.reply_text("❌ PDF was not created. Check LaTeX logs.")

    except subprocess.CalledProcessError as e:
        # Send build error details to Telegram for debugging
        await update.message.reply_text(f"❌ Build failed (Code {e.returncode}).\nError: {e.stderr[:200]}")
    except Exception as e:
        await update.message.reply_text(f"⚠️ System Error during build: {e}")

def main():
    """Start the bot."""
    # Build the application
    app = Application.builder().token(TELEGRAM_TOKEN).build()
    
    # Add handler for text messages (URLs)
    app.add_handler(MessageHandler(filters.TEXT & (~filters.COMMAND), handle_job_link))
    
    print(f"--- Agent Active on T14 ---")
    print(f"Model: {MODEL_ID}")
    print(f"Listening for job links in Telegram...")
    
    app.run_polling()

if __name__ == "__main__":
    main()