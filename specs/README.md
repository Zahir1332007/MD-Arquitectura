# Specs (Spec-First)

Formal specifications written **prior to** any line of business logic implementation. The documents in `docs/` explain the design;
these files define the technical contracts that the implementation must satisfy and from which tests and code are generated.

| Folder / File | What it specifies | Format | Purpose |
| :--- | :--- | :--- | :--- |
| [03_CONTRATOS_API.yaml](03_CONTRATOS_API.yaml) | Endpoints, DTOs, errors and SUNAT/OSE services, with `x-ubl` / `x-sunat` annotations per field | OpenAPI 3.0.3 | Generate controllers/clients and validate requests |
| [ejemplos/20123456786-01-F001-1.xml](ejemplos/20123456786-01-F001-1.xml) | Reference sample invoice in UBL 2.1 Peru | XML | Conformance testing for UBL XML generator |

## Rules → Specs Matrix

| Rule | Description | API Contract | Traceability Matrix |
| :--- | :--- | :--- | :--- |
| RN-01, RN-02 | RUC / customer document validation | `ClienteDto`, EP-09 | E01, R01 |
| RN-03, RN-04 | Series and sequence numbering | `serie`, `correlativo` | T03 |
| RN-05 | Issue date constraints | `fechaEmision` | T04 |
| RN-06 | Mandatory customer identification | `cliente` | R01, R02 |
| RN-07 | Tax calculations (IGV, ISC Cat. 08, ICBPER) | `ProductoDto.isc`, `TributoDto` | X01–X08 |
| RN-08 | Monetary totals calculation | `TotalesDto` | M01–M06, X09 |
| RN-09 | Currency & exchange rate | `tipoCambio` | T10 |
| RN-10 | Payment terms & installment schedule | `FormaPagoDto` | T06, T14 |
| RN-11 | UBL 2.1 Peru XML schema validation | UBL generator | T01, T02, T12 + `ejemplos/` |
| RN-12 | Immutability, credit/debit notes, baja | EP-05, EP-06 | §4.7 |
| RN-13 | Legacy data migration & reconciliation | EP-13..EP-15 | §4.6 |

## Suggested Implementation Sequence (Next Phase)

1. Value objects for SUNAT catalogs → pass format validation tests for `RN-01..RN-06`.
2. Tax computation engine → pass `RN-07` and `RN-08` calculation tests.
3. UBL XML generator + XSD validation → generated XML must match `ejemplos/20123456786-01-F001-1.xml`.
4. Output adapters (repositories, OSE/SUNAT gateway, digital signature).
5. Legacy migration ETL pipeline.
