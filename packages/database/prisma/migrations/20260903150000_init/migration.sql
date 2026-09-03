-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateEnum
CREATE TYPE "Role" AS ENUM ('MANAGER', 'STAFF');
CREATE TYPE "PaymentMethod" AS ENUM ('CASH', 'POS_CARD', 'BANK_TRANSFER', 'OTHER');
CREATE TYPE "PaymentStatus" AS ENUM ('UNPAID', 'PARTIALLY_PAID', 'PAID', 'REFUNDED');
CREATE TYPE "SaleStatus" AS ENUM ('COMPLETED', 'REVERSED');
CREATE TYPE "OrderStatus" AS ENUM ('PENDING', 'CONFIRMED', 'PROCESSING', 'READY', 'COMPLETED', 'CANCELLED');
CREATE TYPE "InventoryAdjustmentType" AS ENUM ('SALE', 'STOCK_ADDED', 'STOCK_REMOVED', 'CORRECTION', 'DAMAGED', 'RETURNED', 'OTHER', 'REVERSAL');
CREATE TYPE "AuditAction" AS ENUM ('LOGIN', 'LOGOUT', 'SALE_CREATED', 'SALE_REVERSED', 'PRODUCT_CREATED', 'PRODUCT_UPDATED', 'PRODUCT_ARCHIVED', 'INVENTORY_ADJUSTED', 'EXPENSE_CREATED', 'EXPENSE_UPDATED', 'ORDER_CREATED', 'ORDER_STATUS_CHANGED', 'DAILY_CLOSING', 'USER_CREATED', 'USER_DISABLED', 'SETTINGS_CHANGED');

CREATE TABLE "User" (
  "id" TEXT NOT NULL, "email" TEXT NOT NULL, "name" TEXT NOT NULL, "passwordHash" TEXT NOT NULL,
  "role" "Role" NOT NULL DEFAULT 'STAFF', "isActive" BOOLEAN NOT NULL DEFAULT true,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "Session" (
  "id" TEXT NOT NULL, "userId" TEXT NOT NULL, "expiresAt" TIMESTAMP(3) NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, CONSTRAINT "Session_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "Category" (
  "id" TEXT NOT NULL, "name" TEXT NOT NULL, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "Category_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "Product" (
  "id" TEXT NOT NULL, "name" TEXT NOT NULL, "sku" TEXT NOT NULL, "description" TEXT,
  "costPrice" DECIMAL(14,2) NOT NULL, "sellingPrice" DECIMAL(14,2) NOT NULL,
  "currentStock" INTEGER NOT NULL DEFAULT 0, "minimumStock" INTEGER NOT NULL DEFAULT 0,
  "unit" TEXT NOT NULL DEFAULT 'unit', "isActive" BOOLEAN NOT NULL DEFAULT true, "categoryId" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "Product_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "Sale" (
  "id" TEXT NOT NULL, "receiptNumber" SERIAL NOT NULL, "businessDate" DATE NOT NULL,
  "customerName" TEXT, "customerPhone" TEXT, "discount" DECIMAL(14,2) NOT NULL DEFAULT 0,
  "subtotal" DECIMAL(14,2) NOT NULL, "total" DECIMAL(14,2) NOT NULL,
  "status" "SaleStatus" NOT NULL DEFAULT 'COMPLETED', "notes" TEXT, "recordedById" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, CONSTRAINT "Sale_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "SaleItem" (
  "id" TEXT NOT NULL, "saleId" TEXT NOT NULL, "productId" TEXT NOT NULL, "quantity" INTEGER NOT NULL,
  "unitSellingPrice" DECIMAL(14,2) NOT NULL, "unitCostPrice" DECIMAL(14,2) NOT NULL,
  "subtotal" DECIMAL(14,2) NOT NULL, CONSTRAINT "SaleItem_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "Payment" (
  "id" TEXT NOT NULL, "amount" DECIMAL(14,2) NOT NULL, "method" "PaymentMethod" NOT NULL,
  "status" "PaymentStatus" NOT NULL DEFAULT 'PAID', "saleId" TEXT, "orderId" TEXT,
  "recordedById" TEXT NOT NULL, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "Payment_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "Order" (
  "id" TEXT NOT NULL, "orderNumber" SERIAL NOT NULL, "customerName" TEXT, "customerPhone" TEXT,
  "discount" DECIMAL(14,2) NOT NULL DEFAULT 0, "subtotal" DECIMAL(14,2) NOT NULL, "total" DECIMAL(14,2) NOT NULL,
  "paymentStatus" "PaymentStatus" NOT NULL DEFAULT 'UNPAID', "status" "OrderStatus" NOT NULL DEFAULT 'PENDING',
  "businessDate" DATE NOT NULL, "notes" TEXT, "createdById" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "Order_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "OrderItem" (
  "id" TEXT NOT NULL, "orderId" TEXT NOT NULL, "productId" TEXT NOT NULL, "quantity" INTEGER NOT NULL,
  "unitPrice" DECIMAL(14,2) NOT NULL, "subtotal" DECIMAL(14,2) NOT NULL,
  CONSTRAINT "OrderItem_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "ExpenseCategory" (
  "id" TEXT NOT NULL, "name" TEXT NOT NULL, "isActive" BOOLEAN NOT NULL DEFAULT true,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, CONSTRAINT "ExpenseCategory_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "Expense" (
  "id" TEXT NOT NULL, "businessDate" DATE NOT NULL, "description" TEXT NOT NULL,
  "amount" DECIMAL(14,2) NOT NULL, "paymentMethod" "PaymentMethod" NOT NULL, "notes" TEXT, "receiptUrl" TEXT,
  "categoryId" TEXT NOT NULL, "recordedById" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "Expense_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "InventoryTransaction" (
  "id" TEXT NOT NULL, "productId" TEXT NOT NULL, "previousQuantity" INTEGER NOT NULL,
  "adjustmentQuantity" INTEGER NOT NULL, "newQuantity" INTEGER NOT NULL, "type" "InventoryAdjustmentType" NOT NULL,
  "reason" TEXT NOT NULL, "userId" TEXT NOT NULL, "saleId" TEXT, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "InventoryTransaction_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "DailyClosing" (
  "id" TEXT NOT NULL, "businessDate" DATE NOT NULL, "closedById" TEXT NOT NULL,
  "closedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, CONSTRAINT "DailyClosing_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "AuditLog" (
  "id" TEXT NOT NULL, "action" "AuditAction" NOT NULL, "entity" TEXT NOT NULL, "entityId" TEXT,
  "details" JSONB, "userId" TEXT, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "AuditLog_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "User_email_key" ON "User"("email");
CREATE INDEX "Session_userId_idx" ON "Session"("userId"); CREATE INDEX "Session_expiresAt_idx" ON "Session"("expiresAt");
CREATE UNIQUE INDEX "Category_name_key" ON "Category"("name");
CREATE UNIQUE INDEX "Product_sku_key" ON "Product"("sku"); CREATE INDEX "Product_name_idx" ON "Product"("name"); CREATE INDEX "Product_categoryId_idx" ON "Product"("categoryId");
CREATE UNIQUE INDEX "Sale_receiptNumber_key" ON "Sale"("receiptNumber"); CREATE INDEX "Sale_businessDate_idx" ON "Sale"("businessDate"); CREATE INDEX "Sale_recordedById_idx" ON "Sale"("recordedById");
CREATE INDEX "SaleItem_productId_idx" ON "SaleItem"("productId");
CREATE INDEX "Payment_saleId_idx" ON "Payment"("saleId"); CREATE INDEX "Payment_orderId_idx" ON "Payment"("orderId"); CREATE INDEX "Payment_createdAt_idx" ON "Payment"("createdAt");
CREATE UNIQUE INDEX "Order_orderNumber_key" ON "Order"("orderNumber"); CREATE INDEX "Order_businessDate_idx" ON "Order"("businessDate"); CREATE INDEX "Order_status_idx" ON "Order"("status");
CREATE INDEX "OrderItem_productId_idx" ON "OrderItem"("productId"); CREATE UNIQUE INDEX "ExpenseCategory_name_key" ON "ExpenseCategory"("name");
CREATE INDEX "Expense_businessDate_idx" ON "Expense"("businessDate"); CREATE INDEX "Expense_categoryId_idx" ON "Expense"("categoryId");
CREATE INDEX "InventoryTransaction_productId_createdAt_idx" ON "InventoryTransaction"("productId", "createdAt"); CREATE INDEX "InventoryTransaction_saleId_idx" ON "InventoryTransaction"("saleId");
CREATE UNIQUE INDEX "DailyClosing_businessDate_key" ON "DailyClosing"("businessDate"); CREATE INDEX "AuditLog_createdAt_idx" ON "AuditLog"("createdAt"); CREATE INDEX "AuditLog_action_idx" ON "AuditLog"("action"); CREATE INDEX "AuditLog_entity_entityId_idx" ON "AuditLog"("entity", "entityId");

ALTER TABLE "Session" ADD CONSTRAINT "Session_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Product" ADD CONSTRAINT "Product_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "Category"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "Sale" ADD CONSTRAINT "Sale_recordedById_fkey" FOREIGN KEY ("recordedById") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "SaleItem" ADD CONSTRAINT "SaleItem_saleId_fkey" FOREIGN KEY ("saleId") REFERENCES "Sale"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "SaleItem" ADD CONSTRAINT "SaleItem_productId_fkey" FOREIGN KEY ("productId") REFERENCES "Product"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "Payment" ADD CONSTRAINT "Payment_saleId_fkey" FOREIGN KEY ("saleId") REFERENCES "Sale"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "Payment" ADD CONSTRAINT "Payment_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "Order"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "Payment" ADD CONSTRAINT "Payment_recordedById_fkey" FOREIGN KEY ("recordedById") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "Order" ADD CONSTRAINT "Order_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "OrderItem" ADD CONSTRAINT "OrderItem_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "Order"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "OrderItem" ADD CONSTRAINT "OrderItem_productId_fkey" FOREIGN KEY ("productId") REFERENCES "Product"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "Expense" ADD CONSTRAINT "Expense_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "ExpenseCategory"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "Expense" ADD CONSTRAINT "Expense_recordedById_fkey" FOREIGN KEY ("recordedById") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "InventoryTransaction" ADD CONSTRAINT "InventoryTransaction_productId_fkey" FOREIGN KEY ("productId") REFERENCES "Product"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "InventoryTransaction" ADD CONSTRAINT "InventoryTransaction_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "DailyClosing" ADD CONSTRAINT "DailyClosing_closedById_fkey" FOREIGN KEY ("closedById") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "AuditLog" ADD CONSTRAINT "AuditLog_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
