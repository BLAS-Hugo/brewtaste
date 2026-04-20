import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _processing = false;

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  String? _parseCode(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri != null && uri.scheme == 'brewtaste' && uri.host == 'join') {
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) return segments.first.toUpperCase();
    }
    final upper = raw.trim().toUpperCase();
    if (RegExp(r'^BREW-\d{4}$').hasMatch(upper)) return upper;
    return null;
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    final code = _parseCode(raw);
    if (code == null) return;

    setState(() => _processing = true);
    await _controller.stop();

    if (mounted) Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner le QR code')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          if (_processing)
            const ColoredBox(
              color: Colors.black54,
              child: Center(child: CircularProgressIndicator()),
            ),
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Pointez la caméra sur le QR code',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
