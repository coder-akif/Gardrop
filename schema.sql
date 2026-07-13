-- ============================================================
--  DİJİTAL GARDIROP — SUPABASE ŞEMA KURULUMU
--  Bu dosyanın tamamını kopyalayıp Supabase panelindeki
--  SQL Editor'e yapıştır ve RUN'a bas. Tek seferlik kurulumdur.
-- ============================================================

-- 1) TABLO: clothes
create table if not exists public.clothes (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  category    text not null check (category in ('ust_giyim','alt_giyim','ayakkabi','dis_giyim')),
  subtype     text,
  image_url   text,
  status      text not null default 'dolapta' check (status in ('dolapta','kirlide','makinede')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- 2) updated_at OTOMATİK GÜNCELLEME TRIGGER'I
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_clothes_updated_at on public.clothes;
create trigger trg_clothes_updated_at
before update on public.clothes
for each row
execute function public.set_updated_at();

-- 3) RLS (Row Level Security)
alter table public.clothes enable row level security;

drop policy if exists "clothes_select_all" on public.clothes;
create policy "clothes_select_all"
  on public.clothes for select
  using (true);

drop policy if exists "clothes_insert_all" on public.clothes;
create policy "clothes_insert_all"
  on public.clothes for insert
  with check (true);

drop policy if exists "clothes_update_all" on public.clothes;
create policy "clothes_update_all"
  on public.clothes for update
  using (true)
  with check (true);

drop policy if exists "clothes_delete_all" on public.clothes;
create policy "clothes_delete_all"
  on public.clothes for delete
  using (true);

-- 4) REALTIME YAYINI
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'clothes'
  ) then
    alter publication supabase_realtime add table public.clothes;
  end if;
end $$;

-- 5) STORAGE: clothes-images bucket'ı (public)
insert into storage.buckets (id, name, public)
values ('clothes-images', 'clothes-images', true)
on conflict (id) do nothing;

drop policy if exists "clothes_images_read" on storage.objects;
create policy "clothes_images_read"
  on storage.objects for select
  using (bucket_id = 'clothes-images');

drop policy if exists "clothes_images_insert" on storage.objects;
create policy "clothes_images_insert"
  on storage.objects for insert
  with check (bucket_id = 'clothes-images');

drop policy if exists "clothes_images_update" on storage.objects;
create policy "clothes_images_update"
  on storage.objects for update
  using (bucket_id = 'clothes-images');

drop policy if exists "clothes_images_delete" on storage.objects;
create policy "clothes_images_delete"
  on storage.objects for delete
  using (bucket_id = 'clothes-images');