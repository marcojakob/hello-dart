part of hello_dart;

const int directionRight = 0;
const int directionDown = 90;
const int directionLeft = 180;
const int directionUp = 270;

/// Superclass for all [Actor]s.
abstract class Actor {

  /// A reference to the world.
  World world;

  /// The horizontal position.
  int x = 0;

  /// The vertical position.
  int y = 0;

  /// The direction of this actor in degrees.
  int direction = directionRight;

  /// The direction of this actor in radian.
  num get directionRadian => _degreesToRadian(direction);

  /// The name of the actor's current image.
  String get imageName;

  /// Visual representation of this actor.
  ///
  /// Note: The position and direction of the actor and its bitmap may
  /// not be in sync because the visual moves and turns are delayed.
  _ActorBitmap _bitmap;

  Actor([this.world, this.x, this.y]);

  /// Moves the actor in the specified [direction].
  ///
  /// If the actor moves over the world's edge it will appear on the opposite
  /// side.
  void _move(int direction) {
    switch (direction) {
      case directionRight:
        x = (x + 1) % world.widthInCells;
        break;
      case directionDown:
        y = (y + 1) % world.heightInCells;
        break;
      case directionLeft:
        x = (x - 1) % world.widthInCells;
        break;
      case directionUp:
        y = (y - 1) % world.heightInCells;
        break;
    }
  }

  /// Adds the bitmap of this actor to the world.
  void _addToWorld() {
    if (_bitmap == null) {
      // Create the bitmap.
      var coords = World.cellToPixel(x, y);
      _bitmap = new _ActorBitmap(world, world._getLayer(this),
          world.resourceManager.getBitmapData(imageName));
      _bitmap
          ..x = coords.x
          ..y = coords.y
          ..rotation = directionRadian;
    }

    // Add to the layer for this actor type.
    _bitmap.addTo(world._getLayer(this));
  }

  /// Removes the bitmap of this actor from the world.
  void _removeFromWorld() {
    if (_bitmap != null) {
      _bitmap.removeFromParent();
      _bitmap = null;
    }
  }
}

/// Visual representation of an [Actor].
///
/// Note: The position and direction of the [Actor] and its [_ActorBitmap] may
/// not be in sync because the visual moves and turns are delayed.
class _ActorBitmap extends Bitmap {

  /// The world this actor bitmap is part of.
  final World world;

  /// The layer in the world that is used for this kind of actor.
  final Sprite layer;

  _ActorBitmap(this.world, this.layer,
      [BitmapData bitmapData = null]) : super(bitmapData);

  /// Creates a move animation from [currentPoint] to the [targetPoint] with
  /// the specified [speed].
  Animatable moveAnimation(Point currentPoint, Point targetPoint,
                                  int direction, Duration speed) {

    Point moveOutPoint; // The point we move to if screen is left.
    Point moveInPoint; // The point we move in from if screen was left.

    // Test if the animation goes out of bounds and must thus appear on the
    // other side.
    if (direction == directionRight && targetPoint.x <= currentPoint.x) {
      // Crossed the right border.
      moveOutPoint = new Point(currentPoint.x + 1, currentPoint.y);
      moveInPoint = new Point(targetPoint.x - 1, targetPoint.y);
    } else if (direction == directionDown && targetPoint.y <= currentPoint.y) {
      // Crossed the bottom border.
      moveOutPoint = new Point(currentPoint.x, currentPoint.y + 1);
      moveInPoint = new Point(targetPoint.x, targetPoint.y - 1);
    } else if (direction == directionLeft && targetPoint.x >= currentPoint.x) {
      // Crossed the left border.
      moveOutPoint = new Point(currentPoint.x - 1, currentPoint.y);
      moveInPoint = new Point(targetPoint.x + 1, targetPoint.y);
    } else if (direction == directionUp && targetPoint.y >= currentPoint.y) {
      // Crossed the bottom border.
      moveOutPoint = new Point(currentPoint.x, currentPoint.y - 1);
      moveInPoint = new Point(targetPoint.x, targetPoint.y + 1);
    }

    if (moveOutPoint != null && moveInPoint != null) {
      // Must create multiple animations because we're out of bounds and appear
      // again on other side.
      AnimationChain animChain = new AnimationChain();

      Point currentPixel = World.cellToPixel(currentPoint.x, currentPoint.y);

      // Create a clone to animate out.
      var bitmapClone = new Bitmap(bitmapData)
          ..x = currentPixel.x
          ..y = currentPixel.y
          ..rotation = _degreesToRadian(direction);

      // Add the clone.
      animChain.add(new DelayedCall(() {
        bitmapClone.addTo(layer);
      }, 0));


      Point moveInPixel = World.cellToPixel(moveInPoint.x, moveInPoint.y);
      animChain.add(new DelayedCall(() {
        x = moveInPixel.x;
        y = moveInPixel.y;
      }, 0));

      AnimationGroup animGroup = new AnimationGroup();
      animChain.add(animGroup);

      // Animate clone to the point that is out of bounds.
      Point moveOutPixel = World.cellToPixel(moveOutPoint.x, moveOutPoint.y);
      animGroup.add(new Tween(bitmapClone, speed.inMilliseconds / 1000, TransitionFunction.easeInOutQuadratic)
          ..animate.x.to(moveOutPixel.x)
          ..animate.y.to(moveOutPixel.y));

      // Animate original to the target point.
      Point targetPixel = World.cellToPixel(targetPoint.x, targetPoint.y);
      animGroup.add(new Tween(this, speed.inMilliseconds / 1000, TransitionFunction.easeInOutQuadratic)
          ..animate.x.to(targetPixel.x)
          ..animate.y.to(targetPixel.y));


      // Remove clone.
      animChain.add(new DelayedCall(() {
        bitmapClone.removeFromParent();
      }, 0));

      return animChain;
    } else {
      // Animation to the target point.
      Point targetPixel = World.cellToPixel(targetPoint.x, targetPoint.y);
      return new Tween(this, speed.inMilliseconds / 1000, TransitionFunction.easeInOutQuadratic)
          ..animate.x.to(targetPixel.x)
          ..animate.y.to(targetPixel.y);
    }
  }

  /// Creates a turn animation that turns by [deltaValue], in radians.
  Animatable turnByAnimation(num deltaValue, Duration speed) {
    Tween anim = new Tween(this, speed.inMilliseconds / 1000, TransitionFunction.easeInOutQuadratic)
        ..animate.rotation.by(deltaValue);

    return anim;
  }

  /// Updates the bitmap image to the specified [newImageName].
  void updateImage(String newImageName) {
    bitmapData = world.resourceManager.getBitmapData(newImageName);
  }

  /// Creates a [DelayedCall] to update the image.
  DelayedCall delayedUpdateImage(String newImageName, Duration speed) {
    return new DelayedCall(() {
      updateImage(newImageName);
    }, speed.inMilliseconds / 1500);
  }
}


/// Helper method to convert the [degrees] to radian.
num _degreesToRadian(num degrees) => degrees * math.PI / 180;