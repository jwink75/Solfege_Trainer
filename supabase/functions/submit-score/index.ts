import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.21.0"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

serve(async (req) => {
  // Handle CORS preflight request
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    if (req.method !== 'POST') {
      return new Response(JSON.stringify({ error: "Method not allowed" }), {
        status: 405,
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      })
    }

    const { profile_cloud_id, display_name, board_id, score, app_version } = await req.json()

    // 1. Basic validation
    if (!profile_cloud_id || !display_name || !board_id || typeof score !== 'number' || !app_version) {
      return new Response(JSON.stringify({ error: "Missing or invalid parameters" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      })
    }

    // Validate score theoretical max for specific boards
    let maxPossible = 0
    if (board_id === 'checkpoint_1') {
      maxPossible = 300 // Checkpoint 1 (10.9): 10 questions * 3 notes * 10 pts
    } else if (board_id === 'checkpoint_2') {
      maxPossible = 500 // Checkpoint 2 (19.9): 10 questions * 5 notes * 10 pts
    } else {
      return new Response(JSON.stringify({ error: `Invalid board_id: ${board_id}` }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      })
    }

    if (score < 0 || score > maxPossible) {
      return new Response(JSON.stringify({ error: `Score ${score} is out of bounds for board ${board_id} (max: ${maxPossible})` }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      })
    }

    // 2. Initialize Supabase client with SERVICE_ROLE key to bypass RLS for writes
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ""
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ""
    
    if (!supabaseUrl || !supabaseServiceKey) {
      return new Response(JSON.stringify({ error: "Server configuration error" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      })
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // 3. Query existing score to see if this is a new high score
    const { data: existing, error: fetchError } = await supabase
      .from('leaderboard_scores')
      .select('score')
      .eq('profile_cloud_id', profile_cloud_id)
      .eq('board_id', board_id)
      .maybeSingle()

    if (fetchError) {
      console.error("Fetch existing score error:", fetchError)
      return new Response(JSON.stringify({ error: "Database error fetching existing score" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      })
    }

    let isNewHigh = false
    if (!existing || score > existing.score) {
      isNewHigh = true
      // Upsert the score
      const { error: upsertError } = await supabase
        .from('leaderboard_scores')
        .upsert({
          profile_cloud_id,
          display_name,
          board_id,
          score,
          achieved_at: new Date().toISOString(),
          app_version
        })

      if (upsertError) {
        console.error("Upsert score error:", upsertError)
        return new Response(JSON.stringify({ error: "Database error saving score" }), {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" }
        })
      }
    }

    return new Response(JSON.stringify({ success: true, isNewHigh, currentHighScore: isNewHigh ? score : existing.score }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" }
    })

  } catch (err) {
    console.error("Unexpected error:", err)
    return new Response(JSON.stringify({ error: err.message || "Internal server error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" }
    })
  }
})
