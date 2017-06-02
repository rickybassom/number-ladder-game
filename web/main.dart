import 'dart:html';
import 'dart:math';
import 'dart:async';
import 'package:dragula/dragula.dart';

int numSpaces;
const int defMaxRandomNumber = 5;
const int defMinRandomNumber = -5;

int maxRandomNumber;
int minRandomNumber;
int numberWithMaxDigits;

final int digitHeight = 70;
const int randAnimationWaitTime = 1000;

int numRecords = 0;
List<int> numLadder;

bool droppedNumber = true;
bool animation = false;

final InputElement maxRandomNumberInput = querySelector("#maxnumrange");
final InputElement minRandomNumberInput = querySelector("#minnumrange");

List<String> recordIdsDropped = [];
List<String> spacesFull = [];

Drake drag;

void main() {
  print("Number Ladder Game");
  print("Source Code: https://github.com/rickybas/number-ladder-game");

  setVariables();
  updateButton();
  drawLadder();
  drawNumberGenerator();

  drag = dragula(new List.from(querySelectorAll('.space'))
    ..add(querySelector('#generatednumbers')),
      removeOnSpill: true,
      copy: true,
      accepts: (el, container, handle, sibling) =>
      (!spacesFull.contains(container.dataset["num"])),
      moves: (el, container, handle, sibling) =>
      (handle.className == 'record')
          && (!recordIdsDropped.contains(handle.id))
  )
    ..onOver((Element el, Element container, Element source) {
      if (container.className == "space")
        container.style.backgroundColor = "red";
    })
    ..onOut((Element el, Element container, Element source) {
      if (container.className == "space") container.style.backgroundColor = "";
    })
    ..onDrop(drop);
}

updateButton() {
  querySelector("#update")
    ..onClick.listen((e) {
      if (minRandomNumberInput.value == null ||
          minRandomNumberInput.value == "" ||
          maxRandomNumberInput.value == null ||
          maxRandomNumberInput.value == "") {
        window.location.href = getPathFromUrl(window.location.href)
            + "?maxr=" + defMaxRandomNumber.toString() + "&"
            + "minr=" + defMinRandomNumber.toString();
      }

      window.location.href = getPathFromUrl(window.location.href)
          + "?maxr=" + maxRandomNumberInput.value + "&"
          + "minr=" + minRandomNumberInput.value;
    });
}

setVariables() {
  try {
    maxRandomNumber = int.parse(getQueryVariable("maxr"));
  } catch (e) {
    maxRandomNumber = defMaxRandomNumber;
    minRandomNumber = defMinRandomNumber;
  } finally {
    try {
      minRandomNumber = int.parse(getQueryVariable("minr"));
    } catch (e) {
      maxRandomNumber = defMaxRandomNumber;
      minRandomNumber = defMinRandomNumber;
    }
  }

  if(maxRandomNumber<minRandomNumber){
    maxRandomNumber = defMaxRandomNumber;
    minRandomNumber = defMinRandomNumber;
  }

  numSpaces = (0.5*(maxRandomNumber - minRandomNumber).abs()).floor();

  if (numSpaces <= 2 || numSpaces >= 35) {
    maxRandomNumber = defMaxRandomNumber;
    minRandomNumber = defMinRandomNumber;
    numSpaces = (0.5*(maxRandomNumber - minRandomNumber).abs()).floor();
  }

  numLadder = new List(numSpaces);

  if (numSpaces <= 10)
    querySelector("#ladder").style.fontSize = "25px";
  else if (numSpaces > 10 && numSpaces <= 20)
    querySelector("#ladder").style.fontSize = "20px";
  else if (numSpaces > 20)
    querySelector("#ladder").style.fontSize = "15px";
  else
    querySelector("#ladder").style.fontSize = "10px";

  maxRandomNumberInput.value = maxRandomNumber.toString();
  minRandomNumberInput.value = minRandomNumber.toString();
  numberWithMaxDigits = ((maxRandomNumber.abs() > minRandomNumber.abs())
      ? maxRandomNumber.abs()
      : minRandomNumber.abs());
}

drawNumberGenerator() {
  int numDigits = (log(numberWithMaxDigits) / log(10)).floor() + 1;

  Element digitsEl = querySelector("#digits");
  for (int j = 0; j < numDigits; j++) {
    digitsEl.append(new DivElement()
      ..className = "number"
      ..id = "num" + j.toString());
  }

  int j = 0;
  for (Element el in querySelectorAll(".number")) {
    for (int i = 0; i < 10; i++) {
      el.append(new DivElement()
        ..classes = ["digit", "d" + j.toString()]
        ..id = "dig" + i.toString()
        ..text = i.toString());
    }
    j++;
  }

  Element btn = querySelector("#click");
  btn.onClick.listen(genRandNum);
}

drawLadder() {
  Element ladder = querySelector("#ladder")
    ..style.height = (90 - (2 * (90 / numSpaces))).toString() + "%";
  for (int i = 0; i < numSpaces; i++) {
    ladder.append(new DivElement()
      ..className = "space"
      ..style.height = (100 / numSpaces).toString() + "%"
      ..style.borderTop = "4px solid black"
      ..dataset = {"num": i.toString()}
    );
  }
  querySelectorAll(".legs")
    ..style.height = (45 / numSpaces).toString() + "%";
}

int getRandomInt(min, max) {
  Random rng = new Random();
  return (min + rng.nextInt(max - min));
}

genRandNum(e) {
  if (animation) return;
  if (!droppedNumber) {
    window.alert("Please drop number on ladder");
    return;
  }

  int number;
  bool foundNum = false;
  while (!foundNum) {
    number = getRandomInt(minRandomNumber, maxRandomNumber + 1);
    if (!numLadder.contains(number)) foundNum = true;
  }

  int numDigits = (log(numberWithMaxDigits) / log(10)).floor() + 1;
  String pad = "0" * numDigits;
  String input = pad.substring(0, pad.length - number
      .abs()
      .toString()
      .length) + number.abs().toString();
  for (int i = 0; i < input.length; i++) {
    int digit = int.parse(input[i]);
    for (Element el in querySelectorAll(".d" + i.toString())) {
      el.style.top = (-1 * digit * digitHeight).toString() + "px";
    }
  }

  Element negSign = querySelector("#negsign");
  if (number.isNegative) {
    negSign.style.top = "0px";
  } else {
    negSign.style.top = "70px";
  }

  animation = true;
  const time = const Duration(milliseconds: (randAnimationWaitTime));
  new Timer(time, () => addNewNumber(number));
  droppedNumber = false;
}

drop(Element el, Element space, __, ___) {
  el.className = "";
  el.style.height = (100 / (numSpaces)).toString() + "%";

//  if(space.children.length > 0 && space.children[0].id != el.id){
//    window.alert("Number already in that space");
//    return;
//  }

  for (Element el in querySelector("#generatednumbers").children) {
    el.draggable = false;
    el.style.cursor = "not-allowed";
  }

  if (!checkNumbers(int.parse(el.text), int.parse(space.dataset["num"]))) {
    window.alert("Lost - score: " + calScore().toString());
    window.location.reload();
  }
  numLadder[int.parse(space.dataset["num"])] = int.parse(el.text);

  int numAl = 0;
  for (int num in numLadder) {
    if (num != null) numAl++;
  }
  if (numAl == numSpaces) {
    window.alert("Won! - score: " + numSpaces.toString());
    window.location.reload();
  }

  droppedNumber = true;
  recordIdsDropped.add(el.id);
  spacesFull.add(space.dataset["num"]);
}

addNewNumber(int number) {
  checkAllPositions(number);
  Element generatednumbers = querySelector("#generatednumbers");
  generatednumbers.insertBefore(new DivElement()
    ..id = "record" + numRecords.toString()
    ..className = "record"
    ..text = number.toString()
    ..style.height = "50px",
      generatednumbers.firstChild);
  numRecords += 1;
  animation = false;
}

checkAllPositions(int newNum) {
  for (int i = 0; i < numSpaces; i++) {
    if (numLadder[i] != null) continue;
    if (checkNumbers(newNum, i)) {
      return;
    }
  }
  window.alert("Lost - score: " + calScore().toString());
  window.location.reload();
}


bool checkNumbers(int newNum, int newNumPos) {
  for (int i = newNumPos - 1; i >= 0; i--) {
    if (numLadder[i] != null && newNum < numLadder[i]) {
      return false;
    }
  }
  for (int i = newNumPos + 1; i != numSpaces; i++) {
    if (numLadder[i] != null && newNum > numLadder[i]) {
      return false;
    }
  }
  return true;
}

getQueryVariable(String variable) {
  String query = window.location.search.substring(1);
  List<String> vars = query.split("&");
  for (int i = 0; i < vars.length; i++) {
    List<String> pair = vars[i].split("=");
    if (pair[0] == variable) return pair[1];
  }
  return false;
}

getPathFromUrl(String url) {
  return url.split("?")[0];
}

int calScore() {
  int score = 0;
  for (int num in numLadder) {
    if (num != null) score++;
  }
  return score;
}
