import 'package:flutter/material.dart';

double screenHeight(BuildContext context, double percent) {
  return MediaQuery.of(context).size.height * percent;
}

double screenWidth(BuildContext context, double percent) {
  return MediaQuery.of(context).size.width * percent;
}

double screenPadding(BuildContext context, double factor) {
  return MediaQuery.of(context).size.width * factor;
}
