# Kâhya — Demo Agent Harcama Gönderim Betiği (PowerShell)
# Kullanım: .\docs\demo_agent.ps1 [-BaseUrl http://localhost:3000] [-ApiKey kahya-secret-agent-key-2026]

param (
    [string]$BaseUrl = $(if ($env:BASE_URL) { $env:BASE_URL } else { "http://localhost:3000" }),
    [string]$ApiKey = $(if ($env:AGENT_API_KEY) { $env:AGENT_API_KEY } else { "kahya-secret-agent-key-2026" })
)

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Kâhya Harcama Denetim Platformu — Demo Agent Simülasyonu" -ForegroundColor Cyan
Write-Host "Hedef Sunucu: $BaseUrl" -ForegroundColor Cyan
Write-Host "============================================================"
Write-Host ""

$headers = @{
    "Content-Type" = "application/json"
    "Authorization" = "Bearer $ApiKey"
}

# Senaryo 1: Temiz ve Düşük Tutarlı Harcama (Otomatik Onay Beklenir)
Write-Host "▶ [1/3] Otomatik Onaylanabilir Harcama Gönderiliyor (Kırtasiye - 450 TL)..." -ForegroundColor Yellow
$body1 = @{
    amount_cents = 45000
    merchant = "OfisDepo Kırtasiye Ltd."
    category = "Ofis Malzemeleri"
    description = "Destek ekibi için A4 fotokopi kağıdı ve tükenmez kalem alımı"
    spent_on = (Get-Date).ToString("yyyy-MM-dd")
    submitted_by = "OfficeProcurementBot"
} | ConvertTo-Json

try {
    $res1 = Invoke-RestMethod -Uri "$BaseUrl/api/expenses" -Method Post -Headers $headers -Body $body1
    $res1 | ConvertTo-Json
} catch {
    Write-Host "Hata: $_" -ForegroundColor Red
}

Write-Host "------------------------------------------------------------"

# Senaryo 2: Gri Alan / Yönetici İncelemesi Gerektiren Harcama (Flag Beklenir)
Write-Host "▶ [2/3] Gri Alanda Kalan Harcama Gönderiliyor (İş Yemeği - 2.800 TL)..." -ForegroundColor Yellow
$body2 = @{
    amount_cents = 280000
    merchant = "Akdeniz Balıkçısı"
    category = "Temsil ve Ağırlama"
    description = "Yurt dışı iş ortağı heyeti ile cuma akşamı yemek toplantısı"
    spent_on = (Get-Date).ToString("yyyy-MM-dd")
    submitted_by = "TravelBot"
} | ConvertTo-Json

try {
    $res2 = Invoke-RestMethod -Uri "$BaseUrl/api/expenses" -Method Post -Headers $headers -Body $body2
    $res2 | ConvertTo-Json
} catch {
    Write-Host "Hata: $_" -ForegroundColor Red
}

Write-Host "------------------------------------------------------------"

# Senaryo 3: Yüksek Tutarlı Doğrudan CFO İncelemesi (5.000 TL Üzeri)
Write-Host "▶ [3/3] Yüksek Tutarlı Harcama Gönderiliyor (MacBook Donanım - 9.500 TL)..." -ForegroundColor Yellow
$body3 = @{
    amount_cents = 950000
    merchant = "Apple Store Zorlu"
    category = "Donanım"
    description = "Kıdemli yapay zekâ mühendisi için 16 inç M4 iş istasyonu alımı"
    spent_on = (Get-Date).ToString("yyyy-MM-dd")
    submitted_by = "ITAssetBot"
} | ConvertTo-Json

try {
    $res3 = Invoke-RestMethod -Uri "$BaseUrl/api/expenses" -Method Post -Headers $headers -Body $body3
    $res3 | ConvertTo-Json
} catch {
    Write-Host "Hata: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Demo Tamamlandı." -ForegroundColor Cyan
