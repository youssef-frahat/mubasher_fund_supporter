# 📋 Trading System Development & Portfolio Strategy Plan
> **Filename**: `trading_development_plan.md`  
> **Path**: `assets/docs/`  
> **Role**: Product Manager & Business Analyst Specification Document  
> **Status**: Strategic Blueprint for Future Implementation  

---

## 🎯 1. Executive Summary

Transforming **Watheqa** from an exploration & simulation platform into a full-fledged **Real Mutual Funds Trading Engine**, enabling Egyptian investors to place real BUY/SELL orders, manage real cash wallets, and complete KYC verification under full Admin/Broker supervision.

---

## 🔐 2. KYC & Subscription Engine

### Requirements:
1. **Active Paid Subscription (`is_subscribed = true`)**: Only subscribed users can place real trading orders.
2. **KYC Verification (`kyc_status = 'approved'`)**:
   - Upload National ID (Front & Back).
   - Complete personal, employment, and income details.
   - **Digital E-Signature Contract** for terms and regulatory approvals.

---

## ⚙️ 3. Order Lifecycle Engine & Resource Locking

| Order Status | Description & Resource Lock Rules | Permissions |
| :--- | :--- | :--- |
| **`PENDING`** | Order created by user; waiting for admin review. | User/Admin can edit or cancel. |
| **`ACCEPTED`** | **Resource Lock Active**: Cash locked for BUY orders, Units locked for SELL orders. | **Locked for User**. Only Admin can edit or cancel. |
| **`AMENDED`** | Order modified by Admin with `amended_by` audit trail. | Admin only. |
| **`REJECTED`** | Order rejected with reason. **Resource Lock Released Immediately**. | Read-only. |
| **`APPROVED`** | Final verification for execution with fund manager. | Admin only. |
| **`COMPLETED`** | Final settlement: Cash/Units deducted & real portfolio updated. | Completed State. |

---

## ⏱️ 4. Settlement & Cut-off Rules

- **Settlement Tags**: `T+0`, `T+1`, `T+2`, `T+5`.
- **Order Timing**: Users can place orders 24/7. Execution aligns with prospectus Cut-off times.

---

## 💳 5. Real Cash Wallet

- **Wallet Balances**: Available Balance vs. Reserved Balance.
- **Payment Methods**: InstaPay, Bank Transfer, Vodafone Cash, Cards.

---

## 🖥️ 6. Admin Broker Dashboard

- Live Real-time Order Queue & Status Actions (Accept & Lock, Reject with Reason, Amend, Complete).
- Wallet Deposit Receipts Approval & Withdrawal Processing.

---

## 📌 7. Execution Note
This document is safely stored in `assets/docs/trading_development_plan.md` as a blueprint and will only be implemented upon your explicit instruction.
