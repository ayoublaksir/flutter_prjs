// ignore_for_file: prefer_const_constructors

import 'package:audioplayers/audioplayers.dart';

/// SCORE Variables calculated in function [startGame] in [GamePage]
int score = 0;
int topScore = 0;

/// [Spark] Variables - The character that represents personal growth
double yAxis = 0;
double sparkWidth = 0.183;
double sparkHeight = 0.183;

/// Variables to calculate spark movements function [startGame] in [GamePage]
double time = 0;
double height = 0;
double gravity = -3.9; // How strong the Gravity
double velocity = 2.5; // How strong the jump
double initialHeight = yAxis;
bool gameHasStarted = false;

/// [Negative Force Barriers] Variables - Obstacles representing negative traits
List<double> barrierX = [2, 3.4];
double barrierWidth = 0.5;
List<List<double>> barrierHeight = [
  // TODO: list of Lists to make different height for the barrier [topHeight,bottomHeight]
  [0.6, 0.4],
  [0.4, 0.6],
];
double barrierMovement = 0.05;

/// Screen Boundary
double screenEnd = -1.9;
double screenStart = 3.5;

/// Audio
final player = AudioPlayer();
bool play = true;

/// Game Stages - Different negative forces encountered
enum NegativeForce { fear, laziness, anger, doubt }

/// Badge System - Tracks personality growth
int currentStage = 0;
List<String> unlockedBadges = [];
