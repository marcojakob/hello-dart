part of hello_dart;

/// This is the superclass for all Players.
///
/// Your program should be written in a subclass of this class.
abstract class Player extends Actor {
  /// The direction of this actor.
  Direction direction = Direction.right;

  /// Constructor.
  Player() : super(null, -1, -1);

  /// The start method where you can write your program.
  void start();

  /// The player makes a step in the current direction.
  void move() {
    // Ensure there is a field in front.
    if (world.getFieldInFront(x, y, direction) == null) {
      say(messages.cantMoveBecauseNoField(), -1);
      stop();
    }

    // Ensure there is no tree.
    if (treeFront()) {
      say(messages.cantMoveBecauseOfTree(), -1);
      stop();
    }

    // Check for a box. If there is a box, ensure it can be moved.
    Box box = world
        .getActorsInFront(x, y, direction)
        .firstWhere((Actor a) => a is Box, orElse: () => null) as Box;

    if (box != null) {
      // Check if the box can be pushed to the next field.
      if (box.canMove(direction)) {
        Point<int> boxStartPointCopy = Point(box.x, box.y);
        Point<int> playerStartPointCopy = Point(x, y);

        // Push the box and move the player.
        box._move(direction);
        _move(direction);

        Point<int> boxTargetPointCopy = Point(box.x, box.y);
        Point<int> playerTargetPointCopy = Point(x, y);

        // Copy the current box image name and the player's direction.
        var boxImage = box.image;
        Direction directionCopy = direction;

        world.queueAction((duration) {
          AnimationGroup animGroup = AnimationGroup();
          animGroup.add(box._bitmapMoveAnimation(
              boxStartPointCopy, boxTargetPointCopy, directionCopy, duration));
          animGroup.add(box._bitmapUpdateImage(boxImage, duration));
          animGroup.add(_bitmapMoveAnimation(playerStartPointCopy,
              playerTargetPointCopy, directionCopy, duration));

          return animGroup;
        });
      } else {
        // Could not push the box.
        say(messages.cantMoveBecauseOfBox(), -1);
        stop();
      }
    } else {
      Point<int> startPointCopy = Point(x, y);

      // Nothing in the way, the player can move.
      _move(direction);

      Point<int> targetPointCopy = Point(x, y);
      Direction directionCopy = direction;

      world.queueAction((duration) {
        return _bitmapMoveAnimation(
            startPointCopy, targetPointCopy, directionCopy, duration);
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
      return _bitmapTurnAnimation(
          startDirectionCopy, endDirectionCopy, duration,
          clockwise: false);
    });
  }

  /// The player turns right by 90 degrees.
  void turnRight() {
    var startDirectionCopy = direction;

    // Change the direction.
    direction = _nextDirectionClockwise;

    var endDirectionCopy = direction;

    world.queueAction((duration) {
      return _bitmapTurnAnimation(
          startDirectionCopy, endDirectionCopy, duration,
          clockwise: true);
    });
  }

  /// The player checks if he/she can move to the next field.
  bool canMove() {
    // Ensure there is a field in front.
    if (world.getFieldInFront(x, y, direction) == null) {
      return false;
    }

    // Ensure there is no tree.
    if (treeFront()) {
      return false;
    }

    // Check for a box. If there is a box, ensure it can be moved.
    Box box = world
        .getActorsInFront(x, y, direction)
        .firstWhere((Actor a) => a is Box, orElse: () => null) as Box;

    if (box != null && !box.canMove(direction)) {
      return false;
    }

    // Nothing in the way, we can move.
    return true;
  }

  /// The player checks if there is a tree in front.
  bool treeFront() {
    return world.getActorsInFront(x, y, direction).any((Actor a) => a is Tree);
  }

  /// The player checks if there is a tree on the left side.
  bool treeLeft() {
    return world
        .getActorsInFront(x, y, _nextDirectionCounterclockwise)
        .any((Actor a) => a is Tree);
  }

  /// The player checks if there is a tree on the right side.
  bool treeRight() {
    return world
        .getActorsInFront(x, y, _nextDirectionClockwise)
        .any((Actor a) => a is Tree);
  }

  /// The player checks if there is a box in front.
  bool boxFront() {
    return world.getActorsInFront(x, y, direction).any((Actor a) => a is Box);
  }

  /// The player adds a star.
  void putStar() {
    if (!onStar()) {
      Star star = Star(world, x, y);
      world.actors.add(star);

      world.queueAction((duration) {
        star._bitmapAddToWorld();
        return null;
      });
    } else {
      say(messages.cantPutStar(), -1);
      stop();
    }
  }

  /// The player removes a star.
  void removeStar() {
    Star star = world
        .getActorsAt(x, y)
        .firstWhere((Actor a) => a is Star, orElse: () => null) as Star;

    if (star != null) {
      world.actors.remove(star);

      world.queueAction((duration) {
        star._bitmapRemoveFromWorld();
        return null;
      });
    } else {
      say(messages.cantRemoveStar(), -1);
      stop();
    }
  }

  /// The player checks if he/she is on a star.
  bool onStar() {
    return world.getActorsAt(x, y).any((Actor a) => a is Star);
  }

  /// Creates a speech bubble with the specified [text].
  ///
  /// The [seconds] specifies how long the text should appear on the screen.
  /// If [seconds] is set to -1, the speech bubble will stay on the screen.
  void say(String text, [num seconds = 3]) {
    Point<int> playerPixelCopy = World.cellToPixel(x, y);

    world.queueAction((duration) {
      bool bubbleLeft = false;
      if (playerPixelCopy.x > world.widthInPixels / 2) {
        bubbleLeft = true;
      }

      var textField = _createTextField(text, bubbleLeft);
      var bubble = _createSpeechBubble(textField.width - 4, bubbleLeft);

      SpriteZ speechBubble = SpriteZ()
        ..layer = world.heightInCells // Position on top of everything.
        ..y = playerPixelCopy.y - 120
        ..addChild(bubble)
        ..addChild(textField);

      if (bubbleLeft) {
        speechBubble.x = playerPixelCopy.x - 40 - speechBubble.width;
      } else {
        speechBubble.x = playerPixelCopy.x + 40;
      }

      world.addChildAtZOrder(speechBubble);

      if (seconds > -1) {
        // Remove after the specified time.
        return DelayedCall(() {
          speechBubble.removeFromParent();
        }, seconds);
      }

      return null;
    });
  }

  /// Creates a text field.
  TextField _createTextField(String text, bool bubbleLeft) {
    // Only allow 4 lines of text.
    var lines = text.split(RegExp(r'\r?\n'));
    if (lines.length > 4) {
      lines.removeRange(4, lines.length);
    }
    text = lines.join('\n');

    var marginTop = 0;
    switch (lines.length) {
      case 1:
        marginTop = 29;
        break;
      case 2:
        marginTop = 19;
        break;
      case 3:
        marginTop = 9;
    }

    var textField = TextField()
      ..defaultTextFormat = TextFormat(
          'Helvetica Neue, Helvetica, Arial, sans-serif', 15, Color.Black,
          bold: true)
      ..text = text
      ..x = bubbleLeft ? 13 : 17
      ..y = 10 + marginTop
      ..autoSize = TextFieldAutoSize.LEFT;

    return textField;
  }

  /// Creates a speech bubble for this player.
  Bitmap _createSpeechBubble(num width, bool bubbleLeft) {
    var atlas = world.resourceManager.getTextureAtlas('speech-bubble');

    var bubbleBitmap = BitmapData(34 + width, 106, 0x00);

    bubbleBitmap.drawPixels(
        atlas.getBitmapData('left'), Rectangle(0, 0, 20, 106), Point(0, 0));

    var centerData = atlas.getBitmapData('center');
    for (int i = 0; i < width; i++) {
      bubbleBitmap.drawPixels(
          centerData, Rectangle(0, 0, 1, 106), Point(i + 20, 0));
    }

    bubbleBitmap.drawPixels(atlas.getBitmapData('right'),
        Rectangle(0, 0, 14, 106), Point(20 + width, 0));

    var bubble = Bitmap(bubbleBitmap);

    if (bubbleLeft) {
      // Mirror the bubble to the left side.
      bubble.scaleX = -1;
      bubble.x = bubbleBitmap.width;
    }

    return bubble;
  }

  @override
  BitmapData get image {
    return world.resourceManager
        .getTextureAtlas('character')
        .getBitmapData('${direction}-0');
  }

  @override
  int get zIndex => 4;

  /// Stops the execution.
  void stop() {
    // We throw an exception here because it is the only way to immediately
    // leave an executing method.
    throw StopException();
  }

  /// Returns the next direction when turning clockwise.
  Direction get _nextDirectionClockwise =>
      Direction.values[(direction.index + 1) % Direction.values.length];

  /// Returns the next direction when turning counter clockwise.
  Direction get _nextDirectionCounterclockwise =>
      Direction.values[(direction.index - 1) % Direction.values.length];

  @override
  Animatable _bitmapMoveAnimation(Point<int> startPoint, Point<int> targetPoint,
      Direction direction, double duration) {
    Point<int> targetPixel = World.cellToPixel(targetPoint.x, targetPoint.y);

    List<BitmapData> bitmapDatas = world.resourceManager
        .getTextureAtlas('character')
        .getBitmapDatas('${direction}');

    // Create the walk cycle.
    var walkCycle = [
      bitmapDatas[1],
      bitmapDatas[0],
      bitmapDatas[2],
      bitmapDatas[0]
    ];

    // Calculate the flip book frame rate.
    int frameRate = (walkCycle.length / duration).ceil();

    int layerDuringMove = startPoint.y;
    if (targetPoint.y > startPoint.y) {
      layerDuringMove = targetPoint.y;
    }

    // Create walking flip book.
    var flipBook = FlipBookZ(walkCycle, frameRate, false)
      ..x = _bitmap.x
      ..y = _bitmap.y
      ..layer = layerDuringMove
      ..zIndex = _bitmap.zIndex
      ..pivotX = _bitmap.pivotX
      ..pivotY = _bitmap.pivotY
      ..mouseEnabled = false
      ..play();

    // Create the move tween.
    Tween tween = Tween(flipBook, duration, Transition.linear)
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
        _bitmap.layer = targetPoint.y.toInt();
        _bitmapAddToWorld();
      };

    AnimationGroup animGroup = AnimationGroup();
    animGroup.add(tween);
    animGroup.add(flipBook);

    return animGroup;
  }

  @override
  Animatable _bitmapTurnAnimation(
      Direction startDirection, Direction endDirection, double duration,
      {bool clockwise = true}) {
    List<BitmapData> endImages = world.resourceManager
        .getTextureAtlas('character')
        .getBitmapDatas('${endDirection}');

    // Create the turn cycle.
    List<BitmapData> turnCycle;

    if (clockwise) {
      turnCycle = [endImages[2], endImages[0]];
    } else {
      turnCycle = [endImages[1], endImages[0]];
    }

    // Calculate the flip book frame rate.
    int frameRate = (turnCycle.length / duration).ceil();

    // Create walking flip book.
    var flipBook = FlipBookZ(turnCycle, frameRate, false)
      ..x = _bitmap.x
      ..y = _bitmap.y
      ..layer = _bitmap.layer
      ..zIndex = _bitmap.zIndex
      ..pivotX = _bitmap.pivotX
      ..pivotY = _bitmap.pivotY
      ..mouseEnabled = false
      ..play();

    Tween tween = Tween(flipBook, duration, Transition.linear)
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

    AnimationGroup animGroup = AnimationGroup();
    animGroup.add(flipBook);
    animGroup.add(tween);
    return animGroup;
  }
}
