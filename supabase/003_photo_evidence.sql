-- Private photo evidence for JejakTim. Run once after 001 and 002.
insert into storage.buckets
  (id, name, public, file_size_limit, allowed_mime_types)
values
  ('jt-evidence', 'jt-evidence', false, 5242880,
   array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update set
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create or replace function public.jt_can_read_evidence(object_name text)
returns boolean language plpgsql security definer stable set search_path = '' as $$
declare pid uuid;
begin
  if object_name !~ '^([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/){2}[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.(jpg|png|webp)$'
    then return false; end if;
  pid := split_part(object_name, '/', 1)::uuid;
  return public.jt_is_member(pid);
end $$;

create or replace function public.jt_can_upload_evidence(object_name text)
returns boolean language plpgsql security definer stable set search_path = '' as $$
declare pid uuid; tid uuid; u uuid := auth.uid();
begin
  if u is null or
     object_name !~ '^([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/){2}[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.(jpg|png|webp)$'
    then return false; end if;
  pid := split_part(object_name, '/', 1)::uuid;
  tid := split_part(object_name, '/', 2)::uuid;
  return exists (
    select 1 from public.jt_tasks t
    join public.jt_projects p on p.id = t.project_id
    where t.id = tid and t.project_id = pid and p.data->>'status' = 'active'
      and t.data->>'status' in ('in_progress', 'revision_requested')
      and t.data->'assigneeIds' ? u::text
      and public.jt_is_member(pid)
  );
end $$;

revoke all on function public.jt_can_read_evidence(text) from public, anon;
revoke all on function public.jt_can_upload_evidence(text) from public, anon;
grant execute on function public.jt_can_read_evidence(text) to authenticated;
grant execute on function public.jt_can_upload_evidence(text) to authenticated;

drop policy if exists "JejakTim members view evidence" on storage.objects;
create policy "JejakTim members view evidence" on storage.objects
for select to authenticated using (
  bucket_id = 'jt-evidence' and public.jt_can_read_evidence(name)
);

drop policy if exists "JejakTim assignees upload evidence" on storage.objects;
create policy "JejakTim assignees upload evidence" on storage.objects
for insert to authenticated with check (
  bucket_id = 'jt-evidence' and public.jt_can_upload_evidence(name)
);

create or replace function public.jt_submit_evidence(input_data jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  u uuid := auth.uid(); pid uuid; tid uuid; p jsonb; t jsonb;
  photo_path text := nullif(input_data->>'photoPath', '');
  evidence_url text := nullif(trim(input_data->>'url'), '');
  note_text text := coalesce(input_data->>'note', '');
  rid uuid := gen_random_uuid();
  stamp text := to_char(clock_timestamp() at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"');
  submission jsonb;
begin
  if u is null then raise exception 'Masuk terlebih dahulu.'; end if;
  pid := nullif(input_data->>'projectId', '')::uuid;
  tid := nullif(input_data->>'taskId', '')::uuid;
  if pid is null or tid is null or not public.jt_is_member(pid) then
    raise exception 'Akses proyek tidak tersedia.';
  end if;
  select data into p from public.jt_projects where id = pid;
  if p is null or p->>'status' <> 'active' then
    raise exception 'Proyek tidak aktif.';
  end if;
  select data into t from public.jt_tasks
    where id = tid and project_id = pid for update;
  if t is null then raise exception 'Tugas tidak ditemukan.'; end if;
  if (t->>'version')::integer <> (input_data->>'version')::integer then
    raise exception 'Tugas berubah. Muat ulang.';
  end if;
  if not (t->'assigneeIds' ? u::text) or
     t->>'status' not in ('in_progress', 'revision_requested') or
     t->>'reviewerId' = u::text then
    raise exception 'Tugas belum siap dikirim.';
  end if;
  if length(note_text) > 2000 then
    raise exception 'Catatan maksimal 2000 karakter.';
  end if;
  if photo_path is null and evidence_url is null then
    raise exception 'Pilih foto atau isi tautan bukti kerja.';
  end if;
  if evidence_url is not null and (
    length(evidence_url) > 2048 or
    evidence_url !~* '^https?://[a-z0-9-]+(\.[a-z0-9-]+)+(:[0-9]{1,5})?([/?#]|$)'
  ) then
    raise exception 'Masukkan tautan web yang valid.';
  end if;
  if photo_path is not null and (
    not public.jt_can_read_evidence(photo_path) or
    split_part(photo_path, '/', 1) <> pid::text or
    split_part(photo_path, '/', 2) <> tid::text or
    not exists (
      select 1 from storage.objects o
      where o.bucket_id = 'jt-evidence' and o.name = photo_path
        and o.owner_id = u::text
        and o.metadata->>'mimetype' in
          ('image/jpeg', 'image/png', 'image/webp')
    )
  ) then
    raise exception 'Foto bukti belum berhasil diunggah.';
  end if;
  submission := jsonb_build_object(
    'id', rid::text, 'submittedBy', u::text, 'note', note_text,
    'status', 'pending_review', 'submittedAt', stamp,
    'evidenceLinks',
      case when evidence_url is null then '[]'::jsonb else
        jsonb_build_array(jsonb_build_object(
          'label', 'Buka tautan bukti', 'url', evidence_url)) end,
    'evidenceFiles',
      case when photo_path is null then '[]'::jsonb else
        jsonb_build_array(jsonb_build_object(
          'label', 'Foto hasil kerja', 'path', photo_path)) end
  );
  t := t || jsonb_build_object(
    'status', 'submitted', 'latestSubmissionId', rid::text,
    'submissions', coalesce(t->'submissions', '[]'::jsonb)
      || jsonb_build_array(submission),
    'version', (t->>'version')::integer + 1, 'updatedAt', stamp
  );
  update public.jt_tasks set data = t where id = tid;
  insert into public.jt_events(project_id, data)
    values (pid, jsonb_build_object(
      'actorId', u::text, 'summary', 'Mengirim bukti kerja',
      'createdAt', stamp));
  return t;
end $$;

revoke all on function public.jt_submit_evidence(jsonb) from public, anon;
grant execute on function public.jt_submit_evidence(jsonb) to authenticated;
