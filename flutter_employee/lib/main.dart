
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'theme.dart';
import 'api_service.dart';
import 'employee.dart';

void main() {
  runApp(MyApp()); 
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Employee Manager',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const EmployeePage(),
    );
  }
}

class EmployeePage extends StatefulWidget {
  const EmployeePage({super.key});

  @override
  State<EmployeePage> createState() => _EmployeePageState();
}

class _EmployeePageState extends State<EmployeePage> {
  final ApiService api = ApiService();

  final _nameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _deptCtl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<Employee> _employees = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _emailCtl.dispose();
    _deptCtl.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    setState(() => _loading = true);
    try {
      final list = await api.getEmployees();
      setState(() => _employees = list);
    } catch (e) {
      _showSnack('Failed to load employees: $e', isError: true);
      setState(() => _employees = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _addOrUpdateEmployee({Employee? existing}) async {
    if (existing != null) {
      _nameCtl.text = existing.name;
      _emailCtl.text = existing.email;
      _deptCtl.text = existing.department;
    } else {
      _clearForm();
    }

    final title = existing == null ? 'Add Employee' : 'Edit Employee';

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: Form(
            key: _formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: _nameCtl,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter name' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailCtl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter email';
                  final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim());
                  return ok ? null : 'Enter valid email';
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _deptCtl,
                decoration: const InputDecoration(labelText: 'Department'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter department' : null,
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                final emp = Employee(
                  id: existing?.id,
                  name: _nameCtl.text.trim(),
                  email: _emailCtl.text.trim(),
                  department: _deptCtl.text.trim(),
                );
                try {
                  await api.addEmployee(emp);
                  _showSnack(existing == null ? 'Employee added' : 'Employee saved');
                  Navigator.of(ctx).pop();
                  _clearForm();
                  await _loadEmployees();
                } catch (e) {
                  _showSnack('Save failed: $e', isError: true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteEmployee(int id) async {
    try {
      await api.deleteEmployee(id);
      _showSnack('Employee deleted');
      await _loadEmployees();
    } catch (e) {
      _showSnack('Delete failed: $e', isError: true);
    }
  }

  Future<void> _exportExcelHandler() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      messenger.showSnackBar(const SnackBar(content: Text('Preparing Excel...')));
      final result = await api.exportToExcel(); 
      messenger.hideCurrentSnackBar();

      if (kIsWeb) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Download started'),
            content: SelectableText(
                result ?? 'If download didn\'t start, open: ${ApiService.baseUrl}/export/excel'),
            actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close'))],
          ),
        );
      } else {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Excel saved'),
            content: Text('File saved to:\n${result ?? "unknown"}'),
            actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close'))],
          ),
        );
      }

      messenger.showSnackBar(const SnackBar(content: Text('Export completed')));
    } catch (e) {
      messenger.hideCurrentSnackBar();
      _showSnack('Export failed: $e', isError: true);
    }
  }

  void _clearForm() {
    _nameCtl.clear();
    _emailCtl.clear();
    _deptCtl.clear();
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete'),
        content: const Text('Are you sure you want to delete this employee?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteEmployee(id);
            },
            child: const Text('Delete'),
          )
        ],
      ),
    );
  }

  void _showSnack(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: isError ? Colors.red.shade700 : null,
      duration: const Duration(seconds: 2),
    ));
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(children: [
        Expanded(
          child: Text(
            'Employees',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _exportExcelHandler,
          icon: const Icon(Icons.file_download_outlined),
          label: const Text('Export'),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          onPressed: _loadEmployees,
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
        ),
      ]),
    );
  }

  Widget _buildList() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: _employees.isEmpty
              ? ListView(
                  children: [
                    const SizedBox(height: 80),
                    Icon(Icons.people_alt_outlined, size: 72, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 12),
                    Center(child: Text('No employees yet', style: Theme.of(context).textTheme.bodyMedium)),
                  ],
                )
              : ListView.separated(
                  itemCount: _employees.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final e = _employees[i];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        leading: CircleAvatar(
                          radius: 26,
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                          child: Text(
                            e.name.isNotEmpty ? e.name[0].toUpperCase() : '?',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${e.email} • ${e.department}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: e.id != null ? () => _addOrUpdateEmployee(existing: e) : null,
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: e.id != null ? () => _confirmDelete(e.id!) : null,
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Database'),
        actions: [
          IconButton(onPressed: _exportExcelHandler, icon: const Icon(Icons.file_download_outlined), tooltip: 'Export'),
          IconButton(onPressed: _loadEmployees, icon: const Icon(Icons.refresh), tooltip: 'Refresh'),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadEmployees,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildList()),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 6.0, right: 6.0),
        child: FloatingActionButton.extended(
          onPressed: () => _addOrUpdateEmployee(),
          icon: const Icon(Icons.add),
          label: const Text('Add'),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
