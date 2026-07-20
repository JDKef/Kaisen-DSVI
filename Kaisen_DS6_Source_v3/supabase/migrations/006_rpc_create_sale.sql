-- Kaisen Phase 1: transactional and idempotent sale RPC.
-- No down migration is provided by design.

create or replace function public.create_sale(
  p_business_id uuid,
  p_client_operation_id uuid,
  p_items jsonb,
  p_occurred_at timestamptz default null
)
returns table (
  sale_id bigint,
  item_ids bigint[],
  replayed boolean
)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_user uuid;
  v_existing_id bigint;
  v_existing_hash text;
  v_sale_id bigint;
  v_item_id bigint;
  v_item_ids bigint[];
  v_product_ids bigint[];
  v_product_id bigint;
  v_quantity integer;
  v_item_count bigint;
  v_distinct_count bigint;
  v_total numeric(12, 2);
  v_line_total numeric(12, 2);
  v_product public.products;
  v_canonical text;
  v_payload_hash text;
  v_occurred_at timestamptz;
  v_input_item record;
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

  if p_client_operation_id is null then
    raise exception using
      errcode = 'P0003',
      message = 'Client operation ID is required';
  end if;

  -- Serialize only retries for the same business and client operation. The
  -- lock is transaction-scoped and is acquired before the first sale lookup.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      p_business_id::text || ':' || p_client_operation_id::text,
      0
    )
  );

  if p_items is null
     or jsonb_typeof(p_items) <> 'array'
     or jsonb_array_length(p_items) = 0 then
    raise exception using
      errcode = 'P0003',
      message = 'Sale items must be a non-empty JSON array';
  end if;

  if exists (
    select 1
    from jsonb_to_recordset(p_items) as item(product_id bigint, cantidad integer)
    where item.product_id is null
       or item.cantidad is null
       or item.product_id <= 0
       or item.cantidad <= 0
  ) then
    raise exception using
      errcode = 'P0003',
      message = 'Sale items must have positive product IDs and quantities';
  end if;

  select
    count(*),
    count(distinct item.product_id),
    array_agg(item.product_id order by item.product_id)
  into
    v_item_count,
    v_distinct_count,
    v_product_ids
  from jsonb_to_recordset(p_items) as item(product_id bigint, cantidad integer);

  if v_item_count <> v_distinct_count then
    raise exception using
      errcode = 'P0003',
      message = 'A product may appear only once in a sale';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'product_id', item.product_id,
        'cantidad', item.cantidad
      )
      order by item.product_id
    ),
    '[]'::jsonb
  )::text
  into v_canonical
  from jsonb_to_recordset(p_items) as item(product_id bigint, cantidad integer);

  v_payload_hash := md5(v_canonical);
  v_occurred_at := coalesce(p_occurred_at, now());

  -- Fast path for a retry that arrives after the original transaction committed.
  select
    s.id,
    s.payload_hash
  into
    v_existing_id,
    v_existing_hash
  from public.sales as s
  where s.business_id = p_business_id
    and s.client_operation_id = p_client_operation_id;

  if found then
    if v_existing_hash <> v_payload_hash then
      raise exception using
        errcode = 'P0001',
        message = 'Client operation ID was used with a different payload';
    end if;

    select coalesce(array_agg(si.id order by si.id), array[]::bigint[])
    into v_item_ids
    from public.sale_items as si
    where si.business_id = p_business_id
      and si.sale_id = v_existing_id;

    return query
    select v_existing_id, v_item_ids, true;
    return;
  end if;

  -- Locks are acquired in ascending product ID order to reduce deadlocks.
  v_total := 0;
  foreach v_product_id in array v_product_ids loop
    select *
    into v_product
    from public.products as p
    where p.business_id = p_business_id
      and p.id = v_product_id
    for update;

    if not found then
      raise exception using
        errcode = 'P0002',
        message = 'Product not found in the requested business';
    end if;

    if not v_product.activo then
      raise exception using
        errcode = 'P0002',
        message = 'Archived products cannot be sold';
    end if;

    select item.cantidad
    into v_quantity
    from jsonb_to_recordset(p_items) as item(product_id bigint, cantidad integer)
    where item.product_id = v_product_id;

    if v_product.stock < v_quantity then
      raise exception using
        errcode = 'P0004',
        message = 'Insufficient product stock';
    end if;

    v_total := v_total + cast(v_product.precio * v_quantity as numeric(12, 2));
  end loop;

  -- A concurrent retry may have passed the fast-path lookup before the first
  -- transaction committed. Handle the unique constraint without duplicating.
  begin
    insert into public.sales (
      business_id,
      client_operation_id,
      payload_hash,
      seller_id,
      occurred_at,
      total
    )
    values (
      p_business_id,
      p_client_operation_id,
      v_payload_hash,
      v_user,
      v_occurred_at,
      v_total
    )
    returning id into v_sale_id;
  exception
    when unique_violation then
      select
        s.id,
        s.payload_hash
      into
        v_existing_id,
        v_existing_hash
      from public.sales as s
      where s.business_id = p_business_id
        and s.client_operation_id = p_client_operation_id;

      if not found then
        raise;
      end if;

      if v_existing_hash <> v_payload_hash then
        raise exception using
          errcode = 'P0001',
          message = 'Client operation ID was used with a different payload';
      end if;

      select coalesce(array_agg(si.id order by si.id), array[]::bigint[])
      into v_item_ids
      from public.sale_items as si
      where si.business_id = p_business_id
        and si.sale_id = v_existing_id;

      return query
      select v_existing_id, v_item_ids, true;
      return;
  end;

  v_item_ids := array[]::bigint[];

  -- Insert lines in the caller's item order. Product locks were already taken
  -- in sorted order above.
  for v_input_item in
    select
      (elements.item ->> 'product_id')::bigint as product_id,
      (elements.item ->> 'cantidad')::integer as cantidad
    from jsonb_array_elements(p_items) with ordinality as elements(item, ordinal)
    order by elements.ordinal
  loop
    v_product_id := v_input_item.product_id;
    v_quantity := v_input_item.cantidad;

    select *
    into v_product
    from public.products as p
    where p.business_id = p_business_id
      and p.id = v_product_id
    for update;

    v_line_total := cast(v_product.precio * v_quantity as numeric(12, 2));

    insert into public.sale_items (
      business_id,
      sale_id,
      product_id,
      producto_nombre,
      categoria,
      cantidad,
      precio_unitario,
      line_total
    )
    values (
      p_business_id,
      v_sale_id,
      v_product.id,
      v_product.nombre,
      v_product.categoria,
      v_quantity,
      v_product.precio,
      v_line_total
    )
    returning id into v_item_id;

    v_item_ids := array_append(v_item_ids, v_item_id);

    update public.products
    set
      stock = stock - v_quantity,
      version = version + 1,
      updated_at = now(),
      updated_by = v_user
    where business_id = p_business_id
      and id = v_product_id
      and stock >= v_quantity;

    if not found then
      raise exception using
        errcode = 'P0004',
        message = 'Insufficient product stock';
    end if;
  end loop;

  return query
  select v_sale_id, v_item_ids, false;
end;
$function$;

revoke all on function public.create_sale(uuid, uuid, jsonb, timestamptz)
from public, anon, authenticated;
grant execute on function public.create_sale(uuid, uuid, jsonb, timestamptz)
to authenticated;
