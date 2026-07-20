# Kaisen Supabase foundation

This directory contains only the Phase 1 database foundation. It is not a
Flutter integration and it has not been executed or deployed by this task.

## Files

Apply the migrations in this order, after review:

1. migrations/001_identity_and_business.sql
2. migrations/002_products.sql
3. migrations/003_sales.sql
4. migrations/004_rls_and_grants.sql
5. migrations/005_rpc_products.sql
6. migrations/006_rpc_create_sale.sql

SMOKE_TEST.sql is a rollback-only verification script. It is not a migration.

The migrations intentionally have no destructive down migrations.

## Applying manually

No Supabase CLI or automatic deployment is part of this phase. When the plan is
approved, a maintainer may paste each file into the Supabase Dashboard SQL
Editor in the order above, or apply it through the team's separately reviewed
SQL process.

Before applying:

- Confirm the target project and environment.
- Take the normal project backup/export.
- Confirm that the migration directory is still in the expected order.
- Review the SQL and smoke test in a staging project first.
- Do not paste secrets into these files.

Do not run these files from Flutter. No service credential belongs in a
Flutter-facing artifact.

## Seeded business

The default business ID is:

    00000000-0000-4000-8000-000000000001

Migration 001 inserts the Kaisen business if it does not already exist. It also
creates an AFTER INSERT trigger on auth.users. For every new Auth user, the
trigger creates:

- public.profiles with username and username_normalized;
- public.business_members membership in the default business with role
  operator.

Flutter will later retain its username/password UI and derive a deterministic
internal email alias from the username. It should also send the visible
username in raw_user_meta_data.username during Auth signup. The database
fallback uses the alias prefix or Auth user ID so the profile invariant remains
valid if metadata is absent.

This phase does not create an Edge Function and does not decide the final alias
normalization/domain. That decision must be fixed before Flutter Auth is wired.

## Security model

- RLS is enabled on profiles, businesses, business_members, products, sales and
  sale_items.
- API reads are granted only to authenticated and are filtered by membership.
- anon receives no table read access and no write-RPC execution.
- products, sales and sale_items have no client INSERT, UPDATE or DELETE
  policies or grants.
- Product writes use create_product, update_product and archive_product.
- Sales use create_sale only.
- All SECURITY DEFINER functions use SET search_path = '' and schema-qualified
  application objects.
- No function or file contains a service_role key.

The sale RPC locks product rows in ascending ID order, gets name/category/price
from products, inserts the sale and lines, decrements stock, and returns one
result for a client_operation_id. A retry with the same payload is replayed; a
different payload with that ID is rejected. A failure rolls back all writes.

After authentication and basic `client_operation_id` validation, and before the
fast-path sale lookup, the RPC acquires a transaction-scoped
`pg_catalog.pg_advisory_xact_lock` keyed by
`pg_catalog.hashtextextended(business_id::text || ':' || client_operation_id::text, 0)`.
Therefore, concurrent calls sharing both values are serialized: the second call
waits, then sees the committed sale and returns it as a replay instead of
rechecking stock as a new sale. Different operation IDs use different lock keys
and do not block one another except for a theoretical 64-bit hash collision.
The unique constraint and `unique_violation` fallback remain defense in depth.

## Running the smoke test later

SMOKE_TEST.sql starts a transaction, runs the product and sale assertions, and
rolls the test data back. It must run through an authenticated session whose
user belongs to the seeded business. A normal SQL Editor session commonly has
auth.uid() = NULL, so a maintainer must use an authenticated request/session
appropriate to the staging environment.

The smoke test covers:

- product creation and validation;
- negative price and duplicate active barcode rejection;
- optimistic-version update and stale-version rejection;
- archive;
- multi-item sale and stock reduction;
- insufficient-stock rollback;
- idempotent retry;
- concurrent identical calls with one sale, one stock decrement, and a replay;
- same operation ID with a different payload;
- sale_history line count.

The section after the rollback block documents the two-session concurrent
idempotency check. It requires two authenticated connections and a staging
product. The final section documents the two-session/two-business isolation
check. It requires a staging-only second business and a second authenticated user. Since
the signup trigger initially assigns every new user to the default business,
the comments show how a staging database owner can move the second user to the
second business before testing. Client roles must not perform those membership
administration statements.

## Explicitly out of scope

This phase does not:

- modify any Flutter file or dependency;
- modify SQLite or legacy_api;
- import or reconcile historical data;
- implement offline or bidirectional synchronization;
- create inventory_movements;
- remove the PHP backend;
- deploy or execute migrations automatically;

## Decisions still requiring review

1. The exact deterministic username-to-internal-email alias algorithm and
   non-deliverable domain.
2. How future business creation/invitations should work beyond the seeded
   single-business deployment.
3. Whether Flutter will keep sale_items.id as Venta.idRemoto or later expose
   sales.id as a separate sale-group field.
4. Whether SQLite remains a read-through cache after the cutover.
