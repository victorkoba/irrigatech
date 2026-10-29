import 'file_downloader_stub.dart'
    if (dart.library.html) 'file_downloader_web.dart'
    if (dart.library.io) 'file_downloader_io.dart';

class FileDownloader {
  static void download(String fileName, String content) {
    downloadFileBytes(fileName, content);
  }

  static void downloadBytes(String fileName, List<int> bytes, {String mimeType = 'application/pdf'}) {
    downloadRawBinary(fileName, bytes, mimeType);
  }
}
