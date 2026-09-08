import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class UpdateDialog extends StatefulWidget {
  final String latestVersion;
  final String downloadUrl;
  final String? changelog;

  const UpdateDialog({
    super.key,
    required this.latestVersion,
    required this.downloadUrl,
    this.changelog,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusText = '';

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _statusText = 'Downloading update...';
    });

    try {
      final dio = Dio();
      final tempDir = await getTemporaryDirectory();
      final savePath =
          '${tempDir.path}/KVMan-update-${widget.latestVersion}.apk';

      await dio.download(
        widget.downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _progress = received / total;
            });
          }
        },
      );

      setState(() {
        _statusText = 'Download complete. Installing...';
      });

      // Open the APK to prompt installation
      final result = await OpenFilex.open(savePath);
      if (result.type != ResultType.done) {
        setState(() {
          _statusText = 'Failed to open installer: ${result.message}';
          _isDownloading = false;
        });
      } else {
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      setState(() {
        _statusText = 'Error downloading update.';
        _isDownloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Available'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A new version of KVMan (v${widget.latestVersion}) is available.',
          ),
          if (widget.changelog != null &&
              widget.changelog!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'What\'s new:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withAlpha(12)
                    : Colors.black.withAlpha(12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Text(
                  widget.changelog!.trim(),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (_isDownloading) ...[
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 8),
            Text(_statusText, style: const TextStyle(fontSize: 12)),
          ] else
            const Text('Would you like to download and install it now?'),
        ],
      ),
      actions: [
        if (!_isDownloading)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
        if (!_isDownloading)
          FilledButton(
            onPressed: _startDownload,
            child: const Text('Update Now'),
          ),
      ],
    );
  }
}
