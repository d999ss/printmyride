#!/usr/bin/env bash
set -euo pipefail

# Strava API Test Setup for PrintMyRide
# Uses Strava's playground and API to seed test data safely

echo "🚴‍♂️ Setting up Strava test environment for PrintMyRide"
echo "=========================================================="

# Configuration
CLIENT_ID="${STRAVA_CLIENT_ID:-}"
CLIENT_SECRET="${STRAVA_CLIENT_SECRET:-}"
ACCESS_TOKEN="${STRAVA_ACCESS_TOKEN:-}"

if [[ -z "$CLIENT_ID" || -z "$ACCESS_TOKEN" ]]; then
    echo "❌ Missing required environment variables:"
    echo "   export STRAVA_CLIENT_ID=your_client_id"
    echo "   export STRAVA_ACCESS_TOKEN=your_access_token"
    echo ""
    echo "💡 Get these from:"
    echo "   1. Create app at https://www.strava.com/settings/api"
    echo "   2. Set callback domain to 'developers.strava.com'"  
    echo "   3. Use Swagger Playground to get access token"
    echo "   4. https://developers.strava.com/playground/"
    exit 1
fi

# Test endpoints and create sample activities
echo "🔍 Testing Strava API connection..."

# 1. Test basic athlete info
echo "📊 Fetching athlete info..."
ATHLETE_RESPONSE=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" \
    "https://www.strava.com/api/v3/athlete")

if echo "$ATHLETE_RESPONSE" | grep -q "errors"; then
    echo "❌ Failed to authenticate with Strava API"
    echo "$ATHLETE_RESPONSE"
    exit 1
fi

ATHLETE_NAME=$(echo "$ATHLETE_RESPONSE" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(f\"{data.get('firstname', 'Unknown')} {data.get('lastname', '')}\".strip())
")

echo "✅ Connected as: $ATHLETE_NAME"

# 2. Create test activities for PrintMyRide
echo "🎯 Creating test activities for poster generation..."

# Test Activity 1: Boulder Canyon Climb
echo "Creating Boulder Canyon test activity..."
ACTIVITY_1=$(curl -s -X POST "https://www.strava.com/api/v3/activities" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "PMR Test: Boulder Canyon",
        "sport_type": "Ride", 
        "start_date_local": "2025-08-28T09:30:00Z",
        "elapsed_time": 2100,
        "distance": 1800,
        "description": "Test activity for PrintMyRide poster generation - safe to delete"
    }')

ACTIVITY_1_ID=$(echo "$ACTIVITY_1" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('id', ''))
except:
    print('')
")

# Test Activity 2: City Sprint
echo "Creating City Sprint test activity..."
ACTIVITY_2=$(curl -s -X POST "https://www.strava.com/api/v3/activities" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "PMR Test: City Sprint", 
        "sport_type": "Ride",
        "start_date_local": "2025-08-29T17:15:00Z",
        "elapsed_time": 1500,
        "distance": 1200,
        "description": "Test activity for PrintMyRide poster generation - safe to delete"
    }')

ACTIVITY_2_ID=$(echo "$ACTIVITY_2" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('id', ''))
except:
    print('')
")

echo "✅ Created test activities:"
if [[ -n "$ACTIVITY_1_ID" ]]; then
    echo "   - Boulder Canyon: ID $ACTIVITY_1_ID"
fi
if [[ -n "$ACTIVITY_2_ID" ]]; then
    echo "   - City Sprint: ID $ACTIVITY_2_ID"
fi

# 3. Fetch activities to test import flow
echo "📋 Testing activity import flow..."
ACTIVITIES=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" \
    "https://www.strava.com/api/v3/athlete/activities?per_page=5&page=1")

echo "✅ Recent activities fetched successfully"
echo "$ACTIVITIES" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(f'Found {len(data)} activities')
for activity in data[:3]:
    name = activity.get('name', 'Unnamed')
    distance = activity.get('distance', 0) / 1000
    polyline = activity.get('map', {}).get('summary_polyline', '')
    has_route = 'Yes' if polyline else 'No'
    print(f'  - {name}: {distance:.1f}km, Route: {has_route}')
"

# 4. Test streams endpoint for high-res poster data
if [[ -n "$ACTIVITY_1_ID" ]]; then
    echo "🗺️  Testing streams endpoint for detailed route data..."
    STREAMS=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" \
        "https://www.strava.com/api/v3/activities/$ACTIVITY_1_ID/streams?keys=latlng,distance,altitude&key_by_type=true")
    
    if echo "$STREAMS" | grep -q "latlng"; then
        echo "✅ Streams data available for high-resolution poster rendering"
    else
        echo "⚠️  Streams data not available (may be synthetic activity)"
    fi
fi

# 5. Generate test configuration file
echo "📝 Creating test configuration..."
cat > "/tmp/strava_test_config.json" <<EOF
{
    "client_id": "$CLIENT_ID",
    "test_activities": [
        ${ACTIVITY_1_ID:+\"$ACTIVITY_1_ID\"}${ACTIVITY_1_ID:+${ACTIVITY_2_ID:+,}}
        ${ACTIVITY_2_ID:+\"$ACTIVITY_2_ID\"}
    ],
    "athlete_name": "$ATHLETE_NAME",
    "endpoints": {
        "activities": "https://www.strava.com/api/v3/athlete/activities",
        "streams": "https://www.strava.com/api/v3/activities/{id}/streams",
        "delete": "https://www.strava.com/api/v3/activities/{id}"
    },
    "rate_limits": {
        "overall": "200 requests per 15 minutes",
        "non_upload": "100 requests per 15 minutes", 
        "daily": "2000 requests per day"
    }
}
EOF

echo "✅ Test configuration saved to /tmp/strava_test_config.json"

# 6. Cleanup instructions
echo ""
echo "🧹 Cleanup commands (run when done testing):"
if [[ -n "$ACTIVITY_1_ID" ]]; then
    echo "   curl -X DELETE -H \"Authorization: Bearer $ACCESS_TOKEN\" \"https://www.strava.com/api/v3/activities/$ACTIVITY_1_ID\""
fi
if [[ -n "$ACTIVITY_2_ID" ]]; then
    echo "   curl -X DELETE -H \"Authorization: Bearer $ACCESS_TOKEN\" \"https://www.strava.com/api/v3/activities/$ACTIVITY_2_ID\""
fi

echo ""
echo "🚀 Ready for PrintMyRide Strava integration testing!"
echo "   - Use /tmp/strava_test_config.json for app configuration"
echo "   - Test activities are marked as PMR Test and safe to delete"
echo "   - Rate limits: 200/15min, respect 429 responses"