import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateInfo {
  final bool isUpdateAvailable;
  final String latestVersion;
  final String downloadUrl;

  UpdateInfo({
    required this.isUpdateAvailable,
    required this.latestVersion,
    required this.downloadUrl,
  });
}

class UpdateService {
  static const String _repoUrl =
      'https://api.github.com/repos/arunpt/kvman/releases/latest';

  Future<UpdateInfo> checkForUpdate() async {
    try {
      final dio = Dio();
      final response = await dio.get(_repoUrl);

      if (response.statusCode == 200) {
        final data = response.data;
        String tagName = data['tag_name'] as String;
        // Clean 'v' from tag if present (e.g., v1.0.0 -> 1.0.0)
        final latestVersion = tagName.startsWith('v')
            ? tagName.substring(1)
            : tagName;

        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;
        final currentBuild = packageInfo.buildNumber;

        String latestVer = latestVersion;
        String latestBuild = '';
        if (latestVer.contains('+')) {
          final parts = latestVer.split('+');
          latestVer = parts[0];
          latestBuild = parts[1];
        }

        bool isUpdateAvailable = _isVersionGreater(
          latestVer,
          latestBuild,
          currentVersion,
          currentBuild,
        );

        String downloadUrl = '';
        if (isUpdateAvailable) {
          final assets = data['assets'] as List;
          for (var asset in assets) {
            final name = asset['name'] as String;
            if (name.endsWith('.apk')) {
              downloadUrl = asset['browser_download_url'];
              break;
            }
          }
        }

        return UpdateInfo(
          isUpdateAvailable: isUpdateAvailable && downloadUrl.isNotEmpty,
          latestVersion: latestVersion,
          downloadUrl: downloadUrl,
        );
      }
    } catch (e) {
      // Ignore errors for update checks so it doesn't interrupt user flow
    }
    return UpdateInfo(
      isUpdateAvailable: false,
      latestVersion: '',
      downloadUrl: '',
    );
  }

  bool _isVersionGreater(
    String latestVer,
    String latestBuild,
    String currentVer,
    String currentBuild,
  ) {
    final v1 = latestVer.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final v2 = currentVer.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      final part1 = i < v1.length ? v1[i] : 0;
      final part2 = i < v2.length ? v2[i] : 0;

      if (part1 > part2) return true;
      if (part1 < part2) return false;
    }

    // If the semantic versions (1.0.0) are exactly equal, fall back to checking the build number (+X)
    final b1 = int.tryParse(latestBuild) ?? 0;
    final b2 = int.tryParse(currentBuild) ?? 0;
    return b1 > b2;
  }
}
