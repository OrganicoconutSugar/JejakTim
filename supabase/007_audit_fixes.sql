-- JejakTim backend audit fixes. Run once in Supabase SQL Editor after 001..006.
begin;

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
      join public.jt_members mine on mine.project_id = t.project_id
      where mine.uid = u and not (t.data ? 'deletedAt')), '[]'::jsonb),
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
  u uuid := auth.uid(); pid uuid; tid uuid; rid uuid; p jsonb; t jsonb;
  result jsonb; code text; stamp text := to_char(clock_timestamp() at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"');
  assignees jsonb; reviewer uuid; ver integer; decision text;
  already_member boolean; event_summary text; avatar_url text; next_status text;
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
    if input_data ? 'name' and length(trim(coalesce(input_data->>'name', ''))) not between 3 and 80 then
      raise exception 'Nama lengkap antara 3 sampai 80 karakter.';
    end if;
    if input_data ? 'avatarDataUrl' then
      avatar_url := coalesce(input_data->>'avatarDataUrl', '');
      if avatar_url <> '' and (
        length(avatar_url) > 360000 or
        avatar_url !~ '^data:image/(jpeg|png|webp);base64,[A-Za-z0-9+/]+={0,2}$'
      ) then
        raise exception 'Gunakan foto profil JPG, PNG, atau WebP maksimal 250 KB.';
      end if;
    end if;
    update public.jt_profiles set data = data || (input_data - 'requestId' - 'uid' - 'email' - 'createdAt')
      where uid = u returning data into result;
    if result is null then raise exception 'Profil tidak ditemukan.'; end if;
    return result;
  end if;

  if action_name = 'deleteAccount' then
    if exists (
      select 1 from public.jt_projects
      where owner_id = u and data->>'status' = 'active'
    ) then
      raise exception 'Arsipkan proyek aktif milikmu terlebih dahulu sebelum menghapus akun.';
    end if;
    delete from public.jt_members where uid = u;
    delete from public.jt_profiles where uid = u;
    return jsonb_build_object('ok', true);
  end if;

  if action_name = 'createProject' then
    if length(trim(coalesce(input_data->>'name', ''))) not between 3 and 120 then
      raise exception 'Nama proyek antara 3 sampai 120 karakter.';
    end if;
    pid := gen_random_uuid();
    p := (input_data - 'requestId' - 'projectId') || jsonb_build_object('id', pid::text, 'ownerId', u::text,
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
    already_member := exists (select 1 from public.jt_members where project_id = pid and uid = u);
    if action_name = 'joinProject' and not already_member then
      if (select count(*) from public.jt_members where project_id = pid) >= 30 then
        raise exception 'Proyek penuh.';
      end if;
      insert into public.jt_members values (pid, u) on conflict do nothing;
      insert into public.jt_events(project_id, data) values (pid, jsonb_build_object('actorId', u::text,
        'summary', 'Bergabung ke proyek', 'createdAt', stamp));
    end if;
    return jsonb_build_object('id', pid::text, 'name', p->>'name',
      'description', p->>'description',
      'ownerName', coalesce((select data->>'name' from public.jt_profiles where uid = (p->>'ownerId')::uuid), 'Ketua'),
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

  if action_name in ('createInvite', 'saveTask', 'startTask', 'addUpdate', 'submitTask', 'reviewSubmission')
     and p->>'status' <> 'active' then
    raise exception 'Proyek diarsipkan. Buka kembali proyek sebelum melakukan perubahan.';
  end if;

  if action_name = 'createInvite' then
    code := upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 12));
    update public.jt_invites set active = false where project_id = pid;
    insert into public.jt_invites values (encode(digest(code, 'sha256'), 'hex'), pid, now() + interval '7 days', true);
    result := jsonb_build_object('code', code);
    event_summary := 'Memperbarui kode undangan';
  elsif action_name = 'saveProject' then
    if input_data ? 'name' and length(trim(coalesce(input_data->>'name', ''))) not between 3 and 120 then
      raise exception 'Nama proyek antara 3 sampai 120 karakter.';
    end if;
    if input_data ? 'status' then
      next_status := input_data->>'status';
      if next_status not in ('active', 'archived') then
        raise exception 'Status proyek tidak valid.';
      end if;
    end if;
    p := p || jsonb_strip_nulls(jsonb_build_object(
      'name', input_data->'name',
      'description', input_data->'description',
      'courseLabel', input_data->'courseLabel',
      'targetDate', input_data->'targetDate',
      'avatar', input_data->'avatar',
      'status', input_data->'status'));
    if input_data ? 'targetDate' and input_data->'targetDate' = 'null'::jsonb then
      p := p - 'targetDate';
    end if;
    update public.jt_projects set data = p where id = pid;
    result := p;
    event_summary := case
      when next_status = 'archived' then 'Mengarsipkan proyek'
      when next_status = 'active' and not (input_data ? 'description') then 'Membuka kembali proyek'
      else 'Memperbarui pengaturan proyek'
    end;
  elsif action_name = 'removeMember' then
    if input_data->>'memberId' = p->>'ownerId' then raise exception 'Ketua tidak dapat dikeluarkan.'; end if;
    if exists (select 1 from public.jt_tasks where project_id = pid
      and not (data ? 'deletedAt')
      and data->>'status' not in ('done','cancelled')
      and ((data->'assigneeIds') ? (input_data->>'memberId') or data->>'reviewerId' = input_data->>'memberId')) then
      raise exception 'Alihkan tugas aktif anggota ini lebih dahulu.';
    end if;
    delete from public.jt_members where project_id = pid and uid = (input_data->>'memberId')::uuid;
    result := p;
    event_summary := 'Menghapus keanggotaan proyek';
  elsif action_name = 'saveTask' then
    if length(trim(coalesce(input_data->>'title', ''))) not between 3 and 160 then
      raise exception 'Judul tugas antara 3 sampai 160 karakter.';
    end if;
    if length(trim(coalesce(input_data->>'description', ''))) not between 3 and 2000 then
      raise exception 'Deskripsi tugas minimal 3 karakter.';
    end if;
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
      event_summary := 'Membuat tugas: ' || trim(input_data->>'title');
    else
      select data into t from public.jt_tasks where id = tid and project_id = pid for update;
      if t is null or (t ? 'deletedAt') then raise exception 'Tugas tidak ditemukan.'; end if;
      if (t->>'version')::integer <> (input_data->>'version')::integer then
        raise exception 'Tugas berubah. Muat ulang.';
      end if;
      if t->>'status' not in ('todo','in_progress','revision_requested') then raise exception 'Tugas tidak dapat diedit.'; end if;
      t := t || jsonb_strip_nulls(jsonb_build_object(
        'title', input_data->'title', 'description', input_data->'description',
        'assigneeIds', assignees, 'reviewerId', reviewer::text,
        'dueAt', input_data->'dueAt')) ||
        jsonb_build_object('version', (t->>'version')::integer + 1, 'updatedAt', stamp);
      if input_data ? 'dueAt' and input_data->'dueAt' = 'null'::jsonb then
        t := t - 'dueAt';
      end if;
      update public.jt_tasks set data = t where id = tid;
      event_summary := 'Memperbarui tugas: ' || trim(input_data->>'title');
    end if;
    result := t;
  elsif action_name = 'generateProjectReport' then
    rid := gen_random_uuid();
    result := jsonb_build_object('id', rid::text, 'projectId', pid::text, 'projectName', p->>'name',
      'generatedBy', u::text, 'createdAt', stamp, 'periodStart', input_data->>'periodStart',
      'periodEnd', input_data->>'periodEnd', 'status', 'ready',
      'tasks', coalesce((select jsonb_agg(data) from public.jt_tasks where project_id = pid
        and not (data ? 'deletedAt')
        and (data->>'updatedAt')::timestamptz between (input_data->>'periodStart')::timestamptz
        and (input_data->>'periodEnd')::timestamptz), '[]'::jsonb));
    insert into public.jt_reports values (rid, pid, result);
    event_summary := 'Membuat snapshot laporan';
  elsif action_name = 'generateTeamInsight' then
    raise exception 'AI Team Insight belum diaktifkan. Ringkasan tugas tersedia tanpa AI.';
  else
    tid := nullif(input_data->>'taskId', '')::uuid;
    select data into t from public.jt_tasks where id = tid and project_id = pid for update;
    if t is null or (t ? 'deletedAt') then raise exception 'Tugas tidak ditemukan.'; end if;
    ver := (t->>'version')::integer;
    if ver <> (input_data->>'version')::integer then raise exception 'Tugas berubah. Muat ulang.'; end if;
    if action_name = 'startTask' then
      if not (t->'assigneeIds' ? u::text) or t->>'status' <> 'todo' then raise exception 'Hanya penanggung jawab dapat memulai tugas.'; end if;
      t := jsonb_set(t, '{status}', '"in_progress"');
      event_summary := 'Memulai tugas';
    elsif action_name = 'addUpdate' then
      if not (t->'assigneeIds' ? u::text) or t->>'status' in ('done','cancelled') then
        raise exception 'Hanya penanggung jawab tugas aktif dapat mencatat pembaruan.';
      end if;
      if length(trim(coalesce(input_data->>'message', ''))) not between 3 and 2000 then
        raise exception 'Catatan minimal 3 karakter dan maksimal 2000 karakter.';
      end if;
      if coalesce(input_data->>'kind', '') not in ('progress', 'blocker') then
        raise exception 'Jenis catatan tidak valid.';
      end if;
      t := jsonb_set(t, '{updates}', coalesce(t->'updates','[]'::jsonb) || jsonb_build_array(
        jsonb_build_object('id', gen_random_uuid()::text, 'authorId', u::text,
          'message', trim(input_data->>'message'), 'kind', input_data->>'kind', 'createdAt', stamp)));
      event_summary := 'Mencatat pembaruan tugas';
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
      event_summary := 'Mengirim bukti kerja';
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
      event_summary := case when decision = 'approved' then 'Menyetujui hasil kerja' else 'Meminta revisi' end;
    else
      raise exception 'Tindakan tidak tersedia.';
    end if;
    t := t || jsonb_build_object('version',ver + 1,'updatedAt',stamp);
    update public.jt_tasks set data = t where id = tid;
    result := t;
  end if;

  insert into public.jt_events(project_id,data) values (pid, jsonb_build_object('actorId',u::text,
    'summary', coalesce(event_summary, action_name), 'createdAt', stamp));
  return result;
end $$;

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
  prior_submissions jsonb;
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
  if t is null or (t ? 'deletedAt') then raise exception 'Tugas tidak ditemukan.'; end if;
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

  prior_submissions := coalesce((
    select jsonb_agg(
      case when s->>'status' = 'pending_review'
        then s || jsonb_build_object('status', 'superseded')
        else s
      end
    )
    from jsonb_array_elements(coalesce(t->'submissions', '[]'::jsonb)) s
  ), '[]'::jsonb);

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
    'submissions', prior_submissions || jsonb_build_array(submission),
    'version', (t->>'version')::integer + 1, 'updatedAt', stamp
  );
  update public.jt_tasks set data = t where id = tid;
  insert into public.jt_events(project_id, data)
    values (pid, jsonb_build_object(
      'actorId', u::text, 'summary', 'Mengirim bukti kerja',
      'createdAt', stamp));
  return t;
end $$;

revoke all on function public.jt_workspace() from public, anon;
revoke all on function public.jt_command(text,jsonb) from public, anon;
revoke all on function public.jt_submit_evidence(jsonb) from public, anon;
grant execute on function public.jt_workspace() to authenticated;
grant execute on function public.jt_command(text,jsonb) to authenticated;
grant execute on function public.jt_submit_evidence(jsonb) to authenticated;

notify pgrst, 'reload schema';
commit;
