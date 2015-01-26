import 'package:hello_dart/hello_dart.dart';

/// Your player.
class MyPlayer extends Player {

  /// Your program.
  void start() {
    move();
    addStar();
    move();
  }
}

/// The applications main method.
void main() {
  launch('scenario.txt', new MyPlayer());
}