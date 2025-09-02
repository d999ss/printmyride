#!/usr/bin/env bash
set -euo pipefail

# Strava API Demo - Copy-paste curl commands for PrintMyRide testing
# Run this after getting your access token from Strava Playground

echo "🚴‍♂️ Strava API Demo for PrintMyRide"
echo "===================================="

# Check for required environment variables
ACCESS_TOKEN="${STRAVA_ACCESS_TOKEN:-}"
if [[ -z "$ACCESS_TOKEN" ]]; then
    echo "❌ Set STRAVA_ACCESS_TOKEN environment variable first"
    echo ""
    echo "Get your token from Strava Playground:"
    echo "https://developers.strava.com/playground/"
    echo ""
    echo "Then run:"
    echo "export STRAVA_ACCESS_TOKEN='your_token_here'"
    echo "./scripts/strava_api_demo.sh"
    exit 1
fi

echo "🔑 Using access token: ${ACCESS_TOKEN:0:12}..."
echo ""

# 1. Test athlete endpoint
echo "📊 1. Fetching authenticated athlete info..."
echo "curl -H \"Authorization: Bearer \$TOKEN\" \\"
echo "  \"https://www.strava.com/api/v3/athlete\""
echo ""

ATHLETE=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" \
    "https://www.strava.com/api/v3/athlete")

if echo "$ATHLETE" | grep -q "errors"; then
    echo "❌ Authentication failed:"
    echo "$ATHLETE" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for error in data.get('errors', []):
        print(f'  - {error.get(\"field\", \"general\")}: {error.get(\"code\", \"unknown\")}')
except:
    print('  - Invalid response format')
"
    exit 1
fi

echo "✅ Connected successfully!"
echo "$ATHLETE" | python3 -c "
import sys, json
data = json.load(sys.stdin)
name = f\"{data.get('firstname', 'Unknown')} {data.get('lastname', '')}\".strip()
print(f'   Athlete: {name}')
print(f'   ID: {data.get(\"id\", \"N/A\")}')
print(f'   Country: {data.get(\"country\", \"N/A\")}')
"
echo ""

# 2. List recent activities
echo "📋 2. Fetching recent activities (last 5)..."
echo "curl -H \"Authorization: Bearer \$TOKEN\" \\"
echo "  \"https://www.strava.com/api/v3/athlete/activities?per_page=5\""
echo ""

ACTIVITIES=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" \
    "https://www.strava.com/api/v3/athlete/activities?per_page=5")

echo "✅ Recent activities:"
echo "$ACTIVITIES" | python3 -c "
import sys, json
data = json.load(sys.stdin)
if not data:
    print('   No activities found')
else:
    for i, activity in enumerate(data[:5]):
        name = activity.get('name', 'Unnamed')
        distance = activity.get('distance', 0) / 1000
        activity_type = activity.get('sport_type', 'Unknown')
        polyline = activity.get('map', {}).get('summary_polyline', '')
        has_route = '✅' if polyline else '❌'
        print(f'   {i+1}. {name} ({activity_type})')
        print(f'      Distance: {distance:.1f}km, Route data: {has_route}')
        print(f'      ID: {activity.get(\"id\", \"N/A\")}')
"
echo ""

# 3. Get first activity with route data for testing
FIRST_ACTIVITY_WITH_ROUTE=$(echo "$ACTIVITIES" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for activity in data:
    polyline = activity.get('map', {}).get('summary_polyline', '')
    if polyline:
        print(activity.get('id', ''))
        break
")

if [[ -n "$FIRST_ACTIVITY_WITH_ROUTE" ]]; then
    echo "🗺️  3. Testing streams endpoint for detailed route data..."
    echo "curl -H \"Authorization: Bearer \$TOKEN\" \\"
    echo "  \"https://www.strava.com/api/v3/activities/$FIRST_ACTIVITY_WITH_ROUTE/streams?keys=latlng&key_by_type=true\""
    echo ""
    
    STREAMS=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" \
        "https://www.strava.com/api/v3/activities/$FIRST_ACTIVITY_WITH_ROUTE/streams?keys=latlng&key_by_type=true")
    
    if echo "$STREAMS" | grep -q "latlng"; then
        echo "✅ Streams data available!"
        echo "$STREAMS" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    latlng_data = data.get('latlng', {}).get('data', [])
    print(f'   Coordinates: {len(latlng_data)} points')
    if latlng_data:
        first = latlng_data[0]
        last = latlng_data[-1]
        print(f'   Start: {first[0]:.4f}, {first[1]:.4f}')
        print(f'   End: {last[0]:.4f}, {last[1]:.4f}')
except:
    print('   Could not parse streams data')
"
    else
        echo "⚠️  Streams not available (may be synthetic activity)"
    fi
    echo ""
else
    echo "⚠️  No activities with route data found for streams test"
    echo ""
fi

# 4. Demonstrate polyline decoding
echo "🔍 4. Testing polyline decoding for PrintMyRide poster generation..."
SAMPLE_POLYLINE=$(echo "$ACTIVITIES" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for activity in data:
    polyline = activity.get('map', {}).get('summary_polyline', '')
    if polyline:
        print(polyline[:100] + '...' if len(polyline) > 100 else polyline)
        break
")

if [[ -n "$SAMPLE_POLYLINE" ]]; then
    echo "Sample polyline: $SAMPLE_POLYLINE"
    echo "✅ This polyline can be decoded to CLLocationCoordinate2D array for poster rendering"
else
    echo "⚠️  No polyline data available in recent activities"
fi
echo ""

# 5. Rate limiting info
echo "⏱️  5. Rate limiting information:"
echo "   Overall: 200 requests per 15 minutes"
echo "   Non-upload: 100 requests per 15 minutes"
echo "   Daily: 2000 requests per day"
echo "   Handle 429 responses with Retry-After header"
echo ""

# 6. Cleanup commands template
echo "🧹 6. Cleanup test activities (when needed):"
echo "# Delete a specific activity:"
echo "curl -X DELETE -H \"Authorization: Bearer \$TOKEN\" \\"
echo "  \"https://www.strava.com/api/v3/activities/ACTIVITY_ID\""
echo ""

echo "✅ Strava API demo complete!"
echo ""
echo "Next steps for PrintMyRide integration:"
echo "1. Use StravaIntegrationTests.swift for automated testing"
echo "2. Implement OAuth PKCE flow in your app"
echo "3. Use polyline decoding for poster coordinate data"
echo "4. Respect rate limits and handle 429 responses"
echo "5. Test end-to-end: Strava → coordinates → poster generation"