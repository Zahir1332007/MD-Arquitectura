# 4. Matriz de Trazabilidad Normativa (SUNAT ↔ UBL 2.1 Perú ↔ Dominio ↔ Legado)

Esta matriz usa la **adaptación peruana de UBL 2.1** definida por SUNAT ("Guía de elaboración de documentos electrónicos XML —
UBL 2.1, estructura 2.0"), no el UBL genérico de OASIS. Cada fila responde: *¿qué exige SUNAT?*, *¿dónde y con qué atributos va
en el XML?*, *¿con qué formato?*, *¿qué atributo del dominio lo produce?*, *¿de qué dato legado proviene?* y *¿qué regla lo valida?*.

Normas: N-01 RS 097-2012, N-02 RS 234-2006, N-04 Anexo 8 Catálogos, N-05 Guía XML UBL 2.1 Perú (ver [00_README.md](00_README.md)).
Ejemplo completo: [`specs/ejemplos/20123456789-01-F001-1.xml`](../specs/ejemplos/20123456789-01-F001-1.xml).

## 4.0 Diferencias entre UBL 2.1 OASIS y UBL 2.1 Perú (SUNAT)

| Aspecto | UBL 2.1 OASIS (`UBL-Invoice-2.1.xsd`) | UBL 2.1 Perú (SUNAT) |
| :--- | :--- | :--- |
| Personalización | `cbc:CustomizationID` libre | `cbc:CustomizationID` = `2.0` con `schemeAgencyName="PE:SUNAT"` |
| Cardinalidad | Muchos elementos opcionales (`0..1`) | SUNAT los vuelve **obligatorios** (tipo de documento, moneda, RUC, totales, etc.) mediante sus reglas de validación |
| Códigos | Listas libres | **Catálogos del Anexo 8** referenciados con `listAgencyName="PE:SUNAT"` y `listURI="urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogoNN"` |
| Tributos | `TaxScheme` genérico | Cat. 05 (`1000` IGV, `2000` ISC, `7152` ICBPER…), afectación IGV Cat. 07 y sistema ISC **Cat. 08** en `cbc:TierRange` |
| Extensiones | `ext:UBLExtensions` libre | Solo se usa para la **firma XML-DSig**; las extensiones `sac:` de UBL 2.0 ya no se usan |
| Documentos | Un esquema por tipo | Factura `01` y Boleta `03` → `Invoice`; NC `07` → `CreditNote`; ND `08` → `DebitNote`; Resumen diario y Baja → esquemas propios SUNAT (`SummaryDocuments`, `VoidedDocuments`) |
| Nombre del archivo | No definido | `{RUC}-{TipoDoc}-{Serie}-{Correlativo}.xml` comprimido en `.zip` (p. ej. `20123456789-01-F001-1.zip`) |

### Atributos de catálogo usados en todo el XML

| Catálogo | Atributos SUNAT |
| :--- | :--- |
| 01 Tipo de documento | `listAgencyName="PE:SUNAT" listName="Tipo de Documento" listURI="urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo01"` |
| 02 Moneda | `listID="ISO 4217 Alpha" listName="Currency" listAgencyName="United Nations Economic Commission for Europe"` |
| 03 Unidad de medida | `unitCodeListID="UN/ECE rec 20" unitCodeListAgencyName="United Nations Economic Commission for Europe"` |
| 05 Tributos | `schemeName="Codigo de tributos" schemeAgencyName="PE:SUNAT" schemeURI="urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo05"` |
| 06 Doc. de identidad | `schemeName="Documento de Identidad" schemeAgencyName="PE:SUNAT" schemeURI="urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06"` |
| 07 Afectación IGV | `listAgencyName="PE:SUNAT" listName="Afectacion del IGV" listURI="urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo07"` |
| 08 Sistema ISC | `listAgencyName="PE:SUNAT" listName="Tipo de Sistema ISC" listURI="urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo08"` |
| 16 Tipo de precio | `listAgencyName="PE:SUNAT" listName="Tipo de Precio" listURI="urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo16"` |
| 51 Tipo de operación | `name="Tipo de Operacion" listSchemeURI="urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo51"` (como `listID` del tipo de documento) |
| 25 Producto SUNAT | `listID="UNSPSC" listAgencyName="GS1 US" listName="Item Classification"` |
| Ubigeo | `schemeName="Ubigeos" schemeAgencyName="PE:INEI"` |

**Notación de formato (de la guía SUNAT):** `an..13` = alfanumérico hasta 13; `n11` = numérico exacto 11; `n(12,2)` = hasta 12 enteros y 2 decimales.

## 4.1 Cabecera del comprobante

| # | Dato exigido por SUNAT | Norma | Cat. | Elemento UBL 2.1 Perú (`/Invoice/...`) y atributos | Formato SUNAT | Card. XSD → SUNAT | Atributo de dominio | Origen legado | Regla |
| :--- | :--- | :--- | :---: | :--- | :--- | :---: | :--- | :--- | :--- |
| T01 | Versión UBL | N-05 | — | `cbc:UBLVersionID` = `2.1` | `an..10` | 0..1 → 1 | constante | — | RN-11 |
| T02 | Versión de la estructura | N-05 | — | `cbc:CustomizationID schemeAgencyName="PE:SUNAT"` = `2.0` | `an..10` | 0..1 → 1 | constante | — | RN-11 |
| T03 | Serie y correlativo | N-01 | — | `cbc:ID` = `F001-1` | `an..13`, patrón `[FB][A-Z0-9]{3}-[0-9]{1,8}` | 1 → 1 | `serie` + `correlativo` | *No se usa `nro_documento`* (RN-04) | RN-03, RN-04 |
| T04 | Fecha de emisión | N-01 | — | `cbc:IssueDate` | `an..10` `YYYY-MM-DD` | 1 → 1 | `fechaEmision` | *No aplica* (ver §4.6) | RN-05 |
| T05 | Hora de emisión | N-05 | — | `cbc:IssueTime` | `an..8` `hh:mm:ss` | 0..1 → 1 | `horaEmision` | — | — |
| T06 | Fecha de vencimiento | N-05 | — | `cbc:DueDate` | `an..10` `YYYY-MM-DD` | 0..1 | `fechaVencimiento` | — | RN-10 |
| T07 | Tipo de comprobante | N-01 | 01 | `cbc:InvoiceTypeCode` + atributos Cat. 01 | `an2` | 0..1 → 1 | `tipo` | — | RN-03 |
| T08 | Tipo de operación | N-05 | 51 | `cbc:InvoiceTypeCode/@listID` = `0101` | `an4` | — → 1 | `tipoOperacion` | — | — |
| T09 | Leyenda monto en letras | N-05 | 52 | `cbc:Note languageLocaleID="1000"` | `an..200` | 0..n | `leyendas` | — | — |
| T10 | Moneda | N-01 | 02 | `cbc:DocumentCurrencyCode` + atributos Cat. 02 | `an3` | 0..1 → 1 | `moneda` | — (por defecto `PEN`) | RN-09 |
| T11 | Cantidad de ítems | N-05 | — | `cbc:LineCountNumeric` | `n..4` | 0..1 | `detalles.size` | — | — |
| T12 | Firma digital | N-01 | — | `ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature` | XML-DSig | 0..1 → 1 | `hashCpe` | — | RN-11 |
| T13 | Datos del firmante | N-05 | — | `cac:Signature/cbc:ID`, `cac:SignatoryParty/cac:PartyIdentification/cbc:ID` (RUC), `cac:DigitalSignatureAttachment/cac:ExternalReference/cbc:URI` | `an..3000` | 0..n → 1 | `emisor` | — | RN-11 |
| T14 | Forma de pago | N-05 | — | `cac:PaymentTerms/cbc:ID` = `FormaPago` + `cbc:PaymentMeansID` (`Contado` / `Credito` / `Cuota001`…) + `cbc:Amount` + `cbc:PaymentDueDate` | `an..7`, `n(12,2)` | 0..n → 1..n | `formaPago` | — | RN-10 |

## 4.2 Emisor y receptor

| # | Dato exigido por SUNAT | Norma | Cat. | Elemento UBL 2.1 Perú y atributos | Formato SUNAT | Atributo de dominio | Origen legado | Regla |
| :--- | :--- | :--- | :---: | :--- | :--- | :--- | :--- | :--- |
| E01 | RUC del emisor | N-01 | 06 | `cac:AccountingSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID schemeID="6"` + atributos Cat. 06 | `n11` | `emisor.ruc` | — | RN-01 |
| E02 | Nombre comercial | N-05 | — | `.../cac:Party/cac:PartyName/cbc:Name` | `an..1500` | `emisor.nombreComercial` | — | — |
| E03 | Razón social emisor | N-01 | — | `.../cac:PartyLegalEntity/cbc:RegistrationName` | `an..1500` | `emisor.razonSocial` | — | — |
| E04 | Código de establecimiento | N-05 | — | `.../cac:PartyLegalEntity/cac:RegistrationAddress/cbc:AddressTypeCode listAgencyName="PE:SUNAT" listName="Establecimientos anexos"` = `0000` | `an4` | `emisor.codigoEstablecimiento` | — | — |
| E05 | Ubigeo y dirección | N-05 | — | `.../cac:RegistrationAddress/cbc:ID schemeAgencyName="PE:INEI"` + `cac:AddressLine/cbc:Line` | `an6` | `emisor.domicilioFiscal` | — | — |
| R01 | Tipo y número de doc. del adquirente | N-01 | 06 | `cac:AccountingCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID schemeID="6"` + atributos Cat. 06 | `an..15` | `cliente.tipoDoc`, `cliente.numeroDoc` | — (el legado no registra clientes) | RN-02, RN-06 |
| R02 | Razón social adquirente | N-01 | — | `.../cac:PartyLegalEntity/cbc:RegistrationName` | `an..1500` | `cliente.razonSocial` | — | RN-06 |

## 4.3 Líneas (ítems)

| # | Dato exigido por SUNAT | Norma | Cat. | Elemento UBL 2.1 Perú (`cac:InvoiceLine/...`) y atributos | Formato SUNAT | Atributo de dominio | Origen legado | Regla |
| :--- | :--- | :--- | :---: | :--- | :--- | :--- | :--- | :--- |
| L01 | N° de orden del ítem | N-05 | — | `cbc:ID` | `n..3` | `linea` | — | — |
| L02 | Cantidad | N-01 | — | `cbc:InvoicedQuantity` | `n(12,10)` | `cantidad` | `salida` (solo referencia de kardex) | — |
| L03 | Unidad de medida | N-01 | 03 | `cbc:InvoicedQuantity/@unitCode` + atributos Cat. 03 | `an..3` | `unidad` | inferida de `producto` | — |
| L04 | Descripción | N-01 | — | `cac:Item/cbc:Description` | `an..500` | `descripcion` | `producto` (normalizado) | — |
| L05 | Código de producto | N-05 | — | `cac:Item/cac:SellersItemIdentification/cbc:ID` | `an..30` | `codigoProducto` | generado en migración | RN-13 |
| L06 | Código de producto SUNAT | N-05 | 25 | `cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode` + atributos UNSPSC | `an..8` | `producto.codigoSunat` | — | — |
| L07 | Valor unitario (sin tributos) | N-01 | — | `cac:Price/cbc:PriceAmount currencyID` | `n(12,10)` | `valorUnitario` | — | RN-07 |
| L08 | Precio de venta unitario | N-01 | 16 | `cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceAmount` + `cbc:PriceTypeCode` (`01`) + atributos Cat. 16 | `n(12,10)`, `an2` | `precioUnitario` | — | RN-07 |
| L09 | Valor de venta del ítem | N-01 | — | `cbc:LineExtensionAmount currencyID` | `n(12,2)` | `valorVenta` | — | RN-07 |

## 4.4 Tributos — incluye el Catálogo 08

Ubicación: `cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal/...` (por línea) y `/Invoice/cac:TaxTotal/cac:TaxSubtotal/...` (resumen).

| # | Dato exigido por SUNAT | Norma | Cat. | Elemento UBL 2.1 Perú y atributos | Formato SUNAT | Atributo de dominio | Regla |
| :--- | :--- | :--- | :---: | :--- | :--- | :--- | :--- |
| X01 | Código de tributo | N-04 | **05** | `cac:TaxCategory/cac:TaxScheme/cbc:ID` + atributos Cat. 05; `cbc:Name` (`IGV`, `ISC`, `ICBPER`, `EXO`, `INA`, `EXP`, `GRA`); `cbc:TaxTypeCode` (`VAT`, `EXC`, `OTH`, `FRE`) | `an4` | `tributo.codigo` | RN-07 |
| X02 | Afectación al IGV | N-04 | **07** | `cac:TaxCategory/cbc:TaxExemptionReasonCode` + atributos Cat. 07 | `an2` | `afectacionIgv` | RN-07 |
| X03 | Tasa IGV | N-01 | — | `cac:TaxCategory/cbc:Percent` = `18.00` | `n(3,5)` | `tributo.tasa` | RN-07 |
| X04 | **Sistema de cálculo del ISC** | N-04 | **08** | `cac:TaxCategory/cbc:TierRange` (`01`, `02`, `03`) — solo si `TaxScheme/cbc:ID = 2000` | `an2` | `tributo.sistemaIsc` | RN-07 |
| X05 | Tasa / monto ISC | N-04 | 08 | `cac:TaxCategory/cbc:Percent` | `n(3,5)` | `tributo.tasa` | RN-07 |
| X06 | ICBPER (bolsas plásticas) | N-04 | 05 (`7152`) | `cbc:BaseUnitMeasure unitCode="NIU"` (n.º de bolsas) + `cac:TaxCategory/cbc:PerUnitAmount` | `n(12,2)` | `tributo` si `producto.afectoIcbper` | RN-07 |
| X07 | Base imponible | N-05 | — | `cbc:TaxableAmount currencyID` (IGV: `valorVenta + ISC`) | `n(12,2)` | `tributo.base` | RN-07 |
| X08 | Monto del tributo | N-05 | — | `cbc:TaxAmount currencyID` | `n(12,2)` | `tributo.monto` | RN-07 |
| X09 | Total de tributos del comprobante | N-05 | — | `/Invoice/cac:TaxTotal/cbc:TaxAmount currencyID` | `n(12,2)` | `totales.totalTributos` | RN-08 |

> Caso peruano que conviene tener presente: el **arroz pilado** no lleva IGV, sino IVAP (Cat. 05 `1016`). El maestro de productos lo
> configura igual que cualquier otro tributo.

## 4.5 Totales (`/Invoice/cac:LegalMonetaryTotal/...`)

| # | Dato | Elemento UBL 2.1 Perú | Formato | Card. XSD → SUNAT | Atributo de dominio | Regla |
| :--- | :--- | :--- | :--- | :---: | :--- | :--- |
| M01 | Total valor de venta | `cbc:LineExtensionAmount currencyID` | `n(12,2)` | 0..1 → 1 | `totales.valorVenta` | RN-08 |
| M02 | Total precio de venta | `cbc:TaxInclusiveAmount currencyID` | `n(12,2)` | 0..1 → 1 | `totales.precioVenta` | RN-08 |
| M03 | Descuentos globales | `cbc:AllowanceTotalAmount currencyID` | `n(12,2)` | 0..1 | `totales.descuentos` | RN-08 |
| M04 | Otros cargos | `cbc:ChargeTotalAmount currencyID` | `n(12,2)` | 0..1 | `totales.cargos` | RN-08 |
| M05 | Anticipos | `cbc:PrepaidAmount currencyID` | `n(12,2)` | 0..1 | `totales.anticipos` | RN-08 |
| M06 | Importe total | `cbc:PayableAmount currencyID` | `n(12,2)` | 1 → 1 | `totales.importeTotal` | RN-08 |

## 4.6 Datos del software legado (registros, N-02)

Los campos legados **no** se convierten en comprobantes electrónicos. Alimentan el Registro de Inventario Permanente (kardex) y el
maestro de productos. Así se cumple la trazabilidad exigida sin emitir comprobantes electrónicos retroactivos.

| Campo legado | Requerimiento formal | Norma | Destino en dominio | Relación con UBL 2.1 Perú | Regla |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `fecha` | Fecha del movimiento en el registro de inventario | N-02 | `MovimientoInventario.fecha` | Ninguna directa (las ventas nuevas usan T04) | RN-13 |
| `ingreso` | Entradas de inventario | N-02 | `MovimientoInventario(INGRESO)` | — | RN-13 |
| `salida` | Salidas de inventario | N-02 | `MovimientoInventario(SALIDA)` | Las ventas nuevas generan la SALIDA desde L02 | RN-13 |
| `producto` | Descripción y unidad del bien | N-01, N-02 | `Producto` | L03, L04, L05 | RN-13 |
| `nro_documento` | Documento que sustenta el movimiento | N-02 | `documentoReferencia` + `OrigenLegacy` | **No** se mapea a T03 ni a R01 | RN-04, RN-13 |

## 4.7 Respuesta SUNAT / OSE (CDR `ApplicationResponse`) → estado de dominio

| Código CDR (`cac:DocumentResponse/cac:Response/cbc:ResponseCode`) | Significado | Estado de dominio | Acción |
| :--- | :--- | :--- | :--- |
| `0` | Aceptado | `ACEPTADO` | Guardar el CDR y generar la SALIDA de inventario |
| `0100`–`1999` | Excepción (no procesado) | `PENDIENTE_ENVIO` | Reintentar con el mismo XML |
| `2000`–`3999` | Rechazo | `RECHAZADO` | Corregir y emitir con nuevo correlativo |
| `4000`+ | Observación | `ACEPTADO_CON_OBS` | Aceptado; registrar las observaciones (`cbc:Note`) |

## 4.8 Coordinación API ↔ UBL 2.1 Perú ↔ SUNAT

Cada campo del contrato [`specs/03_CONTRATOS_API.yaml`](../specs/03_CONTRATOS_API.yaml) declara dos extensiones:
`x-ubl` (elemento XML y atributos) y `x-sunat` (fila de esta matriz, catálogo, formato y regla). Las restricciones JSON
(`pattern`, `maxLength`, `enum`, `maximum`) se derivan del formato SUNAT. Así la API rechaza el dato **antes** de generar un XML que
SUNAT/OSE rechazaría.

Hay tres tipos de dato:

- **Recibido**: lo envía el cliente de la API.
- **Configurado**: viene de la configuración del emisor o del maestro de productos.
- **Generado**: lo calcula el dominio. **No** se acepta desde la API, para que el XML siempre sea coherente.

| Campo API (DTO) | Origen | Elemento UBL 2.1 Perú | Fila | Catálogo | Formato SUNAT → restricción API | Regla |
| :--- | :---: | :--- | :---: | :---: | :--- | :--- |
| — | Generado | `cbc:UBLVersionID` = 2.1, `cbc:CustomizationID` = 2.0 | T01, T02 | — | constante | RN-11 |
| `serie` + correlativo interno | Recibido + Generado | `cbc:ID` | T03 | — | `an..13` → `^[FB][A-Z0-9]{3}$` + correlativo `n..8` | RN-03, RN-04 |
| `fechaEmision` | Recibido | `cbc:IssueDate` | T04 | — | `YYYY-MM-DD` → `format: date` | RN-05 |
| — | Generado | `cbc:IssueTime` | T05 | — | `hh:mm:ss` | — |
| `formaPago.cuotas[-1].fechaVencimiento` | Recibido | `cbc:DueDate` | T06 | — | `format: date` | RN-10 |
| `tipoComprobante` | Recibido | `cbc:InvoiceTypeCode` | T07 | 01 | `an2` → `enum` | RN-03 |
| `tipoOperacion` | Recibido | `cbc:InvoiceTypeCode/@listID` | T08 | 51 | `an4` → `^\d{4}$` | — |
| `totales.montoEnLetras` | Generado | `cbc:Note[@languageLocaleID="1000"]` | T09 | 52 | `an..200` | — |
| `observaciones` | Recibido | `cbc:Note` | — | — | `an..200` → `maxLength: 200` | — |
| `moneda` | Recibido | `cbc:DocumentCurrencyCode` y `@currencyID` | T10 | 02 | `an3` → `enum` | RN-09 |
| — | Generado | `cbc:LineCountNumeric` | T11 | — | `n..4` | — |
| `hash` (salida) | Generado | `ds:DigestValue` | T12 | — | — | RN-11 |
| `formaPago.tipo` / `cuotas[].monto` | Recibido | `cac:PaymentTerms/cbc:PaymentMeansID` / `cbc:Amount` | T14 | — | `Contado`/`Credito`, `n(12,2)` | RN-10 |
| `configuracion.ruc` | Configurado | `cac:AccountingSupplierParty/.../cbc:ID` | E01 | 06 | `n11` → `^(10\|15\|16\|17\|20)\d{9}$` | RN-01 |
| `configuracion.nombreComercial` | Configurado | `cac:PartyName/cbc:Name` | E02 | — | `an..1500` | — |
| `configuracion.razonSocial` | Configurado | `cac:PartyLegalEntity/cbc:RegistrationName` | E03 | — | `an..1500` | — |
| `configuracion.codigoEstablecimiento` | Configurado | `cac:RegistrationAddress/cbc:AddressTypeCode` | E04 | — | `an4` → `^\d{4}$` | — |
| `configuracion.ubigeo` / `direccion` | Configurado | `cac:RegistrationAddress/cbc:ID` / `cac:AddressLine/cbc:Line` | E05 | INEI | `an6` / `an..200` | — |
| `cliente.tipoDoc` | Recibido | `cac:AccountingCustomerParty/.../cbc:ID/@schemeID` | R01 | 06 | `an1` → `enum` | RN-02 |
| `cliente.numeroDoc` | Recibido | `cac:AccountingCustomerParty/.../cbc:ID` | R01 | — | `an..15` → `maxLength: 15` + patrón por tipo | RN-02, RN-06 |
| `cliente.razonSocial` | Recibido | `cac:PartyLegalEntity/cbc:RegistrationName` | R02 | — | `an..1500` | RN-06 |
| posición en `items[]` | Generado | `cac:InvoiceLine/cbc:ID` | L01 | — | `n..3` | — |
| `items[].cantidad` | Recibido | `cbc:InvoicedQuantity` | L02 | — | `n(12,10)` → `maximum`, `> 0` | — |
| `items[].unidadMedida` | Recibido / Configurado | `cbc:InvoicedQuantity/@unitCode` | L03 | 03 | `an..3` → `^[A-Z0-9]{1,3}$` | — |
| `items[].descripcion` | Recibido / Configurado | `cac:Item/cbc:Description` | L04 | — | `an..500` | — |
| `items[].codigoProducto` | Recibido | `cac:Item/cac:SellersItemIdentification/cbc:ID` | L05 | — | `an..30` | RN-13 |
| `producto.codigoSunat` | Configurado | `cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode` | L06 | 25 | `an..8` → `^\d{8}$` | — |
| `items[].valorUnitario` | Recibido | `cac:Price/cbc:PriceAmount` | L07 | — | `n(12,10)` | RN-07 |
| `items[].precioUnitario` + `tipoPrecio` | Recibido | `cac:PricingReference/.../cbc:PriceAmount` + `cbc:PriceTypeCode` | L08 | 16 | `n(12,10)`, `an2` | RN-07 |
| — | Generado | `cac:InvoiceLine/cbc:LineExtensionAmount` | L09 | — | `n(12,2)` | RN-07 |
| `items[].descuento` / `descuentoGlobal` | Recibido | `cac:AllowanceCharge` | M03 | 53 | `n(12,2)` | RN-07, RN-08 |
| `totales.tributos[].codigo` / `nombre` / `codigoInternacional` | Generado | `cac:TaxScheme/cbc:ID` / `cbc:Name` / `cbc:TaxTypeCode` | X01 | 05 | `an4` → `enum` | RN-07 |
| `items[].tipoAfectacionIgv` | Recibido / Configurado | `cbc:TaxExemptionReasonCode` | X02 | 07 | `an2` → `enum` | RN-07 |
| `totales.tributos[].tasa` | Generado | `cbc:Percent` / `cbc:PerUnitAmount` | X03, X05, X06 | — | `n(3,5)` | RN-07 |
| `producto.isc.sistema` | Configurado | `cbc:TierRange` | X04 | **08** | `an2` → `enum ['01','02','03']` | RN-07 |
| `producto.afectoIcbper` | Configurado | `cbc:BaseUnitMeasure` + `cbc:PerUnitAmount` (tributo 7152) | X06 | 05 | `n(12,2)` | RN-07 |
| `totales.tributos[].base` / `monto` | Generado | `cbc:TaxableAmount` / `cbc:TaxAmount` | X07, X08 | — | `n(12,2)` | RN-07 |
| `totales.totalTributos` | Generado | `/Invoice/cac:TaxTotal/cbc:TaxAmount` | X09 | — | `n(12,2)` | RN-08 |
| `totales.valorVenta` / `precioVenta` / `importeTotal` | Generado | `LegalMonetaryTotal/cbc:LineExtensionAmount` / `TaxInclusiveAmount` / `PayableAmount` | M01, M02, M06 | — | `n(12,2)` | RN-08 |
| `respuestaSunat.codigo` / `descripcion` / `observaciones` | Generado (CDR) | `ApplicationResponse/.../cbc:ResponseCode` / `cbc:Description` / `cbc:Note` | 4.7 | — | — | — |
| `notas.motivo` / `sustento` | Recibido | `cac:DiscrepancyResponse/cbc:ResponseCode` / `cbc:Description` | — | 09 / 10 | `an2` / `an..250` | — |
| `baja.motivo` | Recibido | `sac:VoidedDocumentsLine/sac:VoidReasonDescription` | — | — | `an..100` | — |
| `cliente.email`, `tipoCambio`, `origenLegacy` | Recibido / Generado | **No viajan en el XML** (uso interno, registro de ventas o trazabilidad del legado) | 4.6 | — | — | RN-09, RN-13 |

**Errores coordinados:** `ErrorResponse.detalles[]` devuelve el `campo` de la API y el `elementoUbl` afectado. Si el rechazo viene
de SUNAT/OSE, devuelve además su `codigoSunat`. Así un error se puede rastrear en ambos sentidos: API → XML → regla SUNAT.
