import 'package:hello_dart/hello_dart.dart';

/// Your player.
class MyPlayer extends Player {

  /// Your program.
  void start() {
    move();
    putStar();
    move();
  }
}

/// The applications main method.
void main() {
  launch('scenario.txt', new MyPlayer());
}