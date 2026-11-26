begin;

-- Remove the unused PL/pgSQL variable that conflicts with the submission alias.
-- Keep the deployed function's other branches, permissions and search path.
do $$
declare
  original text := pg_get_functiondef('public.jt_command(text,jsonb)'::regprocedure);
  patched text := replace(original, 't jsonb; s jsonb;', 't jsonb;');
begin
  if original <> patched then
    execute patched;
  elsif original ~ '[[:space:]]s[[:space:]]+jsonb[[:space:]]*;' then
    raise exception 'Definisi jt_command berbeda. Periksa deklarasi variabel review.';
  end if;
end $$;

alter table public.jt_projects drop constraint jt_project_avatar_valid;
alter table public.jt_projects add constraint jt_project_avatar_valid check (
  not (data ? 'avatar') or coalesce(
    length(data->>'avatar') <= 180000 and
    (data->>'avatar' in (
      'folder', 'sprout', 'sparkles', 'rocket', 'design', 'code',
      'research', 'book', 'target', 'idea', 'team', 'event'
    ) or data->>'avatar' ~ '^data:image/(jpeg|png|webp);base64,[A-Za-z0-9+/]+={0,2}$'),
    false
  )
);

commit;
