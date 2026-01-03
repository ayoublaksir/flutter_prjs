// ignore_for_file: prefer_const_constructors
import 'package:personality_builder/Database/database.dart';
import 'package:personality_builder/Resources/strings.dart';
import 'package:flutter/material.dart';
import '../../Global/functions.dart';

class ThemesSettings extends StatefulWidget {
  const ThemesSettings({Key? key}) : super(key: key);
  @override
  State<ThemesSettings> createState() => _ThemesSettingsState();
}

class _ThemesSettingsState extends State<ThemesSettings> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                Str.themesTitle,
                style: TextStyle(fontSize: 20, fontFamily: "Magic4"),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    Str.image = "0";
                    write("background", Str.image);
                    background(Str.image);
                  });
                },
                child: Image.asset("assets/pics/bg_calm.png",
                    width: 73, height: 70),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    Str.image = "1";
                    write("background", Str.image);
                    background(Str.image);
                  });
                },
                child: Image.asset("assets/pics/bg_tense.png",
                    width: 73, height: 70),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    Str.image = "2";
                    write("background", Str.image);
                    background(Str.image);
                  });
                },
                child: Image.asset("assets/pics/bg_victory.png",
                    width: 63, height: 66),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
