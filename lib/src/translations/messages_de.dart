part of hello_dart;

class MessagesDe extends Messages {
  @override
  String cantMoveBecauseNoField() =>
      "Ich kann mich nicht bewegen, da es kein Feld mehr hat!";

  @override
  String cantMoveBecauseOfTree() =>
      "Ich kann mich nicht bewegen wegen einem Baum!";

  @override
  String cantMoveBecauseOfBox() =>
      "Ich kann mich nicht bewegen, da ich die Box nicht schieben kann!";

  @override
  String cantPutStar() =>
      "Ich kann keinen Stern auf ein Feld legen, auf dem schon einer ist!";

  @override
  String cantRemoveStar() => "Ich kann hier keinen Stern auflesen!";

  @override
  String playerExceptionDefault() =>
      "Ich habe irgend ein Problem, weiss aber nicht genau was. Sorry!";

  @override
  String actionOverflowException() =>
      "Ihr Programm dauert zu lange oder beendet gar nicht!";

  @override
  String fileNotFoundException() =>
      "Eine Datei konnte nicht geladen werden. Bitte überprüfe die Bilder oder die Szenario-Datei.";

  @override
  String scenarioInvalid() => "Das Szenario ist ungültig.";
}
