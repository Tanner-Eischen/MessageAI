import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.0";
import { detectBoundaryViolations, generateBoundaryAnalysisPrompt, BOUNDARY_ANALYSIS_SYSTEM_PROMPT, validateBoundaryAnalysis, type ViolationType, type Severity } from "../_shared/prompts/boundary-analysis.ts";
import { createOpenAIClient } from "../_shared/openai-client.ts";

interface ViolationDetectionRequest {
  messageId: string;
  messageBody: string;
  senderId: string;
  messageTimestamp: number; // Unix timestamp in seconds
}

interface BoundaryViolation {
  type: string;
  severity: string;
  explanation: string;
  evidence: string[];
  suggestedGentle: string;
  suggestedModerate: string;
  suggestedFirm: string;
}

interface ViolationResponse {
  success: boolean;
  violations: BoundaryViolation[];
  violationCount: number;
  senderViolationHistory: number; // Total violations from this sender in 30 days
  isRepeatOffender: boolean;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const body = (await req.json()) as ViolationDetectionRequest;
    const userId = req.headers.get("x-user-id");

    if (!userId) {
      return new Response("Unauthorized - User ID required", { status: 401 });
    }

    // Validate request
    if (!body.messageId || !body.messageBody || !body.senderId || !body.messageTimestamp) {
      return new Response("Missing required fields", { status: 400 });
    }

    console.log(`🔍 Detecting boundary violations in message from ${body.senderId}`);

    // Query sender's violation history (last 30 days)
    const thirtyDaysAgo = Math.floor(Date.now() / 1000) - 30 * 24 * 60 * 60;

    const { data: violationHistory, error: historyError } = await supabase
      .from("boundary_violations")
      .select("id, violation_type")
      .eq("sender_id", body.senderId)
      .eq("user_id", userId)
      .gte("message_timestamp", thirtyDaysAgo);

    if (historyError) {
      console.error("Error querying violation history:", historyError);
      // Continue even if we can't get history - detection should still work
    }

    const senderViolationCount = (violationHistory || []).length;
    const isRepeatOffender = senderViolationCount >= 3;

    // Step 1: Rule-based detection (fast, catches obvious patterns)
    let violations = detectBoundaryViolations(
      body.messageBody,
      body.messageTimestamp,
      senderViolationCount
    );

    console.log(`📋 Rule-based detection found ${violations.length} violations`);

    // Step 2: If no violations found, use AI detection (catches nuanced violations)
    if (violations.length === 0) {
      try {
        console.log('🤖 Running AI-based boundary detection...');
        console.log(`📝 Message to analyze: "${body.messageBody}"`);
        const openai = createOpenAIClient();
        
        const userPrompt = generateBoundaryAnalysisPrompt(
          body.messageBody,
          senderViolationCount
        );
        
        console.log('📤 Sending to OpenAI...');

        const aiResult = await openai.sendMessageForJSON(
          userPrompt,
          BOUNDARY_ANALYSIS_SYSTEM_PROMPT
        );

        console.log('📥 Raw AI result:', JSON.stringify(aiResult, null, 2));

        // Handle the format OpenAI actually returns (violations array)
        if (aiResult.violations && Array.isArray(aiResult.violations) && aiResult.violations.length > 0) {
          console.log(`🤖 AI detected ${aiResult.violations.length} violation(s)!`);
          
          // Add each violation from the AI response
          for (const violation of aiResult.violations) {
            violations.push({
              type: violation.type as ViolationType,
              severity: violation.severity as Severity,
              explanation: violation.explanation,
              evidence: violation.evidence || ['AI-detected pattern'],
              suggestedGentle: violation.suggested_gentle || violation.suggestedGentle || 'I appreciate you reaching out, but I need to maintain my boundaries here.',
              suggestedModerate: violation.suggested_moderate || violation.suggestedModerate || 'I need to be clear about my boundaries. This doesn\'t work for me.',
              suggestedFirm: violation.suggested_firm || violation.suggestedFirm || 'This crosses my boundaries. I need you to respect my limits.',
            });
            
            console.log(`✅ Added violation: type=${violation.type}, severity=${violation.severity}`);
            console.log(`📋 Explanation: ${violation.explanation}`);
          }
        } else {
          console.log('🤖 AI detected no violations');
        }
      } catch (aiError) {
        console.error('❌ AI boundary detection failed:', aiError);
        console.error('Error details:', aiError instanceof Error ? aiError.message : String(aiError));
        console.error('Stack:', aiError instanceof Error ? aiError.stack : 'No stack trace');
        // Continue with rule-based results only
      }
    }

    console.log(`✅ Total violations detected: ${violations.length}`);

    // Save violations to database
    if (violations.length > 0) {
      console.log(`💾 Saving ${violations.length} violation(s) to database...`);
      
      const violationsToInsert = violations.map((v) => ({
        message_id: body.messageId,
        sender_id: body.senderId,
        user_id: userId,
        violation_type: v.type,
        severity: v.severity,
        explanation: v.explanation,
        evidence: v.evidence,
        is_after_hours: v.type === "after_hours_pressure",
        suggested_gentle: v.suggestedGentle,
        suggested_moderate: v.suggestedModerate,
        suggested_firm: v.suggestedFirm,
        message_timestamp: body.messageTimestamp,
      }));

      console.log('📝 First violation to insert:', JSON.stringify(violationsToInsert[0], null, 2));

      const { data: insertedData, error: insertError } = await supabase
        .from("boundary_violations")
        .insert(violationsToInsert)
        .select();

      if (insertError) {
        console.error("❌ Error saving violations:", insertError);
        console.error("   Error code:", insertError.code);
        console.error("   Error message:", insertError.message);
        console.error("   Error details:", insertError.details);
        // Don't fail - still return the detections
      } else {
        console.log(`✅ Successfully saved ${insertedData?.length || 0} violation(s) to database`);
        if (insertedData && insertedData.length > 0) {
          console.log('   First saved violation ID:', insertedData[0].id);
        }
      }
    }

    // Update or create violation pattern for this sender
    if (violations.length > 0) {
      const violationType = violations[0].type;

      const { data: existingPattern } = await supabase
        .from("boundary_violation_patterns")
        .select("occurrence_count, severity_trend")
        .eq("user_id", userId)
        .eq("sender_id", body.senderId)
        .eq("violation_type", violationType)
        .maybeSingle();

      if (existingPattern) {
        // Update existing pattern
        await supabase
          .from("boundary_violation_patterns")
          .update({
            occurrence_count: (existingPattern.occurrence_count || 0) + 1,
            last_violation_timestamp: body.messageTimestamp,
            is_repeat_offender: senderViolationCount >= 3,
            updated_at: new Date().toISOString(),
          })
          .eq("user_id", userId)
          .eq("sender_id", body.senderId)
          .eq("violation_type", violationType);
      } else {
        // Create new pattern
        await supabase
          .from("boundary_violation_patterns")
          .insert([
            {
              user_id: userId,
              sender_id: body.senderId,
              violation_type: violationType,
              occurrence_count: 1,
              last_violation_timestamp: body.messageTimestamp,
              is_repeat_offender: false,
              severity_trend: "initial",
            },
          ]);
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        violations: violations,
        violationCount: violations.length,
        senderViolationHistory: senderViolationCount,
        isRepeatOffender: isRepeatOffender,
      }),
      {
        status: 200,
        headers: { "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("❌ Error in detect-boundary-violations:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
