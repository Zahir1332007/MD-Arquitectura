# language: es
# Spec ejecutable del ciclo de vida del comprobante: forma de pago, XML, envío, CDR, notas y bajas (RN-09..RN-12).
# Trazabilidad: docs/01_MODELO_DE_DOMINIO.md §5 · docs/04_MATRIZ_TRAZABILIDAD.md (T10, T12, T14, §4.7) · CU-03, CU-05, CU-13

Característica: Ciclo de vida del comprobante electrónico

  Antecedentes:
    Dado un emisor configurado con RUC "20123456786"

  # ---------- RN-09 Moneda ----------
  Escenario: Factura en dólares exige tipo de cambio
    Cuando emito una factura en moneda "USD" sin tipo de cambio
    Entonces la emisión se rechaza con código "TIPO_CAMBIO_REQUERIDO" y regla "RN-09"

  Escenario: Todos los montos llevan la moneda del comprobante
    Cuando emito una factura válida en moneda "USD" con tipo de cambio 3.75
    Entonces cbc:DocumentCurrencyCode es "USD"
    Y todos los atributos @currencyID del XML son "USD"

  # ---------- RN-10 Forma de pago (T14) ----------
  Escenario: Factura al contado
    Cuando emito una factura con forma de pago "Contado"
    Entonces existe cac:PaymentTerms con cbc:ID "FormaPago" y cbc:PaymentMeansID "Contado"

  Escenario: Factura al crédito en cuotas
    Dado una factura con importe total 1180.00
    Cuando la emito con forma de pago "Credito" y las cuotas:
      | monto  | fechaVencimiento |
      | 590.00 | 2026-11-22       |
      | 590.00 | 2026-12-22       |
    Entonces existen cac:PaymentTerms con cbc:PaymentMeansID "Credito", "Cuota001" y "Cuota002"
    Y cbc:DueDate es "2026-12-22"

  Escenario: Las cuotas no suman el monto pendiente
    Dado una factura con importe total 1180.00
    Cuando la emito con forma de pago "Credito" y una cuota de 500.00
    Entonces la emisión se rechaza con código "CUOTAS_INVALIDAS" y regla "RN-10"

  # ---------- RN-11 XML UBL 2.1 Perú ----------
  Escenario: El XML generado cumple la estructura UBL 2.1 Perú
    Cuando emito una factura válida
    Entonces el XML valida contra "UBL-Invoice-2.1.xsd"
    Y cbc:UBLVersionID es "2.1"
    Y cbc:CustomizationID es "2.0" con schemeAgencyName "PE:SUNAT"
    Y cbc:InvoiceTypeCode tiene listURI "urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo01" y listID "0101"
    Y existe ds:Signature dentro de ext:UBLExtensions
    Y el XML coincide en estructura con "specs/ejemplos/20123456786-01-F001-1.xml"

  Escenario: Un XML que no valida no se firma ni se envía
    Dado que el generador produce un XML sin cac:LegalMonetaryTotal
    Cuando se intenta firmar
    Entonces el proceso se detiene con código "XML_NO_VALIDA_XSD" y regla "RN-11"
    Y el estado del comprobante sigue en "VALIDADO"

  # ---------- Respuesta SUNAT/OSE (§4.7) ----------
  Esquema del escenario: El código del CDR determina el estado
    Dado una factura en estado "ENVIADO"
    Cuando SUNAT/OSE responde con cbc:ResponseCode "<codigo>"
    Entonces el estado del comprobante es "<estado>"

    Ejemplos:
      | codigo | estado            |
      | 0      | ACEPTADO          |
      | 0109   | PENDIENTE_ENVIO   |
      | 2800   | RECHAZADO         |
      | 4252   | ACEPTADO_CON_OBS  |

  Escenario: Sin conexión la venta no se detiene
    Dado que el servicio de SUNAT/OSE no responde
    Cuando emito una factura válida
    Entonces la API responde 202
    Y el estado es "PENDIENTE_ENVIO"
    Y el XML firmado queda guardado

  Escenario: El reintento reenvía el mismo XML firmado
    Dado una factura en "PENDIENTE_ENVIO" con hash "qW2a"
    Cuando el planificador reintenta el envío y SUNAT responde "0"
    Entonces el estado es "ACEPTADO"
    Y el hash sigue siendo "qW2a"

  Escenario: Un comprobante aceptado genera la salida de inventario
    Cuando SUNAT acepta una factura con 10 unidades de "PROD-001"
    Entonces existe un MovimientoInventario SALIDA de 10 unidades de "PROD-001" con documentoReferencia "F001-1"

  # ---------- RN-12 Inmutabilidad, notas y bajas ----------
  Escenario: Un comprobante aceptado no se puede modificar
    Dado la factura "F001-1" en estado "ACEPTADO"
    Cuando intento modificar su cliente
    Entonces la operación se rechaza con código "COMPROBANTE_INMUTABLE" y regla "RN-12"

  Escenario: Nota de crédito por anulación de la operación
    Dado la factura "F001-1" en estado "ACEPTADO" por 1180.00
    Cuando emito una nota de crédito con serie "F001", motivo "01" y sustento "Anulación de la operación"
    Entonces se genera un documento /CreditNote con cac:BillingReference/cac:InvoiceDocumentReference/cbc:ID "F001-1"
    Y cac:DiscrepancyResponse/cbc:ResponseCode es "01" (Cat. 09)
    Y su importe total es 1180.00

  Escenario: La nota de crédito no puede superar al documento afectado
    Dado la factura "F001-1" en estado "ACEPTADO" por 1180.00
    Cuando emito una nota de crédito por 1500.00
    Entonces la emisión se rechaza con código "MONTOS_INCONSISTENTES"

  Escenario: Comunicación de baja de una factura
    Dado la factura "F001-1" en estado "ACEPTADO"
    Cuando solicito su baja con motivo "Error en la descripción del cliente"
    Entonces se envía un /VoidedDocuments con identificador "RA-20261022-1" mediante sendSummary
    Y la API responde 202 con un ticket
    Cuando getStatus del ticket devuelve statusCode "0"
    Entonces el estado de la factura es "ANULADO"
