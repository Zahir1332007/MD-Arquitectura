// Spec-First: contratos de los PUERTOS DE SALIDA del núcleo hexagonal.
// El dominio solo conoce estas interfaces; los adaptadores (SQLite, firma, SOAP SUNAT/OSE, padrón, legado) las implementan.
// Ubicación prevista: core-application/src/commonMain/kotlin/pe/abc/facturacion/application/port/output
// Trazabilidad: docs/02_ARQUITECTURA.md §2 y §4 · specs/03_CONTRATOS_API.yaml (x-servicios-externos)
package pe.abc.facturacion.application.port.output

import pe.abc.facturacion.domain.*
import java.time.LocalDate
import java.util.UUID

/** Persistencia del agregado ComprobantePago. Adaptador: adapters-persistence (SQLDelight/SQLite; PostgreSQL en fase 2). */
interface ComprobanteRepository {
    fun guardar(comprobante: ComprobantePago)
    fun buscarPorId(id: UUID): ComprobantePago?
    fun buscarPorNumero(rucEmisor: Ruc, tipo: TipoComprobante, serie: String, correlativo: Long): ComprobantePago?
    fun pendientesDeEnvio(): List<ComprobantePago>
    fun boletasSinResumen(fecha: LocalDate): List<ComprobantePago>
}

/** RN-04: asignación atómica del correlativo (bloqueo transaccional por serie). */
interface SerieRepository {
    fun siguienteCorrelativo(serie: String, tipo: TipoComprobante): Long
}

/** Idempotencia de la API (Idempotency-Key). */
interface IdempotenciaRepository {
    fun resultadoPrevio(clave: UUID): UUID?
    fun registrar(clave: UUID, comprobanteId: UUID)
}

interface ClienteRepository {
    fun guardar(cliente: Cliente)
    fun buscar(tipoDoc: TipoDocIdentidad, numeroDoc: String): Cliente?
}

interface ProductoRepository {
    fun guardar(producto: Producto)
    fun buscarPorCodigo(codigo: String): Producto?
    fun buscarPorTexto(texto: String): List<Producto>
}

interface InventarioRepository {
    fun registrar(movimientos: List<MovimientoInventario>)
    fun totalesPorLote(loteId: UUID): TotalesReconciliacion
}

/** Genera el XML UBL 2.1 Perú (estructura 2.0) a partir del agregado. Adaptador: adapters-sunat. Matriz 04 §4.1–4.5. */
interface GeneradorUblPort {
    fun generar(comprobante: ComprobantePago): XmlUbl
    /** RN-11: XSD UBL 2.1 + personalización SUNAT. Devuelve la lista de violaciones (vacía si es válido). */
    fun validar(xml: XmlUbl): List<ViolacionUbl>
}

/** Firma XML-DSig con el certificado .pfx del emisor (T12). */
interface FirmaDigitalPort {
    fun firmar(xml: XmlUbl): XmlFirmado   // incluye el DigestValue (hash)
}

/** Servicio SOAP billService de SUNAT u OSE (mismo contrato). Un adaptador por proveedor. */
interface EnvioSunatPort {
    /** sendBill: envío síncrono de factura, boleta o nota. Lanza ExcepcionTransitoria si no hay conexión. */
    fun enviar(nombreZip: String, zip: ByteArray): Cdr
    /** sendSummary: resumen diario (RC) o comunicación de baja (RA). */
    fun enviarResumen(nombreZip: String, zip: ByteArray): String // ticket
    /** getStatus */
    fun consultarTicket(ticket: String): EstadoTicket
}

/** Consulta de estado y condición del contribuyente (RN-01, RN-02). */
interface PadronRucPort {
    fun consultar(ruc: Ruc): ContribuyentePadron?
}

/** Lectura del software básico de almacén (CU-12). */
interface LegacySourcePort {
    fun leer(archivo: ByteArray, formatoFecha: String): Sequence<RegistroLegado>
}

/** Representación impresa (PDF con QR y hash) y envío por correo (CU-08). */
interface RepresentacionImpresaPort {
    fun pdf(comprobante: ComprobantePago): ByteArray
}

interface NotificacionPort {
    fun enviarCorreo(destinatarios: List<String>, adjuntos: Map<String, ByteArray>)
}

/** Eventos de dominio entre contextos (ComprobanteAceptado → inventario). En fase 3 se implementa con un broker. */
interface EventPublisherPort {
    fun publicar(evento: EventoDominio)
}

/** Reloj y parámetros normativos configurables (plazos, umbral de boleta, tasas IGV/ICBPER). */
interface ParametrosNormativosPort {
    fun hoy(): LocalDate
    fun plazoMaximoEnvioDias(tipo: TipoComprobante): Int
    fun umbralBoletaIdentificada(): java.math.BigDecimal
    fun tasaIgv(): java.math.BigDecimal
    fun tasaIcbper(fecha: LocalDate): java.math.BigDecimal
}
