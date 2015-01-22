part of hello_dart;

class Messages {

  String cantMoveBecauseNoField() =>
      "The player can't move because there is no field!";

  String cantMoveBecauseOfTree() =>
      "The player can't move because of a tree!";

  String cantMoveBecauseOfBox() =>
      "The player can't move because the box can't be pushed!";

  String cantPutStar() =>
      "The player can't put a star on top of another star!";

  String cantRemoveStar() =>
      "There is no star that the player could remove here!";

  String playerExceptionDefault() =>
      "The player has some problem!";

  String actionOverflowException() =>
      "Your program takes too long to execute or doesn't end at all!";

  String fileNotFoundException() =>
      "Could not load a file: Please check your scenario and image files.";

  String scenarioInvalid() => "The scenario is invalid.";
}