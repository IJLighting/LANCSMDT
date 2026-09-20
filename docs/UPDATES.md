# LANCSMDT release/update process

Control v4.9+ checks `https://raw.githubusercontent.com/IJLighting/LANCSMDT/main/update-manifest.json`.

For each future version:
1. Build and test the Windows ZIP.
2. Publish it as a GitHub Release asset named `MDTPlatform-Windows.zip`.
3. Calculate its SHA-256.
4. Update `update-manifest.json` with the new version, release asset URL and SHA-256.
5. Commit the manifest only after the release asset is live.

The updater downloads the package on the MDT server, verifies SHA-256, stages it, backs up the current program, preserves `backend/data` and local `.env`, restarts, checks `/api/health`, and rolls back if startup fails.

Do not put Control passwords, registration keys, tokens, state.json, or other local secrets in this repository.
