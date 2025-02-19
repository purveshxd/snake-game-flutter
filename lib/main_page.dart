import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snake_game/snake_config.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  void initState() {
    super.initState();
    foodPosition = Random().nextInt(totalBox);
    getHighScore();
  }

  void saveHighScore() async {
    final sharedPref = await SharedPreferences.getInstance();
    if (currentScore > highScore) {
      await sharedPref.setInt('highScore', currentScore);
    } else {
      await sharedPref.setInt('highScore', highScore);
    }
    dev.log("current : $currentScore || high : $highScore");
  }

  void getHighScore() async {
    final sharedPref = await SharedPreferences.getInstance();
    highScore = sharedPref.getInt('highScore')!;
    setState(() {});
    dev.log("current : $currentScore || high : $highScore");
  }

  void hapticFeedBack() async {
    await HapticFeedback.mediumImpact();
  }

  // user score
  int currentScore = 0;

  // highscore
  int highScore = 0;

  late Timer timer;
  // start game
  bool gameStarted = false;
  // food position
  late int foodPosition;
  // Snake direction initial
  SnakeDirection snakeDirection = SnakeDirection.right;
  // grid width
  int gridWidth = 30;
  // total box
  int totalBox = 900;
  // snakes position
  List<int> snakePosition = [0, 1, 2];

  // move snake forward
  void startGame() {
    timer = Timer.periodic(
      Duration(milliseconds: 300),
      (timer) {
        if (gameStarted) {
          setState(() {
            moveSnake();

            // check game over
            if (gameOver()) {
              timer.cancel();

              saveHighScore();

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) {
                  return AlertDialog(
                    title: Text("Game over"),
                    content: Text("Your score is : $currentScore"),
                    actions: [
                      FilledButton.tonal(
                        onPressed: () {
                          newGame();
                          Navigator.pop(context);
                        },
                        child: Text("Restart"),
                      ),
                    ],
                  );
                },
              );
            }
          });
        }
      },
    );
  }

  // move snake
  void moveSnake() {
    switch (snakeDirection) {
      case SnakeDirection.up:
        {
          if (snakePosition.last < gridWidth) {
            snakePosition.add(snakePosition.last - gridWidth + totalBox);
          } else {
            snakePosition.add(snakePosition.last - gridWidth);
          }

          // snakePosition.removeAt(0);
        }
        break;
      case SnakeDirection.down:
        {
          if (snakePosition.last + gridWidth > totalBox) {
            snakePosition.add(snakePosition.last + gridWidth - totalBox);
          } else {
            snakePosition.add(snakePosition.last + gridWidth);
          }

          // snakePosition.removeAt(0);
        }
        break;
      case SnakeDirection.right:
        {
          if (snakePosition.last % gridWidth == gridWidth - 1) {
            snakePosition.add(snakePosition.last + 1 - gridWidth);
          } else {
            snakePosition.add(snakePosition.last + 1);
          }
          // snakePosition.removeAt(0);
        }
        break;
      case SnakeDirection.left:
        {
          if (snakePosition.last % gridWidth == 0) {
            snakePosition.add(snakePosition.last - 1 + gridWidth);
          } else {
            snakePosition.add(snakePosition.last - 1);
          }

          // snakePosition.removeAt(0);
        }
        break;
    }
    if (snakePosition.last == foodPosition) {
      eatFood();
    } else {
      snakePosition.removeAt(0);
    }
  }

  void eatFood() {
    currentScore++;
    while (snakePosition.contains(foodPosition)) {
      foodPosition = Random().nextInt(totalBox);
    }
    hapticFeedBack();
  }

  void newGame() {
    setState(() {
      snakePosition = [0, 1, 2];
      foodPosition = Random().nextInt(totalBox);
      snakeDirection = SnakeDirection.right;
      gameStarted = false;
      currentScore = 0;
      getHighScore();
    });
  }

  void playPause() {
    setState(() {
      if (gameStarted) {
        timer.cancel();
      } else {
        startGame();
      }
      gameStarted = !gameStarted;
    });
    hapticFeedBack();
  }

  bool gameOver() {
    List<int> snakeBody = snakePosition.sublist(0, snakePosition.length - 1);
    if (snakeBody.contains(snakePosition.last)) {
      hapticFeedBack();
      return true;
    }
    return false;
  }

  void verticalSwipe(DragUpdateDetails details) {
    if (details.delta.dy < 0 && snakeDirection != SnakeDirection.down) {
      // dev.log("up");
      snakeDirection = SnakeDirection.up;
      // hapticFeedBack();
    } else if (details.delta.dy > 0 && snakeDirection != SnakeDirection.up) {
      snakeDirection = SnakeDirection.down;
      // hapticFeedBack();
    }
  }

  void horizontalSwipe(DragUpdateDetails details) {
    if (details.delta.dx > 0 && snakeDirection != SnakeDirection.left) {
      snakeDirection = SnakeDirection.right;
      // hapticFeedBack();
    } else if (details.delta.dx < 0 && snakeDirection != SnakeDirection.right) {
      snakeDirection = SnakeDirection.left;
      // hapticFeedBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Snake Game"),
      ),
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              // crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    spacing: 8,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Score : $currentScore",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "High Score : $highScore",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: GestureDetector(
                    onTap: () => playPause(),
                    onVerticalDragUpdate: (details) => verticalSwipe(details),
                    onHorizontalDragUpdate: (details) =>
                        horizontalSwipe(details),
                    onVerticalDragEnd: (details) => hapticFeedBack(),
                    onHorizontalDragEnd: (details) => hapticFeedBack(),
                    child: GridView.builder(
                      physics: NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.all(8),
                      itemCount: totalBox,
                      shrinkWrap: true,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          childAspectRatio: 1,
                          crossAxisCount: gridWidth,
                          crossAxisSpacing: 1,
                          mainAxisSpacing: 1),
                      itemBuilder: (context, index) {
                        if (snakePosition.contains(index)) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: Colors.white70,
                            ),
                            // child: Text(
                            //   "$index",
                            //   style: TextStyle(
                            //       color: Colors.black, fontWeight: FontWeight.bold),
                            // ),
                          );
                        } else if (foodPosition == index) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: Colors.green,
                            ),
                          );
                        } else {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: Colors.white10,
                            ),
                            // child: Text(
                            //   "$index",
                            //   style: TextStyle(
                            //       color: Colors.black, fontWeight: FontWeight.bold),
                            // ),
                          );
                        }
                      },
                    ),
                  ),
                ),
                Expanded(child: Container())
              ],
            ),
            !gameStarted
                ? GestureDetector(
                    onTap: () => playPause(),
                    child: Container(
                      color: Colors.black45,
                      width: double.maxFinite,
                      height: double.maxFinite,
                      alignment: Alignment.center,
                      child: Text(
                        "Tap to Play",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                  )
                : SizedBox(),
          ],
        ),
      ),
    );
  }
}
