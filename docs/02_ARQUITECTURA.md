# 2. MVC Architecture Diagrams with a Hexagonal Vision

## 1. System Context (C4 — Level 1)

```mermaid
flowchart LR
    U1([Salesperson / Cashier]) --> APP
    U2([Accountant / Administrator]) --> APP
    APP["ABC Invoicing System<br/>(MVC monolith — Windows / Android)"]
    APP -->|"signed UBL 2.1 Peru XML (SOAP)"| OSE[Authorized OSE]
    APP -->|"sendBill / sendSummary / getStatus"| SUNAT[SUNAT SEE]
    APP -->|"RUC query"| PADRON[SUNAT RUC Registry]
    LEG[(Legacy basic software<br/>fecha, ingreso, salida,<br/>producto, nro_documento)] -->|"export CSV / DB"| APP
    APP -->|"PDF + XML"| MAIL[Customer email]
```

## 2. Base Vision: Clean Monolith with the MVC Pattern

The monolith is **a single executable** per platform. MVC organizes user interaction; the "M" is not an anemic model
tied to the database, but a domain core with services and repositories accessed through interfaces.

```mermaid
flowchart TB
    subgraph V["VIEW (Compose Multiplatform)"]
        V1[EmisionView]
        V2[ComprobantesListView]
        V3[ClientesProductosView]
        V4[MigracionView]
    end
    subgraph C["CONTROLLER"]
        C1[ComprobanteController]
        C2[MaestrosController]
        C3[MigracionController]
    end
    subgraph M["MODEL"]
        direction TB
        S1["Application services<br/>EmitirComprobante, AnularComprobante,<br/>MigrarLote, ConsultarEstado"]
        D1["Domain<br/>ComprobantePago, Tributo, Serie,<br/>SUNAT Catalogs, Rules RN-01..RN-13"]
        R1["Interfaces<br/>ComprobanteRepository, FirmaDigital,<br/>EnvioSunatGateway, PadronRuc, LegacySource"]
        S1 --> D1
        S1 --> R1
    end
    subgraph I["INFRASTRUCTURE (implementations)"]
        I1[(Local SQLite — SQLDelight)]
        I2[XML-DSig .pfx Signer]
        I3[OSE / SUNAT SOAP Client]
        I4[Legacy CSV / DB Reader]
    end
    V -- "UI events / DTO" --> C
    C -- "DTO" --> S1
    S1 -- "Response DTO" --> C
    C -- "ViewState" --> V
    I1 -. implements .-> R1
    I2 -. implements .-> R1
    I3 -. implements .-> R1
    I4 -. implements .-> R1
```

**Rules that keep the MVC "clean" (and prepare it for Hexagonal):**

1. **Dependency rule**: View → Controller → Services → Domain. The domain does not import anything from UI, SQL, SOAP or frameworks.
2. **Controllers** only translate UI events ↔ DTOs; they do not contain tax rules.
3. All I/O (database, digital signing, SUNAT/OSE, RUC registry, legacy import) is accessed **via interfaces** declared in the Model and implemented in Infrastructure.
4. **Entities never leave** the Model: the View receives DTOs/ViewState.
5. One module per bounded context (`facturacion`, `maestros`, `inventario`, `migracion`); they communicate only through public interfaces or domain events (`ComprobanteAceptado`).

### Module Structure (Multiplatform Gradle)

```text
abc-facturacion/
├── core-domain/          # Entities, value objects, SUNAT catalogs, RN-xx (pure Kotlin, zero external dependencies)
├── core-application/     # Use cases + ports (interfaces)                 (pure Kotlin)
├── adapters-persistence/ # SQLDelight (SQLite) → ComprobanteRepository, ...
├── adapters-sunat/       # UBL generator, XSD validator, XML-DSig signer, OSE/SUNAT SOAP client
├── adapters-legacy/      # Legacy basic software readers (CSV / DB)
├── app-ui/               # Views + Controllers (Compose Multiplatform)
├── app-desktop/          # main() Windows → MSI installer package
└── app-android/          # Android Activity → APK
```

## 3. Main Sequence Flow: Issue Factura

```mermaid
sequenceDiagram
    actor U as Salesperson
    participant V as EmisionView
    participant C as ComprobanteController
    participant UC as EmitirComprobante (use case)
    participant D as Domain
    participant R as ComprobanteRepository
    participant X as UBL Generator + Signature
    participant G as EnvioSunatGateway (OSE)
    U->>V: enters customer and items
    V->>C: EmitirComprobanteRequest
    C->>UC: execute(request)
    UC->>D: build ComprobantePago (catalogs, RN-01..RN-10)
    D-->>UC: calculated taxes and totals (Cat. 05/07/08)
    UC->>R: reserve sequence number (Serie) and persist VALIDADO
    UC->>X: generate UBL 2.1 Peru XML, validate XSD + SUNAT rules (RN-11), sign
    X-->>UC: signed XML + hash
    UC->>G: submit ZIP
    alt Online connection available
        G-->>UC: CDR (code 0 / 2000+ / 4000+)
    else Offline / connection lost
        UC->>R: state PENDIENTE_ENVIO (retry queue)
    end
    UC->>R: update state and CDR
    UC-->>C: ComprobanteResponse
    C-->>V: ViewState (status, hash, QR code)
```

## 4. Future Vision: Hexagonal Architecture (Ports and Adapters)

The architectural migration **does not rewrite the domain**: the `core-*` packages already constitute the hexagon. The MVC Controllers become just another driving adapter, and new adapters (REST API, messaging) can be plugged in without touching the business core.

```mermaid
flowchart LR
    subgraph IN["DRIVING Adapters (Input)"]
        A1[Compose UI<br/>MVC controllers]
        A2[REST API<br/>OpenAPI 03]
        A3[Event consumer]
        A4[Scheduled Job<br/>retries / daily summary]
    end
    subgraph HEX["CORE (core-application + core-domain)"]
        P1{{"Input Ports<br/>EmitirComprobanteUseCase<br/>AnularComprobanteUseCase<br/>ConsultarEstadoUseCase<br/>MigrarLoteUseCase"}}
        DOM["Domain<br/>ComprobantePago · Tributo · Serie<br/>SUNAT Catalogs · RN-xx"]
        P2{{"Output Ports<br/>ComprobanteRepository<br/>FirmaDigitalPort<br/>EnvioSunatPort<br/>PadronRucPort<br/>LegacySourcePort<br/>EventPublisherPort"}}
        P1 --> DOM --> P2
    end
    subgraph OUT["DRIVEN Adapters (Output)"]
        B1[(SQLite / PostgreSQL)]
        B2[XML-DSig Signature]
        B3[OSE / SUNAT SOAP]
        B4[RUC Registry API]
        B5[Legacy Reader]
        B6[Message Broker]
    end
    A1 & A2 & A3 & A4 --> P1
    P2 --> B1 & B2 & B3 & B4 & B5 & B6
```

### Mapping MVC → Hexagonal

| Element in MVC Monolith | Role in Hexagonal Architecture | Required change upon migration |
| :--- | :--- | :--- |
| View + Controller | Driving / Input adapter | None; REST adapters are added alongside |
| Application services | Input ports (use cases) | None |
| Entities and business rules (RN) | Domain core | None |
| Repository and gateway interfaces | Output ports | None |
| SQLite, SOAP, digital signing, CSV | Driven / Output adapters | Implementations added (e.g., PostgreSQL, messaging broker) |

## 5. Evolutionary Roadmap to Microservices

```mermaid
flowchart LR
    F1["Phase 1<br/>Modular MVC Monolith<br/>(Windows + Android, SQLite)"] --> F2["Phase 2<br/>Hexagonal + REST API<br/>central PostgreSQL server,<br/>apps as synchronized clients"]
    F2 --> F3["Phase 3<br/>Microservices per Context"]
    F3 --- MS1[ms-facturacion]
    F3 --- MS2[ms-maestros]
    F3 --- MS3[ms-inventario]
    F3 --- MS4[ms-integracion-sunat]
    F3 --- MS5[ms-migracion]
```

- Each module (`facturacion / maestros / inventario / migracion`) maintains its own table schema from Phase 1 (no cross-context SQL joins), enabling independent database extraction.
- Cross-context communication is already handled through domain events (`ComprobanteAceptado` → `inventario` records the `SALIDA`); in Phase 3, `EventPublisherPort` shifts to an external message broker without modifying domain logic.
- `ms-integracion-sunat` concentrates XML generation, XSD validation, XML-DSig signing, and SOAP submission: it is the primary candidate for early extraction due to its distinct scaling requirements (month-end volume spikes).

## 6. Migration Module Architecture

```mermaid
flowchart LR
    L[(Legacy System)] --> E[Extract<br/>LegacySourcePort] --> S[(Staging<br/>raw rows + hash)]
    S --> VAL[Validate<br/>formats, dates, quantities]
    VAL --> T[Transform<br/>Producto + MovimientoInventario<br/>+ OrigenLegacy]
    T --> CAR[Load<br/>transaction per batch]
    CAR --> REC[Reconcile<br/>Σ legacy = Σ migrated]
    VAL -->|invalid rows| ERR[Rejection Report]
```

## 7. Deployment and Cross-Platform Execution

| Requirement | Architectural Decision | Technical Rationale |
| :--- | :--- | :--- |
| Native Windows & Android execution | **Kotlin Multiplatform + Compose Multiplatform** | Single shared domain and UI codebase; compiles to a native Android APK and to a packaged Windows desktop JVM app bundled with its own runtime |
| MSI Installer | Compose Desktop plugin `nativeDistributions { targetFormats(TargetFormat.Msi) }` (using `jpackage` + WiX) | Produces a standard Windows `.msi` package with desktop shortcuts and clean uninstall support |
| Android APK | `assembleRelease` signed with corporate keystore | Direct enterprise deployment (sideloading outside Google Play) |
| Local persistence | SQLite via SQLDelight (runs natively on both platforms) | PostgreSQL does not run embedded on Android devices; reserved for central Phase 2 server |
| Digital signature | Encrypted `.pfx` certificate storage (Windows DPAPI / Android Keystore) | Private key is never persisted or transmitted in plaintext |
| Offline store operations | In-memory and persisted `PENDIENTE_ENVIO` queue with retries | Essential for retail locations experiencing intermittent internet connectivity |

```mermaid
flowchart TB
    subgraph PC["Windows Desktop (.msi installer)"]
        D1[app-desktop + embedded JVM runtime] --> DB1[(SQLite)]
    end
    subgraph AND["Android Tablet / Smartphone (.apk)"]
        D2[app-android] --> DB2[(SQLite)]
    end
    D1 -->|HTTPS/SOAP| OSE[OSE / SUNAT]
    D2 -->|HTTPS/SOAP| OSE
```

## 8. Quality Attributes (Non-Functional Requirements)

| Quality Attribute | Architectural Scenario | Applied Tactic |
| :--- | :--- | :--- |
| Compliance | 100% of generated XML documents must validate against `UBL-Invoice-2.1.xsd` and UBL 2.1 Peru customization | Pre-signing XSD validation (RN-11) + automated test assertions against official SUNAT sample XMLs |
| Availability | Retail checkout counter operations must never stop during internet outages | Offline queuing (`PENDIENTE_ENVIO`) with exponential backoff retry worker |
| Data Integrity | Sequence numbers must never duplicate or skip numbers | Transactional row-level lock on `Serie` entity during issuance |
| Modifiability | Switch authorized OSE vendor in < 1 business day | `EnvioSunatPort` abstraction with pluggable adapter implementations |
| Traceability | Every migrated record must trace directly to its original legacy source row | `OrigenLegacy` metadata stamp + mathematical quantity reconciliation |
| Security | Digital certificate private keys and SOL credentials must remain protected | OS-level secure credential storage (DPAPI/Keystore), never stored in plaintext |
