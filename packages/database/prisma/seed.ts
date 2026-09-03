import { PrismaClient, Role, PaymentMethod } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  const passwordHash = await bcrypt.hash('ChangeMe123!', 12);
  const manager = await prisma.user.upsert({ where: { email: 'manager@storeflow.local' }, update: {}, create: { email: 'manager@storeflow.local', name: 'Ada Manager', passwordHash, role: Role.MANAGER } });
  await prisma.user.upsert({ where: { email: 'staff@storeflow.local' }, update: {}, create: { email: 'staff@storeflow.local', name: 'Tunde Staff', passwordHash, role: Role.STAFF } });
  const groceries = await prisma.category.upsert({ where: { name: 'Groceries' }, update: {}, create: { name: 'Groceries' } });
  await prisma.category.upsert({ where: { name: 'Household' }, update: {}, create: { name: 'Household' } });
  await prisma.expenseCategory.upsert({ where: { name: 'Packaging' }, update: {}, create: { name: 'Packaging' } });
  await prisma.expenseCategory.upsert({ where: { name: 'Transportation' }, update: {}, create: { name: 'Transportation' } });
  await prisma.product.upsert({ where: { sku: 'RICE-25KG' }, update: {}, create: { name: 'Rice 25kg', sku: 'RICE-25KG', costPrice: 65000, sellingPrice: 85000, currentStock: 50, minimumStock: 10, unit: 'bag', categoryId: groceries.id } });
  await prisma.product.upsert({ where: { sku: 'OIL-5L' }, update: {}, create: { name: 'Cooking Oil 5L', sku: 'OIL-5L', costPrice: 12000, sellingPrice: 15000, currentStock: 8, minimumStock: 12, unit: 'bottle', categoryId: groceries.id } });
  await prisma.expense.create({ data: { businessDate: new Date(), description: 'Sample packaging supplies', amount: 18500, paymentMethod: PaymentMethod.CASH, category: { connect: { name: 'Packaging' } }, recordedBy: { connect: { id: manager.id } } } });
}

main().finally(() => prisma.$disconnect());
