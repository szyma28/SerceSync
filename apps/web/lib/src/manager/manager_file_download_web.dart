import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'manager_file_download_api.dart';

ManagerFileDownloader createManagerFileDownloader() {
  return const _WebManagerFileDownloader();
}

class _WebManagerFileDownloader implements ManagerFileDownloader {
  const _WebManagerFileDownloader();

  @override
  Future<bool> downloadText({
    required String fileName,
    required String contents,
    String mimeType = 'text/plain;charset=utf-8',
  }) async {
    final blob = web.Blob(
      [contents.toJS].toJS,
      web.BlobPropertyBag(type: mimeType),
    );
    final objectUrl = web.URL.createObjectURL(blob);
    final container = web.document.body ?? web.document.documentElement;
    if (container == null) {
      web.URL.revokeObjectURL(objectUrl);
      return false;
    }

    final anchor = web.HTMLAnchorElement()
      ..href = objectUrl
      ..download = fileName
      ..style.display = 'none';

    container.appendChild(anchor);
    anchor.click();
    anchor.remove();
    web.URL.revokeObjectURL(objectUrl);
    return true;
  }
}
