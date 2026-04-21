import 'package:flutter/services.dart';

class AndroidDownloadManagerService {
  static const MethodChannel _channel = MethodChannel(
    'smart_receipt/downloads',
  );

  static Future<int> enqueuePdfDownload({
    required String url,
    required String fileName,
    String title = 'Claim PDF',
    String description =
        'Downloading document. Open notification to view when complete.',
  }) async {
    final result = await _channel.invokeMethod<int>('enqueuePdfDownload', {
      'url': url,
      'fileName': fileName,
      'title': title,
      'description': description,
    });

    if (result == null || result <= 0) {
      throw PlatformException(
        code: 'DOWNLOAD_ENQUEUE_FAILED',
        message: 'Could not enqueue download request.',
      );
    }

    return result;
  }
}
