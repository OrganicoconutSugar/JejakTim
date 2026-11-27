-- JejakTim Realtime Project Chat & Membership actions (leave project + transfer ownership).
-- Run once in Supabase SQL Editor after 001..007.
begin;

-- 1. Enable Supabase Realtime notifications on jt_project_messages for project members.
grant select on public.jt_project_messages to authenticated;

drop policy if exists "project members receive realtime chat" on public.jt_project_messages;
create policy "project members receive realtime chat" on public.jt_project_messages
  for select to authenticated using (
    public.jt_is_member(project_id)
  );

do $$
begin
  alter publication supabase_realtime add table public.jt_project_messages;
exception
  when duplicate_object then null;
end $$;

-- 2. Allow non-owner members to leave a project when they have no active tasks.
create or replace function public.jt_leave_project(input_data jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  caller uuid := auth.uid();
  project uuid := nullif(input_data->>'projectId', '')::uuid;
  proj_owner uuid;
  stamp text := to_char(clock_timestamp() at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"');
begin
  if caller is null then
    raise exception 'Masuk terlebih dahulu.';
  end if;
  if project is null or not public.jt_is_member(project) then
    raise exception 'Akses proyek tidak tersedia.';
  end if;
  select owner_id into proj_owner from public.jt_projects where id = project for update;
  if proj_owner is null then
    raise exception 'Proyek tidak ditemukan.';
  end if;
  if proj_owner = caller then
    raise exception 'Ketua proyek tidak dapat keluar. Alihkan peran ketua ke anggota lain terlebih dahulu.';
  end if;
  if exists (
    select 1 from public.jt_tasks
    where project_id = project
      and not (data ? 'deletedAt')
      and data->>'status' not in ('done', 'cancelled')
      and ((data->'assigneeIds') ? caller::text or data->>'reviewerId' = caller::text)
  ) then
    raise exception 'Alihkan atau selesaikan tugas aktifmu di proyek ini terlebih dahulu.';
  end if;

  delete from public.jt_members where project_id = project and uid = caller;
  insert into public.jt_events(project_id, data) values (
    project,
    jsonb_build_object('actorId', caller::text, 'summary', 'Keluar dari proyek', 'createdAt', stamp)
  );
  return jsonb_build_object('ok', true);
end $$;

-- 3. Allow current project owner to transfer leadership to another project member.
create or replace function public.jt_transfer_ownership(input_data jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  caller uuid := auth.uid();
  project uuid := nullif(input_data->>'projectId', '')::uuid;
  target uuid := nullif(input_data->>'newOwnerId', '')::uuid;
  p jsonb;
  stamp text := to_char(clock_timestamp() at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"');
begin
  if caller is null then
    raise exception 'Masuk terlebih dahulu.';
  end if;
  if project is null or target is null then
    raise exception 'Pilih anggota tujuan terlebih dahulu.';
  end if;
  if target = caller then
    raise exception 'Kamu sudah menjadi ketua proyek ini.';
  end if;

  select data into p from public.jt_projects
   where id = project and owner_id = caller and public.jt_is_member(project)
   for update;
  if not found then
    raise exception 'Hanya ketua proyek yang dapat mengalihkan kepemilikan.';
  end if;

  if not exists (
    select 1 from public.jt_members where project_id = project and uid = target
  ) then
    raise exception 'Calon ketua harus merupakan anggota proyek.';
  end if;

  p := p || jsonb_build_object('ownerId', target::text);
  update public.jt_projects set owner_id = target, data = p where id = project;

  insert into public.jt_events(project_id, data) values (
    project,
    jsonb_build_object('actorId', caller::text, 'summary', 'Mengalihkan peran ketua proyek', 'createdAt', stamp)
  );
  return p;
end $$;

revoke all on function public.jt_leave_project(jsonb), public.jt_transfer_ownership(jsonb)
  from public, anon, authenticated;
grant execute on function public.jt_leave_project(jsonb), public.jt_transfer_ownership(jsonb)
  to authenticated;

notify pgrst, 'reload schema';
commit;
