
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

extension StateExtension on State {

  void showSnack(String text, {String? actionText, VoidCallback? actionClicked}) {
    final _log = Logger('StateExtension');
    _log.info("showSnack text $text actionText $actionText");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        action: actionText != null && actionClicked != null
          ? SnackBarAction(
              label: actionText,
              onPressed: () {
                _log.info("showSnack text $text Desfazer clicado");
                actionClicked.call();
              }
            )
          : null
      )
    );
  }
}