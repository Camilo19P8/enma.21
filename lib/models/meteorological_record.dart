import 'package:cloud_firestore/cloud_firestore.dart';

class SensorMeasurement {
  final String key;
  final String label;
  final dynamic value;
  final String unit;

  const SensorMeasurement({
    required this.key,
    required this.label,
    required this.value,
    required this.unit,
  });

  String get valueText {
    if (value == null) {
      return '--';
    }

    final text = value.toString().trim();
    return text.isEmpty ? '--' : text;
  }

  String get valueWithUnit => unit.isEmpty ? valueText : '$valueText $unit';
}

class MeteorologicalRecord {
  final String id;
  final String dayKey;
  final DateTime? recordedAt;
  final DateTime? submittedAt;
  final List<SensorMeasurement> measurements;
  final Map<String, dynamic> rawData;

  const MeteorologicalRecord({
    required this.id,
    required this.dayKey,
    required this.recordedAt,
    required this.submittedAt,
    required this.measurements,
    required this.rawData,
  });

  SensorMeasurement? measurement(String key) {
    for (final item in measurements) {
      if (item.key == key) {
        return item;
      }
    }
    return null;
  }

  String get displayDateTime {
    final date = submittedAt ?? recordedAt;
    if (date == null) {
      return dayKey.isNotEmpty ? dayKey : 'Sin fecha registrada';
    }

    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String get shortTime {
    final date = submittedAt ?? recordedAt;
    if (date == null) {
      return '--:--';
    }

    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  static MeteorologicalRecord fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    // Intentos flexibles para obtener la marca de tiempo real del documento.
    DateTime? recordedAt = _parseDateTime(data['datetime']);
    recordedAt ??= _parseDateTime(data['subido_en']);
    recordedAt ??= _parseDateTime(data['recordedAt']);

    // Si aún no tenemos datetime, pero existe 'fecha' y 'hora', combínalos.
    if (recordedAt == null) {
      final fecha = data['fecha'];
      final hora = data['hora'] ?? data['hora_local'] ?? data['time'];
      if (fecha is String &&
          fecha.isNotEmpty &&
          hora is String &&
          hora.isNotEmpty) {
        final combined = '${fecha.trim()} ${hora.trim()}';
        recordedAt = _parseDateTime(combined);
      }
    }

    // Si 'subido_en' contiene una hora dentro de un texto (ej. "2 de mayo... 8:34:46 p.m."), extraer formato HH:MM:SS
    if (recordedAt == null && data['subido_en'] is String) {
      final s = data['subido_en'] as String;
      final dateMatch = RegExp(r'(\d{4}-\d{2}-\d{2})').firstMatch(s);
      final timeMatch = RegExp(r'(\d{1,2}:\d{2}:\d{2})').firstMatch(s);
      if (dateMatch != null && timeMatch != null) {
        recordedAt =
            _parseDateTime('${dateMatch.group(0)} ${timeMatch.group(0)}');
      }
    }

    final dayKey = _parseDayKey(data['fecha'], recordedAt) ?? doc.id;

    final measurements = <SensorMeasurement>[
      _readMeasurement(data, 'temperatura', 'Temperatura'),
      _readMeasurement(data, 'humedad', 'Humedad'),
      _readMeasurement(data, 'precipitacion', 'Precipitación'),
      _readMeasurement(data, 'presion_atmosferica', 'Presión atmosférica'),
      _readMeasurement(data, 'radiacion_solar', 'Radiación solar'),
      _readMeasurement(data, 'calidad_aire', 'Calidad del aire'),
      _readMeasurement(data, 'gases_combustibles', 'Gases combustibles'),
      _readMeasurement(data, 'ldr', 'LDR'),
    ];

    return MeteorologicalRecord(
      id: doc.id,
      dayKey: dayKey,
      recordedAt: recordedAt ?? _parseDateTime(data['datetime']),
      submittedAt: recordedAt,
      measurements: measurements,
      rawData: data,
    );
  }

  static SensorMeasurement _readMeasurement(
    Map<String, dynamic> data,
    String key,
    String label,
  ) {
    final raw = data[key];
    if (raw is Map<String, dynamic>) {
      return SensorMeasurement(
        key: key,
        label: label,
        value: raw['valor'] ?? raw['value'],
        unit: _stringValue(raw['unidad'] ?? raw['unit']),
      );
    }

    return SensorMeasurement(
      key: key,
      label: label,
      value: raw,
      unit: '',
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String && value.trim().isNotEmpty) {
      final v = value.trim();
      // Prueba parse estándar
      final direct = DateTime.tryParse(v);
      if (direct != null) return direct;

      // Extraer patrón YYYY-MM-DD HH:MM:SS
      final match = RegExp(r"(\d{4}-\d{2}-\d{2})(?:[ T](\d{2}:\d{2}:\d{2}))?")
          .firstMatch(v);
      if (match != null) {
        final date = match.group(1);
        final time = match.group(2) ?? '00:00:00';
        return DateTime.tryParse('$date $time');
      }

      // Extraer hora HH:MM:SS y si hay fecha en formato YYYY-MM-DD en el string
      final timeMatch = RegExp(r'(\d{1,2}:\d{2}:\d{2})').firstMatch(v);
      final dateMatch = RegExp(r'(\d{4}-\d{2}-\d{2})').firstMatch(v);
      if (timeMatch != null && dateMatch != null) {
        return DateTime.tryParse('${dateMatch.group(0)} ${timeMatch.group(0)}');
      }

      // Intentar extraer fecha en formato dd/MM/yyyy o dd/MM/yy
      final altDateMatch = RegExp(r'(\d{1,2}/\d{1,2}/\d{2,4})').firstMatch(v);
      if (altDateMatch != null) {
        final parts = altDateMatch.group(0)!.split('/');
        if (parts.length == 3) {
          final d = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          var y = int.tryParse(parts[2]);
          if (y != null && y < 100) y += 2000;
          if (d != null && m != null && y != null) {
            return DateTime(y, m, d);
          }
        }
      }

      return null;
    }

    return null;
  }

  static String? _parseDayKey(dynamic value, DateTime? fallback) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    if (fallback != null) {
      return '${fallback.year.toString().padLeft(4, '0')}-${fallback.month.toString().padLeft(2, '0')}-${fallback.day.toString().padLeft(2, '0')}';
    }

    return null;
  }

  static String _stringValue(dynamic value) {
    if (value == null) {
      return '';
    }

    final text = value.toString().trim();
    return text;
  }
}
