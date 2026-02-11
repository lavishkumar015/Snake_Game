import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SnakeGame(),
    );
  }
}

enum Direction { up, down, left, right }

class SnakeGame extends StatefulWidget {
  const SnakeGame({super.key});

  @override
  State<SnakeGame> createState() => _SnakeGameState();
}

class _SnakeGameState extends State<SnakeGame> {
  final FocusNode _focusNode = FocusNode();

  static const int rowSize = 20;
  static const int totalSquares = rowSize * rowSize;

  List<int> snake = [45, 44, 43];
  int food = 120;
  Direction direction = Direction.right;

  int score = 0;
  int highScore = 0;
  int level = 1;
  int speed = 300; // milliseconds

  Timer? timer;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    startGame();
  }

  void startGame() {
    timer?.cancel();
    timer = Timer.periodic(Duration(milliseconds: speed), (timer) {
      setState(() {
        moveSnake();

        if (snake.first == food) {
          score++;
          if (score > highScore) highScore = score;

          // 🔥 LEVEL & SPEED INCREASE
          if (score % 5 == 0) {
            level++;
            speed = max(80, speed - 30);
            startGame();
          }

          generateFood();
        } else {
          snake.removeLast();
        }
      });
    });
  }

  void moveSnake() {
    int newHead;

    switch (direction) {
      case Direction.right:
        newHead = snake.first + 1;
        break;
      case Direction.left:
        newHead = snake.first - 1;
        break;
      case Direction.up:
        newHead = snake.first - rowSize;
        break;
      case Direction.down:
        newHead = snake.first + rowSize;
        break;
    }

    // 🧱 WALL COLLISION
    if (newHead < 0 || newHead >= totalSquares) {
      gameOver();
      return;
    }

    // LEFT & RIGHT WALL FIX
    if (direction == Direction.left &&
        snake.first % rowSize == 0) {
      gameOver();
      return;
    }

    if (direction == Direction.right &&
        snake.first % rowSize == rowSize - 1) {
      gameOver();
      return;
    }

    // 🐍 SELF COLLISION
    if (snake.contains(newHead)) {
      gameOver();
      return;
    }

    snake.insert(0, newHead);
  }


  void generateFood() {
    food = Random().nextInt(totalSquares);
  }

  // 🎮 CONTROL BUTTON
  Widget controlButton(IconData icon, Direction dir) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(16),
        backgroundColor: Colors.blueGrey,
      ),
      onPressed: () {
        setState(() {
          direction = dir;
        });
      },
      child: Icon(icon, size: 26, color: Colors.white),
    );
  }
  void gameOver() {
    timer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Game Over"),
          content: Text("Score: $score\nHigh Score: $highScore"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                resetGame();
              },
              child: const Text("Restart"),
            ),
          ],
        );
      },
    );
  }

  void resetGame() {
    setState(() {
      snake = [45, 44, 43];
      direction = Direction.right;
      food = Random().nextInt(totalSquares);
      score = 0;
      level = 1;
      speed = 300;
    });
    startGame();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final boardSize = min(size.width, size.height * 0.7);

    return RawKeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKey: (event) {
        if (event is RawKeyDownEvent) {
          setState(() {
            if (event.logicalKey == LogicalKeyboardKey.arrowUp &&
                direction != Direction.down) {
              direction = Direction.up;
            } else if (event.logicalKey ==
                LogicalKeyboardKey.arrowDown &&
                direction != Direction.up) {
              direction = Direction.down;
            } else if (event.logicalKey ==
                LogicalKeyboardKey.arrowLeft &&
                direction != Direction.right) {
              direction = Direction.left;
            } else if (event.logicalKey ==
                LogicalKeyboardKey.arrowRight &&
                direction != Direction.left) {
              direction = Direction.right;
            }
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              // 🧮 SCORE BOARD
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    textInfo("Score", score),
                    textInfo("High", highScore),
                    textInfo("Level", level),
                  ],
                ),
              ),

              // 🟦 GAME BOARD (RESPONSIVE)
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1, // perfect square
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.lightBlue[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: totalSquares,
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: rowSize,
                        ),
                        itemBuilder: (context, index) {
                          if (snake.contains(index)) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            );
                          } else if (index == food) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            );
                          } else {
                            return const SizedBox();
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 🎮 CONTROL BUTTONS
              Column(
                children: [
                  controlButton(Icons.keyboard_arrow_up, Direction.up),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      controlButton(
                          Icons.keyboard_arrow_left, Direction.left),
                      const SizedBox(width: 20),
                      controlButton(
                          Icons.keyboard_arrow_right, Direction.right),
                    ],
                  ),
                  controlButton(
                      Icons.keyboard_arrow_down, Direction.down),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget textInfo(String title, int value) {
    return Column(
      children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white70, fontSize: 14)),
        Text(
          value.toString(),
          style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    timer?.cancel();
    super.dispose();
  }
}
