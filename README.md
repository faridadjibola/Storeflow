# StoreFlow

Internal sales, inventory, expenses, and daily-closing workspace for authorized store staff. There is no customer portal or customer login.

## Current release

- React + TypeScript + Vite + Tailwind CSS web app
- Express + TypeScript REST API
- Prisma + PostgreSQL normalized data model
- HTTP-only cookie sessions with bcrypt password hashing
- Manager/staff role enforcement in the API and role-aware navigation in the web app
- Prisma migrations, seed data, Prettier, and Vitest business tests

See [ARCHITECTURE.md](ARCHITECTURE.md) for the schema relationships, business flows, API plan, and consistency controls.

## Local development prerequisites

Install Node.js 20 or newer (npm included) and use a PostgreSQL database. For production, use a managed PostgreSQL provider and never use `db push` or the seed script.

## Run locally

```powershell
npm install
npm run db:generate
npm run db:push
npm run db:seed
npm run dev
```

Web: `http://localhost:5173`  
API health: `http://localhost:4000/api/health`

Seed accounts use the fictional password `ChangeMe123!` and should be changed for any shared environment:

- Manager: `manager@storeflow.local`
- Staff: `staff@storeflow.local`

## Deployment

Deploy PostgreSQL through a managed provider, the API as a Node.js service, and the web app as a static site. Keep production environment variables in the hosting provider and out of source control.

For Supabase, use its pooled connection string for `DATABASE_URL` and its direct database connection string for `DIRECT_URL`. The pooled URL is for serverless API requests; the direct URL is for Prisma migrations.

### Vercel deployment

Use two Vercel projects from this repository:

- API project: repository root. Vercel uses `api/index.ts` and `vercel.json` automatically.
- Web project: set the project root to `apps/web`, use `npm run build`, and publish `dist`.

Deploy the API project first, then set the web project's `VITE_API_URL` to its public URL. Configure `DATABASE_URL`, `DIRECT_URL`, `SESSION_SECRET`, `WEB_ORIGIN`, and `NODE_ENV=production` in the API project. Configure `VITE_API_URL` in the web project. Run `npm run db:migrate:deploy` against the hosted database before the first release.

### API service

- Build command: `npm run db:generate && npm run build`
- Start command: `npm run start`
- Health check: `/api/ready`
- Required variables: `DATABASE_URL`, `DIRECT_URL`, `SESSION_SECRET`, `WEB_ORIGIN`, and `NODE_ENV=production`
- Set `API_PORT` only when the provider does not supply its port through the environment.

Run migrations once during each release, before starting the new API version:

```powershell
npm run db:migrate:deploy
```

### Web service

- Build command: `npm run build -w @storeflow/web`
- Publish directory: `apps/web/dist`
- Build variable: `VITE_API_URL`, set to the public API origin

Serve `apps/web/dist` with SPA fallback to `index.html`, and use HTTPS for both services. Set `WEB_ORIGIN` to the exact web origin. The API uses secure HTTP-only cookies in production, so cross-origin deployments must allow credentials and use the exact origins shown above.

Production deployments use `prisma migrate deploy`; schema changes must be reviewed and committed as migrations. The seed script is for local development only and must not run in production.

## Quality gates

```powershell
npm run db:generate
npm run test
npm run build
```

The repository currently has unit/business-rule coverage. Run API integration tests against a staging PostgreSQL database before a live release.

## Planned phases

Phase 2 adds product and inventory workflows. Phase 3 adds transactional sales and payment flows. Orders, expenses, reporting, daily closing, and administration follow in the phases described in [ARCHITECTURE.md](ARCHITECTURE.md).
