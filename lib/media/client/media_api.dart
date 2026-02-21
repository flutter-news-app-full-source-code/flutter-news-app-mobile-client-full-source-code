import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:http_client/http_client.dart';
import 'package:http_parser/http_parser.dart';
import 'package:logging/logging.dart';

/// {@template media_api}
/// An implementation of [MediaClient] that uses an [HttpClient] for
/// communication with the media resource endpoint.
///
/// This class provides concrete implementations for the media access methods
/// defined in [MediaClient], handling the underlying HTTP requests.
/// {@endtemplate}
class MediaApi implements MediaClient {
  /// {@macro media_api}
  const MediaApi({required HttpClient httpClient, required Logger logger})
    : _httpClient = httpClient,
      _logger = logger;

  static const String _basePath = '/api/v1/media';

  final HttpClient _httpClient;
  final Logger _logger;

  @override
  Future<RequestUploadUrlResponse> requestUploadUrl(
    RequestUploadUrlRequest request,
  ) async {
    _logger.info('Requesting upload URL for: ${request.fileName}');
    final responseData = await _httpClient.post<Map<String, dynamic>>(
      '$_basePath/request-upload-url',
      data: request.toJson(),
    );
    _logger.fine('Request upload URL response: $responseData');
    return RequestUploadUrlResponse.fromJson(responseData);
  }

  @override
  Future<void> uploadFileWithSignedPolicy({
    required String url,
    required Map<String, String> fields,
    required String fileName,
    required Uint8List fileBytes,
    required String contentType,
  }) async {
    _logger.info('Uploading file with signed policy to: $url');
    final formData = FormData.fromMap({
      ...fields,
      'file': MultipartFile.fromBytes(
        fileBytes,
        filename: fileName,
        contentType: MediaType.parse(contentType),
      ),
    });
    await _httpClient.post<void>(
      url,
      data: formData,
      options: Options(headers: {'Authorization': null}),
    );
    _logger.fine('File upload with signed policy successful.');
  }
}
