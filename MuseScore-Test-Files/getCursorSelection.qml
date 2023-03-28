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

        var positionInMeasure = cursor.segment.elementAt(startStaff*4).position.ticks;
        console.log("START POSITION: " + positionInMeasure);


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
                            noteArray.push({'trackID': i + 1, 'tick': (cursor.tick - startTick + positionInMeasure), 'duration': noteDuration, 'pitch': notesInChord[j].pitch});
                        }
                    }
                }
                cursor.next();
            }
        }

        for(var k = 0; k < noteArray.length; k++) {
            console.log("trackID: " + noteArray[k].trackID + ", tick: " + noteArray[k].tick + ", duration: " + noteArray[k].duration + ", pitch: " + noteArray[k].pitch)
        }

        var outputText = ""; //text for output
        var oldTrackValue = noteArray[0].trackID;
        var newTrackValue;
        var previousTick;
        
        outputText = outputText + "\n0, 0, Header, 1, " + totalTracks + ", 480\n"; //print file header info
        outputText = outputText + "1, 0, Start_track\n" //print start track for first track
        for(var i = 0; i < noteArray.length; i++) {
            newTrackValue = noteArray[i].trackID;
            if(newTrackValue != oldTrackValue) { //checks if there is a new track
                for(var j = oldTrackValue; j < newTrackValue; j++){ //cycle through empty tracks to maintain track info
                    outputText = outputText + j + ", " + (previousTick + 1) + ", End track\n";
                    outputText = outputText + (j+1) + ", 0, Start_track\n"
                }
            }
            previousTick = (noteArray[i].tick + noteArray[i].duration)
            outputText = outputText + noteArray[i].trackID + ", " + noteArray[i].tick + ", " + "Note_on_c, 0, " + noteArray[i].pitch + ", 80\n";
            outputText = outputText + noteArray[i].trackID + ", " + previousTick + ", " + "Note_on_c, 0, " + noteArray[i].pitch + ", 0\n";

            oldTrackValue = noteArray[i].trackID;
        }
        outputText = outputText + oldTrackValue + ", " + (previousTick+1) + ", End track\n";  

        console.log(outputText);
        cursor.rewind(Cursor.SELECTION_START); //put cursor at beginning of selection
/*
        var ele = cursor.segment.elementAt(4).notes[0];
        //console.log("SELECTION SIZE: " + ele.length); 
        var getKeys = function(obj){
        var keys = [];
        var i = 0;
        for(var key in obj){
            keys.push(key);
            console.log(i + ": " + key + ": " + obj[key]);
            i++;
            
        }
        return keys;
        }
        //getKeys(ele);
        */
        

        Qt.quit();
    }
}
