#!/bin/bash

# Supabase Function Logs Debugging Script
# Usage: ./get-function-logs.sh [execution_id]

EXECUTION_ID="${1:-5888a6d9-0e81-4c1f-bb45-8324a65eb7c6}"
FUNCTION_NAME="ai_analyze_tone"

echo "🔍 Fetching logs for $FUNCTION_NAME"
echo "Execution ID: $EXECUTION_ID"
echo "================================"
echo ""

# Try Method 1: Direct supabase CLI
if command -v supabase &> /dev/null; then
  echo "📋 Using Supabase CLI..."
  supabase functions fetch $FUNCTION_NAME --logs 2>/dev/null | grep -A 20 "$EXECUTION_ID"
else
  echo "⚠️  Supabase CLI not found. Using browser-based method:"
fi

echo ""
echo "📊 To view logs in Supabase Dashboard:"
echo "================================"
echo "1. Go to: https://supabase.com/dashboard"
echo "2. Select your project"
echo "3. Navigate to: Functions → $FUNCTION_NAME"
echo "4. Click 'Logs' tab"
echo "5. Search for execution ID: $EXECUTION_ID"
echo ""
echo "🔑 Look for these log markers:"
echo "   ✅ Success indicators:"
echo "      - '📤 Preparing JSON request'"
echo "      - '📥 Received response from OpenAI'"
echo "      - '✅ JSON parsed successfully'"
echo "      - '✅ Validation passed!'"
echo ""
echo "   ❌ Failure indicators:"
echo "      - '❌ JSON parsing failed!'"
echo "      - '❌ Invalid tone'"
echo "      - '❌ Invalid urgency level'"
echo "      - '💥 Failed to get JSON response'"
echo ""
