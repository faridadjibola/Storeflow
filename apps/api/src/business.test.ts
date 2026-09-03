import { describe, expect, it } from 'vitest';
import { Prisma } from '@prisma/client';
import { assertOrderTransition, assertSufficientStock, calculateSale, paymentStatus } from './business';

const decimal = (value: number) => new Prisma.Decimal(value);

describe('sale calculations', () => {
  it('calculates subtotal, discount, COGS, and gross profit with Decimal values', () => {
    const result = calculateSale([{ quantity: 2, unitSellingPrice: decimal(85000), unitCostPrice: decimal(65000) }, { quantity: 3, unitSellingPrice: decimal(15000), unitCostPrice: decimal(12000) }], decimal(5000));
    expect(result.subtotal.toString()).toBe('215000');
    expect(result.total.toString()).toBe('210000');
    expect(result.cogs.toString()).toBe('166000');
    expect(result.grossProfit.toString()).toBe('44000');
  });

  it('rejects a discount larger than subtotal', () => {
    expect(() => calculateSale([{ quantity: 1, unitSellingPrice: decimal(100), unitCostPrice: decimal(60) }], decimal(101))).toThrow('Discount cannot exceed');
  });
});

describe('inventory and payments', () => {
  it('rejects insufficient or invalid stock quantities', () => {
    expect(() => assertSufficientStock(2, 3)).toThrow('Insufficient stock');
    expect(() => assertSufficientStock(2, 0)).toThrow('Insufficient stock');
  });

  it('classifies unpaid, partial, and paid balances', () => {
    expect(paymentStatus(decimal(100), decimal(0))).toBe('UNPAID');
    expect(paymentStatus(decimal(100), decimal(40))).toBe('PARTIALLY_PAID');
    expect(paymentStatus(decimal(100), decimal(100))).toBe('PAID');
    expect(() => paymentStatus(decimal(100), decimal(101))).toThrow('Payment exceeds');
  });
});

describe('order transitions', () => {
  it('allows the controlled fulfilment path', () => {
    expect(() => assertOrderTransition('PENDING', 'CONFIRMED')).not.toThrow();
    expect(() => assertOrderTransition('READY', 'COMPLETED')).not.toThrow();
  });

  it('rejects backwards or terminal-state changes', () => {
    expect(() => assertOrderTransition('PROCESSING', 'PENDING')).toThrow('not permitted');
    expect(() => assertOrderTransition('COMPLETED', 'CANCELLED')).toThrow('not permitted');
  });
});
