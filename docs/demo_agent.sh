#!/usr/bin/env bash
# Kâhya — Demo Agent Harcama Gönderim Betiği
# Kullanım: ./docs/demo_agent.sh [BASE_URL] [API_KEY]
# Örnek yerel: ./docs/demo_agent.sh http://localhost:3000 kahya-secret-agent-key-2026
# Örnek canlı: ./docs/demo_agent.sh https://tempodesk.onrender.com $AGENT_API_KEY

set -e

BASE_URL="${1:-${BASE_URL:-http://localhost:3000}}"
API_KEY="${2:-${AGENT_API_KEY:-kahya-secret-agent-key-2026}}"

echo "============================================================"
echo "Kahya Harcama Denetim Platformu — Demo Agent Simulasyonu"
echo "Hedef Sunucu: $BASE_URL"
echo "============================================================"
echo ""

# Senaryo 1: Temiz ve Düşük Tutarlı Harcama (Otomatik Onay Beklenir)
echo "▶ [1/3] Otomatik Onaylanabilir Harcama Gonderiliyor (Kirtasiye - 450 TL)..."
curl -s -X POST "$BASE_URL/api/expenses" \
  -H "Content-Type: application/json; charset=utf-8" \
  -H "Authorization: Bearer $API_KEY" \
  -d '{
    "amount_cents": 45000,
    "merchant": "OfisDepo Kirtasiye Ltd.",
    "category": "Ofis Malzemeleri",
    "description": "Destek ekibi icin A4 fotokopi kagidi ve tukenmez kalem alimi",
    "spent_on": "2026-10-24",
    "submitted_by": "OfficeProcurementBot"
  }'
echo ""
echo "------------------------------------------------------------"

# Senaryo 2: Gri Alan / Yönetici İncelemesi Gerektiren Harcama (Flag Beklenir)
echo "▶ [2/3] Gri Alanda Kalan Harcama Gonderiliyor (Is Yemegi - 2.800 TL)..."
curl -s -X POST "$BASE_URL/api/expenses" \
  -H "Content-Type: application/json; charset=utf-8" \
  -H "Authorization: Bearer $API_KEY" \
  -d '{
    "amount_cents": 280000,
    "merchant": "Akdeniz Balikcisi",
    "category": "Temsil ve Agirlama",
    "description": "Yurt disi is ortagi heyeti ile cuma aksami yemek toplantisi",
    "spent_on": "2026-10-23",
    "submitted_by": "TravelBot"
  }'
echo ""
echo "------------------------------------------------------------"

# Senaryo 3: Yüksek Tutarlı Doğrudan CFO İncelemesi (5.000 TL Üzeri)
echo "▶ [3/3] Yuksek Tutarli Harcama Gonderiliyor (MacBook Donanim - 9.500 TL)..."
curl -s -X POST "$BASE_URL/api/expenses" \
  -H "Content-Type: application/json; charset=utf-8" \
  -H "Authorization: Bearer $API_KEY" \
  -d '{
    "amount_cents": 950000,
    "merchant": "Apple Store Zorlu",
    "category": "Donanim",
    "description": "Kidemli yapay zeka muhendisi icin 16 inc M4 is istasyonu alimi",
    "spent_on": "2026-10-24",
    "submitted_by": "ITAssetBot"
  }'
echo ""
echo "============================================================"
echo "Demo Tamamlandi."
