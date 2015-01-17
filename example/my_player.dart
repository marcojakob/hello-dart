
import 'package:hello_dart/hello_dart.dart';

class MyPlayer extends Player {

  void start() {
    turnLeft();
    turnLeft();
    move();
    turnLeft();
    move();
    // move();
  }
}

void main() {
  launch('packages/hello_dart/scenarios/scenario108.txt', new MyPlayer(), 1000);
}



