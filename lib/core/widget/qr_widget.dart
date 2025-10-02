import 'dart:developer';

import 'package:TPASS/core/config/logger.dart';
import 'package:TPASS/features/home/bloc/home_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../config/style.dart';
import '../util/static_dialog.dart';
import '../util/ticker.dart';


class QrWidget extends StatefulWidget {
  final HomeBloc bloc;
  QrWidget({required this.bloc});
  @override
  _QrWidgetState createState() => _QrWidgetState(bloc:bloc);
}

class _QrWidgetState extends State<QrWidget> {
  final HomeBloc bloc;
  _QrWidgetState({required this.bloc});
  late MobileScannerController qrViewController;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  @override
  void initState() {
    super.initState();
    qrViewController = MobileScannerController();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (context) => HomeBloc(const Ticker()),
        child: BlocBuilder<HomeBloc, HomeState>(
            buildWhen: (previous, current) => previous.status != current.status || previous.cameraPermissionStatus != current.cameraPermissionStatus,
            builder: (context, state) {
              return Stack(
                children: [
                  MobileScanner(
                    key: qrKey,
                    controller: qrViewController,
                    onDetect: _onQRViewCreated,
                  ),
                  Positioned(
                      top: 16,
                      right: 16,
                      child: IconButton(
                        onPressed: () {
                          qrViewController.dispose();
                          Navigator.pop(context);
                        },
                        icon: Icon(Icons.close, color: Colors.white,),
                      )),
                ],
              );
            }));
  }

  String? lastScannedBarcode;

  void _onQRViewCreated(BarcodeCapture capture) {
    if (capture.barcodes.isNotEmpty) {
      final barcode = capture.barcodes.first;
      logger.d('스캔원시데이터${barcode.rawValue}');
      final scannedBarcode = barcode.rawValue;
      if(scannedBarcode != null && scannedBarcode != lastScannedBarcode){
        lastScannedBarcode = scannedBarcode;

        qrViewController.stop();
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        bloc.add(ScanQR(barcode: capture));
      }
    }
  }

  @override
  void dispose() {
    qrViewController.dispose();
    super.dispose();
  }
}
