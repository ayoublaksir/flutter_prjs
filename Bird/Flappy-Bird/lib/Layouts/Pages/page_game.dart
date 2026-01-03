// ignore_for_file: prefer_const_constructors, prefer_const_constructors_in_immutables, avoid_unnecessary_containers, avoid_print
import 'dart:async';
import 'package:personality_builder/Layouts/Pages/page_start_screen.dart';
import 'package:personality_builder/Layouts/Widgets/widget_spark.dart';
import 'package:personality_builder/Layouts/Widgets/widget_barrier.dart';
import 'package:personality_builder/Layouts/Widgets/widget_cover.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../Database/database.dart';
import '../../Global/constant.dart';
import '../../Global/functions.dart';
import '../../Resources/strings.dart';

class GamePage extends StatefulWidget {
  GamePage({Key? key}) : super(key: key);
  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  // Badge system variables
  bool showBadgeDialog = false;
  String currentBadge = '';

  // Stage progression
  String getCurrentStageBarrier() {
    if (score < 10) return 'fear';
    if (score < 20) return 'laziness';
    if (score < 30) return 'anger';
    return 'doubt';
  }

  void checkBadgeUnlock() {
    if (score == 10 && !unlockedBadges.contains('courage')) {
      unlockedBadges.add('courage');
      currentBadge = Str.courageBadge;
      showBadgeDialog = true;
    } else if (score == 20 && !unlockedBadges.contains('focus')) {
      unlockedBadges.add('focus');
      currentBadge = Str.focusedBadge;
      showBadgeDialog = true;
    } else if (score == 30 && !unlockedBadges.contains('calm')) {
      unlockedBadges.add('calm');
      currentBadge = Str.calmBadge;
      showBadgeDialog = true;
    } else if (score == 40 && !unlockedBadges.contains('confidence')) {
      unlockedBadges.add('confidence');
      currentBadge = Str.confidenceBadge;
      showBadgeDialog = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: gameHasStarted ? jump : startGame,
      child: Scaffold(
        body: Column(children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: background(Str.image),
              child: Stack(
                children: [
                  Spark(yAxis, sparkWidth, sparkHeight),
                  // Tap to play text
                  Container(
                    alignment: Alignment(0, -0.3),
                    child: myText(
                        gameHasStarted ? '' : 'TAP TO GROW', Colors.white, 25),
                  ),
                  // Stage indicator
                  Container(
                    alignment: Alignment(0, -0.6),
                    child: myText(
                        gameHasStarted
                            ? 'Facing: ${getCurrentStageBarrier().toUpperCase()}'
                            : '',
                        Colors.yellow,
                        18),
                  ),
                  Barrier(barrierHeight[0][0], barrierWidth, barrierX[0], true),
                  Barrier(
                      barrierHeight[0][1], barrierWidth, barrierX[0], false),
                  Barrier(barrierHeight[1][0], barrierWidth, barrierX[1], true),
                  Barrier(
                      barrierHeight[1][1], barrierWidth, barrierX[1], false),
                  // Badge dialog overlay
                  if (showBadgeDialog)
                    Container(
                      color: Colors.black54,
                      child: Center(
                        child: Container(
                          width: 300,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.stars, size: 60, color: Colors.amber),
                              SizedBox(height: 10),
                              Text(Str.badgeUnlocked,
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 10),
                              Text(currentBadge,
                                  style: TextStyle(fontSize: 16)),
                              SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    showBadgeDialog = false;
                                  });
                                },
                                child: Text('Continue Growing'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 1,
                    right: 1,
                    left: 1,
                    child: Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text("Growth: $score",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontFamily: "Magic4")),
                          Text("Best: $topScore",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontFamily: "Magic4")),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Cover(),
          ),
        ]),
      ),
    );
  }

  // Jump Function:
  void jump() {
    setState(() {
      time = 0;
      initialHeight = yAxis;
    });
  }

  //Start Game Function:
  void startGame() {
    gameHasStarted = true;
    Timer.periodic(Duration(milliseconds: 35), (timer) {
      height = gravity * time * time + velocity * time;
      setState(() {
        yAxis = initialHeight - height;
      });
      /* <  Barriers Movements  > */
      setState(() {
        if (barrierX[0] < screenEnd) {
          barrierX[0] += screenStart;
        } else {
          barrierX[0] -= barrierMovement;
        }
      });
      setState(() {
        if (barrierX[1] < screenEnd) {
          barrierX[1] += screenStart;
        } else {
          barrierX[1] -= barrierMovement;
        }
      });
      if (sparkIsDead()) {
        timer.cancel();
        _showDialog();
      }
      time += 0.032;
    });
    /* <  Calculate Score  > */
    Timer.periodic(Duration(seconds: 2), (timer) {
      if (sparkIsDead()) {
        // Todo : save the top score in the database  <---
        write("score", topScore);
        timer.cancel();
        score = 0;
      } else {
        setState(() {
          if (score == topScore) {
            topScore++;
          }
          score++;
          checkBadgeUnlock(); // Check for badge unlocks
        });
      }
    });
  }

  /// Make sure the [Spark] doesn't go out screen & hit the barrier
  bool sparkIsDead() {
    // Screen
    if (yAxis > 1.26 || yAxis < -1.1) {
      return true;
    }

    /// Barrier hitBox
    for (int i = 0; i < barrierX.length; i++) {
      if (barrierX[i] <= sparkWidth &&
          (barrierX[i] + (barrierWidth)) >= sparkWidth &&
          (yAxis <= -1 + barrierHeight[i][0] ||
              yAxis + sparkHeight >= 1 - barrierHeight[i][1])) {
        return true;
      }
    }
    return false;
  }

  void resetGame() {
    Navigator.pop(context); // dismisses the alert dialog
    setState(() {
      yAxis = 0;
      gameHasStarted = false;
      time = 0;
      score = 0;
      initialHeight = yAxis;
      barrierX[0] = 2;
      barrierX[1] = 3.4;
    });
  }

  // TODO: Alert Dialog with 2 options (try again, exit)
  void _showDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: myText("..Oops", Colors.blue[900], 35),
          actionsPadding: EdgeInsets.only(right: 8, bottom: 8),
          content: Container(
            child: Lottie.asset("assets/pics/loss.json", fit: BoxFit.cover),
          ),
          actions: [
            gameButton(() {
              resetGame();
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StartScreen(),
                  ));
            }, "Exit", Colors.grey),
            gameButton(() {
              resetGame();
            }, "try again", Colors.green),
          ],
        );
      },
    );
  }
}
