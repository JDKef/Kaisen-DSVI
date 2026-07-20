-- Kaisen Phase 1: RLS and least-privilege API grants.
-- No down migration is provided by design.

create or replace function public.is_business_member(p_business_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select exists (
    select 1
    from public.business_members as bm
    where bm.business_id = p_business_id
      and bm.user_id = auth.uid()
  );
$function$;

alter table public.profiles enable row level security;
alter table public.businesses enable row level security;
alter table public.business_members enable row level security;
alter table public.products enable row level security;
alter table public.sales enable row level security;
alter table public.sale_items enable row level security;

create policy profiles_select_own
on public.profiles
for select
to authenticated
using (id = auth.uid());

create policy businesses_select_member
on public.businesses
for select
to authenticated
using (public.is_business_member(id));

create policy business_members_select_own
on public.business_members
for select
to authenticated
using (user_id = auth.uid());

create policy products_select_active_member
on public.products
for select
to authenticated
using (
  activo = true
  and public.is_business_member(business_id)
);

create policy sales_select_member
on public.sales
for select
to authenticated
using (public.is_business_member(business_id));

create policy sale_items_select_member
on public.sale_items
for select
to authenticated
using (public.is_business_member(business_id));

-- There are intentionally no INSERT, UPDATE or DELETE policies for
-- products, sales or sale_items. Absence of a policy denies those operations.
revoke all on table
  public.profiles,
  public.businesses,
  public.business_members,
  public.products,
  public.sales,
  public.sale_items
from public, anon, authenticated;

grant select on table
  public.profiles,
  public.businesses,
  public.business_members,
  public.products,
  public.sales,
  public.sale_items
to authenticated;

revoke all on table public.sale_history from public, anon, authenticated;
grant select on table public.sale_history to authenticated;

revoke all on function public.is_business_member(uuid)
from public, anon, authenticated;

-- RLS policies invoke this helper on behalf of authenticated callers. It is
-- safe to expose only the boolean membership result, never the membership
-- rows themselves.
grant execute on function public.is_business_member(uuid)
to authenticated;
