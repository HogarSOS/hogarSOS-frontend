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
