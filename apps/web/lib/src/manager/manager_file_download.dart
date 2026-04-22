import 'manager_file_download_api.dart';
import 'manager_file_download_stub.dart'
    if (dart.library.html) 'manager_file_download_web.dart';

ManagerFileDownloader buildManagerFileDownloader() {
  return createManagerFileDownloader();
}
