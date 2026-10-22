# Spec-First Specification — ABC Software Corp Electronic Invoicing System

> Midterm exam — Software Architecture (UNAS, FIIS) — Group "A"
> Phase 1: **technical specification skeleton** (no business logic implemented).

## 1. Context

ABC Software Corp sells groceries and general merchandise, wholesale and retail. It currently runs a basic warehouse application
whose records hold `fecha` (date), `ingreso` (inbound qty), `salida` (outbound qty), `producto` (product) and `nro_documento`
(an informal internal document number). That system:

- does not validate RUC/DNI taxpayer IDs,
- does not compute taxes (IGV, ISC, ICBPER),
- does not generate digitally signed UBL 2.1 XML,
- does not communicate with an OSE (Electronic Services Operator) or with SUNAT.

The new system must comply with SUNAT's Electronic Issuance System (SEE). Following **Spec-First**, rules, data contracts,
validations and interfaces are defined first, using the `UBL-Invoice-2.1.xsd` schema (OASIS) **in its Peruvian customization
(UBL 2.1 Peru, SUNAT structure 2.0)** as the source.

## 2. Regulatory and technical basis

| Code | Source | What it contributes to the specification |
| :--- | :--- | :--- |
| N-01 | SUNAT Resolution No. 097-2012/SUNAT and amendments | Creates the SEE from the taxpayer's own systems (SEE-Del Contribuyente): issuing invoices, sales receipts and notes as signed XML, submission to SUNAT or an OSE, CDR (acceptance receipt). |
| N-02 | SUNAT Resolution No. 234-2006/SUNAT and amendments | Tax-related books and records: Sales Register and Permanent Inventory Register (destination of the migrated warehouse data). |
| N-03 | SUNAT Resolution No. 117-2017/SUNAT (OSE) | Electronic Services Operator that validates documents on SUNAT's behalf. |
| N-04 | Annex No. 8 — SUNAT code catalogs | Catalogs 01, 02, 03, 05, 06, 07, **08**, 09, 10, 16, 51, 52, etc. |
| N-05 | **UBL 2.1 Peru**: SUNAT "Guide for building UBL 2.1 XML documents" (structure 2.0) and SUNAT validation rules | Peruvian customization of the standard: mandatory elements, `PE:SUNAT` attributes, catalog URIs, formats (`an..13`, `n(12,2)`), file naming and error/observation codes. |
| T-01 | OASIS UBL 2.1 — `UBL-Invoice-2.1.xsd` (+ `UBL-CreditNote-2.1.xsd`, `UBL-DebitNote-2.1.xsd`) | Base structure and cardinality. SUNAT does not change the XSD: it restricts it through N-05. |
| T-02 | W3C XML-DSig | Digital signature of the XML (`ext:UBLExtensions/.../ds:Signature`). |

### Peruvian terms kept in Spanish

| Term | Meaning |
| :--- | :--- |
| SUNAT | Peru's National Customs and Tax Administration |
| RUC / DNI | Taxpayer ID (11 digits) / National ID card (8 digits) |
| Factura / Boleta | Invoice (B2B, catalog code `01`) / Sales receipt (B2C, code `03`) |
| IGV | General Sales Tax (VAT, 18 %) |
| ISC | Selective Consumption Tax (excise: beer, liquor, soft drinks, tobacco) |
| ICBPER | Plastic Bag Consumption Tax |
| IVAP | Tax on sales of hulled rice |
| OSE | Electronic Services Operator authorized by SUNAT |
| CDR | *Constancia de Recepción* — SUNAT/OSE acceptance receipt (`ApplicationResponse`) |
| SOL | SUNAT Online credentials |
| Kardex | Inventory ledger (Permanent Inventory Register) |

## 3. Deliverables and cross-document traceability

| # | Required deliverable | File |
| :--- | :--- | :--- |
| 1 | Domain Model and Contracts (DTOs / Schemas) | [01_MODELO_DE_DOMINIO.md](01_MODELO_DE_DOMINIO.md) |
| 2 | MVC Architecture Diagrams with a Hexagonal vision | [02_ARQUITECTURA.md](02_ARQUITECTURA.md) |
| 3 | Endpoint / Service Specification (API Contracts) | [../specs/03_CONTRATOS_API.yaml](../specs/03_CONTRATOS_API.yaml) (OpenAPI 3.0.3) |
| 4 | Regulatory Traceability Matrix SUNAT ↔ UBL | [04_MATRIZ_TRAZABILIDAD.md](04_MATRIZ_TRAZABILIDAD.md) |
| — | Use cases (section 3 of the assignment) | [05_CASOS_DE_USO.md](05_CASOS_DE_USO.md) |
| — | Sample UBL 2.1 Peru XML (invoice) | [../specs/ejemplos/20123456786-01-F001-1.xml](../specs/ejemplos/20123456786-01-F001-1.xml) |

Identifier conventions used across all documents:

- `UC-xx`: use case — `BR-xx`: business / validation rule — `N-xx`: regulation — `EP-xx`: endpoint — `ARCH-xx`: architecture rule.
- Every `BR` appears in the domain model (where it is enforced), in the API contract (which error it returns) and in the matrix (which regulation / UBL element it comes from).

## 4. Architectural constraints (summary)

| Constraint from the assignment | Decision | Details |
| :--- | :--- | :--- |
| Legacy and data migration | Migration module with batches, staging, reconciliation and a `legacyOrigin` stamp on every record | 01 §6, 02 §6, API `/migrations` |
| Peruvian tax regulations | SUNAT catalogs as validated *value objects*; IGV/ISC/ICBPER tax engine (catalogs 05, 07, **08**) | 01 §3–4, 04 |
| MVC monolith today, Hexagonal/microservices tomorrow | Modular MVC monolith whose Model is already organized as ports and adapters | 02 §2–5 |
| Native Windows + Android, MSI and APK | Kotlin Multiplatform + Compose Multiplatform (shared UI), `packageMsi` and signed APK | 02 §7 |
