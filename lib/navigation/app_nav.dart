import 'package:flutter/material.dart';

void replaceRoot(BuildContext context, Widget page) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => page),
    (route) => false,
  );
}
