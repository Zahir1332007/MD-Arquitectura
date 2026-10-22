# language: es
# Spec ejecutable del motor de tributos y totales (RN-07, RN-08), incluido el Catálogo 08 (sistema de cálculo del ISC).
# Trazabilidad: docs/01_MODELO_DE_DOMINIO.md §3.1 y §4 · docs/04_MATRIZ_TRAZABILIDAD.md (L07–L09, X01–X09, M01–M06)
# Convención: montos de línea redondeados a 2 decimales (HALF_UP) en cada paso; IGV = 18 %.

Característica: Cálculo de tributos IGV, ISC (Catálogo 08) e ICBPER
  Como contador de ABC
  Quiero que los montos del XML se calculen siempre igual
  Para que SUNAT/OSE no rechace comprobantes por inconsistencia de montos

  Antecedentes:
    Dado la tasa de IGV es 18.00 %
    Y la tasa de ICBPER vigente es 0.50 por bolsa

  # ---------- IGV (Cat. 05 = 1000, Cat. 07 = 10) ----------
  Escenario: Línea gravada con valor unitario sin IGV
    Dado el producto "PROD-001" con afectación IGV "10"
    Cuando agrego 10 unidades con valor unitario 100.00
    Entonces la línea tiene:
      | elemento UBL                        | fila | valor   |
      | cbc:LineExtensionAmount             | L09  | 1000.00 |
      | cac:TaxSubtotal/cbc:TaxableAmount   | X07  | 1000.00 |
      | cac:TaxSubtotal/cbc:TaxAmount       | X08  | 180.00  |
      | cac:TaxScheme/cbc:ID                | X01  | 1000    |
      | cbc:TaxExemptionReasonCode          | X02  | 10      |
      | cbc:PriceTypeCode                   | L08  | 01      |
      | AlternativeConditionPrice/PriceAmount | L08 | 118.00  |
    Y los totales del comprobante son:
      | elemento UBL                        | fila | valor   |
      | cbc:LineExtensionAmount             | M01  | 1000.00 |
      | /Invoice/cac:TaxTotal/cbc:TaxAmount | X09  | 180.00  |
      | cbc:TaxInclusiveAmount              | M02  | 1180.00 |
      | cbc:PayableAmount                   | M06  | 1180.00 |
    Y la leyenda 1000 (Cat. 52) es "MIL CIENTO OCHENTA CON 00/100 SOLES"

  Escenario: Línea gravada ingresada con precio unitario (incluye IGV)
    Cuando agrego 10 unidades del producto "PROD-001" con precio unitario 118.00
    Entonces el valor unitario calculado es 100.00
    Y el IGV de la línea es 180.00

  Esquema del escenario: Afectaciones distintas de gravado (Cat. 07 → Cat. 05)
    Cuando agrego 1 unidad con valor unitario 50.00 y afectación IGV "<cat07>"
    Entonces el tributo de la línea es "<cat05>" con nombre "<nombre>" y código internacional "<tipo>"
    Y el monto del tributo es 0.00
    Y el importe total es 50.00

    Ejemplos:
      | cat07 | cat05 | nombre | tipo |
      | 20    | 9997  | EXO    | VAT  |
      | 30    | 9998  | INA    | FRE  |
      | 40    | 9995  | EXP    | FRE  |

  Escenario: Operación gratuita (transferencia a título gratuito)
    Cuando agrego 1 unidad con valor referencial 20.00 y afectación IGV "21"
    Entonces cbc:PriceTypeCode es "02" (Cat. 16)
    Y el tributo del resumen es "9996" GRA
    Y el importe total es 0.00
    Y se agrega la leyenda "1002" (Cat. 52)

  # ---------- ISC: Catálogo 08 (cbc:TierRange) ----------
  # El ISC se calcula ANTES del IGV porque forma parte de su base imponible.
  Esquema del escenario: Cálculo del ISC según el sistema del Catálogo 08
    Dado un producto afecto a ISC con sistema "<cat08>" y <parametro>
    Cuando agrego <cantidad> unidades con valor unitario <valorUnitario>
    Entonces cbc:TierRange es "<cat08>"
    Y el valor de venta de la línea es <valorVenta>
    Y el ISC (tributo 2000, EXC) es <isc>
    Y la base imponible del IGV es <baseIgv>
    Y el IGV es <igv>
    Y el total de la línea es <total>

    Ejemplos:
      | cat08 | parametro                                   | cantidad | valorUnitario | valorVenta | isc   | baseIgv | igv   | total  |
      | 01    | tasa 17.00 %                                | 10       | 10.00         | 100.00     | 17.00 | 117.00  | 21.06 | 138.06 |
      | 02    | monto fijo 2.50 por unidad                  | 12       | 5.00          | 60.00      | 30.00 | 90.00   | 16.20 | 106.20 |
      | 03    | tasa 30.00 % y precio de venta al público 10.00 | 10   | 6.00          | 60.00      | 25.42 | 85.42   | 15.38 | 100.80 |
    # Sistema 03: ISC = (PVP × cantidad / 1.18) × tasa = (100.00 / 1.18) × 0.30 = 25.42

  Escenario: Un producto con ISC sin sistema configurado no se puede vender
    Dado un producto afecto a ISC sin sistema del Catálogo 08
    Cuando lo agrego a una factura
    Entonces la emisión se rechaza con código "MONTOS_INCONSISTENTES" y regla "RN-07"

  Escenario: El código del Catálogo 08 solo aparece en el tributo ISC
    Dado un producto afecto a ISC con sistema "01" y tasa 17.00 %
    Cuando genero el XML
    Entonces cbc:TierRange aparece solo en el cac:TaxSubtotal con cac:TaxScheme/cbc:ID "2000"
    Y no aparece en el cac:TaxSubtotal del IGV

  # ---------- ICBPER (Cat. 05 = 7152) ----------
  Escenario: Venta de bolsas plásticas
    Dado el producto "BOLSA-01" con afectación IGV "10" y afecto a ICBPER
    Cuando agrego 2 unidades con valor unitario 0.10
    Entonces el valor de venta de la línea es 0.20
    Y el IGV de la línea es 0.04
    Y el tributo "7152" ICBPER (OTH) tiene cbc:BaseUnitMeasure 2, cbc:PerUnitAmount 0.50 y monto 1.00

  # ---------- RN-08 Totales ----------
  Escenario: Totales con varias líneas y descuento global
    Dado una factura con las líneas:
      | producto | cantidad | valorUnitario | afectacion |
      | PROD-001 | 10       | 100.00        | 10         |
      | PROD-002 | 1        | 50.00         | 20         |
    Y un descuento global que afecta la base de 100.00 (Cat. 53 código "02")
    Entonces los totales son:
      | elemento UBL                  | fila | valor   |
      | cac:AllowanceCharge/cbc:Amount | M03 | 100.00  |
      | cbc:LineExtensionAmount       | M01  | 950.00  |
      | TaxSubtotal 1000 TaxableAmount| X07  | 900.00  |
      | TaxSubtotal 1000 TaxAmount    | X08  | 162.00  |
      | TaxSubtotal 9997 TaxableAmount| X07  | 50.00   |
      | cbc:TaxInclusiveAmount        | M02  | 1112.00 |
      | cbc:PayableAmount             | M06  | 1112.00 |
    # El descuento "02" afecta la base: reduce LineExtensionAmount y la base del IGV.
    # cbc:AllowanceTotalAmount se reserva para descuentos globales que NO afectan la base (Cat. 53 "03").

  Escenario: Descuento global que no afecta la base imponible
    Dado una factura con 10 unidades de "PROD-001" a valor unitario 100.00
    Y un descuento global que no afecta la base de 50.00 (Cat. 53 código "03")
    Entonces los totales son:
      | elemento UBL                  | fila | valor   |
      | cbc:LineExtensionAmount       | M01  | 1000.00 |
      | /Invoice/cac:TaxTotal/cbc:TaxAmount | X09 | 180.00 |
      | cbc:TaxInclusiveAmount        | M02  | 1180.00 |
      | cbc:AllowanceTotalAmount      | M03  | 50.00   |
      | cbc:PayableAmount             | M06  | 1130.00 |

  Escenario: Los totales enviados por el cliente de la API se ignoran
    Cuando envío un EmitirComprobanteRequest con un campo "importeTotal" de 999.99
    Entonces la API responde 400 porque el campo no existe en el contrato
