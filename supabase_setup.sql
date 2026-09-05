-- supabase_setup.sql
-- Run this in your Supabase SQL Editor to set up the leaderboard table, security, and ranking RPC.

-- 1. Create the leaderboard scores table
CREATE TABLE IF NOT EXISTS public.leaderboard_scores (
  profile_cloud_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  display_name TEXT NOT NULL,
  board_id TEXT NOT NULL,
  score INTEGER NOT NULL,
  achieved_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  app_version TEXT NOT NULL,
  
  -- Ensures one high score per user per challenge board
  PRIMARY KEY (profile_cloud_id, board_id)
);

-- 2. Enable Row Level Security (RLS)
ALTER TABLE public.leaderboard_scores ENABLE ROW LEVEL SECURITY;

-- 3. Policy to allow public read-only access (anyone can fetch scores)
CREATE POLICY "Allow public read access" ON public.leaderboard_scores
  FOR SELECT USING (true);

-- Note: Because no INSERT/UPDATE/DELETE policies are defined, direct writes using 
-- the anon/authenticated key will fail. Writes are restricted to the service-role client
-- used inside the Edge Function.

-- 4. Database RPC function to retrieve the user's rank and score on a board.
-- We use explicit $body$ tags and subquery aliases to prevent parser truncation 
-- and column parameter conflicts.
CREATE OR REPLACE FUNCTION public.get_user_rank(
  p_board_id TEXT,
  p_profile_cloud_id UUID
)
RETURNS TABLE (
  rank BIGINT,
  score INTEGER
)
LANGUAGE sql
SECURITY DEFINER
AS $body$
  SELECT sub.r, sub.s
  FROM (
    SELECT 
      profile_cloud_id,
      score as s,
      RANK() OVER (ORDER BY score DESC, achieved_at ASC) as r
    FROM public.leaderboard_scores
    WHERE board_id = p_board_id
  ) sub
  WHERE sub.profile_cloud_id = p_profile_cloud_id;
$body$;
