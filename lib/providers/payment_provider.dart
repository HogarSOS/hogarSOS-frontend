import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/payment_service.dart';

final paymentServiceProvider = Provider((ref) => PaymentService());

/// Porcentajes de comisión vigentes — se consultan una sola vez por
/// pantalla y se comparten entre las tarjetas de presupuesto/ampliación/
/// cierre de horas para no repetir la llamada.
final comisionesProvider = FutureProvider.autoDispose<ComisionesInfo>((ref) {
  final servicio = ref.watch(paymentServiceProvider);
  return servicio.obtenerComisiones();
});

/// Argumentos del desglose de un pago pendiente. Un record para que la
/// family cachee por valor: la misma tarjeta re-renderizada no repite la
/// llamada, y dos importes distintos no comparten resultado.
typedef DesgloseArgs = ({String serviceRequestId, double montoBase, String modo});

/// Desglose exacto calculado por el backend (fuente única de verdad) —
/// ver [PaymentService.obtenerDesglose]. Las tarjetas del cliente pintan
/// EXACTAMENTE lo que devuelve esto; el mismo código del backend fija
/// después el importe del PaymentIntent, así que lo mostrado y lo
/// cobrado no pueden divergir.
final desglosePendienteProvider =
    FutureProvider.autoDispose.family<DesglosePago, DesgloseArgs>((ref, args) {
  final servicio = ref.watch(paymentServiceProvider);
  return servicio.obtenerDesglose(args.serviceRequestId, args.montoBase, modo: args.modo);
});
