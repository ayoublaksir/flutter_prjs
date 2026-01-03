// ignore_for_file: sized_box_for_whitespace, prefer_const_constructors, prefer_const_constructors_in_immutables, use_key_in_widget_constructors
import 'package:personality_builder/Resources/strings.dart';
import 'package:flutter/material.dart';

class Spark extends StatelessWidget {
  final double yAxis;
  final double sparkWidth;
  final double sparkHeight;

  Spark(this.yAxis, this.sparkWidth, this.sparkHeight);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return AnimatedContainer(
      alignment: Alignment(0, (2 * yAxis + sparkHeight) / (2 - sparkHeight)),
      duration: Duration(milliseconds: 0),
      child: Image.asset(
        Str.spark,
        width: size.width * sparkWidth,
        height: size.height * sparkHeight,
      ),
    );
  }
}
