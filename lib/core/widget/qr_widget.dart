import 'dart:developer';

import 'package:TPASS/core/config/logger.dart';
import 'package:TPASS/features/home/bloc/home_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

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
  late QRViewController qrViewController;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  @override
  Widget build(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
        MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 200.0;
    return
      BlocProvider(
          create: (context) => HomeBloc(const Ticker()),
      child:BlocBuilder<HomeBloc, HomeState>(
        buildWhen: (previous, current) => previous.status != current.status || previous.cameraPermissionStatus != current.cameraPermissionStatus,
        builder: (context, state) {
          return Stack(
            children: [
              QRView(
                key: qrKey,
                onQRViewCreated: _onQRViewCreated,
                overlay: QrScannerOverlayShape(
                    borderColor: Colors.red,
                    borderRadius: 10,
                    borderLength: 30,
                    borderWidth: 10,
                    cutOutSize: scanArea),
                onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
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

  void _onQRViewCreated(QRViewController controller) {
    String? lastScannedBarcode;
    setState(() {
      qrViewController = controller;
    });

    qrViewController.scannedDataStream.listen((scanData) {
      logger.d('스캔원시데이터'+scanData.code.toString());
      final scannedBarcode = scanData.code;
      if(scannedBarcode != null && scannedBarcode != lastScannedBarcode){
        lastScannedBarcode = scannedBarcode;

        qrViewController.pauseCamera();
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        bloc.add(ScanQR(barcode: scanData));
      }
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }

  @override
  void dispose() {
    qrViewController.dispose();
    super.dispose();
  }
}
