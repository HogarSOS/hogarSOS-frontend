import 'package:flutter/widgets.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'api_service.dart';
import 'professional_service.dart' show EstadoCuentaStripe;

class PaymentIntentResult {
  final String paymentId;
  final double montoBase;
  final double montoTotal;
  final double comisionPlataforma;

  PaymentIntentResult({
    required this.paymentId,
    required this.montoBase,
    required this.montoTotal,
    required this.comisionPlataforma,
  });
}

/// Porcentajes de comisión vigentes ahora mismo (`GET /payments/comisiones`).
/// Puramente informativo — el backend es quien fija los importes reales
/// al crear cada autorización.
class ComisionesInfo {
  final double comisionClientePorcentaje;
  final double comisionProfesionalPorcentaje;

  ComisionesInfo({
    required this.comisionClientePorcentaje,
    required this.comisionProfesionalPorcentaje,
  });

  /// Deriva si hay que mostrar el distintivo de "promoción de lanzamiento"
  /// — no es una fecha ni un flag aparte, solo el hecho de que ahora
  /// mismo ninguna de las dos partes paga comisión.
  bool get esPromoLanzamiento => comisionClientePorcentaje == 0 && comisionProfesionalPorcentaje == 0;

  /// Importe que pagaría el cliente por un `montoBase` dado, con la
  /// comisión vigente.
  double totalCliente(double montoBase) => montoBase * (1 + comisionClientePorcentaje / 100);

  /// Importe que recibiría el profesional por un `montoBase` dado, con
  /// la comisión vigente.
  double totalProfesional(double montoBase) => montoBase * (1 - comisionProfesionalPorcentaje / 100);
}

/// Una fila del historial de cobros del Centro de Pagos — un pago ya
/// liberado y transferido al profesional (ver `Payment.estado == 'liberado'`
/// en el backend).
class CobroHistorial {
  final String id;
  final double monto;
  final DateTime fecha;
  final String categoria;
  final String descripcion;
  final String nombreCliente;

  CobroHistorial({
    required this.id,
    required this.monto,
    required this.fecha,
    required this.categoria,
    required this.descripcion,
    required this.nombreCliente,
  });

  factory CobroHistorial.fromJson(Map<String, dynamic> json) {
    return CobroHistorial(
      id: json['id'] as String,
      monto: (json['monto'] as num).toDouble(),
      fecha: DateTime.parse(json['fecha'] as String),
      categoria: json['categoria'] as String,
      descripcion: json['descripcion'] as String,
      nombreCliente: json['nombreCliente'] as String,
    );
  }
}

/// Centro de Pagos del profesional (`GET /payments/me/summary`).
/// `pendiente`/`disponible` vienen del saldo REAL de Stripe, no de una
/// suma local — pueden tardar en reflejar el último cobro si Stripe
/// todavía no ha liquidado la transferencia.
class PaymentsSummary {
  final EstadoCuentaStripe estadoCuentaStripe;
  final double pendiente;
  final double disponible;
  final List<CobroHistorial> historial;

  PaymentsSummary({
    required this.estadoCuentaStripe,
    required this.pendiente,
    required this.disponible,
    required this.historial,
  });

  factory PaymentsSummary.fromJson(Map<String, dynamic> json) {
    return PaymentsSummary(
      estadoCuentaStripe: EstadoCuentaStripe.fromJson(json['estadoCuentaStripe'] as String? ?? 'pendiente'),
      pendiente: (json['pendiente'] as num).toDouble(),
      disponible: (json['disponible'] as num).toDouble(),
      historial: (json['historial'] as List? ?? [])
          .map((h) => CobroHistorial.fromJson(h as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PaymentService {
  final _api = ApiService.instance.client;

  Future<PaymentsSummary> obtenerResumenPagos() async {
    final respuesta = await _api.get('/payments/me/summary');
    return PaymentsSummary.fromJson(respuesta.data as Map<String, dynamic>);
  }

  Future<ComisionesInfo> obtenerComisiones() async {
    final respuesta = await _api.get('/payments/comisiones');
    return ComisionesInfo(
      comisionClientePorcentaje: (respuesta.data['comisionClientePorcentaje'] as num).toDouble(),
      comisionProfesionalPorcentaje: (respuesta.data['comisionProfesionalPorcentaje'] as num).toDouble(),
    );
  }

  /// Pide al backend que autorice el cargo (modelo escrow — no se
  /// captura todavía) y devuelve los datos para mostrar el desglose
  /// al cliente antes de confirmar.
  Future<PaymentIntentResult> crearIntencionDePago(String serviceRequestId) async {
    final respuesta = await _api.post('/payments/intent', data: {
      'serviceRequestId': serviceRequestId,
    });

    final clientSecret = respuesta.data['clientSecret'] as String;

    // BUG 004 (QA, 2026-08-03): "el campo del número de tarjeta no coge
    // el foco al primer toque, hay que tocar varias veces o tocar otro
    // campo antes". No es un GestureDetector nuestro interceptando el
    // toque —el Payment Sheet de Stripe es una vista NATIVA (fuera del
    // árbol de widgets de Flutter), así que nuestros overlays no pueden
    // ni podrían bloquearla. Es un problema conocido de flutter_stripe
    // en Android (issues #14/#306/#361/#392 del repo): si Flutter se
    // queda con el foco/conexión de teclado (IME) de CUALQUIER campo de
    // texto de la app, el CardField nativo del Payment Sheet no consigue
    // arrebatárselo limpiamente al primer toque. Quitar el foco de
    // Flutter explícitamente (y dar un respiro a la animación de cierre
    // del teclado) justo antes de abrir el Payment Sheet evita el
    // conflicto — es la solución recomendada en esos issues.
    FocusManager.instance.primaryFocus?.unfocus();
    await Future.delayed(const Duration(milliseconds: 100));

    // Presenta la hoja de pago nativa de Stripe (tarjeta, Apple Pay, Google Pay).
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'Hogar SOS',
      ),
    );
    await Stripe.instance.presentPaymentSheet();

    // Si presentPaymentSheet() no lanzó excepción, el cliente completó
    // la autorización. El cargo queda retenido hasta que el profesional
    // complete el servicio (ver payment.service.ts en el backend).
    return PaymentIntentResult(
      paymentId: respuesta.data['paymentId'] as String,
      montoBase: (respuesta.data['montoBase'] as num).toDouble(),
      montoTotal: (respuesta.data['montoTotal'] as num).toDouble(),
      comisionPlataforma: (respuesta.data['comisionPlataforma'] as num).toDouble(),
    );
  }
}
