# Especificación Spec-First — Sistema de Facturación Electrónica ABC Software Corp

> Examen de medio curso — Arquitectura de Software (UNAS, FIIS) — Grupo "A"
> Fase 1: **esqueleto de especificaciones técnicas** (sin lógica de negocio implementada).

## 1. Contexto

ABC Software Corp comercializa abarrotes y mercadería al por mayor y menor. Hoy usa un software básico de almacén con fichas de
`fecha`, `ingreso`, `salida`, `producto` y `nro_documento` (número interno informal). Ese sistema:

- no valida RUC/DNI,
- no calcula tributos (IGV, ISC, ICBPER),
- no genera XML UBL 2.1 firmado digitalmente,
- no se comunica con un OSE ni con SUNAT.

El nuevo sistema debe cumplir el Sistema de Emisión Electrónica (SEE) de SUNAT y, mediante **Spec-First**, se definen primero
reglas, contratos de datos, validaciones e interfaces, tomando como fuente el esquema `UBL-Invoice-2.1.xsd` (OASIS) **en su adaptación peruana (UBL 2.1 Perú, estructura 2.0 de SUNAT)**.

## 2. Base normativa y técnica

| Código | Fuente | Qué aporta a la especificación |
| :--- | :--- | :--- |
| N-01 | RS N° 097-2012/SUNAT y modificatorias | Crea el SEE desde los sistemas del contribuyente (SEE-Del Contribuyente): emisión de factura, boleta y notas en XML firmado, envío a SUNAT u OSE, CDR. |
| N-02 | RS N° 234-2006/SUNAT y modificatorias | Libros y registros vinculados a asuntos tributarios: Registro de Ventas e Ingresos y Registro de Inventario Permanente (destino de los datos de almacén migrados). |
| N-03 | RS N° 117-2017/SUNAT (OSE) | Operador de Servicios Electrónicos que valida el comprobante por cuenta de SUNAT. |
| N-04 | Anexo N° 8 — Catálogo de códigos SUNAT | Catálogos 01, 02, 03, 05, 06, 07, **08**, 09, 10, 16, 51, 52, etc. |
| N-05 | **UBL 2.1 Perú**: Guía de elaboración de documentos XML UBL 2.1 (estructura 2.0) y reglas de validación SUNAT | Personalización peruana del estándar: elementos obligatorios, atributos `PE:SUNAT`, URIs de catálogos, formatos (`an..13`, `n(12,2)`), nombre del archivo y códigos de error/observación. |
| T-01 | OASIS UBL 2.1 — `UBL-Invoice-2.1.xsd` (+ `UBL-CreditNote-2.1.xsd`, `UBL-DebitNote-2.1.xsd`) | Estructura base y cardinalidad. SUNAT no cambia el XSD: lo restringe con N-05. |
| T-02 | W3C XML-DSig | Firma digital del XML (`ext:UBLExtensions/.../ds:Signature`). |

## 3. Entregables y trazabilidad entre documentos

| # | Entregable exigido | Archivo |
| :--- | :--- | :--- |
| 1 | Modelo de Dominio y Contratos (DTOs / Schemas) | [01_MODELO_DE_DOMINIO.md](01_MODELO_DE_DOMINIO.md) |
| 2 | Diagramas de Arquitectura MVC con visión a Hexagonal | [02_ARQUITECTURA.md](02_ARQUITECTURA.md) |
| 3 | Especificación de Endpoints / Servicios (Contratos API) | [../specs/03_CONTRATOS_API.yaml](../specs/03_CONTRATOS_API.yaml) (OpenAPI 3.0.3) |
| 4 | Matriz de Trazabilidad Normativa SUNAT ↔ UBL | [04_MATRIZ_TRAZABILIDAD.md](04_MATRIZ_TRAZABILIDAD.md) |
| — | Casos de uso (sección 3 del enunciado) | [05_CASOS_DE_USO.md](05_CASOS_DE_USO.md) |
| — | XML de ejemplo UBL 2.1 Perú (factura) | [../specs/ejemplos/20123456786-01-F001-1.xml](../specs/ejemplos/20123456786-01-F001-1.xml) |
| — | **Specs formales** (reglas Gherkin, JSON Schemas, catálogos, puertos, mapeo del legado, reglas de arquitectura) | [../specs/README.md](../specs/README.md) |

Convenciones de identificadores usados en todos los documentos:

- `CU-xx`: caso de uso — `RN-xx`: regla de negocio / validación — `N-xx`: norma — `EP-xx`: endpoint.
- Cada `RN` aparece en el modelo de dominio (dónde se aplica), en el contrato API (qué error devuelve) y en la matriz (qué norma/etiqueta UBL la origina).

## 4. Restricciones arquitectónicas (resumen)

| Restricción del enunciado | Decisión tomada | Detalle |
| :--- | :--- | :--- |
| Legado y migración de datos | Módulo de migración con lotes, staging, reconciliación y `origenLegacy` en cada registro | 01 §6, 02 §6, API `/migraciones` |
| Normativa tributaria peruana | Catálogos SUNAT como *value objects* validados; motor de tributos IGV/ISC/ICBPER (catálogos 05, 07, **08**) | 01 §3–4, 04 |
| Monolito MVC hoy, Hexagonal/microservicios mañana | Monolito modular MVC cuyo Modelo ya está organizado en puertos y adaptadores | 02 §2–5 |
| Windows + Android nativos, MSI y APK | Kotlin Multiplatform + Compose Multiplatform (UI compartida), `packageMsi` y APK firmado | 02 §7 |
