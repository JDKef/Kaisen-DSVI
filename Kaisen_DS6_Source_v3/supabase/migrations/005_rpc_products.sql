-- Kaisen Phase 1: controlled product write RPCs.
-- No down migration is provided by design.

create or replace function public.create_product(
  p_business_id uuid,
  p_nombre text,
  p_precio numeric,
  p_stock integer,
  p_categoria text,
  p_codigo_barras text default null
)
returns public.products
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_user uuid;
  v_codigo_barras text;
  v_product public.products;
begin
  v_user := auth.uid();

  if v_user is null then
    raise exception using
      errcode = '42501',
      message = 'Authentication required';
  end if;

  if not exists (
    select 1
    from public.business_members as bm
    where bm.business_id = p_business_id
      and bm.user_id = v_user
      and bm.role in ('admin', 'operator')
  ) then
    raise exception using
      errcode = '42501',
      message = 'Business access denied';
  end if;

  if p_nombre is null or btrim(p_nombre) = '' then
    raise exception using
      errcode = 'P0003',
      message = 'Product name is required';
  end if;

  if p_precio is null or p_precio < 0 then
    raise exception using
      errcode = 'P0003',
      message = 'Product price must be non-negative';
  end if;

  if p_stock is null or p_stock < 0 then
    raise exception using
      errcode = 'P0003',
      message = 'Product stock must be non-negative';
  end if;

  if p_categoria is null or btrim(p_categoria) = '' then
    raise exception using
      errcode = 'P0003',
      message = 'Product category is required';
  end if;

  v_codigo_barras := nullif(btrim(p_codigo_barras), '');

  insert into public.products (
    business_id,
    nombre,
    precio,
    stock,
    categoria,
    codigo_barras,
    activo,
    version,
    created_by,
    updated_by
  )
  values (
    p_business_id,
    btrim(p_nombre),
    cast(p_precio as numeric(12, 2)),
    p_stock,
    btrim(p_categoria),
    v_codigo_barras,
    true,
    1,
    v_user,
    v_user
  )
  returning * into v_product;

  return v_product;
end;
$function$;

create or replace function public.update_product(
  p_product_id bigint,
  p_expected_version bigint,
  p_nombre text,
  p_precio numeric,
  p_stock integer,
  p_categoria text,
  p_codigo_barras text default null
)
returns public.products
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_user uuid;
  v_codigo_barras text;
  v_product public.products;
begin
  v_user := auth.uid();

  if v_user is null then
    raise exception using
      errcode = '42501',
      message = 'Authentication required';
  end if;

  select *
  into v_product
  from public.products as p
  where p.id = p_product_id
  for update;

  if not found then
    raise exception using
      errcode = 'P0002',
      message = 'Product not found';
  end if;

  if not exists (
    select 1
    from public.business_members as bm
    where bm.business_id = v_product.business_id
      and bm.user_id = v_user
      and bm.role in ('admin', 'operator')
  ) then
    raise exception using
      errcode = '42501',
      message = 'Business access denied';
  end if;

  if not v_product.activo then
    raise exception using
      errcode = 'P0002',
      message = 'Archived products cannot be updated';
  end if;

  if p_expected_version is null
     or v_product.version <> p_expected_version then
    raise exception using
      errcode = 'P0001',
      message = 'Product version conflict';
  end if;

  if p_nombre is null or btrim(p_nombre) = '' then
    raise exception using
      errcode = 'P0003',
      message = 'Product name is required';
  end if;

  if p_precio is null or p_precio < 0 then
    raise exception using
      errcode = 'P0003',
      message = 'Product price must be non-negative';
  end if;

  if p_stock is null or p_stock < 0 then
    raise exception using
      errcode = 'P0003',
      message = 'Product stock must be non-negative';
  end if;

  if p_categoria is null or btrim(p_categoria) = '' then
    raise exception using
      errcode = 'P0003',
      message = 'Product category is required';
  end if;

  v_codigo_barras := nullif(btrim(p_codigo_barras), '');

  if v_codigo_barras is not null
     and exists (
       select 1
       from public.products as p
       where p.business_id = v_product.business_id
         and p.id <> p_product_id
         and p.activo = true
         and lower(p.codigo_barras) = lower(v_codigo_barras)
     ) then
    raise exception using
      errcode = '23505',
      message = 'Active product barcode already exists';
  end if;

  update public.products
  set
    nombre = btrim(p_nombre),
    precio = cast(p_precio as numeric(12, 2)),
    stock = p_stock,
    categoria = btrim(p_categoria),
    codigo_barras = v_codigo_barras,
    version = v_product.version + 1,
    updated_at = now(),
    updated_by = v_user
  where id = p_product_id
  returning * into v_product;

  return v_product;
end;
$function$;

create or replace function public.archive_product(
  p_product_id bigint,
  p_expected_version bigint
)
returns public.products
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_user uuid;
  v_product public.products;
begin
  v_user := auth.uid();

  if v_user is null then
    raise exception using
      errcode = '42501',
      message = 'Authentication required';
  end if;

  select *
  into v_product
  from public.products as p
  where p.id = p_product_id
  for update;

  if not found then
    raise exception using
      errcode = 'P0002',
      message = 'Product not found';
  end if;

  if not exists (
    select 1
    from public.business_members as bm
    where bm.business_id = v_product.business_id
      and bm.user_id = v_user
      and bm.role in ('admin', 'operator')
  ) then
    raise exception using
      errcode = '42501',
      message = 'Business access denied';
  end if;

  if p_expected_version is null
     or v_product.version <> p_expected_version then
    raise exception using
      errcode = 'P0001',
      message = 'Product version conflict';
  end if;

  if not v_product.activo then
    raise exception using
      errcode = 'P0002',
      message = 'Product is already archived';
  end if;

  update public.products
  set
    activo = false,
    deleted_at = now(),
    version = v_product.version + 1,
    updated_at = now(),
    updated_by = v_user
  where id = p_product_id
  returning * into v_product;

  return v_product;
end;
$function$;

revoke all on function public.create_product(uuid, text, numeric, integer, text, text)
from public, anon, authenticated;
grant execute on function public.create_product(uuid, text, numeric, integer, text, text)
to authenticated;

revoke all on function public.update_product(bigint, bigint, text, numeric, integer, text, text)
from public, anon, authenticated;
grant execute on function public.update_product(bigint, bigint, text, numeric, integer, text, text)
to authenticated;

revoke all on function public.archive_product(bigint, bigint)
from public, anon, authenticated;
grant execute on function public.archive_product(bigint, bigint)
to authenticated;
