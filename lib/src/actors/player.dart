part of hello_dart;

/// This is the superclass for all Players.
///
/// Your program should be written in a subclass of this class.
abstract class Player extends Actor {

  /// Constructor.
  Player() : super(null, -1, -1);

  /// The start method where you can write your program.
  void start();

  /// The player makes a step in the current direction.
  void move() {
    // Check if there is another field in front.
    if (!fieldFront()) {
      world.queueAction((duration) {
        throw new PlayerException(messages.cantMoveBecauseNoField());
      });
      _stop();
    }

    // Check for a tree.
    if (treeFront()) {
      world.queueAction((duration) {
        throw new PlayerException(messages.cantMoveBecauseOfTree());
      });
      _stop();
    }

    // Check for a box.
    Box box = world.getActorsInFront(x, y, direction)
        .firstWhere((Actor a) => a is Box, orElse: () => null);

    if (box != null) {
      // Check if the box can be pushed to the next field.
      if (world.getFieldInFront(x, y, direction, 2) != null &&
          !world.getActorsInFront(x, y, direction, 2).any((a) => a is Tree || a is Box)) {

        Point boxStartPointCopy = new Point(box.x, box.y);
        Point playerStartPointCopy = new Point(x, y);

        // Push the box and move the player.
        box._move(direction);
        _move(direction);

        Point boxTargetPointCopy = new Point(box.x, box.y);
        Point playerTargetPointCopy = new Point(x, y);

        // Copy the current box image name and the player's direction.
        var boxImage = box.image;
        Direction directionCopy = direction;

        world.queueAction((duration) {
          AnimationGroup animGroup = new AnimationGroup();
          animGroup.add(box._bitmapMoveAnimation(boxStartPointCopy,
                                                 boxTargetPointCopy,
                                                 directionCopy, duration));
          animGroup.add(box._bitmapUpdateImage(boxImage, duration));
          animGroup.add(_bitmapMoveAnimation(playerStartPointCopy,
                                             playerTargetPointCopy,
                                             directionCopy, duration));

          return animGroup;
        });

      } else {
        // Could not push the box.
        world.queueAction((duration) {
          throw new PlayerException(messages.cantMoveBecauseOfBox());
        });
        _stop();
      }
    } else {
      Point startPointCopy = new Point(x, y);

      // Nothing in the way, the player can move.
      _move(direction);

      Point targetPointCopy = new Point(x, y);
      Direction directionCopy = direction;

      world.queueAction((duration) {
        return _bitmapMoveAnimation(startPointCopy, targetPointCopy,
            directionCopy, duration);
      });
    }
  }

  /// The player turns left by 90 degrees.
  void turnLeft() {
    var startDirectionCopy = direction;

    // Change the direction.
    direction = _nextDirectionCounterclockwise;

    var endDirectionCopy = direction;

    world.queueAction((duration) {
      return _bitmapTurnAnimation(startDirectionCopy, endDirectionCopy,
          duration, clockwise: false);
    });
  }

  /// The player turns right by 90 degrees.
  void turnRight() {
    var startDirectionCopy = direction;

    // Change the direction.
    direction = _nextDirectionClockwise;

    var endDirectionCopy = direction;
    var bitmapCopy = image;

    world.queueAction((duration) {
      return _bitmapTurnAnimation(startDirectionCopy, endDirectionCopy,
          duration, clockwise: true);
    });
  }

  /// The player checks if there is another field in front of him.
  bool fieldFront() {
    return world.getFieldInFront(x, y, direction) != null;
  }

  /// The player checks if there is a tree in front of him.
  bool treeFront() {
    return world.getActorsInFront(x, y, direction).any((Actor a) => a is Tree);
  }

  /// The player checks if there is a tree on his left side.
  bool treeLeft() {
    return world.getActorsInFront(x, y, _nextDirectionCounterclockwise)
        .any((Actor a) => a is Tree);
  }

  /// The player checks if there is a tree on his right side.
  bool treeRight() {
    return world.getActorsInFront(x, y, _nextDirectionClockwise)
        .any((Actor a) => a is Tree);
  }

  /// The player checks if there is a box in front of him.
  bool boxFront() {
    return world.getActorsInFront(x, y, direction).any((Actor a) => a is Box);
  }

  /// The player puts down a star.
  void putStar() {
    if (!onStar()) {
      Star star = new Star(world, x, y);
      world.actors.add(star);

      world.queueAction((duration) {
        return new DelayedCall(() {
          star._bitmapAddToWorld();
        }, 0);
      });
    } else {
      world.queueAction((duration) {
        throw new PlayerException(messages.cantPutStar());
      });
      _stop();
    }
  }

  /// The player picks up a star.
  void removeStar() {
    Star star = world.getActorsAt(x, y).firstWhere((Actor a) => a is Star,
        orElse: () => null);

    if (star != null) {
      world.actors.remove(star);

      world.queueAction((duration) {
        return new DelayedCall(() {
          star._bitmapRemoveFromWorld();
        }, 0);
      });
    } else {
      world.queueAction((duration) {
        throw new PlayerException(messages.cantRemoveStar());
      });
      _stop();
    }
  }

  /// The player checks if he stands on a star.
  bool onStar() {
    return world.getActorsAt(x, y).any((Actor a) => a is Star);
  }

  @override
  BitmapData get image {
    return world.resourceManager.getTextureAtlas('character')
        .getBitmapData('${direction}-0');
  }

  @override
  int get zIndex => 4;

  /// Stops the execution.
  void _stop() {
    // We throw an exception here because it is the only way to immediately
    // leave an executing method.
    throw new StopException();
  }

  @override
  Animatable _bitmapMoveAnimation(Point startPoint, Point targetPoint,
                                  Direction direction, double duration) {
    Point targetPixel = World.cellToPixel(targetPoint.x, targetPoint.y);

    List bitmapDatas = world.resourceManager.getTextureAtlas('character')
        .getBitmapDatas('${direction}');

    // Create the walk cycle.
    var walkCycle = [bitmapDatas[1], bitmapDatas[0], bitmapDatas[2], bitmapDatas[0]];

    // Calculate the flip book frame rate.
    int frameRate = (walkCycle.length / duration).ceil();

    int layerDuringMove = startPoint.y;
    if (targetPoint.y > startPoint.y) {
      layerDuringMove = targetPoint.y;
    }

    // Create walking flip book.
    var flipBook = new FlipBookZ(walkCycle, frameRate, false)
            ..x = _bitmap.x
            ..y = _bitmap.y
            ..layer = layerDuringMove
            ..zIndex = _bitmap.zIndex
            ..pivotX = _bitmap.pivotX
            ..pivotY = _bitmap.pivotY
            ..mouseEnabled = false
            ..play();

    // Create the move tween.
    Tween tween = new Tween(flipBook, duration,
        TransitionFunction.linear)
      ..animate.x.to(targetPixel.x)
      ..animate.y.to(targetPixel.y)
      ..onStart = () {
        world.addChildAtZOrder(flipBook);
        _bitmapRemoveFromWorld();
      }
      ..onComplete = () {
        flipBook.removeFromParent();

        // Add bitmap again.
        _bitmap.x = targetPixel.x;
        _bitmap.y = targetPixel.y;
        _bitmap.layer = targetPoint.y;
        _bitmapAddToWorld();
      };

    AnimationGroup animGroup = new AnimationGroup();
    animGroup.add(flipBook);
    animGroup.add(tween);
    return animGroup;
  }

  @override
  Animatable _bitmapTurnAnimation(Direction startDirection,
                                  Direction endDirection, double duration,
                                  {bool clockwise: true}) {

    List endImages = world.resourceManager.getTextureAtlas('character')
        .getBitmapDatas('${endDirection}');

    // Create the turn cycle.
    var turnCycle;

    if (clockwise) {
      turnCycle = [endImages[2], endImages[0]];
    } else {
      turnCycle = [endImages[1], endImages[0]];
    }

    // Calculate the flip book frame rate.
    int frameRate = (turnCycle.length / duration).ceil();

    // Create walking flip book.
    var flipBook = new FlipBookZ(turnCycle, frameRate, false)
            ..x = _bitmap.x
            ..y = _bitmap.y
            ..layer = _bitmap.layer
            ..zIndex = _bitmap.zIndex
            ..pivotX = _bitmap.pivotX
            ..pivotY = _bitmap.pivotY
            ..mouseEnabled = false
            ..play();

    Tween tween = new Tween(flipBook, duration,
        TransitionFunction.linear)
      ..onStart = () {
        _bitmapRemoveFromWorld();
        world.addChildAtZOrder(flipBook);
      }
      ..onComplete = () {
        flipBook.removeFromParent();

        // Add bitmap again with turned image.
        _bitmap.bitmapData = endImages[0];
        _bitmapAddToWorld();
      };

    AnimationGroup animGroup = new AnimationGroup();
    animGroup.add(flipBook);
    animGroup.add(tween);
    return animGroup;
  }
}
