part of hello_dart;

/// The direction of an actor.
///
/// Note: This class mimics an enum in Dart. In future Dart versions we will
/// be able to use real enums.
class Direction {
  static const right = const Direction._(0, 'right');
  static const down = const Direction._(1, 'down');
  static const left = const Direction._(2, 'left');
  static const up = const Direction._(3, 'up');

  static get values => [right, down, left, up];

  final int index;
  final String value;

  const Direction._(this.index, this.value);

  @override
  String toString() => value;
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

  /// Visual representation of this actor.
  ///
  /// Note: The position and direction of the actor and its bitmap may
  /// not be in sync because the visual moves and turns are delayed.
  BitmapZ _bitmap;

  /// Constructor.
  Actor([this.world, this.x, this.y]);

  /// Returns this actor's current image.
  BitmapData get image;

  /// The stack order of this element.
  int get zIndex;

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
      _bitmap = new BitmapZ(image);
      _bitmap
          ..x = coords.x
          ..y = coords.y
          ..layer = y
          ..zIndex = zIndex
          ..pivotX = (_bitmap.width / 2).floor()
          ..pivotY = (_bitmap.height / 2).floor();
    }

    // Add to the world.
    world.addChildAtZOrder(_bitmap);
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
      ..animate.y.to(targetPixel.y)
      ..onStart = () {
        if (targetPoint.y > startPoint.y) {
          // Moving down, we must adjust layer during start.
          _bitmap.layer = targetPoint.y;
          world.updateChildIndexZOrder(_bitmap);
        }
      }
      ..onComplete = () {
        if (targetPoint.y < startPoint.y) {
          // Moving up, we must adjust layer at end.
          _bitmap.layer = targetPoint.y;
          world.updateChildIndexZOrder(_bitmap);
        }
      };
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