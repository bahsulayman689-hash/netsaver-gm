# NetSaver GM v2
1. Supabase: create a project -> SQL Editor -> paste and run `supabase.sql`.
2. Project Settings -> API: copy the Project URL and the *anon public* key into `config.js` (never the service_role key).
3. Deploy on Render (see below) or Netlify. Open the site on a phone, "Add to Home Screen".
4. Moderate: Supabase Table Editor -> `reports` -> tick `approved` on good reports. Only approved rows show on `dashboard.html`.
5. Content: edit `content.js` (WASSCE, rights, farming cards). Translations: edit `i18n.js` (have a native speaker review).
Bump `netsaver-v2` in `sw.js` whenever you change any file, so phones pick up the update.

## Deploy on Render (static site, free)
1. `git init && git add . && git commit -m "NetSaver GM v2"`, create a GitHub repo, then `git remote add origin <url> && git push -u origin main`.
2. Render dashboard -> New -> Blueprint -> pick the repo (it reads `render.yaml`). Or New -> Static Site: build command blank, publish directory `.`.
3. Open the `https://netsaver-gm.onrender.com` URL on a phone, then Add to Home Screen.
4. Every `git push` redeploys. Bump `netsaver-v2` in `sw.js` when files change.
