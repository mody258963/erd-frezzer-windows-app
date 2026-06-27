# Flutter dev handoff — June 2026 (shop owner + cash boxes)

**Audience:** `erd_rezzer` Flutter team  
**Backend:** ERB-Frezzer `/api/v1`  
**Date:** June 2026

Single-page brief for what to build or change in the app **now**.

---

## ملخص سريع

| # | الموضوع | الحالة على الخادم | ماذا يفعل Flutter |
|---|---------|-------------------|-------------------|
| 1 | دفع المورد من الإجمالي (مجمّع) | **جاهز** | `GET /dashboard/payables/by-supplier` + `POST /suppliers/{id}/payments` |
| 2 | الأسبوع التجاري | **جاهز** | لا تحسب الأسبوع في Dart — استخدم `period.from` / `period.to` |
| 3 | تحصيل الآجل في درج اليوم | **جاهز** | بعد التحصيل: `GET /dashboard/cash?period=day` |
| 4 | دفع بين الفروع → صندوق النقد | **جاهز (جديد)** | حدّث صناديق النقد لكل فرع بعد `POST /branch-finance/payments` |

---

## Priority checklist (app status)

| Priority | Task | Status in `erd_rezzer` |
|----------|------|------------------------|
| **High** | Grouped supplier payables UI + lump-sum pay | Done — `SupplierPayablesScreen`, `PaySupplierDialog` |
| **High** | Refresh per-branch cash after inter-branch payment | Done — `BranchFinanceScreen` notifies `AppRefreshKind.dashboard` |
| **Medium** | Remove client-side week math; bind UI to API `period` | Done — `BusinessPeriod`, API `period` only |
| **Medium** | Refresh daily drawer after credit collection / settlement | Done — `AppRefreshKind.dashboard` on collect/settle/POS |
| **Low** | Payment edit/void on branch finance → refresh cash | Done — edit/void payment entries refresh dashboard |

---

## Business week

- Server: Monday **09:00** → Saturday **23:59:59**
- UI: **هذا الأسبوع (الإثنين 9 ص – السبت)**
- Never use `BusinessWeek.rangeFor()` — deprecated

---

## Cash boxes

Use `GET /dashboard/cash?period=day|week|month` with `period_*` fields:

- `cash_on_hand_realized` — snapshot
- `period_cash_in_realized` / `period_cash_out_realized` / `period_net_cash_flow_realized` — selected period

Cash out includes: supplier payments, refunds, owner cash-out, **inter-branch payments sent**.

Cash in includes: cash invoices, customer payments, settlements, **inter-branch payments received**.

---

## QA smoke tests

- [ ] Grouped payables + lump-sum pay
- [ ] Week tab uses API `period.from`–`period.to`
- [ ] Credit collection updates `period_cash_in_realized` (day)
- [ ] Inter-branch payment updates paying + receiving branch cash
- [ ] Void inter-branch payment reverses cash on both branches
