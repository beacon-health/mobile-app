-- Supabase advisor fixes — security and performance lints.
-- Source: Database Linter (https://supabase.com/docs/guides/database/database-linter)
--
-- Deliberately NOT addressed here:
--
--   * PostGIS is installed in `public`. That is the root of two separate
--     warnings — `spatial_ref_sys` reported as RLS-disabled, and
--     `st_estimatedextent` callable by `anon` through /rest/v1/rpc. Relocating
--     the extension touches every geometry column on FCT_Supabase, so it wants
--     its own migration and a maintenance window, not a drive-by fix.
--
--   * `delete_account()` is SECURITY DEFINER and callable by authenticated
--     users. That is intentional and already safe: it pins its search_path,
--     derives the id from `auth.uid()`, raises 28000 when unauthenticated, and
--     only ever touches that caller's own rows.

-- 1. Pin search_path on the functions that lacked it.
--
-- Without this, the schema resolution order is whatever the *caller* sets, so a
-- caller-controlled schema can shadow the tables and operators these functions
-- reference. `facilities_near` is the RPC every guest hits on every search, so
-- it is the one that matters most.
alter function public.facilities_near(
  double precision, double precision, double precision, integer
) set search_path = public;

alter function public.fct_supabase_set_geom() set search_path = public;
alter function public.to_phone_jsonb(text) set search_path = public;
alter function public.update_healthcare_facilities_updated_at() set search_path = public;

-- 2. Stop re-evaluating auth.uid() once per row.
--
-- `auth.uid() = user_id` is re-run for every candidate row; wrapping it in a
-- scalar subquery lets Postgres evaluate it once per statement and reuse the
-- result. Behaviour is identical.
--
-- Each policy also gains an explicit `with check`. For a FOR ALL policy Postgres
-- falls back to the USING expression when WITH CHECK is absent, so this changes
-- nothing at runtime — it just makes the insert/update predicate visible rather
-- than implied.
drop policy if exists "Users manage own favorites" on public.user_favorites;
create policy "Users manage own favorites" on public.user_favorites
  for all
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users manage own feedback" on public.facility_feedback;
create policy "Users manage own feedback" on public.facility_feedback
  for all
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users manage own settings" on public.user_settings;
create policy "Users manage own settings" on public.user_settings
  for all
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users manage own facility requests" on public.facility_requests;
create policy "Users manage own facility requests" on public.facility_requests
  for all
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- 3. Drop a duplicate index.
--
-- fct_category_broad_idx and fct_supabase_category_broad_idx are byte-identical
-- btrees on FCT_Supabase(category_broad). Two copies double the write cost and
-- the storage for no read benefit; keep the canonically-named one.
drop index if exists public.fct_category_broad_idx;

-- 4. Index the facility_requests -> auth.users foreign key.
--
-- An unindexed FK means cascading updates/deletes and any lookup by owner has
-- to seq-scan. `delete_account()` nulls user_id on this table, so it pays this
-- cost directly.
create index if not exists facility_requests_user_id_idx
  on public.facility_requests (user_id);
