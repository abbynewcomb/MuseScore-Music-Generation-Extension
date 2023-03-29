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
    
    onRun: {
        var cursor = curScore.newCursor(); //create new cursor
        cursor.rewind(Cursor.SELECTION_END); //put cursor at end of selection
        var startWriteTick = cursor.tick;
      console.log("START WRITING TICK: " + startWriteTick);
        var cursorWrite = curScore.newCursor(); //create new cursor
        /*
        cursorWrite.rewindToTick(cursor.tick); //set tick position to end of selection
        console.log(cursorWrite.tick);

        cursorWrite.staffIdx = 0; //set what staff the cursor is writing on
        cursorWrite.setDuration(1, 4); //set the duration of the note
        cursorWrite.addNote(64, true); //set pitch of note - true means it will add to chord (probably a good thing)
        */

        var filteredTxt = "";
        var inputTxt = "";
        var filePath = "/PATH/TO/FILE";
        readTest.source = filePath;
        console.log("Reading from: " + filePath);
        inputTxt = readTest.read();

        var strArray = inputTxt.split(/\r?\n/);
        //console.log("strArray[1]:" + strArray[1]);
        //console.log(strArray.length);
        
        for (var i = 0; i < strArray.length; i++) {
            var lineArr = strArray[i].split(","); //split the input array
            if(lineArr[2]){ //if type exists
                var type = lineArr[2].trim() //get line type
                var velocity = parseInt(lineArr[5]);

                var isNote = (type == "Note_on_c");
                if (isNote && (velocity != 0)) { //if the type is a note and it is the start of the note
                    var track = parseInt(lineArr[0]); //get trackID
                    var tickVal = parseInt(lineArr[1]); //get tickVal
                    var pitch = parseInt(lineArr[4]);

                    var currentCount = i;
                    var newCount = i + 1;
                    var newPitch = -1;
                    while((pitch != newPitch)) { //look for note_off
                        var newLineArr = strArray[newCount].split(","); //split the input array
                        var newPitch = parseInt(newLineArr[4]);
                        newCount++;
                    }
                    var endTickVal = parseInt(newLineArr[1]);
                    var noteDuration = roundNote(endTickVal - tickVal);
                    var durationFrac = getNoteDuration(noteDuration);

                    var adjustedTick = startWriteTick+tickVal
                    cursorWrite.rewindToTick(adjustedTick);
                    cursorWrite.staffIdx = track - 1;
                    cursorWrite.setDuration(1, 8); //set the duration of the note
                    cursorWrite.addNote(pitch, false); //NEED TO CHANGE TO SUPPORT CHORDS
                    console.log("tick:" + tickVal + ", pitch: " + pitch + ", duration: " + durationFrac[0] + "/" + durationFrac[1] + ", staffIdx: " + track); 
                }
            }
        } 
     
        
        Qt.quit()
    }
        //FIX FUNCTION
        function getNoteDuration(tick) { //this function takes a tick value and converts it to a fraction to be read into by setDuration().
            var numerator = tick;
            var denominator = 32;

            while (numerator % 2 === 0) {
                numerator /= 2;
                denominator /= 2;
            }

            return [numerator, denominator];
        }

        function roundNote(num) { //this function rounds the note to the closest supported tick, as duration values are slightly shortened in midicsv
        //supports up to a 32nd note
            return Math.ceil(num/60) * 60; //change both to 30 to support 64th note
        }

      }
