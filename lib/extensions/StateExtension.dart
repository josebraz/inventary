
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

extension StateExtension on State {

  void showSnack(String text, {String? actionText, VoidCallback? actionClicked}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(text),
        action: actionText != null && actionClicked != null
            ? SnackBarAction(label: actionText, onPressed: actionClicked)
            : null));
  }
}