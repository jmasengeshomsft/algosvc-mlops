#!/bin/bash

# Test the algosvc endpoints
# Run this in a separate terminal while the service is running

echo "🧪 Testing algosvc endpoints..."
echo ""

BASE_URL="http://localhost:8080"

echo "1️⃣ Health check (ready):"
curl -s "$BASE_URL/health/ready"
echo -e "\n"

echo "2️⃣ Health check (live):"
curl -s "$BASE_URL/health/live"
echo -e "\n"

echo "3️⃣ Version info:"
curl -s "$BASE_URL/version" | python3 -m json.tool 2>/dev/null || curl -s "$BASE_URL/version"
echo -e "\n"

echo "4️⃣ Inference test (sigmoid with scale=2.0):"
curl -s -X POST "$BASE_URL/infer" \
  -H "Content-Type: application/json" \
  -d '{"x":[-2,-1,0,1,2], "scale": 2.0}' | \
  python3 -m json.tool 2>/dev/null || \
  curl -s -X POST "$BASE_URL/infer" \
    -H "Content-Type: application/json" \
    -d '{"x":[-2,-1,0,1,2], "scale": 2.0}'
echo -e "\n"

echo "5️⃣ Inference test (no scale, default=1.0):"
curl -s -X POST "$BASE_URL/infer" \
  -H "Content-Type: application/json" \
  -d '{"x":[0.5, 1.0, 1.5]}' | \
  python3 -m json.tool 2>/dev/null || \
  curl -s -X POST "$BASE_URL/infer" \
    -H "Content-Type: application/json" \
    -d '{"x":[0.5, 1.0, 1.5]}'
echo -e "\n"

echo "✅ All tests completed!"