import QtQuick 2.0
import MuseScore 3.0
import FileIO 3.0

MuseScore {
    menuPath: "Plugins.pluginName"
    description: "Takes input from midicsv and outputs it to the score."
    version: "1.1"

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

        var cursorWrite = curScore.newCursor();

        /*****GET TEXT FROM FILE*****/
        var filteredTxt = "";
        var inputTxt = "";
        var filePath = "/Users/adam/Documents/Capstone MuseScore Plugin/midicsv/MOT1.txt";
        readTest.source = filePath;
        console.log("Reading from: " + filePath);
        inputTxt = readTest.read();

        var strArray = inputTxt.split(/\r?\n/); //splits file into lines

        var prevTickVal = -1; //sets up chord detector

        /*****MAIN LOOP*****/
        for (var i = 0; i < strArray.length; i++) {
            var lineArr = strArray[i].split(","); //split the input array
            if(lineArr[2]){
                var type = lineArr[2].trim() //get line type
                var velocity = parseInt(lineArr[5]);

                var isNote = (type == "Note_on_c");
                /*****ONLY IF START OF NOTE*****/
                if (isNote && (velocity != 0)) {
                    var track = parseInt(lineArr[0]); //get trackID
                    var tickVal = parseInt(lineArr[1]); //get tickVal
                    var pitch = parseInt(lineArr[4]);

                    var currentCount = i;
                    var newCount = i + 1;
                    var newPitch = -1;
                    /*****FIND NOTE DURATION*****/
                    while((pitch != newPitch)) { //look for note_off
                        var newLineArr = strArray[newCount].split(","); //split the input array
                        var newPitch = parseInt(newLineArr[4]);
                        newCount++;
                    }
                    var endTickVal = parseInt(newLineArr[1]);
                    var noteDuration = roundNote(endTickVal - tickVal); //get rounded note duration
                    var durationFrac = getNoteDuration(noteDuration);

                    /*****ADJUSTING WRITE CURSOR ATTRIBUTES AND POSITIONING*****/
                    var adjustedTick = startWriteTick+tickVal;
                    cursorWrite.rewindToTick(adjustedTick);
                    cursorWrite.staffIdx = track - 1;
                    cursorWrite.setDuration(durationFrac[0], durationFrac[1]); //set the duration of the note

                    /*****CHECKING FOR CHORD*****/
                    if(tickVal != prevTickVal) {
                        cursorWrite.addNote(pitch, false); //adds as individual note
                    }
                    else {
                        cursorWrite.addNote(pitch, true); //adds to chord
                        
                    }
                    prevTickVal = tickVal; //update chord checker value
                    console.log("staffIdx: " + track + ", tick:" + tickVal + ", pitch: " + pitch + ", duration: " + durationFrac[0] + "/" + durationFrac[1]); 
                }
            }
        } 
     
        
        Qt.quit()
    }
        /*****given tick, returns numerical fraction of a beat*****/
        //(given 480, returns 1/4 aka quarter note) 
        function getNoteDuration(tick) { 
            var numerator = tick/60; //get total # of 32nd notes 
            var denominator = 32; //change to 64 in conjunction with roundNote to support 64th notes

            while (numerator % 2 === 0) {
                numerator /= 2;
                denominator /= 2;
            }

            return [numerator, denominator];
        }

        function roundNote(num) { //supports up to a 32nd note
            return Math.ceil(num/60) * 60; //change both to 30 to support 64th note
        }

      }
