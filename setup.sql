-- FMD Folio — library setup for Supabase.
-- Paste into Supabase → SQL Editor → New query → Run. Safe to run more than once.
-- Change the admin email on the last line if needed (lowercase).

-- ---------- admin list ----------
create table if not exists public.admins (
  email text primary key check (email = lower(email)),
  added_at timestamptz not null default now()
);
alter table public.admins enable row level security;

create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to authenticated;

create or replace function private.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.admins a
    where a.email = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;
revoke all on function private.is_admin() from public;
grant execute on function private.is_admin() to authenticated;

drop policy if exists "Users see their own admin row" on public.admins;
create policy "Users see their own admin row" on public.admins
  for select to authenticated using (email = lower(coalesce((select auth.jwt()) ->> 'email', '')));

-- ---------- book catalogue ----------
create table if not exists public.books (
  id text primary key default gen_random_uuid()::text,
  title text not null default 'Untitled',
  author text not null default '',
  category text not null default 'Uncategorized',
  description text not null default '',
  pages integer not null default 0,
  aspect real not null default 0.707,
  size bigint not null default 0,
  added_at bigint not null default (extract(epoch from now()) * 1000)::bigint,
  cover_mode text not null default 'pdf' check (cover_mode in ('pdf','design')),
  cover_color text not null default '#2f4a3a',
  cover_style text not null default 'classic' check (cover_style in ('classic','modern','minimal')),
  favorite boolean not null default false,
  pdf_path text not null,
  thumb_path text not null default '',
  created_at timestamptz not null default now()
);
create index if not exists books_added_at_idx on public.books (added_at desc);
alter table public.books enable row level security;

drop policy if exists "Anyone can read books" on public.books;
drop policy if exists "Admins add books" on public.books;
drop policy if exists "Admins edit books" on public.books;
drop policy if exists "Admins remove books" on public.books;
create policy "Anyone can read books" on public.books
  for select to anon, authenticated using (true);
create policy "Admins add books" on public.books
  for insert to authenticated with check ((select private.is_admin()));
create policy "Admins edit books" on public.books
  for update to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));
create policy "Admins remove books" on public.books
  for delete to authenticated using ((select private.is_admin()));

-- ---------- file storage (public bucket, 50 MB per file) ----------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('books', 'books', true, 52428800, array['application/pdf','image/jpeg','image/png','image/webp'])
on conflict (id) do update set public = excluded.public, file_size_limit = excluded.file_size_limit, allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Admins upload library files" on storage.objects;
drop policy if exists "Admins update library files" on storage.objects;
drop policy if exists "Admins delete library files" on storage.objects;
create policy "Admins upload library files" on storage.objects
  for insert to authenticated with check (bucket_id = 'books' and (select private.is_admin()));
create policy "Admins update library files" on storage.objects
  for update to authenticated using (bucket_id = 'books' and (select private.is_admin()));
create policy "Admins delete library files" on storage.objects
  for delete to authenticated using (bucket_id = 'books' and (select private.is_admin()));

-- ---------- live updates ----------
do $$ begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'books') then
    alter publication supabase_realtime add table public.books;
  end if;
end $$;

-- ---------- first admin ----------
insert into public.admins (email) values ('gyeltshensheyrub@gmail.com') on conflict do nothing;
