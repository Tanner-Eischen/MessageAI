# Load RAG Showcase Conversation
# This script helps you load the conversation data into Supabase

Write-Host "====================================" -ForegroundColor Cyan
Write-Host "  RAG Showcase Conversation Loader" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

$sqlFile = "seed_rag_showcase_conversation.sql"

if (!(Test-Path $sqlFile)) {
    Write-Host "ERROR: $sqlFile not found!" -ForegroundColor Red
    Write-Host "Make sure you're in the backend directory." -ForegroundColor Yellow
    exit 1
}

Write-Host "Reading SQL file..." -ForegroundColor Green
$sqlContent = Get-Content $sqlFile -Raw

Write-Host ""
Write-Host "To load this data, you have 3 options:" -ForegroundColor Yellow
Write-Host ""
Write-Host "OPTION 1: Supabase Dashboard (Recommended)" -ForegroundColor Cyan
Write-Host "  1. Go to your Supabase project dashboard" -ForegroundColor White
Write-Host "  2. Navigate to SQL Editor" -ForegroundColor White
Write-Host "  3. Click 'New Query'" -ForegroundColor White
Write-Host "  4. Copy the contents of: backend\seed_rag_showcase_conversation.sql" -ForegroundColor White
Write-Host "  5. Paste into the SQL Editor" -ForegroundColor White
Write-Host "  6. Click 'Run'" -ForegroundColor White
Write-Host ""
Write-Host "OPTION 2: Copy SQL to Clipboard" -ForegroundColor Cyan
$response = Read-Host "Would you like to copy the SQL to your clipboard? (y/n)"
if ($response -eq 'y' -or $response -eq 'Y') {
    $sqlContent | Set-Clipboard
    Write-Host "✓ SQL copied to clipboard!" -ForegroundColor Green
    Write-Host "  Now paste it into Supabase SQL Editor and run it." -ForegroundColor White
}
Write-Host ""
Write-Host "OPTION 3: Use psql (if you have connection string)" -ForegroundColor Cyan
Write-Host "  psql 'your-connection-string' -f seed_rag_showcase_conversation.sql" -ForegroundColor Gray
Write-Host ""
Write-Host "File contains:" -ForegroundColor Yellow
Write-Host "  - 1 new user profile (Sarah Chen)" -ForegroundColor White
Write-Host "  - 1 conversation" -ForegroundColor White
Write-Host "  - 41 messages (6 weeks of conversation)" -ForegroundColor White
Write-Host "  - Read receipts for both users" -ForegroundColor White
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

