part of hello_dart;

/// Boxes can be pushed by the player if there is nothing behind them.
class Box extends Actor {

  /// Constructor.
  Box(World world, int x, int y) : super(world, x, y);

  @override
  BitmapData get image {
    return world.resourceManager.getBitmapData('box');
  }

  @override
  int get zIndex => 2;
}
