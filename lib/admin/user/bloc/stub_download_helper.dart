import 'dart:typed_data';
import '../../../core/core.dart';

class WebDownloadHelper {
  static void downloadFile(Uint8List dataBytes, String fileName) {
    logger.d("Excel download is only supported on web platform");
  }
}