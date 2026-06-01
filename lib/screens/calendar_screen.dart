import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'package:enma_udec/models/meteorological_record.dart';
import 'package:enma_udec/services/firestore_service.dart';
import 'package:enma_udec/utils/app_colors.dart';

class CalendarScreen extends StatefulWidget {
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  Set<String> _daysWithRecords = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _daysSub;

  String _selectedMetric = 'temperatura';
  List<String> _availableMetrics = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    _subscribeMonthDays(_focusedDay);
  }

  @override
  void dispose() {
    _daysSub?.cancel();
    super.dispose();
  }

  void _subscribeMonthDays(DateTime focused) {
    _daysSub?.cancel();
    final start = DateTime(focused.year, focused.month, 1);
    final end = DateTime(focused.year, focused.month + 1, 1);
    _daysSub = FirestoreService.allMeteorologicalRecordsStream().listen((snap) {
      final records = snap.docs.map(MeteorologicalRecord.fromDoc).toList();
      final dayKeys = records
          .where((record) {
            final date = record.recordedAt ?? record.submittedAt;
            if (date == null) return false;
            return !date.isBefore(start) && date.isBefore(end);
          })
          .map((record) => record.dayKey)
          .toSet();
      setState(() {
        _daysWithRecords = dayKeys;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return _buildEmptyState(
        context,
        'Debes iniciar sesión para ver el historial climático.',
      );
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Historial climático por día',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Los registros se leen de registros_meteorologicos y se agrupan por fecha.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.mediumText,
                        ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.darkBgSecondary,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                    child: TableCalendar(
                      focusedDay: _focusedDay,
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      eventLoader: (day) {
                        final key =
                            '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
                        return _daysWithRecords.contains(key) ? [1] : [];
                      },
                      selectedDayPredicate: (day) =>
                          isSameDay(day, _selectedDay),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                          _subscribeMonthDays(focusedDay);
                        });
                      },
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.3),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.accent),
                        ),
                        selectedDecoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        selectedTextStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        todayTextStyle: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                        weekendTextStyle: TextStyle(
                          color: AppColors.mediumText,
                        ),
                        defaultTextStyle: TextStyle(
                          color: AppColors.lightText,
                        ),
                        outsideTextStyle: TextStyle(
                          color: AppColors.darkText,
                        ),
                      ),
                      headerStyle: HeaderStyle(
                        titleCentered: true,
                        formatButtonVisible: false,
                        leftChevronIcon: Icon(
                          Icons.chevron_left,
                          color: AppColors.primary,
                        ),
                        rightChevronIcon: Icon(
                          Icons.chevron_right,
                          color: AppColors.primary,
                        ),
                        titleTextStyle: TextStyle(
                          color: AppColors.lightText,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: TextStyle(color: AppColors.mediumText),
                        weekendStyle: TextStyle(color: AppColors.mediumText),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirestoreService.allMeteorologicalRecordsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        final errorText = snapshot.error.toString();
                        final friendlyMessage = errorText
                                .contains('permission-denied')
                            ? 'Firebase está rechazando la lectura de registros_meteorologicos. Debes publicar las reglas de firestore.rules en el proyecto enma-f8fbf.'
                            : 'No se pudieron cargar los registros de Firestore.\n$errorText';
                        return _buildEmptyState(
                          context,
                          friendlyMessage,
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final allRecords = snapshot.data?.docs
                              .map(MeteorologicalRecord.fromDoc)
                              .toList() ??
                          [];
                      final records = allRecords.where((record) {
                        final date = record.recordedAt ?? record.submittedAt;
                        if (date == null) return false;
                        return date.year == _selectedDay.year &&
                            date.month == _selectedDay.month &&
                            date.day == _selectedDay.day;
                      }).toList()
                        ..sort((a, b) {
                          final ad = a.recordedAt ?? a.submittedAt;
                          final bd = b.recordedAt ?? b.submittedAt;
                          return (ad ?? DateTime.fromMillisecondsSinceEpoch(0))
                              .compareTo(
                                  bd ?? DateTime.fromMillisecondsSinceEpoch(0));
                        });

                      // actualizar lista de métricas disponibles
                      if (records.isNotEmpty) {
                        final keys = records
                            .expand((record) => record.measurements)
                            .map((m) => m.key)
                            .where((k) => k.isNotEmpty)
                            .toSet()
                            .toList();
                        if (keys.isNotEmpty &&
                            !_listEquals(keys, _availableMetrics)) {
                          setState(() {
                            _availableMetrics = keys;
                            if (!_availableMetrics.contains(_selectedMetric)) {
                              _selectedMetric = _availableMetrics.first;
                            }
                          });
                        }
                      }

                      if (records.isEmpty) {
                        return _buildEmptyState(
                          context,
                          'No hay registros para esta fecha en registros_meteorologicos.',
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Registros del ${_formatDay(_selectedDay)}',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.darkBgSecondary,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.18),
                              ),
                            ),
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                SizedBox(
                                  width: 220,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _availableMetrics
                                            .contains(_selectedMetric)
                                        ? _selectedMetric
                                        : (_availableMetrics.isNotEmpty
                                            ? _availableMetrics.first
                                            : null),
                                    decoration: const InputDecoration(
                                      labelText: 'Métrica del gráfico',
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                    items: _availableMetrics
                                        .map((m) => DropdownMenuItem(
                                              value: m,
                                              child: Text(m),
                                            ))
                                        .toList(),
                                    onChanged: (v) {
                                      if (v == null) return;
                                      setState(() {
                                        _selectedMetric = v;
                                      });
                                    },
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: records.isEmpty
                                      ? null
                                      : () => _exportDayToCsv(
                                            _selectedDay,
                                            records,
                                          ),
                                  icon: const Icon(Icons.download_rounded),
                                  label: const Text('Exportar CSV'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (records.isNotEmpty)
                            _buildMetricChart(records, _selectedMetric),
                          const SizedBox(height: 12),
                          Text(
                            'Desliza por horas',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 10),
                          _buildHorizontalHistory(context, records),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildSelectionSummary(context),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalHistory(
    BuildContext context,
    List<MeteorologicalRecord> records,
  ) {
    return SizedBox(
      height: 192,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: records.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return _buildTimelineCard(context, records[index]);
        },
      ),
    );
  }

  Widget _buildTimelineCard(
    BuildContext context,
    MeteorologicalRecord record,
  ) {
    final visibleMeasurements = record.measurements.take(3).toList();

    return SizedBox(
      width: 224,
      child: Material(
        color: AppColors.darkBgSecondary,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openRecordPanel(context, record),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        Icons.schedule,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.shortTime,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            record.displayDateTime,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.mediumText,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppColors.mediumText,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.55,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.accent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ...visibleMeasurements.map(
                  (measurement) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          IconTheme(
                            data: IconThemeData(
                              color: AppColors.primary,
                              size: 15,
                            ),
                            child: _iconForMetric(measurement.key),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              measurement.label,
                              style: Theme.of(context).textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            measurement.valueWithUnit,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                if (record.measurements.length > visibleMeasurements.length)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '+ ${record.measurements.length - visibleMeasurements.length} variables más',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.mediumText,
                          ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openRecordPanel(BuildContext context, MeteorologicalRecord record) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.darkBgSecondary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.18),
                ),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  Center(
                    child: Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.mediumText.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.schedule,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Detalle de ${record.shortTime}',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              record.displayDateTime,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.mediumText,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...record.measurements.map(
                    (measurement) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.darkBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconTheme(
                                data: IconThemeData(
                                  color: AppColors.primary,
                                  size: 16,
                                ),
                                child: _iconForMetric(measurement.key),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                measurement.label,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              measurement.valueWithUnit,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _metricChip(
    BuildContext context,
    String label,
    String value,
    FaIcon icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.darkBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconTheme(
            data: IconThemeData(color: AppColors.primary, size: 16),
            child: icon,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mediumText,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.mediumText,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkBgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen de selección',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Día seleccionado: ${_formatDay(_selectedDay)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Text(
            'Se muestran únicamente los documentos reales de la colección registros_meteorologicos.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.mediumText,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note,
              size: 64,
              color: AppColors.mediumText,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  FaIcon _iconForMetric(String? metric) {
    switch ((metric ?? '').toLowerCase()) {
      case 'temperatura':
        return const FaIcon(FontAwesomeIcons.temperatureHigh);
      case 'humedad':
        return const FaIcon(FontAwesomeIcons.droplet);
      case 'precipitacion':
      case 'precipitación':
        return const FaIcon(FontAwesomeIcons.cloudRain);
      case 'presion_atmosferica':
        return const FaIcon(FontAwesomeIcons.gauge);
      case 'radiacion_solar':
        return const FaIcon(FontAwesomeIcons.sun);
      case 'calidad_aire':
        return const FaIcon(FontAwesomeIcons.smog);
      case 'gases_combustibles':
        return const FaIcon(FontAwesomeIcons.fire);
      case 'ldr':
        return const FaIcon(FontAwesomeIcons.solidLightbulb);
      default:
        return const FaIcon(FontAwesomeIcons.database);
    }
  }

  String _formatDay(DateTime date) {
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];

    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  bool _listEquals(List a, List b) {
    final sa = Set.from(a);
    final sb = Set.from(b);
    return sa.length == sb.length && sa.difference(sb).isEmpty;
  }

  Future<void> _exportDayToCsv(
      DateTime day, List<MeteorologicalRecord> records) async {
    try {
      if (records.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No hay registros para exportar en esta fecha.')));
        return;
      }

      // headers
      final metricKeys = <String>{};
      for (final r in records) {
        for (final m in r.measurements) {
          metricKeys.add(m.key);
        }
      }
      final metrics = metricKeys.toList();

      final rows = <List<Object?>>[];
      final header = <Object?>['id', 'fecha', 'datetime', ...metrics];
      rows.add(header);

      for (final r in records) {
        final row = <Object?>[r.id, r.dayKey, r.displayDateTime];
        for (final k in metrics) {
          final m = r.measurement(k);
          row.add(m?.valueText ?? '');
        }
        rows.add(row);
      }

      final csv = const ListToCsvConverter().convert(rows);
      if (kIsWeb) {
        await Clipboard.setData(ClipboardData(text: csv));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CSV copiado al portapapeles (Web).'),
          ),
        );
        return;
      }

      final filename = 'registros_${FirestoreService.dayKey(day)}.csv';
      final downloadsDir = await getDownloadsDirectory();
      final docsDir = await getApplicationDocumentsDirectory();
      final targetDir = downloadsDir ?? docsDir;
      final file = File('${targetDir.path}/$filename');
      await file.writeAsString(csv);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV guardado en: ${file.path}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error exportando CSV: $e')));
    }
  }

  Widget _buildMetricChart(
      List<MeteorologicalRecord> records, String metricKey) {
    final spots = <FlSpot>[];
    for (final r in records) {
      final m = r.measurement(metricKey);
      if (m == null) continue;
      final raw = m.value;
      double? val;
      if (raw is num)
        val = raw.toDouble();
      else if (raw is String) val = double.tryParse(raw.replaceAll(',', '.'));
      if (val == null) continue;
      final date = r.recordedAt ??
          r.submittedAt ??
          DateTime.tryParse(r.dayKey) ??
          DateTime.now();
      final x = date.hour + date.minute / 60.0;
      spots.add(FlSpot(x, val));
    }

    if (spots.isEmpty) {
      return Container();
    }

    final minX = spots.map((s) => s.x).reduce((a, b) => a < b ? a : b);
    final maxX = spots.map((s) => s.x).reduce((a, b) => a > b ? a : b);
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkBgSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      height: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Serie: $metricKey',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: minX,
                maxX: maxX,
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          interval: (maxX - minX) / 4,
                          getTitlesWidget: (v, meta) => Text('${v.toInt()}:00',
                              style: TextStyle(color: AppColors.mediumText)))),
                  leftTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: true)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                        show: true, color: AppColors.primary.withOpacity(0.15)),
                    color: AppColors.primary,
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
