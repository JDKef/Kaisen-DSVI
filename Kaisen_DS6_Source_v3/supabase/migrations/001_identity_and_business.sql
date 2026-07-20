-- Kaisen Phase 1: identity and default business foundation.
-- No down migration is provided by design.

create table public.businesses (
  id uuid primary key,
  nombre text not null check (btrim(nombre) <> ''),
  created_at timestamptz not null default now()
);

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username text not null check (char_length(btrim(username)) between 3 and 128),
  username_normalized text not null unique
    check (
      char_length(username_normalized) between 3 and 128
      and username_normalized = lower(btrim(username))
    ),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.business_members (
  business_id uuid not null references public.businesses (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  role text not null default 'operator'
    check (role in ('admin', 'operator')),
  created_at timestamptz not null default now(),
  primary key (business_id, user_id)
);

create index business_members_user_idx
on public.business_members (user_id, business_id);

-- Stable seed used by the current single-business application.
insert into public.businesses (id, nombre)
values (
  '00000000-0000-4000-8000-000000000001'::uuid,
  'Kaisen'
)
on conflict (id) do nothing;

-- Supabase Auth creates auth.users. This trigger creates the application
-- profile and default-business membership for every new authenticated user.
-- The username is expected in raw_user_meta_data.username. The fallback keeps
-- the database invariant intact for users created before Flutter sends it.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_username text;
begin
  v_username := coalesce(
    nullif(btrim(new.raw_user_meta_data ->> 'username'), ''),
    nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
    new.id::text
  );

  insert into public.profiles (
    id,
    username,
    username_normalized
  )
  values (
    new.id,
    v_username,
    lower(btrim(v_username))
  );

  insert into public.business_members (
    business_id,
    user_id,
    role
  )
  values (
    '00000000-0000-4000-8000-000000000001'::uuid,
    new.id,
    'operator'
  );

  return new;
end;
$function$;

create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_new_user();

-- Trigger-only function. Do not expose it to API roles.
revoke all on function public.handle_new_user() from public, anon, authenticated;
