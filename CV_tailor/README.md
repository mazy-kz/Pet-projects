# CV Tailor

Small Telegram bot that:

- takes a job link
- scrapes the job description
- asks Gemini to tailor your LaTeX CV
- compiles a fresh PDF and sends it back

It keeps the resume structure in LaTeX, but updates the `Skills` section and the `Work Experience` bullet points so they match the target role better.

## What is inside

- `telegram_cv_bot.py` - the bot
- `main.tex` - single-file resume template
- `build_cv.ps1` - local build script for Windows + MiKTeX

Generated files go into `output/<company_slug>/`.

## Before you run it

You need:

- Python 3.10+
- `pdflatex` available in your terminal
- a Telegram bot token
- a Gemini API key

Install dependencies:

```bash
pip install -r requirements.txt
playwright install chromium
```

## Env vars

Copy `.env.example` or just set these yourself:

```bash
TELEGRAM_TOKEN=your_telegram_bot_token
GEMINI_API_KEY=your_gemini_api_key
GEMINI_MODEL=gemini-3-flash-preview
```

## Run

```bash
python telegram_cv_bot.py
```

Then send the bot a job post URL in Telegram.

## Build the CV manually

If you want to compile `main.tex` yourself on Windows, use:

```powershell
.\build_cv.ps1
```

The script prefers the fresh MiKTeX install in `%LOCALAPPDATA%\Programs\MiKTeX\...` so it does not accidentally use an older TeX install that is first on `PATH`.

## Notes

- Replace `main.tex` with your real CV template if the sample one is just placeholder content.
- The bot only rewrites skills and work-experience bullets.
- The prompt now tries to keep each rewritten job believable for the actual title and consistent with the rest of the CV.
- If you edit `main.tex` by hand, remember to escape special characters in text: `\%`, `\&`, `\_`, `\#`.

## If PDF build breaks on Windows

This project uses a simpler single-file LaTeX template with fewer moving parts, so template-side compile issues should be much less common.

If MiKTeX still fails before it even gets to your content, it is usually a local TeX-install problem, not a `main.tex` problem. This project now tries to avoid that by compiling through `build_cv.ps1` and preferring the fresh MiKTeX install under your local user profile.

If MiKTeX is still broken globally, a typical fix is to open an elevated terminal once and run:

```powershell
miktex --admin fndb refresh
miktex --admin fontmaps configure
miktex --admin formats build pdflatex
```

Then try:

```powershell
pdflatex -interaction=nonstopmode -halt-on-error main.tex
```
