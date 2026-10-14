import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sector_model.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';
  static const Duration timeout = Duration(milliseconds: 1500);

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
        return data.map((item) {
          SectorStatus status = SectorStatus.idle;
          if (item['status'] == 'irrigating') status = SectorStatus.irrigating;
          if (item['status'] == 'error') status = SectorStatus.error;

          return SectorModel(
            id: item['id'],
            name: item['name'],
            region: item['region'],
            status: status,
            flowRate: (item['flowRate'] as num).toDouble(),
            moisture: (item['moisture'] as num).toDouble(),
            temperature: (item['temperature'] as num).toDouble(),
            alertMessage: item['alertMessage'],
          );
        }).toList();
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
}
