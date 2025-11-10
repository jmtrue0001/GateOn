import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../main.dart';
import '../core.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({Key? key, this.message}) : super(key: key);
  final String? message;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Text(
        message ?? "페이지가 없습니다.\n\n불편을 드려 죄송합니다.",
        style: textTheme(context).krSubtitle1R,
        textAlign: TextAlign.center,
      )),
      bottomNavigationBar: InkWell(
          onTap: () {
            context.go('/');
          },
          child: Container(
            padding: const EdgeInsets.only(bottom: 32),
            height: 100,
            color: black,
            child: Center(
                child: Text(
              "홈으로",
              style: textTheme(context).krTitle2.copyWith(color: white),
            )),
          )),
    );
  }
}

class ErrorPage extends StatelessWidget {
  const ErrorPage({Key? key, required this.errorCode}) : super(key: key);

  final String errorCode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
          future: AppConfig.to.storage.read(key: 'deviceId'),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            return Center(
                child: Text(
              "앱에 오류가 발생하였습니다.\n\n관리자에게 문의해주시기 바랍니다.\n불편을 드려 죄송합니다.\n\n에러정보 : [$errorCode]\n\n${snapshot.data}",
              style: textTheme(context).krSubtitle1R,
              textAlign: TextAlign.center,
            ));
          }),
    );
  }
}
