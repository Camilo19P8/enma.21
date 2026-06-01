import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:enma_udec/models/meteorological_record.dart';
import 'package:enma_udec/services/firestore_service.dart';
import 'package:enma_udec/utils/app_colors.dart';

class AlertsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestoreService.latestMeteorologicalRecordStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildEmptyState(
            context,
            'No se pudieron leer los datos reales para generar alertas.',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            context,
            'Todavía no hay registros para calcular alertas.',
          );
        }

        final latestRecord =
            MeteorologicalRecord.fromDoc(snapshot.data!.docs.first);
        final alerts = _buildAlertsFromRecord(latestRecord);

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alertas basadas en datos reales',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Estas alertas se calculan desde el último registro de registros_meteorologicos.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.mediumText,
                      ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.darkBgSecondary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
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
                              'Último documento analizado',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              latestRecord.displayDateTime,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (alerts.isEmpty)
                  _buildSafeState(context, latestRecord)
                else
                  Column(
                    children: alerts
                        .map((alert) => _buildAlertCard(context, alert))
                        .toList(),
                  ),
                const SizedBox(height: 24),
                _buildLegend(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSafeState(BuildContext context, MeteorologicalRecord record) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Icon(Icons.verified, color: AppColors.success, size: 48),
          const SizedBox(height: 12),
          Text(
            'Sin alertas activas en el último registro',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.success,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Los valores actuales están dentro de rangos normales según las reglas de monitoreo.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.mediumText,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Documento: ${record.id}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, DetectedAlert alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkBgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: alert.color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: alert.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(alert.icon, color: alert.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        alert.title,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: alert.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        alert.severityLabel,
                        style: TextStyle(
                          color: alert.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  alert.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.mediumText,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Valor real: ${alert.measurement.valueWithUnit}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    final criteria = [
      {'label': 'Temp >= 30°C', 'color': AppColors.error},
      {'label': 'Humedad <= 40%', 'color': AppColors.warning},
      {'label': 'Presión <= 1000 hPa', 'color': AppColors.warning},
      {'label': 'AQI >= 100', 'color': AppColors.warning},
      {'label': 'Gases >= 100 PPM', 'color': AppColors.error},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkBgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Criterios usados',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: criteria.map((c) {
              return Chip(
                backgroundColor: (c['color'] as Color).withOpacity(0.12),
                label: Text(c['label'] as String),
                avatar: CircleAvatar(
                  backgroundColor: c['color'] as Color,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(
            'Puedes ajustar estos criterios en la configuración avanzada o crear alertas manuales.',
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
              Icons.notifications_off,
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

  List<DetectedAlert> _buildAlertsFromRecord(MeteorologicalRecord record) {
    final alerts = <DetectedAlert>[];

    void addIfNeeded({
      required String key,
      required String title,
      required String description,
      required String severity,
      required Color color,
      required IconData icon,
      required bool Function(double value) condition,
    }) {
      final measurement = record.measurement(key);
      final value = _tryParseDouble(measurement?.valueText);
      if (measurement == null || value == null || !condition(value)) {
        return;
      }

      alerts.add(
        DetectedAlert(
          title: title,
          description: description,
          severity: severity,
          color: color,
          icon: icon,
          measurement: measurement,
        ),
      );
    }

    addIfNeeded(
      key: 'temperatura',
      title: 'Temperatura alta',
      description: 'La temperatura superó el umbral recomendado.',
      severity: 'Crítica',
      color: AppColors.error,
      icon: FontAwesomeIcons.temperatureHigh,
      condition: (value) => value >= 30,
    );

    addIfNeeded(
      key: 'humedad',
      title: 'Humedad baja',
      description: 'La humedad está por debajo del rango recomendado.',
      severity: 'Advertencia',
      color: AppColors.warning,
      icon: FontAwesomeIcons.droplet,
      condition: (value) => value <= 40,
    );

    addIfNeeded(
      key: 'presion_atmosferica',
      title: 'Presión atmosférica baja',
      description: 'La presión atmosférica está por debajo de lo esperado.',
      severity: 'Advertencia',
      color: AppColors.warning,
      icon: FontAwesomeIcons.gauge,
      condition: (value) => value <= 1000,
    );

    addIfNeeded(
      key: 'calidad_aire',
      title: 'Calidad del aire deteriorada',
      description: 'El índice de calidad del aire está alto.',
      severity: 'Advertencia',
      color: AppColors.warning,
      icon: FontAwesomeIcons.smog,
      condition: (value) => value >= 100,
    );

    addIfNeeded(
      key: 'gases_combustibles',
      title: 'Gases combustibles elevados',
      description:
          'La lectura de gases combustibles superó el límite recomendado.',
      severity: 'Crítica',
      color: AppColors.error,
      icon: FontAwesomeIcons.fire,
      condition: (value) => value >= 100,
    );

    return alerts;
  }

  double? _tryParseDouble(String? value) {
    if (value == null) {
      return null;
    }

    final cleaned =
        value.replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.\-]'), '');
    return double.tryParse(cleaned);
  }
}

class DetectedAlert {
  final String title;
  final String description;
  final String severity;
  final Color color;
  final IconData icon;
  final SensorMeasurement measurement;

  DetectedAlert({
    required this.title,
    required this.description,
    required this.severity,
    required this.color,
    required this.icon,
    required this.measurement,
  });

  String get severityLabel => severity.toUpperCase();
}
