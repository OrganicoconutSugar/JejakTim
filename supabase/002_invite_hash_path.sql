-- Applied to the JejakTim Supabase project on 2026-11-19.
-- pgcrypto's digest() lives in extensions, so the command function must
-- include that trusted schema when it hashes invitation codes.
alter function public.jt_command(text,jsonb)
  set search_path = 'pg_catalog', 'extensions';
