import 'package:hello_dart/hello_dart.dart';

/// Your player.
class MyPlayer extends Player {

  bool goingRight = true;

  /// Your program.
  start() {
    while (!treeFront()) {
      invertField();

      if (!canMove()) {
        if (goingRight) {
          // Wir sind am rechten Rand.
          turnAroundRight();
        } else {
          // Wir sind am linken Rand.
          turnAroundLeft();
        }
      } else {
        move();
      }
    }
  }

  turnAroundRight() {
    if (treeRight()) {
      // Wir sind in der Ecke rechts unten.
      stop();
    } else {
      turnRight();
      move();
      turnRight();
      goingRight = false;
    }
  }

  turnAroundLeft() {
    if (treeLeft()) {
      // Wir sind in der Ecke links unten.
      stop();
    } else {
      turnLeft();
      move();
      turnLeft();
      goingRight = true;
    }
  }

  invertField() {
    if (onStar()) {
      removeStar();
    } else {
      putStar();
    }
  }
}


main() {
//  backgroundColorTop = '#fff';
  character = 'catgirl';
  createWorld('scenario.txt', new MyPlayer());
}
