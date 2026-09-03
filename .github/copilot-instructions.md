# StoreFlow project instructions

- Keep customer access out of the system; only manager and staff users authenticate.
- Keep financial calculations and authorization on the API.
- Use Prisma Decimal/PostgreSQL numeric fields for money.
- Use compensating reversals and soft archive/disable behavior instead of deleting history.
- Run the focused workspace test/build command after changes when Node.js is available.
