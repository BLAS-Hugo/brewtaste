import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannedBeer {
  const ScannedBeer({required this.name, required this.brewery});

  final String name;
  final String brewery;
}

class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({super.key});

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final Dio _dio = Dio();

  bool _processing = false;

  @override
  void dispose() {
    unawaited(_controller.dispose());
    _dio.close();
    super.dispose();
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_processing) return;
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null) return;

    setState(() => _processing = true);
    await _controller.stop();

    final result = await _fetchProduct(barcode);
    if (mounted) Navigator.of(context).pop(result);
  }

  Future<ScannedBeer?> _fetchProduct(String barcode) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://world.openfoodfacts.org/api/v2/product/$barcode',
      );
      final product =
          (response.data?['product'] as Map<String, dynamic>?) ?? {};
      final name = product['product_name'] as String?;
      final brewery = product['brands'] as String?;
      if (name == null || name.isEmpty) return null;
      return ScannedBeer(name: name, brewery: brewery ?? '');
    } on DioException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner un code-barres')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onBarcodeDetected,
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
                'Pointez la caméra sur le code-barres',
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
