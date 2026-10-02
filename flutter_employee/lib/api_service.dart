
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'employee.dart';


import 'file_downloader_stub.dart'
  if (dart.library.html) 'file_downloader_web.dart'
  if (dart.library.io) 'file_downloader_io.dart' as downloader;

class ApiService {
 
  // Override at build time: flutter build web --dart-define=API_URL=https://<backend>/api/employees
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8081/api/employees',
  );

  Future<List<Employee>> getEmployees() async {
    final resp = await http.get(Uri.parse(baseUrl));
    if (resp.statusCode == 200) {
      final List parsed = jsonDecode(resp.body) as List;
      return parsed.map((e) => Employee.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load employees: ${resp.statusCode}');
  }

  Future<void> addEmployee(Employee emp) async {
    final resp = await http.post(Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(emp.toJson()));
    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception('Failed to add employee: ${resp.statusCode}');
    }
  }

  Future<void> updateEmployee(Employee emp) async {
    final resp = await http.put(Uri.parse('$baseUrl/${emp.id}'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(emp.toJson()));
    if (resp.statusCode != 200) {
      throw Exception('Failed to update employee: ${resp.statusCode}');
    }
  }

  Future<void> deleteEmployee(int id) async {
    final resp = await http.delete(Uri.parse('$baseUrl/$id'));
    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw Exception('Failed to delete employee: ${resp.statusCode}');
    }
  }

  Future<String> exportToExcel() async {
    final url = Uri.parse('$baseUrl/export/excel');
    final resp = await http.get(url);
    if (resp.statusCode != 200) {
      throw Exception('Failed to export: ${resp.statusCode}');
    }

    final Uint8List bytes = resp.bodyBytes;
    const filename = 'employees.xlsx';


    final String saved = await downloader.saveAndOpen(bytes, filename);
    return saved;
  }
}
