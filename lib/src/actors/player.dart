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
    // Check for a tree.
    if (treeFront()) {
      world.queueAction((spd) {
        throw new PlayerException(messages.cantMoveBecauseOfTree());
      });
      _stop();
    }

    // Check for a box.
    Box box = world.getActorsInFront(x, y, direction)
        .firstWhere((Actor a) => a is Box, orElse: () => null);

    if (box != null) {
      // Check if the box can be pushed to the next field.
      if (!world.getActorsInFront(x, y, direction, 2)
          .any((Actor a) => a is Tree || a is Box)) {

        Point boxStartPointCopy = new Point(box.x, box.y);
        Point playerStartPointCopy = new Point(x, y);
        
        // Push the box and move the player.
        box._move(direction);
        _move(direction);

        Point boxTargetPointCopy = new Point(box.x, box.y);
        Point playerTargetPointCopy = new Point(x, y);

        // Copy the current box image name and the player's direction.
        var boxImage = box.image;
        String directionNameCopy = directionName;

        world.queueAction((spd) {
          AnimationGroup animGroup = new AnimationGroup();
          animGroup.add(box._bitmapMoveAnimation(boxStartPointCopy, 
                                                 boxTargetPointCopy, 
                                                 directionNameCopy, spd));
          animGroup.add(box._bitmapDelayedUpdate(boxImage, spd));
          animGroup.add(_bitmapMoveAnimation(playerStartPointCopy, 
                                             playerTargetPointCopy, 
                                             directionNameCopy, spd));

          return animGroup;
        });

      } else {
        // Could not push the box.
        world.queueAction((spd) {
          throw new PlayerException(messages.cantMoveBecauseOfBox());
        });
        _stop();
      }
    } else {
      Point startPointCopy = new Point(x, y);
      
      // Nothing in the way, the player can move.
      _move(direction);
      
      Point targetPointCopy = new Point(x, y);
      String directionNameCopy = directionName;

      world.queueAction((spd) {
        return _bitmapMoveAnimation(startPointCopy, targetPointCopy, 
            directionNameCopy, spd);
      });
    }
  }

  /// The player turns left by 90 degrees.
  void turnLeft() {
    direction = (direction - 90) % 360;

    var bitmapCopy = image;

    world.queueAction((spd) {
      return _bitmapDelayedUpdate(bitmapCopy, spd);
    });
  }

  /// The player turns right by 90 degrees.
  void turnRight() {
    direction = (direction + 90) % 360;

    var bitmapCopy = image;

    world.queueAction((spd) {
      return _bitmapDelayedUpdate(bitmapCopy, spd);
    });
  }

  /// The player puts down a star.
  void putStar() {
    if (!onStar()) {
      Star star = new Star(world, x, y);
      world.actors.add(star);

      world.queueAction((spd) {
        return new DelayedCall(() {
          star._bitmapAddToWorld();
        }, 0);
      });
    } else {
      world.queueAction((spd) {
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

      world.queueAction((spd) {
        return new DelayedCall(() {
          star._bitmapRemoveFromWorld();
        }, 0);
      });
    } else {
      world.queueAction((spd) {
        throw new PlayerException(messages.cantRemoveStar());
      });
      _stop();
    }
  }

  /// The player checks if he stands on a star.
  bool onStar() {
    return world.getActorsAt(x, y).any((Actor a) => a is Star);
  }

  /// The player checks if there is a tree in front of him.
  bool treeFront() {
    return world.getActorsInFront(x, y, direction).any((Actor a) => a is Tree);
  }

  /// The player checks if there is a tree on his left side.
  bool treeLeft() {
    return world.getActorsInFront(x, y, (direction - 90) % 360).any((Actor a) => a is Tree);
  }

  /// The player checks if there is a tree on his right side.
  bool treeRight() {
    return world.getActorsInFront(x, y, (direction + 90) % 360).any((Actor a) => a is Tree);
  }

  /// The player checks if there is a box in front of him.
  bool boxFront() {
    return world.getActorsInFront(x, y, direction).any((Actor a) => a is Box);
  }

  @override
  BitmapData get image {
    return world.resourceManager.getTextureAtlas(character)
        .getBitmapData('${directionName}-0');
  }

  /// Stops the execution.
  void _stop() {
    // We throw an exception here because it is the only way to immediately
    // leave an executing method.
    throw new StopException();
  }

  @override
  Animatable _bitmapMoveAnimation(Point startPoint, Point targetPoint, 
                                  String directionName, Duration speed) {
    Point startPixel = World.cellToPixel(startPoint.x, startPoint.y);
    Point targetPixel = World.cellToPixel(targetPoint.x, targetPoint.y);
    
    List bitmapDatas = world.resourceManager.getTextureAtlas(character).getBitmapDatas(directionName);
    
    // Add the first image again at third position.
    bitmapDatas.insert(2, bitmapDatas[0]);
    
    // Calculate the flip book frame rate.
    int frameRate = (bitmapDatas.length / (speed.inMilliseconds / 1000)).ceil();
    
    // Create walking flip book.
    FlipBook flipBook = new FlipBook(
        bitmapDatas,
            frameRate, false)
            ..x = startPixel.x
            ..y = startPixel.y
            ..mouseEnabled = false
            ..play()
            ..addTo(layer);


    Tween tween = new Tween(flipBook, speed.inMilliseconds / 1000,
        TransitionFunction.easeInOutQuadratic)
      ..animate.x.to(targetPixel.x)
      ..animate.y.to(targetPixel.y)
      ..onStart = () {
        // Remove bitmap.
        _bitmapRemoveFromWorld();
      }
      ..onComplete = () {
        flipBook.removeFromParent();

        // Add bitmap again.
        _bitmap.x = targetPixel.x;
        _bitmap.y = targetPixel.y;
        _bitmapAddToWorld();
      };
      
    AnimationGroup animGroup = new AnimationGroup(); 
    animGroup.add(flipBook);
    animGroup.add(tween);
    return animGroup;
  }
}
