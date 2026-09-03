import { Prisma } from '@prisma/client';

export type SaleLine = { quantity: number; unitSellingPrice: Prisma.Decimal; unitCostPrice: Prisma.Decimal };

export function calculateSale(lines: SaleLine[], discount: Prisma.Decimal) {
  const subtotal = lines.reduce((total, line) => total.add(line.unitSellingPrice.mul(line.quantity)), new Prisma.Decimal(0));
  if (discount.lt(0) || discount.gt(subtotal)) throw new Error('Discount cannot exceed the sale subtotal.');
  const cogs = lines.reduce((total, line) => total.add(line.unitCostPrice.mul(line.quantity)), new Prisma.Decimal(0));
  const total = subtotal.sub(discount);
  return { subtotal, discount, total, cogs, grossProfit: total.sub(cogs) };
}

export function assertSufficientStock(currentStock: number, quantity: number) {
  if (!Number.isInteger(currentStock) || !Number.isInteger(quantity) || quantity <= 0 || currentStock < quantity) throw new Error('Insufficient stock.');
}

export function paymentStatus(total: Prisma.Decimal, paid: Prisma.Decimal) {
  if (paid.lt(0) || paid.gt(total)) throw new Error('Payment exceeds the order balance.');
  if (paid.eq(0)) return 'UNPAID' as const;
  if (paid.gte(total)) return 'PAID' as const;
  return 'PARTIALLY_PAID' as const;
}

const allowedTransitions: Record<string, string[]> = { PENDING: ['CONFIRMED', 'CANCELLED'], CONFIRMED: ['PROCESSING', 'CANCELLED'], PROCESSING: ['READY', 'CANCELLED'], READY: ['COMPLETED', 'CANCELLED'], COMPLETED: [], CANCELLED: [] };
export function assertOrderTransition(from: string, to: string) {
  if (!allowedTransitions[from]?.includes(to)) throw new Error('That order status change is not permitted.');
}
