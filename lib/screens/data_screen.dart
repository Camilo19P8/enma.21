import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:enma_udec/models/meteorological_record.dart';
import 'package:enma_udec/services/firestore_service.dart';
import 'package:enma_udec/utils/app_colors.dart';

class DataScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestoreService.latestMeteorologicalRecordStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildEmptyState(
            context,
            'No se pudieron cargar los datos meteorológicos reales.',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            context,
            'Todavía no hay registros en registros_meteorologicos.',
          );
        }

        final latestRecord =
            MeteorologicalRecord.fromDoc(snapshot.data!.docs.first);
        final cards = latestRecord.measurements;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Registro meteorológico actual',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Fuente: registros_meteorologicos',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.mediumText,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Última actualización: ${latestRecord.displayDateTime}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.mediumText,
                      ),
                ),
                const SizedBox(height: 20),
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
                          Icons.calendar_today,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Día del registro',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              latestRecord.dayKey,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth >= 900;
                    final isTablet = constraints.maxWidth >= 600;
                    final columns = isDesktop ? 2 : 1;
                    final spacing = 12.0;
                    final itemWidth =
                        (constraints.maxWidth - ((columns - 1) * spacing)) /
                            columns;

                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: cards.map((measurement) {
                        return SizedBox(
                          width: itemWidth,
                          child: _buildMeasurementTile(
                            context,
                            measurement,
                            compact: !isTablet,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Container(
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
                      Row(
                        children: [
                          Icon(
                            Icons.info,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Resumen del documento',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Documento: ${latestRecord.id}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hora de subida: ${latestRecord.shortTime}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Variables mostradas: ${cards.length}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.success,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMeasurementTile(
    BuildContext context,
    SensorMeasurement measurement, {
    required bool compact,
  }) {
    final icon = _iconForMeasurement(measurement.key);
    final description = _descriptionForMeasurement(measurement.key);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkBgSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 38 : 42,
            height: compact ? 38 : 42,
            decoration: BoxDecoration(
              gradient: _gradientForMeasurement(measurement.key),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: compact ? 16 : 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  measurement.label,
                  style: Theme.of(context).textTheme.labelLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mediumText,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            measurement.valueWithUnit,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
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
              Icons.cloud_off,
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

  LinearGradient _gradientForMeasurement(String key) {
    switch (key) {
      case 'temperatura':
        return AppColors.temperatureGradient;
      case 'humedad':
        return AppColors.humidityGradient;
      case 'precipitacion':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0288D1), Color(0xFF01579B)],
        );
      case 'presion_atmosferica':
        return AppColors.pressureGradient;
      case 'radiacion_solar':
        return AppColors.uvGradient;
      case 'calidad_aire':
        return AppColors.aqiGradient;
      case 'gases_combustibles':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)],
        );
      case 'ldr':
        return AppColors.windGradient;
      default:
        return AppColors.pressureGradient;
    }
  }

  String _descriptionForMeasurement(String key) {
    switch (key) {
      case 'temperatura':
        return 'Nivel de calor del ambiente en tiempo real.';
      case 'humedad':
        return 'Cantidad de vapor de agua presente en el aire.';
      case 'precipitacion':
        return 'Lluvia acumulada registrada por el sensor.';
      case 'presion_atmosferica':
        return 'Presión del aire para analizar cambios climáticos.';
      case 'radiacion_solar':
        return 'Intensidad de radiación solar recibida.';
      case 'calidad_aire':
        return 'Índice general de pureza o contaminación del aire.';
      case 'gases_combustibles':
        return 'Concentración detectada de gases inflamables.';
      case 'ldr':
        return 'Nivel de luminosidad ambiental detectado.';
      default:
        return 'Lectura meteorológica actual de la estación.';
    }
  }

  IconData _iconForMeasurement(String key) {
    switch (key) {
      case 'temperatura':
        return FontAwesomeIcons.temperatureHigh;
      case 'humedad':
        return FontAwesomeIcons.droplet;
      case 'precipitacion':
        return FontAwesomeIcons.cloudRain;
      case 'presion_atmosferica':
        return FontAwesomeIcons.gauge;
      case 'radiacion_solar':
        return FontAwesomeIcons.sun;
      case 'calidad_aire':
        return FontAwesomeIcons.smog;
      case 'gases_combustibles':
        return FontAwesomeIcons.fire;
      case 'ldr':
        return FontAwesomeIcons.solidLightbulb;
      default:
        return FontAwesomeIcons.database;
    }
  }
}
