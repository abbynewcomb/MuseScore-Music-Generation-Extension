import QtQuick 2.0
import MuseScore 3.0
import FileIO 3.0

MuseScore {
    menuPath: "Plugins.pluginName"
    description: "Description goes here"
    version: "1.0"

    FileIO {
        id: writeTest
        source: filePath
        onError: console.log(msg + "\nFilename = " + writeTest.source);
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
        
        //PRINT PRE-TRACK DATA
        outputText = outputText + "0, 0, Header, 1, " + totalTracks + ", 480\n";
        outputText = outputText + "1, 0, Start_track\n"
        outputText = outputText + "1, 0, Title_t, \"Piano\\000\"\n";
        outputText = outputText + "1, 0, Time_signature, 4, 2, 24, 8\n"
        outputText = outputText + "1, 0, Key_signature, 0, \"major\"\n";
        outputText = outputText + "1, 0, Tempo, 500000\n";
        outputText = outputText + "1, 0, Control_c, 0, 121, 0\n1, 0, Program_c, 0, 0\n1, 0, Control_c, 0, 7, 100\n1, 0, Control_c, 0, 10, 64\n1, 0, Control_c, 0, 91, 0\n1, 0, Control_c, 0, 93, 0\n1, 0, MIDI_port, 0\n";
        
        var noteStringArray = [];
        for(var i = 0; i < noteArray.length; i++) {
            newTrackValue = noteArray[i].trackID;
            if(newTrackValue != oldTrackValue) { //checks if there is a new track
                for(var j = oldTrackValue; j < newTrackValue; j++){
                    //sorts array by tick and velocity
                    noteStringArray.sort(function (a, b) {
                        return a.tick - b.tick || a.velocity - b.velocity;
                    });

                    console.log("NOTE STRING LENGTH: " + noteStringArray.length);
                    //adds the note_on_c strings to array
                    for(var k = 0; k < noteStringArray.length; k++) {
                        outputText = outputText + noteStringArray[k].outputString;
                    }
                    noteStringArray = [];
                    
                    outputText = outputText + j + ", " + (previousTick + 1) + ", End_track\n";
                    outputText = outputText + (j+1) + ", 0, Start_track\n"
                }
            }
            previousTick = (noteArray[i].tick + noteArray[i].duration)
            
            //Pushes Track Info to Array
            noteStringArray.push({'tick': noteArray[i].tick, 'velocity': 80, 'outputString': (noteArray[i].trackID + ", " + noteArray[i].tick + ", " + "Note_on_c, 0, " + noteArray[i].pitch + ", 80\n")});
            noteStringArray.push({'tick': previousTick, 'velocity': 0, 'outputString': (noteArray[i].trackID + ", " + previousTick + ", " + "Note_on_c, 0, " + noteArray[i].pitch + ", 0\n")});

            oldTrackValue = noteArray[i].trackID;
        }
        noteStringArray.sort(function (a, b) {
            return a.tick - b.tick || a.velocity - b.velocity;
        });

        console.log("NOTE STRING LENGTH: " + noteStringArray.length);
        for(var k = 0; k < noteStringArray.length; k++) {
            outputText = outputText + noteStringArray[k].outputString;
        }
        
        outputText = outputText + oldTrackValue + ", " + (previousTick+1) + ", End_track\n";  
        outputText += "0, 0, End_of_file\n";

        console.log(outputText);

        var filePath = "/Users/adam/Documents/Capstone MuseScore Plugin/midicsv/Export_test_5.txt"
        writeTest.source = filePath;
        console.log("Writing to: " + filePath);
        writeTest.write(outputText);  
       

        Qt.quit();
    }
}
