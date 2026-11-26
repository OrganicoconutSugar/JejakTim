begin;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('jt-chat-images', 'jt-chat-images', false, 5242880,
        array['image/jpeg', 'image/png', 'image/webp']);

alter table public.jt_project_messages
  add column image_path text unique,
  add column file_url text,
  add column client_message_id uuid,
  add unique (project_id, author_id, client_message_id),
  drop constraint jt_project_messages_body_check,
  add check (
    char_length(btrim(body)) <= 1000 and
    (char_length(btrim(body)) > 0 or image_path is not null or file_url is not null)
  );

create function public.jt_chat_image_allowed(object_name text, uploading boolean)
returns boolean language sql stable security definer set search_path = '' as $$
  select case
    when auth.uid() is null or object_name !~ '^([0-9a-f-]{36}/){2}[0-9a-f-]{36}\.(jpg|png|webp)$'
      then false
    when split_part(object_name, '/', 1) !~ '^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$'
      then false
    else public.jt_is_member(split_part(object_name, '/', 1)::uuid) and
      case when uploading then split_part(object_name, '/', 2) = auth.uid()::text
      else exists (select 1 from public.jt_project_messages m
        where m.image_path = object_name
          and m.project_id = split_part(object_name, '/', 1)::uuid)
      end
  end;
$$;
revoke all on function public.jt_chat_image_allowed(text, boolean)
  from public, anon, authenticated;
grant execute on function public.jt_chat_image_allowed(text, boolean) to authenticated;

create policy "project members download posted chat photos" on storage.objects
  for select to authenticated using (
    bucket_id = 'jt-chat-images' and public.jt_chat_image_allowed(name, false)
  );
create policy "project members upload their chat photos" on storage.objects
  for insert to authenticated with check (
    bucket_id = 'jt-chat-images' and public.jt_chat_image_allowed(name, true)
  );

create or replace function public.jt_project_chat(input_data jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  caller uuid := auth.uid();
  project uuid := (input_data->>'projectId')::uuid;
  message text := btrim(coalesce(input_data->>'message', ''));
  image text := nullif(input_data->>'imagePath', '');
  link text := nullif(btrim(input_data->>'fileUrl'), '');
  request_id uuid := (input_data->>'clientMessageId')::uuid;
  before_id bigint := (input_data->>'beforeId')::bigint;
begin
  if caller is null or not public.jt_is_member(project) then
    raise exception 'Chat hanya tersedia untuk anggota proyek.';
  end if;
  if input_data ?| array['message', 'imagePath', 'fileUrl'] then
    if char_length(message) > 1000 or (message = '' and image is null and link is null) then
      raise exception 'Isi pesan atau tambahkan foto atau tautan. Pesan maksimal 1000 karakter.';
    end if;
    if link is not null and (
      char_length(link) > 2048 or
      link !~* '^https?://[a-z0-9][a-z0-9.-]*\.[a-z0-9]([a-z0-9-]*[a-z0-9])?(:[0-9]{1,5})?([/?#][^[:space:]\\]*)?$'
    ) then
      raise exception 'Gunakan tautan HTTP atau HTTPS yang valid.';
    end if;
    if image is not null and (
      request_id is null or not public.jt_chat_image_allowed(image, true)
      or image not in (
        project::text || '/' || caller::text || '/' || request_id::text || '.jpg',
        project::text || '/' || caller::text || '/' || request_id::text || '.png',
        project::text || '/' || caller::text || '/' || request_id::text || '.webp'
      )
      or not exists (select 1 from storage.objects o
        where o.bucket_id = 'jt-chat-images' and o.name = image)
    ) then
      raise exception 'Foto chat belum tersedia atau tidak bisa digunakan.';
    end if;
    insert into public.jt_project_messages(project_id, author_id, body, image_path, file_url, client_message_id)
      values (project, caller, message, image, link, request_id)
      on conflict (project_id, author_id, client_message_id) do nothing;
  end if;
  return jsonb_build_object('attachments', true, 'messages', coalesce((
    select jsonb_agg(jsonb_build_object(
      'id', m.id::text, 'authorId', m.author_id, 'body', m.body,
      'imagePath', m.image_path, 'fileUrl', m.file_url, 'createdAt', m.created_at
    ) order by m.id desc)
    from (
      select * from public.jt_project_messages
      where project_id = project and (before_id is null or id < before_id)
      order by id desc limit 50
    ) m
  ), '[]'::jsonb));
end $$;

notify pgrst, 'reload schema';
commit;
