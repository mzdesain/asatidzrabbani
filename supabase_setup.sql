-- Jalankan di Supabase: SQL Editor > New query > Run
-- Aman dijalankan ulang (idempotent): tabel/aturan yang sudah ada tidak menimbulkan error.

-- ============ 1. Tabel ceklist harian ============
create table if not exists public.mutabaah_entries (
  workspace_id     text        not null,
  id               text        not null,          -- format: YYYY-MM-DD__nama
  teacher          text        not null,
  date             date        not null,
  qobliyah_subuh   boolean     not null default false,
  qobliyah_dzuhur  boolean     not null default false,
  bakdiyah_dzuhur  boolean     not null default false,
  bakdiyah_maghrib boolean     not null default false,
  bakdiyah_isya    boolean     not null default false,
  quran_unit       text        not null default 'Lembar' check (quran_unit in ('Lembar','Juz')),
  quran_amount     numeric     not null default 0,
  tahajud_done     boolean     not null default false,
  tahajud_rakaat   integer     not null default 0,
  notes            text        not null default '',
  updated_at       timestamptz not null default now(),
  primary key (workspace_id, id)
);

create index if not exists mutabaah_entries_ws_date_idx
  on public.mutabaah_entries (workspace_id, date desc);

-- ============ 2. Tabel daftar ustadz / ustadzah ============
create table if not exists public.mutabaah_teachers (
  workspace_id text        not null,
  name         text        not null,              -- nama latin (dipakai di ceklist)
  name_ar      text        not null default '',   -- nama Arab (opsional, untuk PDF)
  created_at   timestamptz not null default now(),
  primary key (workspace_id, name)
);

-- ============ 3. Keamanan (RLS) ============
alter table public.mutabaah_entries  enable row level security;
alter table public.mutabaah_teachers enable row level security;

drop policy if exists "anon select" on public.mutabaah_entries;
drop policy if exists "anon insert" on public.mutabaah_entries;
drop policy if exists "anon update" on public.mutabaah_entries;
drop policy if exists "anon delete" on public.mutabaah_entries;
create policy "anon select" on public.mutabaah_entries for select to anon using (true);
create policy "anon insert" on public.mutabaah_entries for insert to anon with check (true);
create policy "anon update" on public.mutabaah_entries for update to anon using (true) with check (true);
create policy "anon delete" on public.mutabaah_entries for delete to anon using (true);

drop policy if exists "anon select" on public.mutabaah_teachers;
drop policy if exists "anon insert" on public.mutabaah_teachers;
drop policy if exists "anon update" on public.mutabaah_teachers;
drop policy if exists "anon delete" on public.mutabaah_teachers;
create policy "anon select" on public.mutabaah_teachers for select to anon using (true);
create policy "anon insert" on public.mutabaah_teachers for insert to anon with check (true);
create policy "anon update" on public.mutabaah_teachers for update to anon using (true) with check (true);
create policy "anon delete" on public.mutabaah_teachers for delete to anon using (true);

-- ============ 4. Realtime ============
do $$
begin
  begin
    alter publication supabase_realtime add table public.mutabaah_entries;
  exception when duplicate_object then null;
  end;
  begin
    alter publication supabase_realtime add table public.mutabaah_teachers;
  exception when duplicate_object then null;
  end;
end $$;
