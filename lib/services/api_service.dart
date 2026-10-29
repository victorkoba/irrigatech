import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sector_model.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';
  static const Duration timeout = Duration(milliseconds: 1500);

  static SectorModel _parseSector(Map<String, dynamic> item) {
    SectorStatus status = SectorStatus.idle;
    if (item['status'] == 'irrigating') status = SectorStatus.irrigating;
    if (item['status'] == 'error') status = SectorStatus.error;

    return SectorModel(
      id: item['id'],
      name: item['name'],
      region: item['region'],
      status: status,
      isEnabled: item['isEnabled'] is bool ? item['isEnabled'] : true,
      idealMoisture: (item['idealMoisture'] as num?)?.toDouble() ?? 60.0,
      minMoistureTrigger: (item['minMoistureTrigger'] as num?)?.toDouble() ?? 35.0,
      maxMoistureCutoff: (item['maxMoistureCutoff'] as num?)?.toDouble() ?? 75.0,
      flowRate: (item['flowRate'] as num?)?.toDouble() ?? 0.0,
      energyConsumption: (item['energyConsumption'] as num?)?.toDouble() ?? 0.0,
      moisture: (item['moisture'] as num?)?.toDouble() ?? 50.0,
      temperature: (item['temperature'] as num?)?.toDouble() ?? 25.0,
      alertMessage: item['alertMessage'],
      activationReason: item['activationReason'],
      lastActivatedAt: item['lastActivatedAt'] != null
          ? DateTime.tryParse(item['lastActivatedAt'].toString())
          : null,
    );
  }

  static IrrigationScheduleItem _parseSchedule(Map<String, dynamic> item) {
    List<String> ids = ['ALL'];
    if (item['sectorIds'] is List) {
      ids = (item['sectorIds'] as List).map((e) => e.toString()).toList();
    }
    return IrrigationScheduleItem(
      id: item['id']?.toString() ?? 'sched_${DateTime.now().millisecondsSinceEpoch}',
      time: item['time']?.toString() ?? '06:00',
      sectorIds: ids,
      sectorsLabel: item['sectorsLabel']?.toString() ?? 'Todos os Setores',
      isActive: item['isActive'] is bool ? item['isActive'] : true,
    );
  }

  // Health check
  static Future<bool> isBackendOnline() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/health')).timeout(timeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Sectors
  static Future<List<SectorModel>?> fetchSectors() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/sectors')).timeout(timeout);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((item) => _parseSector(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      // Graceful fallback to offline
    }
    return null;
  }

  static Future<bool> toggleSector(String id) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/sectors/$id/toggle')).timeout(timeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<SectorModel?> setSectorEnabled(String id, bool isEnabled) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/sectors/$id/enabled'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'isEnabled': isEnabled}),
      ).timeout(timeout);
      if (res.statusCode == 200) {
        return _parseSector(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> setFlowRate(String id, double rate) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/sectors/$id/flow-rate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'flowRate': rate}),
      ).timeout(timeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<SectorModel?> createSector({
    required String name,
    required String region,
    double idealMoisture = 60.0,
    double minMoistureTrigger = 35.0,
    double maxMoistureCutoff = 75.0,
    bool isEnabled = true,
    double? moisture,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/sectors'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'region': region,
          'idealMoisture': idealMoisture,
          'minMoistureTrigger': minMoistureTrigger,
          'maxMoistureCutoff': maxMoistureCutoff,
          'isEnabled': isEnabled,
          if (moisture != null) 'moisture': moisture,
        }),
      ).timeout(timeout);

      if (res.statusCode == 201) {
        return _parseSector(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }

  static Future<SectorModel?> updateSector({
    required String id,
    required String name,
    required String region,
    required double idealMoisture,
    required double minMoistureTrigger,
    required double maxMoistureCutoff,
    required bool isEnabled,
  }) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/sectors/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'region': region,
          'idealMoisture': idealMoisture,
          'minMoistureTrigger': minMoistureTrigger,
          'maxMoistureCutoff': maxMoistureCutoff,
          'isEnabled': isEnabled,
        }),
      ).timeout(timeout);

      if (res.statusCode == 200) {
        return _parseSector(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> deleteSector(String id) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/sectors/$id')).timeout(timeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Monitoring
  static Future<Map<String, dynamic>?> fetchSectorMonitoringSummary(String sectorId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/monitoring/sector-summary/$sectorId')).timeout(timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return null;
  }

  static Future<List<Map<String, dynamic>>?> fetchWeeklyComparison() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/monitoring/weekly-comparison')).timeout(timeout);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return null;
  }

  // Emergency stop
  static Future<bool> emergencyStop() async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/irrigation/emergency-stop')).timeout(timeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Resume system
  static Future<bool> resumeSystem() async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/irrigation/resume')).timeout(timeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Mode
  static Future<bool> setOperationMode(String mode) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/irrigation/mode'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mode': mode}),
      ).timeout(timeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Automation parameters
  static Future<bool> updateParameters(double min, double max) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/irrigation/parameters'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'minMoisture': min, 'maxMoisture': max}),
      ).timeout(timeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Dashboard summary & alerts
  static Future<Map<String, dynamic>?> fetchDashboardSummary() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/dashboard/summary')).timeout(timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return null;
  }

  // Reports overview & download (PostgreSQL & API)
  static Future<Map<String, dynamic>?> fetchReportsOverview() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/reports/overview')).timeout(timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return null;
  }

  static Future<String?> downloadReport(String reportId, {String format = 'csv'}) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/reports/export/$reportId?format=$format')).timeout(timeout);
      if (res.statusCode == 200) {
        return res.body;
      }
    } catch (_) {}
    return null;
  }

  static Future<List<int>?> downloadMonthlySavingsPdf() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/reports/export-pdf/monthly-savings')).timeout(timeout);
      if (res.statusCode == 200) {
        return res.bodyBytes;
      }
    } catch (_) {}
    return null;
  }

  // Alerts Management (PostgreSQL & API)
  static Future<List<Map<String, dynamic>>?> fetchAlerts({bool includeResolved = false}) async {
    try {
      final uri = Uri.parse('$baseUrl/alerts${includeResolved ? '?all=true' : ''}');
      final res = await http.get(uri).timeout(timeout);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> resolveAlert(String alertId) async {
    try {
      final res = await http.put(Uri.parse('$baseUrl/alerts/$alertId/resolve')).timeout(timeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> createAlert({
    required String title,
    required String description,
    String severity = 'warning',
    String? sectorId,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/alerts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'description': description,
          'severity': severity,
          'sectorId': sectorId,
        }),
      ).timeout(timeout);
      if (res.statusCode == 201) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> deleteAlert(String alertId) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/alerts/$alertId')).timeout(timeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Irrigation Schedules (PostgreSQL & API)
  static Future<Map<String, dynamic>?> fetchSchedule() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/irrigation/schedule')).timeout(timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> updateSchedule(String time, String sectors, {double dailyProgressPct = 65.0}) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/irrigation/schedule'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'time': time,
          'sectors': sectors,
          'dailyProgressPct': dailyProgressPct,
        }),
      ).timeout(timeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<List<IrrigationScheduleItem>?> fetchSchedules() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/irrigation/schedules')).timeout(timeout);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => _parseSchedule(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return null;
  }

  static Future<IrrigationScheduleItem?> createScheduleItem({
    required String time,
    required List<String> sectorIds,
    required String sectorsLabel,
    bool isActive = true,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/irrigation/schedules'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'time': time,
          'sectorIds': sectorIds,
          'sectorsLabel': sectorsLabel,
          'isActive': isActive,
        }),
      ).timeout(timeout);
      if (res.statusCode == 201) {
        return _parseSchedule(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }

  static Future<IrrigationScheduleItem?> updateScheduleItem({
    required String id,
    required String time,
    required List<String> sectorIds,
    required String sectorsLabel,
    required bool isActive,
  }) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/irrigation/schedules/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'time': time,
          'sectorIds': sectorIds,
          'sectorsLabel': sectorsLabel,
          'isActive': isActive,
        }),
      ).timeout(timeout);
      if (res.statusCode == 200) {
        return _parseSchedule(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }

  static Future<IrrigationScheduleItem?> toggleScheduleItem(String id, bool isActive) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/irrigation/schedules/$id/toggle'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'isActive': isActive}),
      ).timeout(timeout);
      if (res.statusCode == 200) {
        return _parseSchedule(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> deleteScheduleItem(String id) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/irrigation/schedules/$id')).timeout(timeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
