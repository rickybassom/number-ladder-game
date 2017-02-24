import 'dart:html';
import 'dart:math';
import 'dart:async';

int numSpaces;
int numRange;
final int digitHeight = 70;
final int spaceHeightPx = 80;
int ladderHeightPx;
const int randAnimationWaitTime = 1000*1;
final defNumSpaces = 6;
final defRanNum = defNumSpaces+3;


int numRecords=0;
List<int> numLadder = new List(numSpaces);

bool droppedNumber = true;
bool animation = false;

void main() {
  print("Number Ladder Game");
  print("Source Code: https://github.com/rickybas/number-ladder-game");
  setVariables();
  updateButton();
  drawLadder();
  drawNumberGenerator();
}

updateButton(){
  querySelector("#update")
    ..onClick.listen((e){
      InputElement numspacesInput = querySelector("#numspaces");
      InputElement numrangeInput = querySelector("#numrange");

      if(numspacesInput.value == null || numspacesInput.value == "" ||
          numrangeInput.value == null || numrangeInput.value == ""){
        window.location.href = getPathFromUrl(window.location.href)
            + "?s=" + "20" + "&"
            + "r=" + "30";
      }

      window.location.href = getPathFromUrl(window.location.href)
          + "?s=" + numspacesInput.value + "&"
          + "r=" + numrangeInput.value;
    });
}

setVariables(){
  InputElement numspacesInput = querySelector("#numspaces");
  InputElement numrangeInput = querySelector("#numrange");

  int min = 2;
  int max = 30;

  int spaces;
  try {
    spaces = int.parse(getQueryVariable("s"));
  } catch(e){
    spaces = defNumSpaces;
  }

  int range;
  try {
    range = int.parse(getQueryVariable("r"));
  } catch(e){
    range = defRanNum;
  }

  if(spaces>max || spaces<min) spaces=defNumSpaces;
  if(spaces>=range) range=spaces+3;
  if(range<min) range = defRanNum;

  numSpaces = spaces;
  numspacesInput.value = numSpaces.toString();

  numRange = range;
  numrangeInput.value = numRange.toString();

  ladderHeightPx = numSpaces * spaceHeightPx;
}

drawNumberGenerator(){
  int numDigits = (log(numRange)/log(10)).floor()+1;

  var digitsEl = querySelector("#digits");
  for(int j=0; j<numDigits; j++){
    digitsEl.append(new DivElement()
      ..className = "number"
      ..id = "num"+j.toString());
  }


  int j=0;
  for (var el in querySelectorAll(".number")) {
    for(var i = 0; i < 10; i++){
      el.append(new DivElement()
        ..classes=["digit", "d"+j.toString()]
        ..id="dig"+i.toString()
        ..text=i.toString());
    }
    j++;
  }
  var numspaces = querySelector("#numspaces");
  var numrange = querySelector("#numrange");



  var btn = querySelector("#click");
  btn.onClick.listen(genRandNum);
}

drawLadder(){
  var ladder = querySelector("#ladder")
    ..style.height = ladderHeightPx.toString() +"px";
  for(int i=0; i<numSpaces; i++){
    ladder.append(new DivElement()
      ..className="space"
      ..style.height = spaceHeightPx.toString() + "px"
      ..style.borderTop = "4px solid black"
      ..dataset={"num": i.toString()}
      ..onDragOver.listen(allowDrop)
      ..onDragLeave.listen(leave)
      ..onDrop.listen(drop)
    );
  }
  querySelectorAll(".legs")
    ..style.height = (ladderHeightPx/numSpaces).toString() + "px";
}

allowDrop(e){
  e.target.id = "hoveredbox";
  e.preventDefault();
}

leave(e){
  e.target.id = "emptybox";
}

drag(ev) {
  ev.dataTransfer.setData("text", ev.target.id);
}

drop(ev) {
  ev.preventDefault();
  ev.target.id = null;
  var data = ev.dataTransfer.getData("text");
  var nodeCopy = document.getElementById(data).clone(true);
  nodeCopy.className="";
  nodeCopy.draggable=false;
  nodeCopy.style.fontSize=(ladderHeightPx*0.6/numSpaces).toString() + "px";
  nodeCopy.style.height=spaceHeightPx.toString() + "px";

  if(ev.target.innerHtml != "" && ev.target.innerHtml != null){
    window.alert("Number already in that space");
    return;
  }
  ev.target.append(nodeCopy);
  document.getElementById(data).draggable=false;

  for(var el in querySelector("#generatednumbers").children){
    el.draggable=false;
    el.style.cursor = "not-allowed";
  }

  if(!checkNumbers(int.parse(document.getElementById(data).text), int.parse(ev.target.dataset["num"]))){
    window.alert("Lost - score: " + calScore().toString());
    window.location.reload();
  }
  numLadder[int.parse(ev.target.dataset["num"])] = int.parse(document.getElementById(data).text);

  int numAl = 0;
  for(var num in numLadder){
    if(num != null) numAl++;
  }
  if(numAl==numSpaces){
    window.alert("Won! - score: " + numSpaces.toString());
    window.location.reload();
  }

  droppedNumber=true;
}

int getRandomInt(min, max) {
  Random rng = new Random();
  return (min + rng.nextInt(max - min));
}

genRandNum(e){
  if(animation) return;
  if(!droppedNumber){
    window.alert("Please drop number on ladder");
    return;
  }

  int number;
  bool foundNum = false;
  while(!foundNum){
    number = getRandomInt(0, numRange)+1;
    if(!numLadder.contains(number)) foundNum=true;
  }

  int numDigits = (log(numRange)/log(10)).floor()+1;
  var pad = "0"*numDigits;
  var input = pad.substring(0, pad.length - number.toString().length) + number.toString();
  for(int i = 0; i < input.length; i++){
    var digit = int.parse(input[i]);
    for (var el in querySelectorAll(".d" + i.toString())){
      el.style.top = (-1*digit*digitHeight).toString() + "px";
    }

  }

  animation = true;
  const time = const Duration(milliseconds:(randAnimationWaitTime));
  new Timer(time, () => addNewNumber(number));
  droppedNumber=false;

}

addNewNumber(int number){
  checkAllPositions(number);
  var generatednumbers = querySelector("#generatednumbers");
  generatednumbers.insertBefore(new DivElement()
    ..id="record"+numRecords.toString()
    ..className="record"
    ..text=number.toString()
    ..draggable=true
    ..style.height="50px"
    ..onDragStart.listen(drag),
      generatednumbers.firstChild);
  numRecords+=1;
  animation = false;
}

checkAllPositions(int newNum){
  for(int i=0; i<numSpaces; i++){
    if(numLadder[i] != null) continue;
    if(checkNumbers(newNum, i)){
      return;
    }
  }
  window.alert("Lost - score: " + calScore().toString());
  window.location.reload();
}


bool checkNumbers(int newNum, int newNumPos){
  for(int i=newNumPos-1; i>=0; i--){
    if(numLadder[i] != null && newNum > numLadder[i]){
      return false;
    }
  }
  for(int i=newNumPos+1; i!=numSpaces; i++){
    if(numLadder[i] != null && newNum < numLadder[i]){
      return false;
    }
  }
  return true;
}

getQueryVariable(String variable) {
  var query = window.location.search.substring(1);
  var vars = query.split("&");
  for (int i=0;i<vars.length;i++) {
    var pair = vars[i].split("=");
    if(pair[0] == variable){return pair[1];}
  }
  return(false);
}

getPathFromUrl(String url) {
  return url.split("?")[0];
}

int calScore(){
  int score = 0;
  for(int num in numLadder){
    if(num != null) score++;
  }
  return score;
}
