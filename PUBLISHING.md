# Publishing to GitHub

Use these steps from the repository root:

## 1. Review what will be committed

```bash
git status
```

## 2. Create the initial commit

```bash
git add .
git commit -m "Initial portfolio release: moneyball-like player similarity project"
```

## 3. Create a GitHub repository

Create a new empty repo on GitHub (no README, no license, no `.gitignore`) and copy the URL.

## 4. Connect local repo and push

```bash
git branch -M main
git remote add origin <your-github-repo-url>
git push -u origin main
```

## 5. Post-publish portfolio checklist

- Add the GitHub URL to your resume and LinkedIn.
- Pin the repository on your GitHub profile.
- Add a short demo section in `README.md` with screenshots or key output snippets.
- Keep a clean commit history for future updates.

