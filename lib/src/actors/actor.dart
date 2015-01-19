part of hello_dart;

/// The direction of an actor.
enum Direction {
  right,
  down,
  left,
  up
}

/// Returns the name of the [direction].
directionName(Direction direction) {
  var s = direction.toString();
  return s.substring(s.indexOf('.') + 1);
}



/// Superclass for all [Actor]s.
abstract class Actor {

  /// A reference to the world.
  World world;

  /// The horizontal position.
  int x = 0;

  /// The vertical position.
  int y = 0;

  /// The direction of this actor.
  Direction direction = Direction.right;

  /// Returns the next direction when turning clockwise.
  Direction get _nextDirectionClockwise =>
      Direction.values[(direction.index + 1) % Direction.values.length];

  /// Returns the next direction when turning counter clockwise.
  Direction get _nextDirectionCounterclockwise =>
      Direction.values[(direction.index - 1) % Direction.values.length];

  /// The layer of the stage that this actor is added to.
  Sprite get layer => world._getLayer(this);

  /// Visual representation of this actor.
  ///
  /// Note: The position and direction of the actor and its bitmap may
  /// not be in sync because the visual moves and turns are delayed.
  Bitmap _bitmap;

  /// Constructor.
  Actor([this.world, this.x, this.y]);

  /// Returns this actor's current image.
  BitmapData get image;

  /// Moves the actor in the specified [direction].
  void _move(Direction direction) {
    switch (direction) {
      case Direction.right:
        x = x + 1;
        break;
      case Direction.down:
        y = y + 1;
        break;
      case Direction.left:
        x = x - 1;
        break;
      case Direction.up:
        y = y - 1;
        break;
    }
  }

  /// Adds the bitmap of this actor to the world.
  void _bitmapAddToWorld() {
    if (_bitmap == null) {
      // Create the bitmap.
      var coords = World.cellToPixel(x, y);
      _bitmap = new Bitmap(image);
      _bitmap
          ..x = coords.x
          ..y = coords.y;
    }

    // Add to the layer for this actor type.
    _bitmap.addTo(layer);
  }

  /// Removes the bitmap of this actor from the world.
  void _bitmapRemoveFromWorld() {
    if (_bitmap != null) {
      _bitmap.removeFromParent();
    }
  }

  /// Creates a move animation to the [targetPoint] with the specified
  /// [duration] in seconds.
  Animatable _bitmapMoveAnimation(Point startPoint, Point targetPoint,
                                  Direction direction, double duration) {
    Point targetPixel = World.cellToPixel(targetPoint.x, targetPoint.y);

    return new Tween(_bitmap, duration,
        TransitionFunction.linear)
      ..animate.x.to(targetPixel.x)
      ..animate.y.to(targetPixel.y);
  }

  /// Creates a turn animation from [startDirection] to [endDirection]
  /// with the specified [duration] in seconds.
  ///
  /// If the bitmap was turned counterclockwise, set the [clockwise] parameter
  /// to false.
  ///
  /// Note: Unless a subclass overrides this method, no turning will be done.
  Animatable _bitmapTurnAnimation(Direction startDirection, Direction endDirection,
                                  double duration, {clockwise: true}) {
    // Do nothing.
    return new DelayedCall(() {}, 0);
  }

  /// Creates a [DelayedCall] to update the image to [newImage].
  Animatable _bitmapUpdateImage(BitmapData newImage, double duration) {
    return new DelayedCall(() {
      _bitmap.bitmapData = newImage;
    }, 0);
  }
}

/// Helper method to convert the [degrees] to radian.
num _degreesToRadian(num degrees) => degrees * math.PI / 180;