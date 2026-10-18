# Strength Tracker

Mobile-first workout log for GitHub Pages, with Supabase Auth and Postgres cloud storage. Each set is stored as an independent record.

## Setup

1. Create a new public GitHub repository named `strength-tracker` and publish only `index.html`, `app.js`, `config.js`, `manifest.webmanifest`, `database.sql`, `README.md`, and `.gitignore` at its root. Never upload `private-backups/`.
2. Create a Supabase project at https://supabase.com/dashboard.
3. Run `database.sql` in Supabase SQL Editor.
4. In Supabase Auth > Providers, enable Email sign-in (magic links / OTP). In Auth > URL Configuration, set Site URL and allowed Redirect URLs to your GitHub Pages URL (`https://YOUR_USERNAME.github.io/strength-tracker/`).
5. Fill `config.js` with your project's URL and **publishable/anon** key from Supabase Project Settings. Never use a service-role/secret key in frontend code.
6. GitHub repo Settings > Pages > Deploy from branch > main > / (root). Wait for deployment.
7. Open the GitHub Pages URL on your iPhone, sign in, then Safari Share > Add to Home Screen.

## Import your first workout

The October 13, 2026 session is preserved locally in `private-backups/first-workout.json`, which is excluded from Git. In the Log tab, choose that file using **Import a single-workout JSON backup**, review it, sign in, and click **Save workout to cloud**. Importing only fills the editor; it does not save automatically. Import it once to avoid duplicate sessions. Use **New workout** for subsequent sessions.

## Notes

- Public hosting does not make workouts public: row-level security restricts database rows to the signed-in user.
- Public app files contain no initial workout notes. Keep `private-backups/` local; `.gitignore` protects Git uploads, but manual uploads must exclude it too.
- The initial app provides cloud save, reopen/edit, history, progress summaries and JSON export. It does not yet have offline sync, multi-device conflict handling, or automatic background import.
- A saved workout is editable. Saving replaces its sets in a database transaction; any failure rolls back the entire save. Existing databases must run the `save_workout` function and its revoke/grant statements at the end of `database.sql` before using this version.
