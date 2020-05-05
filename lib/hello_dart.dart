library hello_dart;

import 'dart:html' as html;
import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:stagexl/stagexl.dart';
import 'package:string_scanner/string_scanner.dart';

part 'src/actors/actor.dart';
part 'src/actors/box.dart';
part 'src/actors/player.dart';
part 'src/actors/star.dart';
part 'src/actors/tree.dart';

part 'src/world/world.dart';
part 'src/world/scenario.dart';
part 'src/world/field.dart';
part 'src/world/exceptions.dart';

part 'src/translations/messages.dart';
part 'src/translations/messages_de.dart';

/// The player image.
///
/// Possible characters:
/// * boy
/// * catgirl
/// * stargirl
/// * pinkgirl
String character = 'boy';

/// The field image.
///
/// Possible fields:
/// * grass
/// * stone
/// * wood
/// * dirt
String field = 'grass';

/// The top color for the background gradient.
String backgroundColorTop = '#b3e3f9';

/// The bottom color for the background gradient.
String backgroundColorBottom = '#ffffff';

/// The translated messages.
///
/// For other languages, set this variable to another [Messages] object.
/// Example for German:
///     messages = MessagesDe();
Messages messages = Messages();

/// Initializes the world with the specified [scenarioFile] and shows it.
///
/// The [player] is the instance where the behaviour is programmed in.
///
/// The [speed] is the duration between the execution of actions (in seconds).
void createWorld(String scenarioFile, Player player, [num speed = 1]) {
  World world = World(player, speed);

  // Initialize the world.
  world.init(scenarioFile).catchError((e) {
    // Show an alert if it is a HelloDartException.
    html.window.alert(e.toString());
  }, test: (e) => e is HelloDartException);
}
