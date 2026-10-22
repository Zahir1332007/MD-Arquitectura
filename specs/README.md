# Specs (Spec-First)

Especificaciones formales escritas **antes** de cualquier línea de lógica de negocio. Los documentos de `docs/` explican el diseño;
estos archivos son los contratos que la implementación debe cumplir y a partir de los cuales se generan pruebas y código.

| Carpeta / archivo | Qué especifica | Formato | Se usa para |
| :--- | :--- | :--- | :--- |
| [03_CONTRATOS_API.yaml](03_CONTRATOS_API.yaml) | Endpoints, DTOs, errores y servicios SUNAT/OSE, con `x-ubl` / `x-sunat` por campo | OpenAPI 3.0.3 | Generar controladores/clientes y validar requests |
| [schemas/comprobante-pago.schema.json](schemas/comprobante-pago.schema.json) | Agregado de dominio `ComprobantePago` ya calculado, con reglas condicionales (RN-03, RN-06, RN-07, RN-09, RN-10) | JSON Schema 2020-12 | Validar el estado interno antes de generar el XML |
| [schemas/registro-legado.schema.json](schemas/registro-legado.schema.json) | Fila del software legado en staging | JSON Schema 2020-12 | Etapa Extraer de la migración |
| [catalogos/catalogos-sunat.json](catalogos/catalogos-sunat.json) | Catálogos 01, 02, 03, 05, 06, 07, **08**, 09, 10, 16, 25, 51, 52, 53 con sus atributos UBL 2.1 Perú | JSON | Fuente única de los value objects y `enum` |
| [reglas/](reglas/) | Reglas RN-01..RN-13 como escenarios con datos concretos | Gherkin (`# language: es`) | Pruebas de aceptación (Cucumber) |
| [puertos/](puertos/) | Puertos de entrada (casos de uso) y de salida (repositorios, SUNAT, firma, legado) | Interfaces Kotlin sin lógica | Contrato del núcleo hexagonal |
| [migracion/mapeo-legado.yaml](migracion/mapeo-legado.yaml) | Mapeo campo a campo del legado, transformaciones, rechazos y reconciliación | YAML | Implementar el ETL de migración |
| [arquitectura/reglas-dependencia.yaml](arquitectura/reglas-dependencia.yaml) | Reglas ARQ-01..ARQ-07 de dependencias entre capas y contextos | YAML | Pruebas de arquitectura (ArchUnit/Konsist) |
| [ejemplos/20123456786-01-F001-1.xml](ejemplos/20123456786-01-F001-1.xml) | Factura de referencia en UBL 2.1 Perú | XML | Prueba de conformidad del generador UBL |

## Reglas → specs que las cubren

| Regla | Gherkin | Schema | API | Matriz |
| :--- | :--- | :--- | :--- | :--- |
| RN-01, RN-02 RUC / documento | `RN-01_06_emision.feature` | `Ruc`, `Cliente` | `ClienteDto`, EP-09 | E01, R01 |
| RN-03, RN-04 Serie y correlativo | `RN-01_06_emision.feature` | `serie`, `correlativo` | `serie`, `SerieDto` | T03 |
| RN-05 Fecha | `RN-01_06_emision.feature` | `fechaEmision` | `fechaEmision` | T04 |
| RN-06 Cliente obligatorio | `RN-01_06_emision.feature` | `allOf` tipo 01 | `cliente` | R01, R02 |
| RN-07 Tributos (IGV, ISC Cat. 08, ICBPER) | `RN-07_08_calculo_tributos.feature` | `Tributo` | `ProductoDto.isc`, `TributoDto` | X01–X08 |
| RN-08 Totales | `RN-07_08_calculo_tributos.feature` | `Totales` | `TotalesDto` | M01–M06, X09 |
| RN-09 Moneda | `RN-09_12_ciclo_de_vida.feature` | `allOf` USD | `tipoCambio` | T10 |
| RN-10 Forma de pago | `RN-09_12_ciclo_de_vida.feature` | `FormaPago` | `FormaPagoDto` | T06, T14 |
| RN-11 XML UBL 2.1 Perú | `RN-09_12_ciclo_de_vida.feature` | — | — | T01, T02, T12 + `ejemplos/` |
| RN-12 Inmutabilidad, notas, baja | `RN-09_12_ciclo_de_vida.feature` | `documentoReferencia` | EP-05, EP-06 | §4.7 |
| RN-13 Migración | `RN-13_migracion_legado.feature` | `registro-legado` | EP-13..EP-15 | §4.6 |

## Orden de implementación sugerido (fase siguiente)

1. Value objects de catálogos desde `catalogos-sunat.json` → pasar los escenarios de formato de `RN-01_06`.
2. Motor de tributos → pasar `RN-07_08_calculo_tributos.feature`.
3. Generador UBL + validación XSD → el XML generado debe coincidir con `ejemplos/`.
4. Adaptadores de salida (`PuertosSalida.kt`) → `RN-09_12_ciclo_de_vida.feature`.
5. ETL de migración → `RN-13_migracion_legado.feature`.
6. Pruebas de arquitectura con `reglas-dependencia.yaml` en el pipeline desde el día 1.
