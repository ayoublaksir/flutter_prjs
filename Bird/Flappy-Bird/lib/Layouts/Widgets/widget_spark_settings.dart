// ignore_for_file: prefer_const_constructors

import 'package:personality_builder/Database/database.dart';
import 'package:personality_builder/Resources/strings.dart';
import 'package:flutter/material.dart';

import '../../Global/functions.dart';

class SparkSettings extends StatelessWidget {
  const SparkSettings({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.symmetric(vertical: 10),
          child: myText(Str.characterSelectTitle, Colors.black, 20),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: () {
                Str.spark = "assets/pics/spark_yellow.png";
                write("spark", Str.spark);
              },
              child: SizedBox(
                width: 75,
                height: 75,
                child: Image.asset("assets/pics/spark_yellow.png",
                    fit: BoxFit.cover),
              ),
            ),
            GestureDetector(
              onTap: () {
                Str.spark = "assets/pics/spark_blue.png";
                write("spark", Str.spark);
              },
              child: SizedBox(
                width: 75,
                height: 75,
                child: Image.asset("assets/pics/spark_blue.png",
                    fit: BoxFit.cover),
              ),
            ),
            GestureDetector(
              onTap: () {
                Str.spark = "assets/pics/spark_green.png";
                write("spark", Str.spark);
              },
              child: SizedBox(
                width: 75,
                height: 75,
                child: Image.asset("assets/pics/spark_green.png",
                    fit: BoxFit.cover),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
