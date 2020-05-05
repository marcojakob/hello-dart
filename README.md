# Hello Dart

Hello Dart is a visual and playful introduction to programming with Dart. It's
your visual **hello world** for Dart.

[![Star this Repo](https://img.shields.io/github/stars/marcojakob/hello-dart.svg?style=flat-square)](https://github.com/marcojakob/hello-dart)
[![Pub Package](https://img.shields.io/pub/v/hello_dart.svg?style=flat-square)](https://pub.dartlang.org/packages/hello_dart)

[GitHub](https://github.com/marcojakob/hello-dart) | 
[Pub](https://pub.dartlang.org/packages/hello_dart) | 
[Course Materials](http://code.makery.ch/library/hello-dart/)

![Hello Dart Screenshot](https://raw.githubusercontent.com/marcojakob/hello-dart/master/doc/hello-dart-animation.gif)


## Course Materials

Hello Dart contains free materials for a complete introductory course in 
programming. It includes theory, instructions, exercises, and solutions.

* [Hello Dart Course (in English)](http://code.makery.ch/library/hello-dart/)
* [Hello Dart Course (in German)](http://code.makery.ch/library/hello-dart/de/)


## How it Works

Hello Dart makes it easy to get startet with programming. It keeps the 
motivation high by providing an attractive visual feedback to the programmer.


### Player and MyPlayer

The class `Player` provides all functionality for controlling the character. The
player provides various action methods (like `move()` and `putStar()`) and some 
sensory methods (like `canMove()` and `treeLeft()`). 

The programming is done in the `MyPlayer` class which, through inheritance, can
access all the methods of `Player`. Thus, the complexity of the player's 
methods are hidden from the programming novice at first.

`MyPlayer` has one method that must be implemented called `start()`. The 
`start()`-method is where the user writes his program. It is called 
automatically when the program is started.

`MyPlayer` should also have a `main()`-function that calls `createWorld()` to
initialize the program.

Here is an example of a typical `MyPlayer` class:

```dart
import 'package:hello_dart/hello_dart.dart';

/// Your player.
class MyPlayer extends Player {

  /// Your program.
  start() {
    move();
    turnRight();
    move();
  }
}


main() {
  createWorld('scenario.txt', MyPlayer());
}
```


### World

The class `World` is the central class that creates the visual environment and 
manages all actors.

Once the world is created and initialized with a call to `createWorld()`, the
user's program in the `start()` method is executed. If we would just run the 
actions at full speed, the user would not see much of his program's execution. 
Therefore, we slow down the execution of each action step with the action queue.


#### Action Queue

Dart and JavaScript are single-threaded programming languages. This means we 
cannot put a method to *sleep* in the middle of its execution as this would 
freeze the entire application including all animations.

When the `World` executes the `start()` method all actions (like `move()`,
`turnLeft()`, etc.) are collected in an action queue. When all actions are 
queued they are played back in any desired speed. 

This mechanism enables us to put a delay between each action which would 
otherwise not be possible.

We've set a limit to how many action methods may be called during the execution
of the `start()`-method. The limit is 10'000 calls (see `World.maxActionCalls`)
which should be more than enough for such simple programs. This also means that
we will detect and report possibly never-ending cycles to the user at the end 
of the execution.


### Scenarios

Each *Hello Dart* scenario comes with a `.txt` file that provides information 
about the positions of the actors in the world (see `example` folder).

A Scenario contains a scenario title and information about the positions of the 
actors in the world.

The actors are described with the following signs:

* Player: @
* Tree: %
* Star: .
* Box: $
* Box on star: *
* Player on star: +


The background:

* Empty: a space
* Border or holes: #

*Note: The border must form a polygon with the actors inside.*

Here is how a `scenario.txt` file looks like:

```
---
1.03 - Around Tree
---
###########
#         #
#@ % %  %.#
###########
```

You may create your own scenarios, of course.


## Options

There are some options for changing the appearance and behavior of *Hello Dart*.
Most options can be found in the `hello_dart.dart` file.

* `character`: Defines the player image. Possible values are *boy*, *catgirl*,
  *stargirl*, *pinkgirl*.
* `field`: The background field image. Possible values are *grass*, *stone*, 
  *wood*, *dirt*.
* `backgroundColorTop`: The top color of the background gradient. To take 
  screenshots I usually set this color to white (*#fff*).
* `backgroundColorBottom`: The bottom color of the background gradient.
* `messages`: The error messages are in English but you may provide 
  translations of those messages. An example can be found in the `MessagesDe`
  class.
* *Speed*: The `createWorld()`-function provides an optional third argumtent
  to set the initial speed (in seconds). You may define the speed in a floating 
  point number.

Here is an example of how to apply various options in the `main()`-function:

```
main() {
  // Change appearance.
  character = 'catgirl';
  field = 'stone';
  backgroundColorTop = '#fff';

  // Set to German error messages.
  messages = MessagesDe();

  // Create the world with an initial speed of 0.3 seconds.
  createWorld('scenario.txt', MyPlayer(), 0.3);
}
```


## Attribution

* [Planet Cute](http://www.lostgarden.com/2007/05/dancs-miraculously-flexible-game.html) 
art by Daniel Cook (Lostgarden.com)
* [Oleg Yadrov](https://www.linkedin.com/in/olegyadrov) has extended the 
"Planet Cute" theme with additional sprite perspectives. He was so kind to provide
his graphics.
* The sprites have been combined and optimized with 
[TexturePacker](http://www.codeandweb.com/texturepacker).

Many thanks to Daniel and Oleg!


## License

The MIT License (MIT)