import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hogarsos/services/chat_service.dart';

// RGPD (deleteMe, ver auditoría pre-lanzamiento): el nombre/foto de la
// contraparte del chat NUNCA sale de Firestore, sale de la ficha de
// usuario en Postgres (ya anonimizada por deleteMe). Este test protege
// esa garantía a nivel de contrato de datos: si algún día alguien añade
// un campo como 'autorNombre'/'autorFoto' a ChatMessage para "ahorrarse
// una consulta", reintroduciría una copia de PII en Firestore que
// deleteMe no sabe limpiar. Falla aquí antes de que llegue a producción.
void main() {
  group('ChatMessage — contrato de datos (sin PII más allá del autorId)', () {
    test('toFirestore() solo serializa texto, autorId y enviadoEn (el id vive fuera del documento)', () {
      final mensaje = ChatMessage(
        id: 'msg-1',
        texto: 'Hola, ¿a qué hora vienes?',
        autorId: 'uid-cliente-123',
        enviadoEn: DateTime(2026, 8, 14),
      );

      expect(mensaje.toFirestore().keys.toSet(), {'texto', 'autorId', 'enviadoEn'});
    });

    test('fromFirestore() parsea correctamente con un Timestamp real, usando el id del documento', () {
      final ahora = DateTime(2026, 8, 14, 10, 30);
      final mensaje = ChatMessage.fromFirestore('msg-2', {
        'texto': 'Ya estoy en camino',
        'autorId': 'uid-profesional-456',
        'enviadoEn': Timestamp.fromDate(ahora),
      });

      expect(mensaje.id, 'msg-2');
      expect(mensaje.texto, 'Ya estoy en camino');
      expect(mensaje.autorId, 'uid-profesional-456');
      expect(mensaje.enviadoEn, ahora);
    });

    // Caso real documentado en el propio código: la primera lectura local
    // de un mensaje recién enviado no tiene 'enviadoEn' todavía (FieldValue
    // .serverTimestamp() no se resuelve hasta que el servidor confirma).
    test('fromFirestore() no revienta si enviadoEn llega null (mensaje local recién enviado)', () {
      expect(
        () => ChatMessage.fromFirestore('msg-3', {'texto': 'Enviando...', 'autorId': 'uid-1', 'enviadoEn': null}),
        returnsNormally,
      );
    });
  });

  group('EstadoLecturaChat — solo UIDs y timestamps, ningún dato identificable', () {
    test('miLastRead/otroLastRead distinguen correctamente cliente vs profesional', () {
      final leidoCliente = DateTime(2026, 8, 14, 9);
      final leidoProfesional = DateTime(2026, 8, 14, 10);
      final estado = EstadoLecturaChat(
        clienteFirebaseUid: 'uid-cliente',
        profesionalFirebaseUid: 'uid-profesional',
        lastReadCliente: leidoCliente,
        lastReadProfesional: leidoProfesional,
      );

      expect(estado.miLastRead('uid-cliente'), leidoCliente);
      expect(estado.otroLastRead('uid-cliente'), leidoProfesional);
      expect(estado.miLastRead('uid-profesional'), leidoProfesional);
      expect(estado.otroLastRead('uid-profesional'), leidoCliente);
    });

    test('vacio no falla con un uid vacío (caso de arranque sin sesión aún resuelta)', () {
      expect(EstadoLecturaChat.vacio.miLastRead(''), isNull);
      expect(EstadoLecturaChat.vacio.otroLastRead(''), isNull);
    });
  });
}
