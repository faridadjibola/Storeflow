# StoreFlow architecture

## Boundaries

StoreFlow is an internal application. Only authenticated `MANAGER` and `STAFF` users exist; customer name and phone are optional fields on transactions and never become accounts.

The repository is an npm-workspaces monorepo:

- `apps/web`: React, Vite, Tailwind CSS, React Router, TanStack Query, React Hook Form, Zod, Recharts.
- `apps/api`: Express REST API, authentication, authorization, validation, and business services.
- `packages/database`: Prisma schema, client, and development seed.

The API is the authority for money, permissions, inventory, daily-close state, and report calculations. The browser only presents and submits validated data.

## Sales flow

`POST /api/sales` validates the request, verifies the user can sell, checks that the transaction date is not closed, and runs one PostgreSQL transaction. It locks and checks each product stock row, calculates line subtotals and the total with Decimal arithmetic, creates the sale and items, creates the payment, decrements stock, writes inventory transactions, and writes an audit event. Any failure rolls back every step, so a failed sale cannot alter inventory.

Reversals are compensating records, never deletes. They create a reversal audit event and inverse inventory/payment effects, subject to authorization and closed-day rules.

## Profit flow

For completed sales, revenue is the server-calculated total after discounts. COGS is the immutable cost snapshot on each sale item multiplied by quantity. Gross profit is revenue minus COGS. Net profit is gross profit minus operating expenses for the same business date range. Unpaid order balances do not inflate sales revenue; payments are tracked separately from completed-sale recognition.

## Daily closing

A manager reviews a server-generated summary, then `POST /api/daily-closing` creates a unique closing row for the business date inside a transaction and audits the actor. All financial mutations check for an existing closing row. Corrections after close must use an explicitly authorized reversal or adjustment workflow; historical rows are never deleted.

## Consistency risks and controls

- **Concurrent sales overselling stock:** product rows are locked during the sale transaction and quantities are checked before decrement.
- **Floating-point money drift:** PostgreSQL `Decimal(14,2)` and Prisma `Decimal` are used; no JavaScript floating-point totals are persisted.
- **Partial writes:** sales, payments, inventory effects, and audit events share one database transaction.
- **Changing historical cost/price:** sale items snapshot unit selling price and unit cost at sale time.
- **Editing closed days:** centralized `assertBusinessDateOpen` guards every financial mutation.
- **Soft deletion breaking history:** products and users are archived/disabled, not removed.
- **Unauthorized manager actions:** API middleware checks role on every protected route; UI visibility is only a convenience.
- **Ambiguous order revenue:** orders have independent payment/status fields and do not affect sales reports until a completed sale is recorded.
- **Refunds and returns:** represented by reversal/refund records and inverse inventory transactions, preserving the original event trail.

## Initial REST surface

- `POST /api/auth/login`, `POST /api/auth/logout`, `GET /api/auth/me`
- `GET /api/dashboard`
- `GET|POST /api/products`, `GET|PATCH /api/products/:id`, `POST /api/products/:id/stock-adjustment`
- `GET|POST /api/sales`, `GET /api/sales/:id`, `POST /api/sales/:id/reverse`
- `GET|POST|PATCH /api/orders`
- `GET|POST|PATCH /api/expenses`
- `GET /api/inventory`, `GET /api/inventory/history`
- `GET /api/reports/daily|weekly|monthly|custom`
- `GET|POST /api/daily-closing`
- `GET /api/audit-logs`
- Manager-only administration routes for users, categories, and settings.

## Web page structure

Protected routes use a shared app shell: Dashboard, Sales/New Sale, Sales History, Daily Sales, Orders, Products, Inventory, Stock History, Expenses, Reports, and Daily Closing. Manager-only routes are Users, Audit Logs, and Settings. Login is the only public page; there is no customer portal.
