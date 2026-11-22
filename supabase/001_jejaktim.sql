-- JejakTim server-owned collaboration state. Run once in Supabase SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.jt_profiles (
  uid uuid primary key references auth.users(id) on delete cascade,
  data jsonb not null
);
create table if not exists public.jt_projects (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id),
  data jsonb not null
);
create table if not exists public.jt_members (
  project_id uuid not null references public.jt_projects(id) on delete cascade,
  uid uuid not null references auth.users(id) on delete cascade,
  primary key (project_id, uid)
);
create table if not exists public.jt_tasks (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.jt_projects(id) on delete cascade,
  data jsonb not null
);
create table if not exists public.jt_invites (
  code_hash text primary key,
  project_id uuid not null references public.jt_projects(id) on delete cascade,
  expires_at timestamptz not null,
  active boolean not null default true
);
create table if not exists public.jt_reports (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.jt_projects(id) on delete cascade,
  data jsonb not null
);
create table if not exists public.jt_events (
  id bigint generated always as identity primary key,
  project_id uuid not null references public.jt_projects(id) on delete cascade,
  data jsonb not null,
  created_at timestamptz not null default now()
);

alter table public.jt_profiles enable row level security;
alter table public.jt_projects enable row level security;
alter table public.jt_members enable row level security;
alter table public.jt_tasks enable row level security;
alter table public.jt_invites enable row level security;
alter table public.jt_reports enable row level security;
alter table public.jt_events enable row level security;

revoke all on public.jt_profiles, public.jt_projects, public.jt_members,
  public.jt_tasks, public.jt_invites, public.jt_reports, public.jt_events
  from anon, authenticated;
grant select on public.jt_events to authenticated;
create or replace function public.jt_is_member(project uuid)
returns boolean language sql security definer stable set search_path = '' as $$
  select exists (select 1 from public.jt_members
    where project_id = project and uid = (select auth.uid()));
$$;
create policy "members receive their project events" on public.jt_events
for select to authenticated using (
  public.jt_is_member(project_id)
);

create or replace function public.jt_workspace()
returns jsonb language plpgsql security definer set search_path = '' as $$
declare u uuid := auth.uid(); result jsonb;
begin
  if u is null then raise exception 'Masuk terlebih dahulu.'; end if;
  select jsonb_build_object(
    'profile', coalesce((select data from public.jt_profiles where uid = u), '{}'::jsonb),
    'profiles', coalesce((select jsonb_agg(distinct p.data) from public.jt_profiles p
      where p.uid = u or exists (
        select 1 from public.jt_members a join public.jt_members b using (project_id)
        where a.uid = u and b.uid = p.uid)), '[]'::jsonb),
    'projects', coalesce((select jsonb_agg(j.data || jsonb_build_object('id', j.id::text,
      'memberIds', (select coalesce(jsonb_agg(m.uid::text), '[]'::jsonb)
                   from public.jt_members m where m.project_id = j.id)))
      from public.jt_projects j join public.jt_members mine on mine.project_id = j.id
      where mine.uid = u), '[]'::jsonb),
    'tasks', coalesce((select jsonb_agg(t.data || jsonb_build_object('id', t.id::text,
      'projectId', t.project_id::text)) from public.jt_tasks t
      join public.jt_members mine on mine.project_id = t.project_id where mine.uid = u), '[]'::jsonb),
    'activity', coalesce((select jsonb_agg(e.data || jsonb_build_object('id', e.id::text,
      'projectId', e.project_id::text)) from public.jt_events e
      join public.jt_members mine on mine.project_id = e.project_id where mine.uid = u), '[]'::jsonb),
    'reports', coalesce((select jsonb_agg(r.data || jsonb_build_object('id', r.id::text))
      from public.jt_reports r join public.jt_members mine on mine.project_id = r.project_id
      where mine.uid = u), '[]'::jsonb)
  ) into result;
  return result;
end $$;

create or replace function public.jt_command(action_name text, input_data jsonb default '{}'::jsonb)
returns jsonb language plpgsql security definer set search_path = 'pg_catalog', 'extensions' as $$
declare
  u uuid := auth.uid(); pid uuid; tid uuid; rid uuid; p jsonb; t jsonb; s jsonb;
  result jsonb; code text; stamp text := to_char(clock_timestamp() at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"');
  member_ids jsonb; assignees jsonb; reviewer uuid; ver integer; decision text;
begin
  if u is null then raise exception 'Masuk terlebih dahulu.'; end if;
  if action_name = 'syncProfile' then
    insert into public.jt_profiles(uid, data) values (u, jsonb_build_object(
      'uid', u::text, 'name', coalesce(nullif(trim(input_data->>'name'), ''), 'Mahasiswa'),
      'email', coalesce((select email from auth.users where id = u), ''),
      'institution', '', 'major', '', 'notificationPrefs', jsonb_build_object('inApp', true, 'push', false)))
      on conflict (uid) do nothing;
    return jsonb_build_object('ok', true);
  end if;
  if action_name = 'saveProfile' then
    update public.jt_profiles set data = data || (input_data - 'requestId' - 'uid' - 'email' - 'createdAt')
      where uid = u returning data into result;
    return result;
  end if;
  if action_name = 'createProject' then
    if length(trim(coalesce(input_data->>'name', ''))) < 3 then raise exception 'Nama proyek minimal 3 karakter.'; end if;
    pid := gen_random_uuid();
    p := (input_data - 'requestId') || jsonb_build_object('id', pid::text, 'ownerId', u::text,
      'status', 'active', 'createdAt', stamp, 'memberIds', jsonb_build_array(u::text));
    insert into public.jt_projects(id, owner_id, data) values (pid, u, p - 'memberIds');
    insert into public.jt_members values (pid, u);
    insert into public.jt_events(project_id, data) values (pid, jsonb_build_object('actorId', u::text,
      'summary', 'Membuat proyek', 'createdAt', stamp));
    return p;
  end if;
  if action_name in ('previewInvite', 'joinProject') then
    code := upper(trim(coalesce(input_data->>'code', '')));
    select project_id into pid from public.jt_invites
      where code_hash = encode(digest(code, 'sha256'), 'hex') and active and expires_at > now();
    if pid is null then raise exception 'Kode tidak cocok atau kedaluwarsa.'; end if;
    select data into p from public.jt_projects where id = pid for update;
    if p->>'status' <> 'active' then raise exception 'Proyek sudah ditutup.'; end if;
    if action_name = 'joinProject' then
      if (select count(*) from public.jt_members where project_id = pid) >= 30 then
        raise exception 'Proyek penuh.';
      end if;
      insert into public.jt_members values (pid, u) on conflict do nothing;
      insert into public.jt_events(project_id, data) values (pid, jsonb_build_object('actorId', u::text,
        'summary', 'Bergabung ke proyek', 'createdAt', stamp));
    end if;
    return jsonb_build_object('id', pid::text, 'name', p->>'name',
      'description', p->>'description',
      'ownerName', (select data->>'name' from public.jt_profiles where uid = (p->>'ownerId')::uuid),
      'memberCount', (select count(*) from public.jt_members where project_id = pid));
  end if;

  pid := nullif(input_data->>'projectId', '')::uuid;
  if pid is null or not exists(select 1 from public.jt_members where project_id = pid and uid = u) then
    raise exception 'Akses proyek tidak tersedia.';
  end if;
  select data into p from public.jt_projects where id = pid for update;
  if p is null then raise exception 'Proyek tidak ditemukan.'; end if;
  if action_name in ('createInvite', 'saveProject', 'removeMember', 'saveTask') and p->>'ownerId' <> u::text then
    raise exception 'Tindakan hanya tersedia untuk ketua.';
  end if;
  if action_name = 'createInvite' then
    code := upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 12));
    update public.jt_invites set active = false where project_id = pid;
    insert into public.jt_invites values (encode(digest(code, 'sha256'), 'hex'), pid, now() + interval '7 days', true);
    result := jsonb_build_object('code', code);
  elsif action_name = 'saveProject' then
    p := p || jsonb_strip_nulls(jsonb_build_object(
      'name', input_data->'name', 'description', input_data->'description',
      'courseLabel', input_data->'courseLabel', 'targetDate', input_data->'targetDate',
      'status', input_data->'status'));
    update public.jt_projects set data = p where id = pid;
    result := p;
  elsif action_name = 'removeMember' then
    if input_data->>'memberId' = p->>'ownerId' then raise exception 'Ketua tidak dapat dikeluarkan.'; end if;
    if exists (select 1 from public.jt_tasks where project_id = pid and data->>'status' not in ('done','cancelled')
      and ((data->'assigneeIds') ? (input_data->>'memberId') or data->>'reviewerId' = input_data->>'memberId')) then
      raise exception 'Alihkan tugas aktif anggota ini lebih dahulu.';
    end if;
    delete from public.jt_members where project_id = pid and uid = (input_data->>'memberId')::uuid;
    result := p;
  elsif action_name = 'saveTask' then
    assignees := coalesce(input_data->'assigneeIds', '[]'::jsonb);
    reviewer := nullif(input_data->>'reviewerId', '')::uuid;
    if jsonb_array_length(assignees) = 0 or reviewer is null then raise exception 'Pilih penanggung jawab dan reviewer.'; end if;
    if not exists(select 1 from public.jt_members where project_id = pid and uid = reviewer)
      or assignees ? reviewer::text then raise exception 'Reviewer harus anggota lain.'; end if;
    if exists(select 1 from jsonb_array_elements_text(assignees) a(id)
      where not exists(select 1 from public.jt_members where project_id = pid and uid::text = a.id)) then
      raise exception 'Penanggung jawab harus anggota proyek.';
    end if;
    tid := nullif(input_data->>'taskId', '')::uuid;
    if tid is null then
      tid := gen_random_uuid();
      t := jsonb_strip_nulls(jsonb_build_object(
        'title', input_data->'title', 'description', input_data->'description',
        'assigneeIds', assignees, 'reviewerId', reviewer::text,
        'dueAt', input_data->'dueAt')) || jsonb_build_object('id', tid::text,
        'projectId', pid::text, 'status', 'todo', 'version', 1, 'createdAt', stamp,
        'updatedAt', stamp, 'updates', '[]'::jsonb, 'submissions', '[]'::jsonb, 'reviews', '[]'::jsonb);
      insert into public.jt_tasks(id, project_id, data) values (tid, pid, t);
    else
      select data into t from public.jt_tasks where id = tid and project_id = pid for update;
      if t is null or (t->>'version')::integer <> (input_data->>'version')::integer then
        raise exception 'Tugas berubah. Muat ulang.';
      end if;
      if t->>'status' not in ('todo','in_progress','revision_requested') then raise exception 'Tugas tidak dapat diedit.'; end if;
      t := t || jsonb_strip_nulls(jsonb_build_object(
        'title', input_data->'title', 'description', input_data->'description',
        'assigneeIds', assignees, 'reviewerId', reviewer::text,
        'dueAt', input_data->'dueAt')) ||
        jsonb_build_object('version', (t->>'version')::integer + 1, 'updatedAt', stamp);
      update public.jt_tasks set data = t where id = tid;
    end if;
    result := t;
  elsif action_name = 'generateProjectReport' then
    rid := gen_random_uuid();
    result := jsonb_build_object('id', rid::text, 'projectId', pid::text, 'projectName', p->>'name',
      'generatedBy', u::text, 'createdAt', stamp, 'periodStart', input_data->>'periodStart',
      'periodEnd', input_data->>'periodEnd', 'status', 'ready',
      'tasks', coalesce((select jsonb_agg(data) from public.jt_tasks where project_id = pid
        and (data->>'updatedAt')::timestamptz between (input_data->>'periodStart')::timestamptz
        and (input_data->>'periodEnd')::timestamptz), '[]'::jsonb));
    insert into public.jt_reports values (rid, pid, result);
  elsif action_name = 'generateTeamInsight' then
    raise exception 'AI Team Insight belum diaktifkan. Ringkasan tugas tersedia tanpa AI.';
  else
    tid := nullif(input_data->>'taskId', '')::uuid;
    select data into t from public.jt_tasks where id = tid and project_id = pid for update;
    if t is null then raise exception 'Tugas tidak ditemukan.'; end if;
    ver := (t->>'version')::integer;
    if ver <> (input_data->>'version')::integer then raise exception 'Tugas berubah. Muat ulang.'; end if;
    if action_name = 'startTask' then
      if not (t->'assigneeIds' ? u::text) or t->>'status' <> 'todo' then raise exception 'Hanya penanggung jawab dapat memulai tugas.'; end if;
      t := jsonb_set(t, '{status}', '"in_progress"');
    elsif action_name = 'addUpdate' then
      if not (t->'assigneeIds' ? u::text) or t->>'status' in ('done','cancelled') then
        raise exception 'Hanya penanggung jawab tugas aktif dapat mencatat pembaruan.';
      end if;
      t := jsonb_set(t, '{updates}', coalesce(t->'updates','[]'::jsonb) || jsonb_build_array(
        jsonb_build_object('id', gen_random_uuid()::text, 'authorId', u::text,
          'message', input_data->>'message', 'kind', input_data->>'kind', 'createdAt', stamp)));
    elsif action_name = 'submitTask' then
      if not (t->'assigneeIds' ? u::text) or t->>'status' not in ('in_progress','revision_requested') then
        raise exception 'Tugas belum siap dikirim.';
      end if;
      if t->>'reviewerId' = u::text then raise exception 'Reviewer harus orang lain.'; end if;
      if coalesce(input_data->>'url','') !~ '^https://[^/]+\.[^/]+' then raise exception 'Gunakan tautan HTTPS yang valid.'; end if;
      rid := gen_random_uuid();
      t := t || jsonb_build_object('status', 'submitted', 'latestSubmissionId', rid::text,
        'submissions', coalesce(t->'submissions','[]'::jsonb) || jsonb_build_array(
          jsonb_build_object('id', rid::text, 'submittedBy', u::text, 'note', input_data->>'note',
            'evidenceLinks', jsonb_build_array(jsonb_build_object('label','Bukti kerja','url',input_data->>'url')),
            'status','pending_review','submittedAt',stamp)));
    elsif action_name = 'reviewSubmission' then
      if t->>'reviewerId' <> u::text or t->>'status' <> 'submitted' then
        raise exception 'Hanya reviewer yang ditunjuk dapat memeriksa hasil.';
      end if;
      decision := input_data->>'decision';
      if decision not in ('approved','revision_requested') or length(trim(coalesce(input_data->>'comment',''))) < 3 then
        raise exception 'Isi keputusan dan komentar minimal 3 karakter.';
      end if;
      t := t || jsonb_build_object('status', case when decision = 'approved' then 'done' else 'revision_requested' end,
        'reviews', coalesce(t->'reviews','[]'::jsonb) || jsonb_build_array(
          jsonb_build_object('id',gen_random_uuid()::text,'submissionId',t->>'latestSubmissionId',
            'reviewerId',u::text,'decision',decision,'comment',input_data->>'comment','createdAt',stamp)),
        'submissions', (select jsonb_agg(case when s->>'id' = t->>'latestSubmissionId'
          then s || jsonb_build_object('status',decision,'reviewedAt',stamp,'reviewedBy',u::text) else s end)
          from jsonb_array_elements(t->'submissions') s));
      if decision = 'approved' then t := t || jsonb_build_object('completedAt',stamp); end if;
    else
      raise exception 'Tindakan tidak tersedia.';
    end if;
    t := t || jsonb_build_object('version',ver + 1,'updatedAt',stamp);
    update public.jt_tasks set data = t where id = tid;
    result := t;
  end if;
  insert into public.jt_events(project_id,data) values (pid, jsonb_build_object('actorId',u::text,
    'summary', action_name, 'createdAt', stamp));
  return result;
end $$;

revoke all on function public.jt_workspace() from public, anon;
revoke all on function public.jt_command(text,jsonb) from public, anon;
revoke all on function public.jt_is_member(uuid) from public, anon;
grant execute on function public.jt_workspace() to authenticated;
grant execute on function public.jt_command(text,jsonb) to authenticated;
grant execute on function public.jt_is_member(uuid) to authenticated;

-- Project events are the lightweight workspace invalidation signal.
alter publication supabase_realtime add table public.jt_events;
