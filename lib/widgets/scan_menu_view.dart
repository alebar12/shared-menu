import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_menu/l10n/app_localizations.dart';

class ScanMenuView extends StatefulWidget {
  const ScanMenuView({
    super.key,
  });

  @override
  State<ScanMenuView> createState() => _ScanMenuViewState();
}

class _ScanMenuViewState extends State<ScanMenuView> {
  final MobileScannerController controller = MobileScannerController(
    formats: const <BarcodeFormat>[BarcodeFormat.qrCode],
  );
  bool detected = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (detected || !mounted) {
      return;
    }
    for (final Barcode barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.isNotEmpty) {
        detected = true;
        Navigator.pop(context, value);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.menuActionJoin),
      ),
      body: MobileScanner(
        controller: controller,
        onDetect: _onDetect,
        overlayBuilder: (context, constraints) {
          return Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                l10n.scanMenuInstruction,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        },
      ),
    );
  }
}
