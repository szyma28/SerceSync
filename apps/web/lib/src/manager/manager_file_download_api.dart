abstract class ManagerFileDownloader {
  Future<bool> downloadText({
    required String fileName,
    required String contents,
    String mimeType = 'text/plain;charset=utf-8',
  });
}
