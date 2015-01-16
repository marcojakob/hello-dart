part of hello_dart;

/// Boxes can be pushed by the player if there is nothing behind them.
class Box extends Actor {

  /// Constructor.
  Box(World world, int x, int y) : super(world, x, y);

  @override
  String get imageName {
    return 'box';
  }
}
