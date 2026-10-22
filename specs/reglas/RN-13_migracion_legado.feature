# language: es
# Spec ejecutable de la migración del software básico de almacén (RN-13).
# Trazabilidad: docs/01_MODELO_DE_DOMINIO.md §6 · docs/04_MATRIZ_TRAZABILIDAD.md §4.6 · specs/migracion/mapeo-legado.yaml · CU-12

Característica: Migración de datos legados sin perder trazabilidad
  Como administrador de ABC
  Quiero importar el historial de fecha, ingreso, salida, producto y nro_documento
  Para conservar el kardex (RS 234-2006) sin emitir comprobantes electrónicos retroactivos

  Antecedentes:
    Dado un archivo legado "almacen_2019_2026.csv" con las filas:
      | fila | fecha      | ingreso | salida | producto               | nro_documento |
      | 1    | 05/03/2019 | 50      | 0      | aceite vegetal 1L cja  | ING-001       |
      | 2    | 06/03/2019 | 0       | 10     | ACEITE VEGETAL 1L CJA  | 0045          |
      | 3    | 31/02/2019 | 5       | 0      | azucar rubia 50kg      | ING-002       |
      | 4    | 07/03/2019 | 20      | 4      | Azucar Rubia 50 kg     | s/n           |
      | 5    | 08/03/2019 | 0       | 0      |                        | X-9           |

  Escenario: Carga a staging y vista previa (dry-run)
    Cuando cargo el archivo
    Entonces se crea un lote en estado "VALIDADO"
    Y filasLeidas es 5
    Y las filas rechazadas son:
      | fila | motivo                         |
      | 3    | Fecha inválida '31/02/2019'    |
      | 5    | Producto vacío                 |
    Y productosACrear es 2
    Y movimientosACrear es 4
    Y no se ha escrito nada en las tablas de inventario

  Escenario: Normalización y deduplicación de productos
    Cuando cargo el archivo
    Entonces "aceite vegetal 1L cja" y "ACEITE VEGETAL 1L CJA" se agrupan en un solo producto
    Y "azucar rubia 50kg" y "Azucar Rubia 50 kg" se agrupan en un solo producto
    Y cada producto nuevo recibe un código interno y la unidad "NIU" marcada para revisión

  Escenario: Una fila con ingreso y salida genera dos movimientos
    Cuando ejecuto la migración del lote
    Entonces la fila 4 genera un MovimientoInventario INGRESO de 20 y uno SALIDA de 4
    Y ambos tienen OrigenLegacy con filaOrigen 4 y nroDocumentoLegacy "s/n"

  Escenario: Cada registro migrado es rastreable a su fila de origen
    Cuando ejecuto la migración del lote
    Entonces cada MovimientoInventario tiene OrigenLegacy con loteId, filaOrigen, nroDocumentoLegacy y hashFila
    Y hashFila es el SHA-256 de la fila original sin modificar

  Escenario: Reconciliación exitosa
    Cuando ejecuto la migración del lote aceptando las filas rechazadas
    Entonces la reconciliación es:
      | concepto            | legado | migrado |
      | totalIngresos       | 70     | 70      |
      | totalSalidas        | 14     | 14      |
    Y el estado del lote es "CON_ERRORES"
    # CON_ERRORES porque se aceptaron 2 filas rechazadas; los totales excluyen esas filas en ambos lados.

  Escenario: Reconciliación fallida revierte el lote
    Dado que durante la carga falla la inserción del movimiento de la fila 2
    Cuando termina la ejecución
    Entonces la reconciliación no cuadra
    Y el estado del lote es "REVERTIDO"
    Y no queda ningún movimiento del lote en inventario

  Escenario: La migración es idempotente
    Dado que el archivo ya fue migrado en el lote "L-1"
    Cuando vuelvo a cargar el mismo archivo
    Entonces la API responde 409 indicando el lote "L-1"
    Y no se duplica ningún movimiento

  Escenario: El legado no genera comprobantes electrónicos
    Cuando ejecuto la migración del lote
    Entonces no se crea ningún ComprobantePago
    Y ninguna serie cambia su último correlativo
