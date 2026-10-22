# language: es
# Spec ejecutable (Gherkin) de las reglas de emisión RN-01..RN-06.
# Trazabilidad: docs/01_MODELO_DE_DOMINIO.md §4 · docs/04_MATRIZ_TRAZABILIDAD.md (T03, T04, T07, E01, R01) · CU-01, CU-02

Característica: Validación de datos de emisión según UBL 2.1 Perú y SUNAT
  Como vendedor de ABC
  Quiero que el sistema rechace los datos inválidos antes de generar el XML
  Para que SUNAT/OSE no rechace el comprobante y no se pierda el correlativo

  Antecedentes:
    Dado un emisor configurado con RUC "20123456786" y certificado digital vigente
    Y la serie "F001" para facturas con último correlativo 0
    Y la serie "B001" para boletas con último correlativo 0

  # ---------- RN-01 / RN-02 RUC y documento de identidad (Cat. 06) ----------
  Esquema del escenario: Validar el RUC por formato y dígito verificador (módulo 11)
    Cuando valido el documento tipo "6" número "<ruc>"
    Entonces el resultado de formato es "<formato>"
    Y el dígito verificador es "<dv>"

    Ejemplos:
      | ruc          | formato  | dv       | comentario                          |
      | 20123456786  | válido   | válido   | pesos 5,4,3,2,7,6,5,4,3,2 → dv 6    |
      | 20123456789  | válido   | inválido | dv esperado 6                       |
      | 20600000005  | válido   | válido   |                                     |
      | 10456789012  | válido   | --       | persona natural, se calcula el dv   |
      | 30123456786  | inválido | --       | prefijo no permitido                |
      | 2012345678   | inválido | --       | 10 dígitos                          |

  Escenario: RUC del cliente en estado de BAJA no permite facturar
    Dado que el padrón SUNAT informa el RUC "20600000005" con estado "BAJA DE OFICIO"
    Cuando emito una factura para ese cliente
    Entonces la emisión se rechaza con código "DOC_CLIENTE_INVALIDO" y regla "RN-02"
    Y no se consume ningún correlativo de la serie "F001"

  Esquema del escenario: DNI con formato inválido
    Cuando valido el documento tipo "1" número "<dni>"
    Entonces el resultado de formato es "<formato>"

    Ejemplos:
      | dni       | formato  |
      | 45678912  | válido   |
      | 4567891   | inválido |
      | 4567891A  | inválido |

  # ---------- RN-03 / RN-04 Serie y correlativo (T03: cbc:ID an..13) ----------
  Esquema del escenario: La serie debe corresponder al tipo de comprobante
    Cuando emito un comprobante tipo "<tipo>" con serie "<serie>"
    Entonces el resultado es "<resultado>"

    Ejemplos:
      | tipo | serie | resultado                     |
      | 01   | F001  | aceptado                      |
      | 03   | B001  | aceptado                      |
      | 01   | B001  | rechazado con SERIE_INVALIDA  |
      | 03   | F001  | rechazado con SERIE_INVALIDA  |
      | 01   | F01   | rechazado con SERIE_INVALIDA  |
      | 01   | X001  | rechazado con SERIE_INVALIDA  |

  Escenario: El correlativo lo asigna el sistema y es consecutivo
    Cuando emito 3 facturas válidas con la serie "F001"
    Entonces los cbc:ID generados son "F001-1", "F001-2" y "F001-3"
    Y los archivos se nombran "20123456786-01-F001-1.zip", "20123456786-01-F001-2.zip" y "20123456786-01-F001-3.zip"

  Escenario: Dos cajas emitiendo a la vez no duplican correlativos
    Cuando dos usuarios emiten simultáneamente una factura con la serie "F001"
    Entonces los correlativos asignados son distintos
    Y no hay saltos en la secuencia

  Escenario: Un comprobante rechazado consume su correlativo
    Dado que la factura "F001-1" fue RECHAZADA por SUNAT con código "2800"
    Cuando emito una nueva factura con la serie "F001"
    Entonces su cbc:ID es "F001-2"

  Escenario: Se ignora el número de documento del software legado
    Dado un registro legado con nro_documento "FAC-0045"
    Cuando se migra el registro
    Entonces "FAC-0045" queda en OrigenLegacy.nroDocumentoLegacy
    Y no se usa como serie ni como correlativo

  # ---------- RN-05 Fecha de emisión (T04) ----------
  Escenario: No se permiten fechas de emisión futuras
    Dado que hoy es "2026-10-22"
    Cuando emito una factura con fecha de emisión "2026-10-23"
    Entonces la emisión se rechaza con código "FECHA_FUERA_DE_PLAZO" y regla "RN-05"

  Escenario: Fecha fuera del plazo máximo de envío configurado
    Dado que hoy es "2026-10-22"
    Y el parámetro "plazoMaximoEnvioDias" vale 3
    Cuando emito una factura con fecha de emisión "2026-10-15"
    Entonces la emisión se rechaza con código "FECHA_FUERA_DE_PLAZO" y regla "RN-05"

  # ---------- RN-06 Cliente obligatorio ----------
  Escenario: La factura exige cliente con RUC
    Cuando emito una factura con cliente tipo "1" número "45678912"
    Entonces la emisión se rechaza con código "CLIENTE_REQUERIDO" y regla "RN-06"

  Esquema del escenario: Boleta con o sin identificación del cliente según el monto
    Dado el parámetro "umbralBoletaIdentificada" vale 700.00
    Cuando emito una boleta por un importe total de <importe> con cliente tipo "<tipoDoc>"
    Entonces el resultado es "<resultado>"

    Ejemplos:
      | importe | tipoDoc | resultado                       |
      | 150.00  | -       | aceptado                        |
      | 700.00  | -       | aceptado                        |
      | 700.01  | -       | rechazado con CLIENTE_REQUERIDO |
      | 900.00  | 1       | aceptado                        |
