// ignore_for_file: one_member_abstracts

import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// {@template package_info_service}
/// An abstract service for retrieving application package information.
///
/// This interface allows for mocking and provides a clean way to access
/// platform-specific app details like version, build number, etc.
/// {@endtemplate}
abstract class PackageInfoService {
  /// {@macro package_info_service}
  const PackageInfoService();

  /// Retrieves the application's version string (e.g., "1.0.0").
  ///
  /// Returns `null` if the version cannot be determined (e.g., on unsupported
  /// platforms or during an error).
  Future<String?> getAppVersion();
}

/// {@template package_info_service_impl}
/// A concrete implementation of [PackageInfoService] using `package_info_plus`.
/// {@endtemplate}
class PackageInfoServiceImpl implements PackageInfoService {
  /// {@macro package_info_service_impl}
  PackageInfoServiceImpl({Logger? logger})
    : _logger = logger ?? Logger('PackageInfoServiceImpl');

  final Logger _logger;

  @override
  Future<String?> getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _logger.info(
        'Successfully fetched package info. Version: ${packageInfo.version}',
      );
      return packageInfo.version;
    } catch (e, s) {
      _logger.warning(
        'Failed to get app version from platform. '
        'This might be expected on some platforms (e.g., web in certain contexts).',
        e,
        s,
      );
      return null;
    }
  }
}
