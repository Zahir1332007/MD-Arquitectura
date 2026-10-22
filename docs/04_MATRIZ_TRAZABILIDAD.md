# 4. Regulatory Traceability Matrix (SUNAT ↔ UBL 2.1 Peru ↔ Domain ↔ Legacy)

This matrix uses the **Peruvian customization of UBL 2.1** defined by SUNAT ("Guía de elaboración de documentos electrónicos XML —
UBL 2.1, estructura 2.0"), not generic OASIS UBL. Each row answers: *what does SUNAT require?*, *where and with which attributes does it go
in the XML?*, *in which format?*, *which domain attribute produces it?*, *which legacy field does it come from?* and *which rule validates it?*.

Regulations: N-01 RS 097-2012, N-02 RS 234-2006, N-04 Annex 8 Catalogs, N-05 UBL 2.1 Peru XML Guide (see [00_README.md](00_README.md)).
Complete sample: [`specs/ejemplos/20123456786-01-F001-1.xml`](../specs/ejemplos/20123456786-01-F001-1.xml).

## 4.0 Differences between OASIS UBL 2.1 and UBL 2.1 Peru (SUNAT)

| Aspect | OASIS UBL 2.1 (`UBL-Invoice-2.1.xsd`) | UBL 2.1 Peru (SUNAT) |
| :--- | :--- | :--- |
| Customization | Free `cbc:CustomizationID` | `cbc:CustomizationID` = `2.0` with `schemeAgencyName="PE:SUNAT"` |
| Cardinality | Many optional elements (`0..1`) | SUNAT makes them **mandatory** (document type, currency, RUC, totals, etc.) via its validation rules |
| Codes | Arbitrary code lists | **Annex 8 Catalogs** referenced with `listAgencyName="PE:SUNAT"` and `listURI="urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogoNN"` |
| Taxes | Generic `TaxScheme` | Cat. 05 (`1000` IGV, `2000` ISC, `7152` ICBPER…), IGV affectation Cat. 07 and ISC system **Cat. 08** in `cbc:TierRange` |
| Extensions | Free `ext:UBLExtensions` | Used exclusively for the **XML-DSig signature**; legacy UBL 2.0 `sac:` extensions are obsolete |
| Documents | One schema per document type | Factura `01` and Boleta `03` → `Invoice`; NC `07` → `CreditNote`; ND `08` → `DebitNote`; Resumen diario and Baja → SUNAT proprietary schemas (`SummaryDocuments`, `VoidedDocuments`) |
| File Name | Undefined | `{RUC}-{TipoDoc}-{Serie}-{Correlativo}.xml` compressed into `.zip` (e.g., `20123456786-01-F001-1.zip`) |

### Catalog Attributes Used Throughout the XML

| Catalog | SUNAT Attributes |
| :--- | :--- |
| 01 Tipo de documento | `listAgencyName="PE:SUNAT" listName="Tipo de Documento" listURI="urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo01"` |
| 02 Moneda | `listID="ISO 4217 Alpha" listName="Currency" listAgencyName="United Nations Economic Commission for Europe"` |
| 03 Unidad de medida | `unitCodeListID="UN/ECE rec 20" unitCodeListAgencyName="United Nations Economic Commission for Europe"` |
| 05 Tributos | `schemeName="Codigo de tributos" schemeAgencyName="PE:SUNAT" schemeURI="urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo05"` |
| 06 Doc. de identidad | `schemeName="Documento de Identidad" schemeAgencyName="PE:SUNAT" schemeURI="urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06"` |
| 07 Afectación IGV | `listAgencyName="PE:SUNAT" listName="Afectacion del IGV" listURI="urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo07"` |
| 08 Sistema ISC | `listAgencyName="PE:SUNAT" listName="Tipo de Sistema ISC" listURI="urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo08"` |
| 16 Tipo de precio | `listAgencyName="PE:SUNAT" listName="Tipo de Precio" listURI="urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo16"` |
| 51 Tipo de operación | `name="Tipo de Operacion" listSchemeURI="urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo51"` (as `listID` of document type) |
| 25 Producto SUNAT | `listID="UNSPSC" listAgencyName="GS1 US" listName="Item Classification"` |
| Ubigeo | `schemeName="Ubigeos" schemeAgencyName="PE:INEI"` |

**Format notation (from SUNAT guide):** `an..13` = alphanumeric up to 13 characters; `n11` = numeric exactly 11 digits; `n(12,2)` = up to 12 integer digits and 2 decimal places.

## 4.1 Document Header

| # | Data required by SUNAT | Standard | Cat. | UBL 2.1 Peru element (`/Invoice/...`) and attributes | SUNAT Format | Card. XSD → SUNAT | Domain attribute | Legacy source | Rule |
| :--- | :--- | :--- | :---: | :--- | :--- | :---: | :--- | :--- | :--- |
| T01 | UBL version | N-05 | — | `cbc:UBLVersionID` = `2.1` | `an..10` | 0..1 → 1 | constant | — | RN-11 |
| T02 | Structure version | N-05 | — | `cbc:CustomizationID schemeAgencyName="PE:SUNAT"` = `2.0` | `an..10` | 0..1 → 1 | constant | — | RN-11 |
| T03 | Series and sequence number | N-01 | — | `cbc:ID` = `F001-1` | `an..13`, pattern `[FB][A-Z0-9]{3}-[0-9]{1,8}` | 1 → 1 | `serie` + `correlativo` | *`nro_documento` is not used* (RN-04) | RN-03, RN-04 |
| T04 | Issue date | N-01 | — | `cbc:IssueDate` | `an..10` `YYYY-MM-DD` | 1 → 1 | `fechaEmision` | *Not applicable* (see §4.6) | RN-05 |
| T05 | Issue time | N-05 | — | `cbc:IssueTime` | `an..8` `hh:mm:ss` | 0..1 → 1 | `horaEmision` | — | — |
| T06 | Due date | N-05 | — | `cbc:DueDate` | `an..10` `YYYY-MM-DD` | 0..1 | `fechaVencimiento` | — | RN-10 |
| T07 | Document type | N-01 | 01 | `cbc:InvoiceTypeCode` + Cat. 01 attributes | `an2` | 0..1 → 1 | `tipo` | — | RN-03 |
| T08 | Operation type | N-05 | 51 | `cbc:InvoiceTypeCode/@listID` = `0101` | `an4` | — → 1 | `tipoOperacion` | — | — |
| T09 | Amount-in-words legend | N-05 | 52 | `cbc:Note languageLocaleID="1000"` | `an..200` | 0..n | `leyendas` | — | — |
| T10 | Currency | N-01 | 02 | `cbc:DocumentCurrencyCode` + Cat. 02 attributes | `an3` | 0..1 → 1 | `moneda` | — (defaults to `PEN`) | RN-09 |
| T11 | Number of lines | N-05 | — | `cbc:LineCountNumeric` | `n..4` | 0..1 | `detalles.size` | — | — |
| T12 | Digital signature | N-01 | — | `ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature` | XML-DSig | 0..1 → 1 | `hashCpe` | — | RN-11 |
| T13 | Signer identity data | N-05 | — | `cac:Signature/cbc:ID`, `cac:SignatoryParty/cac:PartyIdentification/cbc:ID` (RUC), `cac:DigitalSignatureAttachment/cac:ExternalReference/cbc:URI` | `an..3000` | 0..n → 1 | `emisor` | — | RN-11 |
| T14 | Payment terms | N-05 | — | `cac:PaymentTerms/cbc:ID` = `FormaPago` + `cbc:PaymentMeansID` (`Contado` / `Credito` / `Cuota001`…) + `cbc:Amount` + `cbc:PaymentDueDate` | `an..7`, `n(12,2)` | 0..n → 1..n | `formaPago` | — | RN-10 |

## 4.2 Issuer and Customer

| # | Data required by SUNAT | Standard | Cat. | UBL 2.1 Peru element and attributes | SUNAT Format | Domain attribute | Legacy source | Rule |
| :--- | :--- | :--- | :---: | :--- | :--- | :--- | :--- | :--- |
| E01 | Issuer RUC | N-01 | 06 | `cac:AccountingSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID schemeID="6"` + Cat. 06 attributes | `n11` | `emisor.ruc` | — | RN-01 |
| E02 | Commercial trade name | N-05 | — | `.../cac:Party/cac:PartyName/cbc:Name` | `an..1500` | `emisor.nombreComercial` | — | — |
| E03 | Issuer legal name | N-01 | — | `.../cac:PartyLegalEntity/cbc:RegistrationName` | `an..1500` | `emisor.razonSocial` | — | — |
| E04 | Establishment code | N-05 | — | `.../cac:PartyLegalEntity/cac:RegistrationAddress/cbc:AddressTypeCode listAgencyName="PE:SUNAT" listName="Establecimientos anexos"` = `0000` | `an4` | `emisor.codigoEstablecimiento` | — | — |
| E05 | Ubigeo and address | N-05 | — | `.../cac:RegistrationAddress/cbc:ID schemeAgencyName="PE:INEI"` + `cac:AddressLine/cbc:Line` | `an6` | `emisor.domicilioFiscal` | — | — |
| R01 | Customer document type & number | N-01 | 06 | `cac:AccountingCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID schemeID="6"` + Cat. 06 attributes | `an..15` | `cliente.tipoDoc`, `cliente.numeroDoc` | — (legacy did not store customer identities) | RN-02, RN-06 |
| R02 | Customer legal name | N-01 | — | `.../cac:PartyLegalEntity/cbc:RegistrationName` | `an..1500` | `cliente.razonSocial` | — | RN-06 |

## 4.3 Lines (Items)

| # | Data required by SUNAT | Standard | Cat. | UBL 2.1 Peru element (`cac:InvoiceLine/...`) and attributes | SUNAT Format | Domain attribute | Legacy source | Rule |
| :--- | :--- | :--- | :---: | :--- | :--- | :--- | :--- | :--- |
| L01 | Item line number | N-05 | — | `cbc:ID` | `n..3` | `linea` | — | — |
| L02 | Quantity | N-01 | — | `cbc:InvoicedQuantity` | `n(12,10)` | `cantidad` | `salida` (kardex reference only) | — |
| L03 | Unit of measure | N-01 | 03 | `cbc:InvoicedQuantity/@unitCode` + Cat. 03 attributes | `an..3` | `unidad` | inferred from `producto` | — |
| L04 | Description | N-01 | — | `cac:Item/cbc:Description` | `an..500` | `descripcion` | `producto` (normalized) | — |
| L05 | Product code | N-05 | — | `cac:Item/cac:SellersItemIdentification/cbc:ID` | `an..30` | `codigoProducto` | generated in migration | RN-13 |
| L06 | SUNAT product code | N-05 | 25 | `cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode` + UNSPSC attributes | `an..8` | `producto.codigoSunat` | — | — |
| L07 | Unit value (exclusive of taxes) | N-01 | — | `cac:Price/cbc:PriceAmount currencyID` | `n(12,10)` | `valorUnitario` | — | RN-07 |
| L08 | Unit sales price (tax inclusive) | N-01 | 16 | `cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceAmount` + `cbc:PriceTypeCode` (`01`) + Cat. 16 attributes | `n(12,10)`, `an2` | `precioUnitario` | — | RN-07 |
| L09 | Line extension amount (item sales value) | N-01 | — | `cbc:LineExtensionAmount currencyID` | `n(12,2)` | `valorVenta` | — | RN-07 |

## 4.4 Taxes (Tributos) — Including Catalog 08

Location: `cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal/...` (per line) and `/Invoice/cac:TaxTotal/cac:TaxSubtotal/...` (document summary).

| # | Data required by SUNAT | Standard | Cat. | UBL 2.1 Peru element and attributes | SUNAT Format | Domain attribute | Rule |
| :--- | :--- | :--- | :---: | :--- | :--- | :--- | :--- |
| X01 | Tax code | N-04 | **05** | `cac:TaxCategory/cac:TaxScheme/cbc:ID` + Cat. 05 attributes; `cbc:Name` (`IGV`, `ISC`, `ICBPER`, `EXO`, `INA`, `EXP`, `GRA`); `cbc:TaxTypeCode` (`VAT`, `EXC`, `OTH`, `FRE`) | `an4` | `tributo.codigo` | RN-07 |
| X02 | IGV affectation | N-04 | **07** | `cac:TaxCategory/cbc:TaxExemptionReasonCode` + Cat. 07 attributes | `an2` | `afectacionIgv` | RN-07 |
| X03 | IGV tax rate | N-01 | — | `cac:TaxCategory/cbc:Percent` = `18.00` | `n(3,5)` | `tributo.tasa` | RN-07 |
| X04 | **ISC calculation system** | N-04 | **08** | `cac:TaxCategory/cbc:TierRange` (`01`, `02`, `03`) — only if `TaxScheme/cbc:ID = 2000` | `an2` | `tributo.sistemaIsc` | RN-07 |
| X05 | ISC rate / specific amount | N-04 | 08 | `cac:TaxCategory/cbc:Percent` | `n(3,5)` | `tributo.tasa` | RN-07 |
| X06 | ICBPER (plastic bag tax) | N-04 | 05 (`7152`) | `cbc:BaseUnitMeasure unitCode="NIU"` (number of bags) + `cac:TaxCategory/cbc:PerUnitAmount` | `n(12,2)` | `tributo` if `producto.afectoIcbper` | RN-07 |
| X07 | Taxable base amount | N-05 | — | `cbc:TaxableAmount currencyID` (IGV: `valorVenta + ISC`) | `n(12,2)` | `tributo.base` | RN-07 |
| X08 | Tax amount | N-05 | — | `cbc:TaxAmount currencyID` | `n(12,2)` | `tributo.monto` | RN-07 |
| X09 | Total taxes on document | N-05 | — | `/Invoice/cac:TaxTotal/cbc:TaxAmount currencyID` | `n(12,2)` | `totales.totalTributos` | RN-08 |

> Peruvian tax edge case to remember: **arroz pilado** (hulled rice) is not subject to IGV, but to IVAP (Cat. 05 `1016`). The product master
> configures it identically to any other tax category.

## 4.5 Totals (`/Invoice/cac:LegalMonetaryTotal/...`)

| # | Data field | UBL 2.1 Peru element | Format | Card. XSD → SUNAT | Domain attribute | Rule |
| :--- | :--- | :--- | :--- | :---: | :--- | :--- |
| M01 | Total sales value | `cbc:LineExtensionAmount currencyID` | `n(12,2)` | 0..1 → 1 | `totales.valorVenta` | RN-08 |
| M02 | Total sales price (tax inclusive) | `cbc:TaxInclusiveAmount currencyID` | `n(12,2)` | 0..1 → 1 | `totales.precioVenta` | RN-08 |
| M03 | Global discounts | `cbc:AllowanceTotalAmount currencyID` | `n(12,2)` | 0..1 | `totales.descuentos` | RN-08 |
| M04 | Other charges | `cbc:ChargeTotalAmount currencyID` | `n(12,2)` | 0..1 | `totales.cargos` | RN-08 |
| M05 | Prepayments | `cbc:PrepaidAmount currencyID` | `n(12,2)` | 0..1 | `totales.anticipos` | RN-08 |
| M06 | Payable total amount | `cbc:PayableAmount currencyID` | `n(12,2)` | 1 → 1 | `totales.importeTotal` | RN-08 |

## 4.6 Legacy Software Data (Registers, N-02)

Legacy fields **are not** converted into electronic invoices. They feed into the Permanent Inventory Register (Kardex) and the
Product Master. This satisfies statutory traceability without fabricating retroactive electronic invoices.

| Legacy field | Formal requirement | Standard | Destination in domain | Relationship to UBL 2.1 Peru | Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `fecha` | Movement date in inventory register | N-02 | `MovimientoInventario.fecha` | None directly (new sales use T04) | RN-13 |
| `ingreso` | Inventory inbound receipts | N-02 | `MovimientoInventario(INGRESO)` | — | RN-13 |
| `salida` | Inventory outbound dispatches | N-02 | `MovimientoInventario(SALIDA)` | New sales generate SALIDA from L02 | RN-13 |
| `producto` | Good description and unit | N-01, N-02 | `Producto` | L03, L04, L05 | RN-13 |
| `nro_documento` | Supporting document for movement | N-02 | `documentoReferencia` + `OrigenLegacy` | **Not** mapped to T03 or R01 | RN-04, RN-13 |

## 4.7 SUNAT / OSE Response (CDR `ApplicationResponse`) → Domain State

| CDR Code (`cac:DocumentResponse/cac:Response/cbc:ResponseCode`) | Meaning | Domain State | Action |
| :--- | :--- | :--- | :--- |
| `0` | Accepted | `ACEPTADO` | Store CDR receipt and trigger inventory `SALIDA` |
| `0100`–`1999` | Exception (unprocessed) | `PENDIENTE_ENVIO` | Retry using the exact same signed XML |
| `2000`–`3999` | Rejection | `RECHAZADO` | Fix root issue and issue new document with next sequence number |
| `4000`+ | Observation | `ACEPTADO_CON_OBS` | Accepted; record observations (`cbc:Note`) |

## 4.8 Coordination: API ↔ UBL 2.1 Peru ↔ SUNAT

Each field in the contract [`specs/03_CONTRATOS_API.yaml`](../specs/03_CONTRATOS_API.yaml) defines two metadata extensions:
`x-ubl` (XML element and attributes) and `x-sunat` (row in this matrix, catalog, format, and business rule). JSON constraints
(`pattern`, `maxLength`, `enum`, `maximum`) derive directly from the SUNAT specification. Thus, the API rejects invalid data **before** generating an XML document that SUNAT/OSE would reject.

There are three data flow categories:

- **Received**: supplied by the API client.
- **Configured**: originates from the issuer configuration or product master.
- **Generated**: calculated by the domain core. **Never** accepted from the API, ensuring XML structural integrity.

| API field (DTO) | Origin | UBL 2.1 Peru Element | Row | Catalog | SUNAT Format → API Constraint | Rule |
| :--- | :---: | :--- | :---: | :---: | :--- | :--- |
| — | Generated | `cbc:UBLVersionID` = 2.1, `cbc:CustomizationID` = 2.0 | T01, T02 | — | constant | RN-11 |
| `serie` + internal sequence | Received + Generated | `cbc:ID` | T03 | — | `an..13` → `^[FB][A-Z0-9]{3}$` + sequence `n..8` | RN-03, RN-04 |
| `fechaEmision` | Received | `cbc:IssueDate` | T04 | — | `YYYY-MM-DD` → `format: date` | RN-05 |
| — | Generated | `cbc:IssueTime` | T05 | — | `hh:mm:ss` | — |
| `formaPago.cuotas[-1].fechaVencimiento` | Received | `cbc:DueDate` | T06 | — | `format: date` | RN-10 |
| `tipoComprobante` | Received | `cbc:InvoiceTypeCode` | T07 | 01 | `an2` → `enum` | RN-03 |
| `tipoOperacion` | Received | `cbc:InvoiceTypeCode/@listID` | T08 | 51 | `an4` → `^\d{4}$` | — |
| `totales.montoEnLetras` | Generated | `cbc:Note[@languageLocaleID="1000"]` | T09 | 52 | `an..200` | — |
| `observaciones` | Received | `cbc:Note` | — | — | `an..200` → `maxLength: 200` | — |
| `moneda` | Received | `cbc:DocumentCurrencyCode` & `@currencyID` | T10 | 02 | `an3` → `enum` | RN-09 |
| — | Generated | `cbc:LineCountNumeric` | T11 | — | `n..4` | — |
| `hash` (output) | Generated | `ds:DigestValue` | T12 | — | — | RN-11 |
| `formaPago.tipo` / `cuotas[].monto` | Received | `cac:PaymentTerms/cbc:PaymentMeansID` / `cbc:Amount` | T14 | — | `Contado`/`Credito`, `n(12,2)` | RN-10 |
| `configuracion.ruc` | Configured | `cac:AccountingSupplierParty/.../cbc:ID` | E01 | 06 | `n11` → `^(10\|15\|16\|17\|20)\d{9}$` | RN-01 |
| `configuracion.nombreComercial` | Configured | `cac:PartyName/cbc:Name` | E02 | — | `an..1500` | — |
| `configuracion.razonSocial` | Configured | `cac:PartyLegalEntity/cbc:RegistrationName` | E03 | — | `an..1500` | — |
| `configuracion.codigoEstablecimiento` | Configured | `cac:RegistrationAddress/cbc:AddressTypeCode` | E04 | — | `an4` → `^\d{4}$` | — |
| `configuracion.ubigeo` / `direccion` | Configured | `cac:RegistrationAddress/cbc:ID` / `cac:AddressLine/cbc:Line` | E05 | INEI | `an6` / `an..200` | — |
| `cliente.tipoDoc` | Received | `cac:AccountingCustomerParty/.../cbc:ID/@schemeID` | R01 | 06 | `an1` → `enum` | RN-02 |
| `cliente.numeroDoc` | Received | `cac:AccountingCustomerParty/.../cbc:ID` | R01 | — | `an..15` → `maxLength: 15` + pattern per type | RN-02, RN-06 |
| `cliente.razonSocial` | Received | `cac:PartyLegalEntity/cbc:RegistrationName` | R02 | — | `an..1500` | RN-06 |
| position in `items[]` | Generated | `cac:InvoiceLine/cbc:ID` | L01 | — | `n..3` | — |
| `items[].cantidad` | Received | `cbc:InvoicedQuantity` | L02 | — | `n(12,10)` → `maximum`, `> 0` | — |
| `items[].unidadMedida` | Received / Configured | `cbc:InvoicedQuantity/@unitCode` | L03 | 03 | `an..3` → `^[A-Z0-9]{1,3}$` | — |
| `items[].descripcion` | Received / Configured | `cac:Item/cbc:Description` | L04 | — | `an..500` | — |
| `items[].codigoProducto` | Received | `cac:Item/cac:SellersItemIdentification/cbc:ID` | L05 | — | `an..30` | RN-13 |
| `producto.codigoSunat` | Configured | `cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode` | L06 | 25 | `an..8` → `^\d{8}$` | — |
| `items[].valorUnitario` | Received | `cac:Price/cbc:PriceAmount` | L07 | — | `n(12,10)` | RN-07 |
| `items[].precioUnitario` + `tipoPrecio` | Received | `cac:PricingReference/.../cbc:PriceAmount` + `cbc:PriceTypeCode` | L08 | 16 | `n(12,10)`, `an2` | RN-07 |
| — | Generated | `cac:InvoiceLine/cbc:LineExtensionAmount` | L09 | — | `n(12,2)` | RN-07 |
| `items[].descuento` / `descuentoGlobal` | Received | `cac:AllowanceCharge` | M03 | 53 | `n(12,2)` | RN-07, RN-08 |
| `totales.tributos[].codigo` / `nombre` / `codigoInternacional` | Generated | `cac:TaxScheme/cbc:ID` / `cbc:Name` / `cbc:TaxTypeCode` | X01 | 05 | `an4` → `enum` | RN-07 |
| `items[].tipoAfectacionIgv` | Received / Configured | `cbc:TaxExemptionReasonCode` | X02 | 07 | `an2` → `enum` | RN-07 |
| `totales.tributos[].tasa` | Generated | `cbc:Percent` / `cbc:PerUnitAmount` | X03, X05, X06 | — | `n(3,5)` | RN-07 |
| `producto.isc.sistema` | Configured | `cbc:TierRange` | X04 | **08** | `an2` → `enum ['01','02','03']` | RN-07 |
| `producto.afectoIcbper` | Configured | `cbc:BaseUnitMeasure` + `cbc:PerUnitAmount` (tax 7152) | X06 | 05 | `n(12,2)` | RN-07 |
| `totales.tributos[].base` / `monto` | Generated | `cbc:TaxableAmount` / `cbc:TaxAmount` | X07, X08 | — | `n(12,2)` | RN-07 |
| `totales.totalTributos` | Generated | `/Invoice/cac:TaxTotal/cbc:TaxAmount` | X09 | — | `n(12,2)` | RN-08 |
| `totales.valorVenta` / `precioVenta` / `importeTotal` | Generated | `LegalMonetaryTotal/cbc:LineExtensionAmount` / `TaxInclusiveAmount` / `PayableAmount` | M01, M02, M06 | — | `n(12,2)` | RN-08 |
| `respuestaSunat.codigo` / `descripcion` / `observaciones` | Generated (CDR) | `ApplicationResponse/.../cbc:ResponseCode` / `cbc:Description` / `cbc:Note` | 4.7 | — | — | — |
| `notas.motivo` / `sustento` | Received | `cac:DiscrepancyResponse/cbc:ResponseCode` / `cbc:Description` | — | 09 / 10 | `an2` / `an..250` | — |
| `baja.motivo` | Received | `sac:VoidedDocumentsLine/sac:VoidReasonDescription` | — | — | `an..100` | — |
| `cliente.email`, `tipoCambio`, `origenLegacy` | Received / Generated | **Not transmitted in XML** (internal business logic, sales register, or legacy traceability) | 4.6 | — | — | RN-09, RN-13 |

**Coordinated error structure:** `ErrorResponse.detalles[]` returns the API `campo` alongside the affected `elementoUbl`. When rejection comes directly from SUNAT/OSE, it additionally includes `codigoSunat`. Errors can be traced bidirectionally: API → XML → SUNAT business validation rule.
