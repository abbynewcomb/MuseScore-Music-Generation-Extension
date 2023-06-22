import QtQuick 2.0
import MuseScore 3.0
import FileIO 3.0

MuseScore {
    menuPath: "Plugins.pluginName"
    description: "Description goes here"
    version: "1.0"

    FileIO {
        id: readTest
        source: filePath
        onError: console.log(msg + "\nFilename = " + readTest.source);
    }
    /*FileIO {
        id: writeTest
        source: exportFilePath
        onError: console.log(msg + "\nFilename = " + writeTest.source);
    }*/
    onRun: {
        var startTick = 100000000000;
        var endTick = 0;
        var tick = 0;
        var isFirstNote = 0; //checking for the first note in the selection
        var noteLengthArr = [];

        var currentSelection = curScore.selection.elements;
        for (var i in currentSelection) {
            var element = currentSelection[i];
            if (!element) { //if not an element wait until next round of the loop
                continue;
            }
            var type = element.name;
            
            if(type == "Note") {
                //might just want to make a loop for finding tick IDK
                
                if(element.noteType.toString() !== "NORMAL") { //maybe better to say if noteType == 8?
                        console.log("IRREGULAR NOTE TYPE: " + element.noteType.toString());
                    tick = element.parent.parent.parent.tick;
                }
                else {
                    tick = element.parent.parent.tick;
                    
                }
                console.log("TYPE IS NOTE, TICK = " + tick);

                if (tick < startTick) {
                    startTick = tick;
                } else if (tick > endTick) {
                    endTick = tick;
                }

                if(isFirstNote == 0){
                        var startTickPos = element.parent.position.ticks; //get position of first note within the bar
                        isFirstNote++;
                    }
                noteLengthArr.push({'tick': tick, 'duration': element.parent.duration.ticks}); //THIS IS GOOD
            }
        }
        noteLengthArr.sort(function(a, b) { //sorts array based on tick value just in case the last element is not in order
            return parseInt(a['tick']) - parseInt(b['tick']);
        });
        for(var k in noteLengthArr) {
            console.log("tick value: " + noteLengthArr[k].tick);
        }
        var lastNote = noteLengthArr[noteLengthArr.length - 1];
        console.log("ORIGINAL END TICK: " + endTick);
        console.log("NEW END TICK: " + (lastNote['duration'] + lastNote['tick']));
        console.log("DURATION: " + lastNote['duration'] );
        endTick = (lastNote['duration'] + lastNote['tick']);

        console.log("Start tick: " + startTick + ", End tick: " + endTick);

        var filteredTxt = "";
        var inputTxt = "";
        var filePath = "/Users/adam/Documents/Capstone MuseScore Plugin/midicsv-1.1 2/Multi_Staff_test.txt";
        readTest.source = filePath;
        console.log("Reading from: " + filePath);
        inputTxt = readTest.read();

        var strArray = inputTxt.split(/\r?\n/);
        console.log("strArray[1]:" + strArray[1]);
        console.log(strArray.length);
        
        var lastLoop = 0;
        for (var i = 0; i < strArray.length; i++) {
            var lineArr = strArray[i].split(",");
            var tickVal = parseInt(lineArr[1]);
            var tempStr = "";
            var prevLine = [];
            if(lineArr[2]) { //if it exists
                var isNote = (lineArr[2].trim() == "Note_on_c");
                if ((tickVal >= startTick && tickVal <= endTick) || (tickVal == 0 && !isNote)) {
                    var tickCorrectedArray = [];
                    //console.log("lineArr[1]:" + lineArr[1])
                    if (isNote) {
                        for (var k = 0; k < lineArr.length; k++) {
                            if((k == 1) && (tickVal > 0)) {
                                console.log("lineArr[1] ORIGINAL: " + lineArr[1] + ", lineArr[1] CORRECTED: " + (lineArr[1] - startTick + startTickPos));
                               tickCorrectedArray.push((lineArr[1] - startTick + startTickPos));
                            } else {
                                tickCorrectedArray.push(lineArr[k]);
                                console.log("lineArr[ " + k + "]:" + lineArr[k]);
                            }
                        }
                        filteredTxt += tickCorrectedArray.join();
                        filteredTxt += '\n';
                        lastLoop = i; //gets the most recent i value
                    } else {
                        filteredTxt += strArray[i];
                        filteredTxt += '\n';
                    }

                    var prevTick = tickVal;
                } 
            
                if ((lineArr[2].trim() == "End_track")) {
                    console.log("****Success!******");
                    console.log("last loop = " + lastLoop);
                    if(lastLoop > 0) {
                        prevLine = strArray[lastLoop+1].split(",");
                        var prevVelocity = parseInt(prevLine[5]);
                        //filteredTxt += (prevLine[1] - startTick + startTickPos);
                        //filteredTxt += "prev velocity: "
                        //filteredTxt += prevVelocity;
                        if(prevVelocity == 0) {
                            //filteredTxt += "does equal 80!";
                            prevLine[1] = prevLine[1] - startTick + startTickPos;
                            filteredTxt += prevLine.join();
                            filteredTxt += '\n';
                        }
                    }

                    //tempStr = lineArr[0] + ", " + (prevTick + 1 - startTick + startTickPos) + ", End_track\n";
                    tempStr = lineArr[0] + ", " + (prevLine[1] + 1) + ", End_track\n";
                    filteredTxt += tempStr;
                }
            }
        }
        console.log(filteredTxt);

        /*var exportFilePath = "/Users/adam/Documents/Capstone MuseScore Plugin/midicsv-1.1 2/test_5.csv"
        writeTest.source = exportFilePath;
        console.log("Writing to: " + exportFilePath);
        writeTest.write(filteredTxt);  
*/
        Qt.quit();
    }
}
