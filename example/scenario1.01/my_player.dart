import 'package:hello_dart/hello_dart.dart';

/// Your player.
class MyPlayer extends Player {

  /// Your program.
  void start() {
    move();
    turnRight();
    move();
  }
}

/// The applications main method.
void main() {
  launch('scenario.txt', new MyPlayer());
}