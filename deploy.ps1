# Builds the Flutter web app into public/ and deploys app + API to Vercel.
#   .\deploy.ps1           production deploy
#   .\deploy.ps1 -Preview  preview deploy
# Vercel's build machines have no Flutter, so the web build happens here.
param([switch]$Preview)
# Native tools print progress on stderr; rely on exit codes, not 'Stop'.
$ErrorActionPreference = 'Continue'
$root = $PSScriptRoot
$env:Path = "$HOME\dev\node;$HOME\dev\flutter\bin;C:\Program Files\Git\cmd;$env:Path"

Push-Location "$root\app"
try {
  flutter build web --release --no-wasm-dry-run
  if ($LASTEXITCODE) { throw 'flutter build failed' }
} finally { Pop-Location }

Remove-Item -Recurse -Force "$root\public" -ErrorAction SilentlyContinue
Copy-Item -Recurse "$root\app\build\web" "$root\public"

Push-Location $root
try {
  if ($Preview) { npx --yes vercel@latest deploy --yes }
  else { npx --yes vercel@latest deploy --prod --yes }
} finally { Pop-Location }
