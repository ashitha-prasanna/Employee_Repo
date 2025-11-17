
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io' as io;

Future<String> saveAndOpen(Uint8List bytes, String filename) async {
  final dir = await getApplicationDocumentsDirectory();
  final path = '${dir.path}/$filename';
  final file = io.File(path);
  await file.writeAsBytes(bytes);
  try {
    await OpenFilex.open(file.path);
  } catch (e) {
    // ignore open errors but still return path for user reference
    print('OpenFilex.open failed: $e');
  }
  return file.path;
}
