// Spec-First: contratos de los PUERTOS DE ENTRADA (casos de uso) del núcleo hexagonal.
// Solo firmas, sin lógica. En el monolito MVC los invocan los Controladores; en Hexagonal, también el adaptador REST.
// Ubicación prevista: core-application/src/commonMain/kotlin/pe/abc/facturacion/application/port/input
// Trazabilidad: docs/02_ARQUITECTURA.md §4 · docs/05_CASOS_DE_USO.md · specs/03_CONTRATOS_API.yaml (DTOs)
package pe.abc.facturacion.application.port.input

import pe.abc.facturacion.application.dto.*
import java.util.UUID

/** Resultado tipado: los errores de regla (RN-xx) no se lanzan como excepciones genéricas. */
sealed interface Resultado<out T> {
    data class Ok<T>(val valor: T) : Resultado<T>
    data class Error(val codigo: String, val regla: String?, val mensaje: String, val detalles: List<DetalleError> = emptyList()) :
        Resultado<Nothing>
}

data class DetalleError(val campo: String, val elementoUbl: String?, val mensaje: String)

/** CU-01, CU-02 · EP-01 · RN-01..RN-12 */
interface EmitirComprobanteUseCase {
    fun emitir(request: EmitirComprobanteRequest, idempotencyKey: UUID): Resultado<ComprobanteResponse>
}

/** CU-03, CU-04 · EP-05 · Cat. 09 / 10 */
interface EmitirNotaUseCase {
    fun emitir(comprobanteAfectadoId: UUID, request: NotaRequest, idempotencyKey: UUID): Resultado<ComprobanteResponse>
}

/** CU-05 · EP-06 · RN-12 (VoidedDocuments RA / SummaryDocuments RC) */
interface AnularComprobanteUseCase {
    fun solicitarBaja(comprobanteId: UUID, request: BajaRequest): Resultado<TicketResponse>
}

/** CU-06 · EP-07 */
interface EnviarResumenDiarioUseCase {
    fun enviar(fechaEmisionComprobantes: java.time.LocalDate): Resultado<TicketResponse>
    fun consultarTicket(ticket: String): Resultado<TicketResponse>
}

/** CU-07, CU-08 · EP-02..EP-04 */
interface ConsultarComprobanteUseCase {
    fun obtener(id: UUID): Resultado<ComprobanteResponse>
    fun listar(filtro: FiltroComprobantes): Resultado<Pagina<ComprobanteResponse>>
    fun archivo(id: UUID, formato: FormatoArchivo): Resultado<ByteArray>
}

/** CU-13 · EP-16 */
interface ReenviarPendientesUseCase {
    fun reenviar(): Resultado<ResumenReintento>
}

/** CU-09 · EP-08, EP-09 · RN-01, RN-02 */
interface GestionarClientesUseCase {
    fun registrar(cliente: ClienteDto): Resultado<ClienteDto>
    fun validarDocumento(tipoDoc: String, numeroDoc: String): Resultado<ValidacionDocumentoResponse>
}

/** CU-10 · EP-10 · RN-07 (configuración de IGV, ISC Cat. 08 e ICBPER) */
interface GestionarProductosUseCase {
    fun registrar(producto: ProductoDto): Resultado<ProductoDto>
    fun buscar(texto: String): Resultado<List<ProductoDto>>
}

/** CU-11 · EP-11, EP-12 */
interface ConfigurarEmisorUseCase {
    fun configurar(config: ConfiguracionEmisorDto): Resultado<Unit>
    fun crearSerie(serie: SerieDto): Resultado<SerieDto>
}

/** CU-12 · EP-13..EP-15 · RN-13 */
interface MigrarLegadoUseCase {
    fun cargar(archivo: ByteArray, nombre: String, formatoFecha: String): Resultado<LoteMigracionResponse>
    fun ejecutar(loteId: UUID, aceptarFilasRechazadas: Boolean): Resultado<LoteMigracionResponse>
    fun obtener(loteId: UUID): Resultado<LoteMigracionResponse>
}

/** CU-14 · EP-17 · RS 234-2006 */
interface GenerarReporteUseCase {
    fun registroVentas(periodo: String, formato: FormatoReporte): Resultado<ByteArray>
    fun kardex(periodo: String, formato: FormatoReporte): Resultado<ByteArray>
}
