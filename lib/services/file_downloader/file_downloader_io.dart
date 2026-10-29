import 'dart:io';

void downloadFileBytes(String fileName, String content) {
  try {
    final userProfile = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '.';
    final downloadsDir = Directory('$userProfile/Downloads');
    final file = downloadsDir.existsSync()
        ? File('${downloadsDir.path}/$fileName')
        : File(fileName);
    file.writeAsStringSync(content);
  } catch (_) {}
}

void downloadRawBinary(String fileName, List<int> bytes, String mimeType) {
  try {
    final userProfile = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '.';
    final downloadsDir = Directory('$userProfile/Downloads');
    final file = downloadsDir.existsSync()
        ? File('${downloadsDir.path}/$fileName')
        : File(fileName);
    file.writeAsBytesSync(bytes);
  } catch (_) {}
}
