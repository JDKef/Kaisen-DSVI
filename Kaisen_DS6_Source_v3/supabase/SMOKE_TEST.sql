-- Kaisen Phase 1 smoke test.
--
-- Preconditions:
--   1. Apply migrations 001 through 006 manually in order.
--   2. Run this script as an authenticated application user who belongs to
--      the seeded business. A plain SQL editor session normally has auth.uid()
--      = NULL; use an authenticated request/session for the RPC checks.
--   3. This script runs inside a transaction and rolls its test data back.
--
-- It intentionally does not create auth.users. New users must be created by
-- Supabase Auth so the trigger from migration 001 creates profile and
-- default-business membership.

begin;

do $smoke$
declare
  v_business_id constant uuid := '00000000-0000-4000-8000-000000000001'::uuid;
  v_product_a public.products;
  v_product_b public.products;
  v_product_c public.products;
  v_updated public.products;
  v_archived public.products;
  v_receipt record;
  v_retry record;
  v_barcode text := 'SMOKE-BARCODE-001';
  v_stock_b integer;
  v_stock_c integer;
  v_stock_b_after integer;
  v_stock_c_after integer;
  v_sales_before bigint;
  v_sales_after bigint;
  v_history_count bigint;
begin
  if auth.uid() is null then
    raise exception 'Run smoke tests as an authenticated user';
  end if;

  -- Valid product creation.
  select *
  into v_product_a
  from public.create_product(
    p_business_id => v_business_id,
    p_nombre => 'Smoke Product A',
    p_precio => 10.50,
    p_stock => 4,
    p_categoria => 'Smoke',
    p_codigo_barras => v_barcode
  );

  if v_product_a.id is null
     or v_product_a.version <> 1
     or v_product_a.stock <> 4 then
    raise exception 'Valid product creation failed';
  end if;

  -- Negative price rejection.
  begin
    perform public.create_product(
      p_business_id => v_business_id,
      p_nombre => 'Invalid Price',
      p_precio => -1,
      p_stock => 1,
      p_categoria => 'Smoke',
      p_codigo_barras => null
    );
    raise exception 'Negative price was accepted';
  exception
    when sqlstate 'P0003' then
      null;
  end;

  -- Duplicate active barcode rejection.
  begin
    perform public.create_product(
      p_business_id => v_business_id,
      p_nombre => 'Duplicate Barcode',
      p_precio => 1,
      p_stock => 1,
      p_categoria => 'Smoke',
      p_codigo_barras => v_barcode
    );
    raise exception 'Duplicate active barcode was accepted';
  exception
    when unique_violation then
      null;
  end;

  -- Correct-version update.
  select *
  into v_updated
  from public.update_product(
    p_product_id => v_product_a.id,
    p_expected_version => v_product_a.version,
    p_nombre => 'Smoke Product A Updated',
    p_precio => 11.25,
    p_stock => 4,
    p_categoria => 'Smoke Updated',
    p_codigo_barras => v_barcode
  );

  if v_updated.version <> v_product_a.version + 1
     or v_updated.nombre <> 'Smoke Product A Updated' then
    raise exception 'Correct-version update failed';
  end if;

  -- Stale-version rejection.
  begin
    perform public.update_product(
      p_product_id => v_product_a.id,
      p_expected_version => v_product_a.version,
      p_nombre => 'Stale Update',
      p_precio => 99,
      p_stock => 1,
      p_categoria => 'Smoke',
      p_codigo_barras => v_barcode
    );
    raise exception using
      errcode = 'P0099',
      message = 'Stale version was accepted';
  exception
    when sqlstate 'P0001' then
      null;
  end;

  -- Archive.
  select *
  into v_archived
  from public.archive_product(
    p_product_id => v_product_a.id,
    p_expected_version => v_updated.version
  );

  if v_archived.activo then
    raise exception 'Product archive failed';
  end if;

  -- Products for the multi-item sale.
  select *
  into v_product_b
  from public.create_product(
    p_business_id => v_business_id,
    p_nombre => 'Smoke Product B',
    p_precio => 5,
    p_stock => 5,
    p_categoria => 'Smoke',
    p_codigo_barras => null
  );

  select *
  into v_product_c
  from public.create_product(
    p_business_id => v_business_id,
    p_nombre => 'Smoke Product C',
    p_precio => 3,
    p_stock => 3,
    p_categoria => 'Smoke',
    p_codigo_barras => null
  );

  -- Successful multi-item sale and stock reduction.
  select *
  into v_receipt
  from public.create_sale(
    p_business_id => v_business_id,
    p_client_operation_id => '11111111-1111-4111-8111-111111111111'::uuid,
    p_items => jsonb_build_array(
      jsonb_build_object('product_id', v_product_b.id, 'cantidad', 2),
      jsonb_build_object('product_id', v_product_c.id, 'cantidad', 1)
    )
  );

  if v_receipt.sale_id is null
     or cardinality(v_receipt.item_ids) <> 2
     or v_receipt.replayed then
    raise exception 'Successful multi-item sale failed';
  end if;

  select stock into v_stock_b
  from public.products
  where id = v_product_b.id;

  select stock into v_stock_c
  from public.products
  where id = v_product_c.id;

  if v_stock_b <> 3 or v_stock_c <> 2 then
    raise exception 'Stock reduction failed';
  end if;

  select count(*)
  into v_history_count
  from public.sale_history
  where sale_id = v_receipt.sale_id;

  if v_history_count <> 2 then
    raise exception 'sale_history is not one row per sale item';
  end if;

  -- Insufficient-stock rollback. Neither the second product nor sales may
  -- change when the first validation fails.
  select count(*)
  into v_sales_before
  from public.sales
  where business_id = v_business_id;

  begin
    perform public.create_sale(
      p_business_id => v_business_id,
      p_client_operation_id => '22222222-2222-4222-8222-222222222222'::uuid,
      p_items => jsonb_build_array(
        jsonb_build_object('product_id', v_product_b.id, 'cantidad', 99),
        jsonb_build_object('product_id', v_product_c.id, 'cantidad', 1)
      )
    );
    raise exception 'Insufficient stock was accepted';
  exception
    when sqlstate 'P0004' then
      null;
  end;

  select stock into v_stock_b_after
  from public.products
  where id = v_product_b.id;

  select stock into v_stock_c_after
  from public.products
  where id = v_product_c.id;

  select count(*)
  into v_sales_after
  from public.sales
  where business_id = v_business_id;

  if v_stock_b_after <> v_stock_b
     or v_stock_c_after <> v_stock_c
     or v_sales_after <> v_sales_before then
    raise exception 'Insufficient-stock sale was not rolled back';
  end if;

  -- Idempotent retry: same operation ID and canonical payload returns the
  -- original sale without another stock decrement.
  select *
  into v_retry
  from public.create_sale(
    p_business_id => v_business_id,
    p_client_operation_id => '11111111-1111-4111-8111-111111111111'::uuid,
    p_items => jsonb_build_array(
      jsonb_build_object('product_id', v_product_b.id, 'cantidad', 2),
      jsonb_build_object('product_id', v_product_c.id, 'cantidad', 1)
    )
  );

  if v_retry.sale_id <> v_receipt.sale_id
     or not v_retry.replayed then
    raise exception 'Idempotent retry failed';
  end if;

  select stock into v_stock_b_after
  from public.products
  where id = v_product_b.id;

  if v_stock_b_after <> v_stock_b then
    raise exception 'Idempotent retry changed stock';
  end if;

  -- Same operation ID with a different effective payload must be rejected.
  begin
    perform public.create_sale(
      p_business_id => v_business_id,
      p_client_operation_id => '11111111-1111-4111-8111-111111111111'::uuid,
      p_items => jsonb_build_array(
        jsonb_build_object('product_id', v_product_b.id, 'cantidad', 1),
        jsonb_build_object('product_id', v_product_c.id, 'cantidad', 1)
      )
    );
    raise exception using
      errcode = 'P0099',
      message = 'Different payload reused the operation ID';
  exception
    when sqlstate 'P0001' then
      null;
  end;
end;
$smoke$;

rollback;

-- Concurrent same-operation verification requires two independent
-- authenticated sessions. Do not run both calls in one SQL editor session.
-- Use a staging product in the seeded business with stock = 1 (or greater),
-- record its ID and initial stock, and use this fixed operation ID:
--   33333333-3333-4333-8333-333333333333
--
-- Session A:
--   begin;
--   select * from public.create_sale(
--     '00000000-0000-4000-8000-000000000001'::uuid,
--     '33333333-3333-4333-8333-333333333333'::uuid,
--     jsonb_build_array(jsonb_build_object(
--       'product_id', <PRODUCT_ID>::bigint,
--       'cantidad', 1
--     ))
--   );
--   -- Keep this transaction open after recording sale_id and replayed=false.
--
-- Before Session A commits, Session B (a separate authenticated connection):
--   select * from public.create_sale(
--     '00000000-0000-4000-8000-000000000001'::uuid,
--     '33333333-3333-4333-8333-333333333333'::uuid,
--     jsonb_build_array(jsonb_build_object(
--       'product_id', <PRODUCT_ID>::bigint,
--       'cantidad', 1
--     ))
--   );
--   -- This call must wait on the transaction-scoped advisory lock.
--
-- Session A:
--   commit;
--
-- Session B must then return the same sale_id, replayed=true, and the same
-- item ID(s). Verify, in an authenticated session, that the operation created
-- exactly one sale and reduced stock exactly once:
--   select count(*)
--   from public.sales
--   where business_id = '00000000-0000-4000-8000-000000000001'::uuid
--     and client_operation_id =
--       '33333333-3333-4333-8333-333333333333'::uuid;
--   -- Expected: 1
--   select stock
--   from public.products
--   where id = <PRODUCT_ID>::bigint;
--   -- Expected: recorded initial stock - 1
--
-- Reuse the same operation ID with a different item quantity after Session A
-- commits. It must be rejected with SQLSTATE P0001, even if stock is low:
--   select * from public.create_sale(
--     '00000000-0000-4000-8000-000000000001'::uuid,
--     '33333333-3333-4333-8333-333333333333'::uuid,
--     jsonb_build_array(jsonb_build_object(
--       'product_id', <PRODUCT_ID>::bigint,
--       'cantidad', 2
--     ))
--   );
--
-- The lock key is business_id + client_operation_id. Calls with different
-- operation IDs do not wait for one another, except for a theoretical 64-bit
-- hash collision; product row locks remain in ascending product ID order.

-- Access-isolation verification requires two authenticated sessions and two
-- business memberships. It is intentionally documented rather than run by
-- this rollback-only block:
--
-- Session A (user A, member of the seeded business):
--   select id, business_id, nombre from public.products;
--   -- Must return only active products in the seeded business.
--
-- In a staging database, create user B through Supabase Auth. The trigger will
-- initially add B to the default business. As the database owner in the SQL
-- editor, create a second business and move B only to that business:
--
--   insert into public.businesses (id, nombre)
--   values ('00000000-0000-4000-8000-000000000002', 'Smoke Business B');
--   delete from public.business_members
--   where user_id = '<USER_B_UUID>'::uuid
--     and business_id = '00000000-0000-4000-8000-000000000001'::uuid;
--   insert into public.business_members (business_id, user_id, role)
--   values (
--     '00000000-0000-4000-8000-000000000002'::uuid,
--     '<USER_B_UUID>'::uuid,
--     'operator'
--   );
--
-- Session B (user B, member only of Smoke Business B):
--   select id, business_id, nombre from public.products;
--   -- Must not see Session A's products.
--   select * from public.create_product(
--     '00000000-0000-4000-8000-000000000001'::uuid,
--     'Should Fail',
--     1,
--     1,
--     'Isolation',
--     null
--   );
--   -- Must fail with SQLSTATE 42501.
--
-- Session A must likewise receive 42501 when it calls an RPC using business
-- ID 00000000-0000-4000-8000-000000000002.
-- Run these checks through authenticated sessions, never as an anonymous
-- client and never by embedding any privileged server credential.
