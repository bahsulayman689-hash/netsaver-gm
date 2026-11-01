-- Run this once in Supabase: SQL Editor -> New query -> Run.
create table if not exists public.reports (
  id          bigint generated always as identity primary key,
  client_id   text not null unique check (char_length(client_id) between 8 and 64),
  created_at  timestamptz not null default now(),
  reported_at timestamptz,
  type        text not null check (type in ('Outage','Slow speed','Price complaint','Other')),
  provider    text check (provider is null or char_length(provider) <= 40),
  body        text not null check (char_length(body) between 3 and 500),
  lat         numeric(6,2) check (lat is null or lat between 13.0 and 13.9),     -- 2 decimals = ~1 km
  lng         numeric(6,2) check (lng is null or lng between -16.9 and -13.7),
  lang        text check (lang in ('en','wo','mnk')),
  approved    boolean not null default false
);

alter table public.reports enable row level security;

-- Anyone (the app, using the anon key) can SUBMIT, but only unapproved rows.
create policy "anon can submit" on public.reports
  for insert to anon with check (approved = false);

-- Anyone can READ only rows you have approved (moderation protects against spam and personal info).
create policy "public reads approved" on public.reports
  for select to anon using (approved = true);

grant insert, select on public.reports to anon;
grant usage on sequence public.reports_id_seq to anon;

-- Aggregated stats for the dashboard (approved reports only, no free text).
create or replace function public.get_stats() returns json
language sql security definer set search_path = public stable as $$
  select json_build_object(
    'total', (select count(*) from reports where approved),
    'by_type', (select coalesce(json_object_agg(type, c), '{}'::json)
                from (select type, count(*) c from reports where approved group by type) x),
    'by_provider', (select coalesce(json_object_agg(p, c), '{}'::json)
                from (select initcap(coalesce(nullif(trim(provider), ''), 'Unknown')) p, count(*) c
                      from reports where approved group by 1 order by 2 desc limit 10) y),
    'by_day', (select coalesce(json_agg(json_build_object('day', d, 'n', c) order by d), '[]'::json)
                from (select (created_at at time zone 'UTC')::date d, count(*) c
                      from reports where approved and created_at > now() - interval '30 days' group by 1) z),
    'points', (select coalesce(json_agg(json_build_object('lat', lat, 'lng', lng, 'type', type)), '[]'::json)
                from (select lat, lng, type from reports
                      where approved and lat is not null and created_at > now() - interval '30 days'
                      order by created_at desc limit 500) w)
  );
$$;
revoke all on function public.get_stats() from public;
grant execute on function public.get_stats() to anon;

-- MODERATION: Table Editor -> reports -> tick "approved" on good reports (or run: update reports set approved = true where id = 123;)
