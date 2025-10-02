import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import '../../../core/core.dart';

class WebDownloadHelper {
  static void downloadFile(Uint8List dataBytes, String fileName) {
    if (kIsWeb) {
      final blob = html.Blob([dataBytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
      logger.d("Excel file downloaded: $fileName");
    }
  }
}