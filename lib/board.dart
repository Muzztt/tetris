import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

enum Tetromino { L, J, I, O, S, Z, T }

const int rowLength = 10;
const int colLength = 15;

class Piece {
  Tetromino type;
  late List<int> position;
  late Color color;

  Piece({required this.type, this.color = Colors.transparent});

  void initializePiece() {
    switch (type) {
      case Tetromino.L:
        position = [3, 13, 23, 33];
        color = Colors.orange;
        break;
      case Tetromino.J:
        position = [4, 14, 24, 34];
        color = Colors.blue;
        break;
      case Tetromino.I:
        position = [5, 15, 25, 35];
        color = Colors.cyan;
        break;
      case Tetromino.O:
        position = [4, 5, 14, 15];
        color = Colors.yellow;
        break;
      case Tetromino.S:
        position = [4, 5, 13, 14];
        color = Colors.green;
        break;
      case Tetromino.Z:
        position = [3, 4, 14, 15];
        color = Colors.red;
        break;
      case Tetromino.T:
        position = [4, 13, 14, 15];
        color = Colors.purple;
        break;
    }
  }

  void movePiece(Direction direction) {
    if (!checkCollision(direction)) {
      for (int i = 0; i < position.length; i++) {
        position[i] += direction.offset;
      }
    }
  }

  bool checkCollision(Direction direction) {
    for (int i = 0; i < position.length; i++) {
      int row = (position[i] / rowLength).floor();
      int col = position[i] % rowLength;

      if (direction == Direction.left) {
        col -= 1;
      } else if (direction == Direction.right) {
        col += 1;
      } else if (direction == Direction.down) {
        row += 1;
      }

      if (row >= colLength || col < 0 || col >= rowLength) {
        return true;
      }
    }

    return false;
  }
}

enum Direction { left, right, down }

extension DirectionExtension on Direction {
  int get offset {
    switch (this) {
      case Direction.left:
        return -1;
      case Direction.right:
        return 1;
      case Direction.down:
        return rowLength;
      default:
        return 0;
    }
  }
}

class GameBoard extends StatefulWidget {
  const GameBoard({Key? key}) : super(key: key);

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  List<List<Tetromino?>> gameBoard = List.generate(
    colLength,
    (i) => List.generate(
      rowLength,
      (j) => null,
    ),
  );

  Piece currentPiece = Piece(type: Tetromino.T);
  late Timer gameLoopTimer;
  int score = 0;

  @override
  void initState() {
    super.initState();

    startGame();
  }

  void startGame() {
    currentPiece.initializePiece();

    const frameRate = Duration(milliseconds: 800);
    gameLoopTimer = Timer.periodic(frameRate, (timer) {
      setState(() {
        checkLanding();
        currentPiece.movePiece(Direction.down);
      });
    });
  }

  @override
  void dispose() {
    gameLoopTimer.cancel();
    super.dispose();
  }

  void checkLanding() {
    if (checkCollision(Direction.down)) {
      for (int i = 0; i < currentPiece.position.length; i++) {
        int row = (currentPiece.position[i] / rowLength).floor();
        int col = currentPiece.position[i] % rowLength;
        if (row >= 0 && col >= 0) {
          gameBoard[row][col] = currentPiece.type;
        }
      }

      createNewPiece();
      clearFilledRows();
    }
  }

  bool checkCollision(Direction direction) {
    for (int i = 0; i < currentPiece.position.length; i++) {
      int row = (currentPiece.position[i] / rowLength).floor();
      int col = currentPiece.position[i] % rowLength;

      if (direction == Direction.left) {
        col -= 1;
      } else if (direction == Direction.right) {
        col += 1;
      } else if (direction == Direction.down) {
        row += 1;
      }

      if (row >= colLength || col < 0 || col >= rowLength) {
        return true;
      }

      if (row >= 0 && gameBoard[row][col] != null) {
        return true;
      }
    }

    return false;
  }

  void createNewPiece() {
    Random rand = Random();
    Tetromino randomType =
        Tetromino.values[rand.nextInt(Tetromino.values.length)];
    currentPiece = Piece(type: randomType);
    currentPiece.initializePiece();
  }

  void clearFilledRows() {
    List<int> filledRows = [];

    for (int i = 0; i < colLength; i++) {
      bool rowFilled = true;

      for (int j = 0; j < rowLength; j++) {
        if (gameBoard[i][j] == null) {
          rowFilled = false;
          break;
        }
      }

      if (rowFilled) {
        filledRows.add(i);
      }
    }

    if (filledRows.isNotEmpty) {
      setState(() {
        for (int row in filledRows) {
          gameBoard.removeAt(row);
          gameBoard.insert(0, List.generate(rowLength, (index) => null));
        }

        score += filledRows.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Score: $score',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              itemCount: rowLength * colLength,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: rowLength,
              ),
              itemBuilder: (context, index) {
                int row = (index / rowLength).floor();
                int col = index % rowLength;

                if (currentPiece.position.contains(index)) {
                  return Pixel(
                    color: currentPiece.color,
                  );
                } else if (gameBoard[row][col] != null) {
                  Tetromino tetromino = gameBoard[row][col]!;
                  return Pixel(
                    color: getColor(tetromino),
                  );
                } else {
                  return Pixel(
                    color: Colors.grey[900]!,
                  );
                }
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  currentPiece.movePiece(Direction.left);
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.arrow_downward),
              onPressed: () {
                setState(() {
                  currentPiece.movePiece(Direction.down);
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.arrow_forward),
              onPressed: () {
                setState(() {
                  currentPiece.movePiece(Direction.right);
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class Pixel extends StatelessWidget {
  final Color color;

  Pixel({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        border: Border.all(
          color: Colors.black,
          width: 1,
        ),
      ),
    );
  }
}

Color getColor(Tetromino tetromino) {
  switch (tetromino) {
    case Tetromino.L:
      return Color(0xffffa500);
    case Tetromino.J:
      return Color.fromARGB(255, 0, 102, 255);
    case Tetromino.I:
      return Color.fromARGB(255, 242, 0, 255);
    case Tetromino.O:
      return Color(0xffffff00);
    case Tetromino.S:
      return Color(0xff008000);
    case Tetromino.Z:
      return Color(0xffff0000);
    case Tetromino.T:
      return Color.fromARGB(255, 144, 0, 255);
  }
}
