import 'manager_file_download_api.dart';

ManagerFileDownloader createManagerFileDownloader() {
  return const _UnsupportedManagerFileDownloader();
}

class _UnsupportedManagerFileDownloader implements ManagerFileDownloader {
  const _UnsupportedManagerFileDownloader();

  @override
  Future<bool> downloadText({
    required String fileName,
    required String contents,
    String mimeType = 'text/plain;charset=utf-8',
  }) async {
    return false;
  }
}
