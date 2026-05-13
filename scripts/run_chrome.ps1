# Run Naganoor Village App on Chrome with local Supabase config.
# Copy dart_defines.example.json to dart_defines.json and fill in your project values.

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$DefinesFile = Join-Path $Root "dart_defines.json"

if (-not (Test-Path $DefinesFile)) {
  Write-Error "Missing dart_defines.json. Copy dart_defines.example.json to dart_defines.json and add your Supabase values."
}

Set-Location $Root
flutter run -d chrome --dart-define-from-file=dart_defines.json
