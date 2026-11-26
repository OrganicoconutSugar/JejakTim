begin;

create table public.jt_project_messages (
  id bigint generated always as identity primary key,
  project_id uuid not null references public.jt_projects(id) on delete cascade,
  author_id uuid not null,
  body text not null check (char_length(btrim(body)) between 1 and 1000),
  created_at timestamptz not null default now()
);
create index jt_project_messages_project_id_idx
  on public.jt_project_messages(project_id, id desc);
alter table public.jt_project_messages enable row level security;
revoke all on public.jt_project_messages from public, anon, authenticated;

create function public.jt_project_chat(input_data jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  caller uuid := auth.uid();
  project uuid := (input_data->>'projectId')::uuid;
  message text := btrim(input_data->>'message');
  before_id bigint := (input_data->>'beforeId')::bigint;
begin
  if caller is null or not public.jt_is_member(project) then
    raise exception 'Chat hanya tersedia untuk anggota proyek.';
  end if;
  if input_data ? 'message' then
    if message is null or char_length(message) not between 1 and 1000 then
      raise exception 'Isi pesan antara 1 dan 1000 karakter.';
    end if;
    insert into public.jt_project_messages(project_id, author_id, body)
      values (project, caller, message);
  end if;
  return jsonb_build_object('messages', coalesce((
    select jsonb_agg(jsonb_build_object(
      'id', m.id::text, 'authorId', m.author_id, 'body', m.body, 'createdAt', m.created_at
    ) order by m.id desc)
    from (
      select * from public.jt_project_messages
      where project_id = project and (before_id is null or id < before_id)
      order by id desc limit 50
    ) m
  ), '[]'::jsonb));
end $$;

create function public.jt_remove_task(input_data jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  caller uuid := auth.uid();
  project uuid := (input_data->>'projectId')::uuid;
  task uuid := (input_data->>'taskId')::uuid;
  task_data jsonb;
begin
  perform 1 from public.jt_projects p
   where p.id = project and p.owner_id = caller and public.jt_is_member(p.id)
     and p.data->>'status' = 'active' for update;
  if not found then raise exception 'Hanya ketua proyek aktif yang dapat menghapus tugas.'; end if;
  select t.data into task_data from public.jt_tasks t
   where t.id = task and t.project_id = project for update;
  if not found then raise exception 'Tugas tidak ditemukan.'; end if;
  if task_data ? 'deletedAt' then return jsonb_build_object('ok', true); end if;
  if (task_data->>'version')::integer is distinct from (input_data->>'version')::integer then
    raise exception 'Tugas berubah. Muat ulang.';
  end if;
  update public.jt_tasks set data = task_data || jsonb_build_object(
    'status', 'cancelled', 'deletedAt', now(), 'deletedBy', caller,
    'version', (task_data->>'version')::integer + 1
  ) where id = task and project_id = project;
  insert into public.jt_events(project_id, data) values (
    project, jsonb_build_object('actorId', caller, 'summary', 'Tugas dihapus', 'createdAt', now())
  );
  return jsonb_build_object('ok', true);
end $$;

alter table public.jt_projects add constraint jt_project_avatar_valid check (
  not (data ? 'avatar') or coalesce(
    length(data->>'avatar') <= 180000 and
    (data->>'avatar' in ('folder', 'sprout', 'sparkles')
      or data->>'avatar' ~ '^data:image/(jpeg|png|webp);base64,[A-Za-z0-9+/]+={0,2}$'),
    false
  )
);

revoke all on function public.jt_project_chat(jsonb), public.jt_remove_task(jsonb)
  from public, anon, authenticated;
grant execute on function public.jt_project_chat(jsonb), public.jt_remove_task(jsonb)
  to authenticated;

commit;
