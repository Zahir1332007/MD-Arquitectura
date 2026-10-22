# 2. Diagramas de Arquitectura MVC con visión a Hexagonal

## 1. Contexto del sistema (C4 — nivel 1)

```mermaid
flowchart LR
    U1([Vendedor / Cajero]) --> APP
    U2([Contador / Administrador]) --> APP
    APP["Sistema de Facturación ABC<br/>(monolito MVC — Windows / Android)"]
    APP -->|"XML UBL 2.1 Perú firmado (SOAP)"| OSE[OSE autorizado]
    APP -->|"sendBill / sendSummary / getStatus"| SUNAT[SUNAT SEE]
    APP -->|"consulta RUC"| PADRON[Padrón RUC SUNAT]
    LEG[(Software básico legado<br/>fecha, ingreso, salida,<br/>producto, nro_documento)] -->|"export CSV / BD"| APP
    APP -->|"PDF + XML"| MAIL[Correo del cliente]
```

## 2. Visión base: monolito limpio con patrón MVC

El monolito es **un solo ejecutable** por plataforma. MVC organiza la interacción con el usuario; la "M" no es un modelo
anémico ligado a la base de datos, sino un núcleo de dominio con servicios y repositorios por interfaz.

```mermaid
flowchart TB
    subgraph V["VISTA (Compose Multiplatform)"]
        V1[EmisionView]
        V2[ComprobantesListView]
        V3[ClientesProductosView]
        V4[MigracionView]
    end
    subgraph C["CONTROLADOR"]
        C1[ComprobanteController]
        C2[MaestrosController]
        C3[MigracionController]
    end
    subgraph M["MODELO"]
        direction TB
        S1["Servicios de aplicación<br/>EmitirComprobante, AnularComprobante,<br/>MigrarLote, ConsultarEstado"]
        D1["Dominio<br/>ComprobantePago, Tributo, Serie,<br/>Catálogos SUNAT, Reglas RN-01..RN-13"]
        R1["Interfaces<br/>ComprobanteRepository, FirmaDigital,<br/>EnvioSunatGateway, PadronRuc, LegacySource"]
        S1 --> D1
        S1 --> R1
    end
    subgraph I["INFRAESTRUCTURA (implementaciones)"]
        I1[(SQLite local — SQLDelight)]
        I2[Firmador XML-DSig .pfx]
        I3[Cliente SOAP OSE / SUNAT]
        I4[Lector CSV / BD legado]
    end
    V -- "eventos de UI / DTO" --> C
    C -- "DTO" --> S1
    S1 -- "DTO de respuesta" --> C
    C -- "ViewState" --> V
    I1 -. implementa .-> R1
    I2 -. implementa .-> R1
    I3 -. implementa .-> R1
    I4 -. implementa .-> R1
```

**Reglas que hacen al MVC "limpio" (y preparan Hexagonal):**

1. **Regla de dependencia**: Vista → Controlador → Servicios → Dominio. El dominio no importa nada de UI, SQL, SOAP ni del framework.
2. Los **Controladores** solo traducen eventos de UI ↔ DTOs; no contienen reglas tributarias.
3. Toda E/S (base de datos, firma, SUNAT/OSE, padrón RUC, legado) se accede **por interfaz** declarada en el Modelo e implementada en Infraestructura.
4. Las **entidades nunca salen** del Modelo: la Vista recibe DTOs/ViewState.
5. Un módulo por contexto acotado (`facturacion`, `maestros`, `inventario`, `migracion`); se comunican solo por interfaces públicas o eventos de dominio (`ComprobanteAceptado`).

### Estructura de módulos (Gradle multiplataforma)

```text
abc-facturacion/
├── core-domain/          # Entidades, value objects, catálogos SUNAT, RN-xx  (Kotlin puro, sin dependencias)
├── core-application/     # Casos de uso + puertos (interfaces)                (Kotlin puro)
├── adapters-persistence/ # SQLDelight (SQLite) → ComprobanteRepository, ...
├── adapters-sunat/       # Generador UBL, validador XSD, firma XML-DSig, cliente SOAP OSE/SUNAT
├── adapters-legacy/      # Lectores del software básico (CSV / BD)
├── app-ui/               # Vistas + Controladores (Compose Multiplatform)
├── app-desktop/          # main() Windows → instalador MSI
└── app-android/          # Activity Android → APK
```

## 3. Flujo principal: emitir factura

```mermaid
sequenceDiagram
    actor U as Vendedor
    participant V as EmisionView
    participant C as ComprobanteController
    participant UC as EmitirComprobante (caso de uso)
    participant D as Dominio
    participant R as ComprobanteRepository
    participant X as Generador UBL + Firma
    participant G as EnvioSunatGateway (OSE)
    U->>V: completa cliente e ítems
    V->>C: EmitirComprobanteRequest
    C->>UC: ejecutar(request)
    UC->>D: construir ComprobantePago (catálogos, RN-01..RN-10)
    D-->>UC: totales e impuestos calculados (Cat. 05/07/08)
    UC->>R: reservar correlativo (Serie) y guardar VALIDADO
    UC->>X: generar XML UBL 2.1 Perú, validar XSD + reglas SUNAT (RN-11), firmar
    X-->>UC: XML firmado + hash
    UC->>G: enviar ZIP
    alt Hay conexión
        G-->>UC: CDR (código 0 / 2000+ / 4000+)
    else Sin conexión
        UC->>R: estado PENDIENTE_ENVIO (cola de reintentos)
    end
    UC->>R: actualizar estado y CDR
    UC-->>C: ComprobanteResponse
    C-->>V: ViewState (estado, hash, QR)
```

## 4. Visión futura: arquitectura Hexagonal (Puertos y Adaptadores)

La migración **no reescribe el dominio**: los paquetes `core-*` ya son el hexágono. Los Controladores MVC pasan a ser un
adaptador de entrada más, y aparecen otros (REST, mensajería) sin tocar el núcleo.

```mermaid
flowchart LR
    subgraph IN["Adaptadores de ENTRADA (driving)"]
        A1[UI Compose<br/>controladores MVC]
        A2[API REST<br/>OpenAPI 03]
        A3[Consumidor de eventos]
        A4[Job programado<br/>reintentos / resumen diario]
    end
    subgraph HEX["NÚCLEO (core-application + core-domain)"]
        P1{{"Puertos de entrada<br/>EmitirComprobanteUseCase<br/>AnularComprobanteUseCase<br/>ConsultarEstadoUseCase<br/>MigrarLoteUseCase"}}
        DOM["Dominio<br/>ComprobantePago · Tributo · Serie<br/>Catálogos SUNAT · RN-xx"]
        P2{{"Puertos de salida<br/>ComprobanteRepository<br/>FirmaDigitalPort<br/>EnvioSunatPort<br/>PadronRucPort<br/>LegacySourcePort<br/>EventPublisherPort"}}
        P1 --> DOM --> P2
    end
    subgraph OUT["Adaptadores de SALIDA (driven)"]
        B1[(SQLite / PostgreSQL)]
        B2[Firma XML-DSig]
        B3[OSE / SUNAT SOAP]
        B4[API padrón RUC]
        B5[Lector legado]
        B6[Broker de mensajes]
    end
    A1 & A2 & A3 & A4 --> P1
    P2 --> B1 & B2 & B3 & B4 & B5 & B6
```

### Correspondencia MVC → Hexagonal

| Elemento en el monolito MVC | Rol en Hexagonal | Cambio necesario al migrar |
| :--- | :--- | :--- |
| Vista + Controlador | Adaptador de entrada | Ninguno; se añaden adaptadores REST |
| Servicios de aplicación | Puertos de entrada (casos de uso) | Ninguno |
| Entidades y reglas RN | Dominio | Ninguno |
| Interfaces de repositorio/gateway | Puertos de salida | Ninguno |
| SQLite, SOAP, firma, CSV | Adaptadores de salida | Se añaden implementaciones (p. ej. PostgreSQL) |

## 5. Ruta de evolución a microservicios

```mermaid
flowchart LR
    F1["Fase 1<br/>Monolito MVC modular<br/>(Windows + Android, SQLite)"] --> F2["Fase 2<br/>Hexagonal + API REST<br/>servidor central PostgreSQL,<br/>apps como clientes sincronizados"]
    F2 --> F3["Fase 3<br/>Microservicios por contexto"]
    F3 --- MS1[ms-facturacion]
    F3 --- MS2[ms-maestros]
    F3 --- MS3[ms-inventario]
    F3 --- MS4[ms-integracion-sunat]
    F3 --- MS5[ms-migracion]
```

- Cada módulo `facturacion / maestros / inventario / migracion` tiene su propio esquema de tablas desde la fase 1 (sin *joins* entre contextos), así puede extraerse con su base de datos.
- La comunicación entre contextos ya se hace por eventos de dominio (`ComprobanteAceptado` → `inventario` registra la SALIDA); en fase 3 el `EventPublisherPort` cambia a un broker sin modificar el dominio.
- `ms-integracion-sunat` concentra firma, XSD y envío: es el primer candidato a extraer porque escala distinto (picos de fin de mes).

## 6. Vista del módulo de migración

```mermaid
flowchart LR
    L[(Legado)] --> E[Extraer<br/>LegacySourcePort] --> S[(Staging<br/>filas crudas + hash)]
    S --> VAL[Validar<br/>formatos, fechas, cantidades]
    VAL --> T[Transformar<br/>Producto + MovimientoInventario<br/>+ OrigenLegacy]
    T --> CAR[Cargar<br/>transacción por lote]
    CAR --> REC[Reconciliar<br/>Σ legado = Σ migrado]
    VAL -->|filas inválidas| ERR[Reporte de rechazos]
```

## 7. Despliegue y multiplataforma

| Requisito | Decisión | Justificación |
| :--- | :--- | :--- |
| Ejecución nativa Windows y Android | **Kotlin Multiplatform + Compose Multiplatform** | Una sola base de código de dominio y UI; en Android compila a APK nativo, en Windows a app de escritorio JVM empaquetada con su propio runtime |
| Instalador MSI | Plugin Compose Desktop `nativeDistributions { targetFormats(TargetFormat.Msi) }` (usa `jpackage` + WiX) | Genera un `.msi` estándar con acceso directo y desinstalador |
| APK Android | `assembleRelease` firmado con keystore de la empresa | Distribución directa (fuera de Play Store) |
| Persistencia local | SQLite vía SQLDelight (funciona en ambas plataformas) | PostgreSQL no corre nativamente en Android; se reserva para el servidor central de la fase 2 |
| Firma digital | Certificado `.pfx` almacenado cifrado (Windows DPAPI / Android Keystore) | El certificado nunca viaja en texto plano |
| Operación sin internet | Cola `PENDIENTE_ENVIO` con reintentos | Tiendas con conectividad intermitente |

```mermaid
flowchart TB
    subgraph PC["PC Windows (instalador .msi)"]
        D1[app-desktop + runtime JVM embebido] --> DB1[(SQLite)]
    end
    subgraph AND["Tablet / celular Android (.apk)"]
        D2[app-android] --> DB2[(SQLite)]
    end
    D1 -->|HTTPS/SOAP| OSE[OSE / SUNAT]
    D2 -->|HTTPS/SOAP| OSE
```

## 8. Atributos de calidad

| Atributo | Escenario | Táctica |
| :--- | :--- | :--- |
| Conformidad | 100 % de XML generados validan contra `UBL-Invoice-2.1.xsd` y la personalización UBL 2.1 Perú | Validación XSD previa a firma (RN-11) + pruebas con XML de ejemplo SUNAT |
| Disponibilidad | Sin internet, la venta no se detiene | Cola de envío y reintentos |
| Integridad | No se repiten ni saltan correlativos | Bloqueo transaccional en `Serie` |
| Modificabilidad | Cambiar de OSE en < 1 día | `EnvioSunatPort` con un adaptador por proveedor |
| Trazabilidad | Todo registro migrado es rastreable a su fila de origen | `OrigenLegacy` + reconciliación |
| Seguridad | Certificado y credenciales SOL protegidos | Almacén seguro del SO, nunca en la BD en claro |
