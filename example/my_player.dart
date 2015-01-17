
import 'package:hello_dart/hello_dart.dart';

class MyPlayer extends Player {

  void start() {
    while (true) {
      move();
      turnLeft();
      move();
      turnRight();
      move();
      move();
      turnRight();
      move();
      turnRight();
      turnRight();
      move();
      turnRight();
      move();
      move();
      move();
      move();
      move();
      move();
      turnRight();
      move();
      turnLeft();
      move();
      move();
    }
  }
}

void main() {
  launch('packages/hello_dart/scenarios/scenario101.txt', new MyPlayer(), 1000);
}



