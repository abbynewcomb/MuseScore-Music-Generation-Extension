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

        cursor.rewind(Cursor.SELECTION_START); //put cursor at beginning of selection
        var startStaff  = cursor.staffIdx;
        var startTick = cursor.tick;
        console.log("START CURSOR STAFF: " + startStaff);
        console.log("START CURSOR TICKS: " + startTick);

        if(cursor.nextMeasure()){ //figure out how to get adjusted tick
        /****** TODO: GET ADJUSTED TICK VALUE******/
        }


        cursor.rewind(Cursor.SELECTION_END); //put cursor at end of selection
        var endStaff  = cursor.staffIdx;
        var endTick = cursor.tick;
        console.log("END CURSOR STAFF: " + endStaff);
        console.log("END CURSOR TICKS: " + endTick);

        var totalTracks = endStaff - startStaff + 1; //get total number of tracks
        console.log("TOTAL TRACKS: " + totalTracks);

        var noteArray = [];
        for(var i = 0; i < totalTracks; i++) { //iterate through all tracks
            cursor.rewind(Cursor.SELECTION_START); //put cursor back at beginning of selection
            var currentTrack = (startStaff*4);
            startStaff++;
  
            while(cursor.tick < endTick) { 
                console.log("CURRENT TRACK: " + currentTrack);
                var currentElement = cursor.segment.elementAt(currentTrack); //4 channels per track starting at 0, 3, 7, 11,...
                if(currentElement) {
                //console.log("ELEMENT EXISTS!");
                    if(currentElement.name == "Chord") { //if not a rest or a ChordRest
                        var noteDuration = currentElement.duration.ticks;
                        var notesInChord = currentElement.notes;
                        
                        for(var j = 0; j < notesInChord.length; j++) { //for each note in the chord, get the trackID, tick, duration, and pitch
                            noteArray.push({'trackID': i + 1, 'tick': cursor.tick, 'duration': noteDuration, 'pitch': notesInChord[j].pitch});
                        }
                    }
                }
                cursor.next();
            }
        }

        for(var k = 0; k < noteArray.length; k++) { //prints note array
            console.log("trackID: " + noteArray[k].trackID + ", tick: " + noteArray[k].tick + ", duration: " + noteArray[k].duration + ", pitch: " + noteArray[k].pitch)
        }
        
        Qt.quit();
    }
}
