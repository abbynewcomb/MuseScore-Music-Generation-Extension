import QtQuick 2.0
import QtQuick.Controls 2.0
import QtQuick.Controls.Styles 1.3
import QtQuick.Layouts 1.1
import QtQuick.Window 2.2
import Qt.labs.settings 1.0
import QtQuick.Dialogs 1.1
import FileIO 3.0
import MuseScore 3.0

MuseScore {
    menuPath: "Plugins.AI Music Generator 2"
    version: "1.0"
    description: "A simple plugin that displays a window with buttons"
    pluginType: "dialog"
    FileIO {
        id: readTest
        source: filePath
        onError: console.log(msg + "\nFilename = " + readTest.source);
    }
    FileIO {
        id: writeTest
        //source: filePath2
        onError: console.log(msg + "\nFilename = " + writeTest.source);
    }
    property int temperature: 25 // default temperature value
    onRun: {
    }

/******************************************/
/******CREATING THE INTERACTIVE WINDOW*****/
/******************************************/

    Window {
        id: main
        visible: true
        width: 400
        height: 250
        property real scaleFactor: 1.0
        onScaleFactorChanged: {
            main.width = 400 * scaleFactor;
            main.height = 250 * scaleFactor;
        }

        Rectangle {
            anchors.fill: parent
            color: "lightgrey"

            Text {
                id: titleText
                text: "AI Music Generator"
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: 16 * main.scaleFactor
                font.bold: true
                y: 20 * main.scaleFactor
            }
            Button {
                id: button1
                width: 100 * main.scaleFactor
                height: 40 * main.scaleFactor
                font.pixelSize: 16 * main.scaleFactor
                x: 50 * main.scaleFactor
                y: measureCounter.y + measureCounter.height + 70 * main.scaleFactor
                text: "Generate"
                onClicked: {

    /******************************************/
    /*********START READING FROM SCORE*********/
    /******************************************/
                  
                    var cursor = curScore.newCursor(); //create new cursor
                    cursor.rewind(Cursor.SELECTION_START); //put cursor at beginning of selection
                    var startStaff = cursor.staffIdx;
                    var startTick = cursor.tick;
                    console.log("START CURSOR STAFF: " + startStaff);
                    console.log("START CURSOR TICKS: " + startTick);
                    var positionInMeasure = cursor.segment.elementAt(startStaff * 4).position.ticks;
                    console.log("START POSITION: " + positionInMeasure);
                    cursor.rewind(Cursor.SELECTION_END); //put cursor at end of selection
                    var endStaff = cursor.staffIdx;
                    var endTick = cursor.tick;
                    console.log("END CURSOR STAFF: " + endStaff);
                    console.log("END CURSOR TICKS: " + endTick);
                    var totalTracks = endStaff - startStaff + 1; //get total number of tracks
                    console.log("TOTAL TRACKS: " + totalTracks);
                    var noteArray = [];
                    var trackNum = startStaff;
                    for (var i = 0; i < totalTracks; i++) { //iterate through all tracks
                        cursor.rewind(Cursor.SELECTION_START); //put cursor back at beginning of selection
                        cursor.staffIdx = i + startStaff;
                        //cursor.rewindToTick(9600);
                        console.log("START CURSOR!!!!!! " + cursor.tick);
                        var currentTrack = (trackNum * 4);
                        trackNum++;
                        while (cursor.tick < endTick) {
                            console.log("CURRENT TRACK: " + currentTrack);
                            var currentElement = cursor.segment.elementAt(currentTrack); //4 channels per track starting at 0, 3, 7, 11,...
                            if (currentElement) {
                                if (currentElement.name == "Chord") { //if not a rest or a ChordRest
                                    var noteDuration = currentElement.duration.ticks;
                                    var notesInChord = currentElement.notes;
                                    for (var j = 0; j < notesInChord.length; j++) { //for each note in the chord, get the trackID, tick, duration, and pitch
                                        noteArray.push({
                                            'trackID': i + 1,
                                            'tick': (cursor.tick - startTick + positionInMeasure),
                                            'duration': noteDuration,
                                            'pitch': notesInChord[j].pitch
                                        });
                                    }
                                }
                            }
                            cursor.next();
                        }
                    }
                    for (var k = 0; k < noteArray.length; k++) {
                        console.log("trackID: " + noteArray[k].trackID + ", tick: " + noteArray[k].tick + ", duration: " + noteArray[k].duration + ", pitch: " + noteArray[k].pitch)
                    }
                    var outputText = ""; //text for output
                    var oldTrackValue = noteArray[0].trackID;
                    var newTrackValue;
                    var previousTick;
                    outputText = outputText + "#" + measureCounter.value + " " + Math.round(cursor.tempo*60) +" " + temperatureSlider.value + "\n"; //add number of measures to generate as a comment to be extracted later
                    outputText = outputText + "0, 0, Header, 1, " + totalTracks + ", 480\n";
                    outputText = outputText + "1, 0, Start_track\n"
                    outputText = outputText + "1, 0, Title_t, \"Piano\\000\"\n";
                    outputText = outputText + "1, 0, Time_signature, 4, 2, 24, 8\n"
                    outputText = outputText + "1, 0, Key_signature, 0, \"major\"\n";
                    outputText = outputText + "1, 0, Tempo, 500000\n";
                    outputText = outputText + "1, 0, Control_c, 0, 121, 0\n1, 0, Program_c, 0, 0\n1, 0, Control_c, 0, 7, 100\n1, 0, Control_c, 0, 10, 64\n1, 0, Control_c, 0, 91, 0\n1, 0, Control_c, 0, 93, 0\n1, 0, MIDI_port, 0\n";
                    var noteStringArray = [];
                    for (var i = 0; i < noteArray.length; i++) {
                        newTrackValue = noteArray[i].trackID;
                        if (newTrackValue != oldTrackValue) { //checks if there is a new track
                            for (var j = oldTrackValue; j < newTrackValue; j++) {
                                noteStringArray.sort(function(a, b) {
                                    return a.tick - b.tick || a.velocity - b.velocity;
                                });
                                console.log("NOTE STRING LENGTH: " + noteStringArray.length);
                                for (var k = 0; k < noteStringArray.length; k++) {
                                    outputText = outputText + noteStringArray[k].outputString;
                                }
                                noteStringArray = [];
                                outputText = outputText + j + ", " + (previousTick + 1) + ", End_track\n";
                                outputText = outputText + (j + 1) + ", 0, Start_track\n"
                            }
                        }
                        previousTick = (noteArray[i].tick + noteArray[i].duration)
                        noteStringArray.push({
                            'tick': noteArray[i].tick,
                            'velocity': 80,
                            'outputString': (noteArray[i].trackID + ", " + noteArray[i].tick + ", " + "Note_on_c, 0, " + noteArray[i].pitch + ", 80\n")
                        });
                        noteStringArray.push({
                            'tick': previousTick,
                            'velocity': 0,
                            'outputString': (noteArray[i].trackID + ", " + previousTick + ", " + "Note_on_c, 0, " + noteArray[i].pitch + ", 0\n")
                        });
                        oldTrackValue = noteArray[i].trackID;
                    }
                    noteStringArray.sort(function(a, b) {
                        return a.tick - b.tick || a.velocity - b.velocity;
                    });
                    console.log("NOTE STRING LENGTH: " + noteStringArray.length);
                    for (var k = 0; k < noteStringArray.length; k++) {
                        outputText = outputText + noteStringArray[k].outputString;
                    }
                    outputText = outputText + oldTrackValue + ", " + (previousTick + 1) + ", End_track\n";
                    outputText += "0, 0, End_of_file\n";
                    console.log(outputText);
                    var filePath = "/Users/adam/Documents/Capstone MuseScore Plugin/midicsv/Export_test_5.txt"
                    writeTest.source = filePath;
                    console.log("Writing to: " + filePath);
                    writeTest.write(outputText);

    /******************************************/
    /**********START WRITING TO SCORE**********/
    /******************************************/
                    curScore.startCmd();  // allows the score to be edited
                    cursor.rewind(Cursor.SELECTION_END); //put cursor at end of selection
                    var startWriteTick = cursor.tick;
                    console.log("START WRITING TICK: " + startWriteTick);
                    var cursorWrite = curScore.newCursor();
                    /*****GET TEXT FROM FILE*****/
                    var filteredTxt = "";
                    var inputTxt = "";
                    /*CHANGE FILE NAME HERE FOR DEMO*/
                   // var filePath2 = "/Users/adam/Documents/Capstone MuseScore Plugin/midicsv/Export_test_5.txt"
                    var filePath2 = "/Users/adam/Downloads/twinkle_generatedV2.csv"
                    //var filePath2 = "/Users/adam/Documents/Capstone MuseScore Plugin/midicsv/TME2.txt";
                    readTest.source = filePath2;
                    console.log("Reading from: " + filePath2);
                    inputTxt = readTest.read();
                    var strArray = inputTxt.split(/\r?\n/); //splits file into lines
                    var prevTickVal = -1; //sets up chord detector
                    var prevEndTickVal = 0; 
                    var prevEndTickVal = {};
                    /*****MAIN LOOP*****/
                    for (var i = 0; i < strArray.length; i++) {
                        var lineArr = strArray[i].split(","); //split the input array
                        if (lineArr[2]) {
                            var type = lineArr[2].trim() //get line type
                            var velocity = parseInt(lineArr[5]);
                            if (type == "Header") {
                                    var ticksPerQuarter = parseInt(lineArr[5]);
                                    console.log("TICKS PER QUARTER: " +  ticksPerQuarter);
                            }
                            var isNote = (type == "Note_on_c");
                            /*****ONLY IF START OF NOTE*****/
                            if (isNote && (velocity != 0)) {
                                //var track = parseInt(lineArr[0]); //get trackID, uncomment if model can convert properly to csv
                                var track = 1; //This is 1 to account for the fact that the note_on_c output from the model is 2
                                var tickVal = parseInt(lineArr[1]); //get tickVal
                                var pitch = parseInt(lineArr[4]);
                                var currentCount = i;
                                var newCount = i + 1;
                                var newPitch = -1;

                                if (!prevEndTickVal.hasOwnProperty(track)) {
                                    prevEndTickVal[track] = 0;
                                }

                                /*****FIND NOTE DURATION*****/
                                while ((pitch != newPitch)) { //look for note_off
                                    var newLineArr = strArray[newCount].split(","); //split the input array
                                    var newPitch = parseInt(newLineArr[4]);
                                    newCount++;
                                }
                                var endTickVal = parseInt(newLineArr[1]);
                                var noteDuration = roundNote(endTickVal - tickVal); //get rounded note duration
                                var durationFrac = getNoteDuration(noteDuration, ticksPerQuarter);
                                /*****ADJUSTING WRITE CURSOR ATTRIBUTES AND POSITIONING*****/
                                var adjustedTPQ = (Math.round(tickVal*2.18181818181818));
                                var adjustedTick = startWriteTick + adjustedTPQ;
                                if (tickVal > prevEndTickVal[track]) {
                                    var restTicks = tickVal - prevEndTickVal[track]; // calculate length of rest in ticks
                                    var restDuration = roundNote(restTicks); // get rounded rest duration
                                    var restFrac = getNoteDuration(restDuration, ticksPerQuarter); // convert rest duration to suitable format
                                    cursorWrite.staffIdx = track - 1 + startStaff;
                                    cursorWrite.setDuration(restFrac[0], restFrac[1]); // set the duration of the rest
                                    moveCursorToTick(cursorWrite, (startWriteTick + prevEndTickVal[track])); // move cursor to adjustedTick
                                    cursorWrite.addRest(); // add rest
                                }
                                cursorWrite.rewindToTick(adjustedTick);
                                //console.log("ADJUSTED TICK: " + adjustedTick);
                                cursorWrite.staffIdx = track - 1 + startStaff;
                                cursorWrite.setDuration(durationFrac[0], durationFrac[1]); //set the duration of the note
                                /*****CHECKING FOR CHORD*****/
                                if (tickVal != prevTickVal) {
                                    cursorWrite.addNote(pitch, false); //adds as individual note
                                } else {
                                    cursorWrite.addNote(pitch, true); //adds to chord
                                }
                                prevTickVal = tickVal; //update chord checker value
                                prevEndTickVal[track] = endTickVal; // update end of last note for the specific track
                                console.log("staffIdx: " + track + ", tick:" + tickVal + ", pitch: " + pitch + ", duration: " + durationFrac[0] + "/" + durationFrac[1] + ", adjusted ticks: " + adjustedTPQ);
                            }
                        }
                    }
                    var endWriteTick = cursorWrite.tick;
                    curScore.selection.selectRange(startWriteTick, endWriteTick, startStaff, endStaff + 1);
                    curScore.endCmd();  // end the command
                    //curScore.selection.clear();
                    
                    console.log("Generate button clicked")
                    console.log("tempo: " + cursor.tempo);

                }
            }
            Button {
                id: button3
                width: 100 * main.scaleFactor
                height: 40 * main.scaleFactor
                font.pixelSize: 16 * main.scaleFactor
                x: measureCounter.x + measureCounter.width - width
                y: measureCounter.y + measureCounter.height + 70 * main.scaleFactor
                text: "Quit"
                onClicked: {
                    console.log("Quit button clicked")
                    main.close();
                    Qt.quit();
                }
            }
            Text {
                id: counterTitle
                text: "Measures to Generate"
                x: 130 * main.scaleFactor
                y: 70 * main.scaleFactor
                font.pixelSize: 14 * main.scaleFactor
            }
            SpinBox {
                id: measureCounter
                x: 50 * main.scaleFactor
                y: 90 * main.scaleFactor
                width: 300 * main.scaleFactor
                height: 30 * main.scaleFactor
                font.pixelSize: 14 * main.scaleFactor
                from: 1
                to: 10
                value: 5 // default value
                onValueChanged: {
                    console.log("Counter value: " + measureCounter.value)
                }
            }
            Text {
                id: temperatureTitle
                text: "Complexity"
                x: 160 * main.scaleFactor
                y: 140 * main.scaleFactor
                font.pixelSize: 14 * main.scaleFactor
            }
            Slider {
                id: temperatureSlider
                x: 50 * main.scaleFactor
                y: 160 * main.scaleFactor
                width: 300 * main.scaleFactor
                height: 20 * main.scaleFactor
                from: 0
                to: 2
                stepSize: 1
                value: 25
                onValueChanged: {
                    //main.temperature = value;
                    console.log("Temperature: " + temperatureSlider.value);
                }
            }

            Button {
                id: increaseScaleButton
                width: 30 * main.scaleFactor
                height: width
                font.pixelSize: 14 * main.scaleFactor
                x: 10 * main.scaleFactor
                y: 10 * main.scaleFactor
                text: "+"
                onClicked: {
                    main.scaleFactor += 0.1;
                    console.log("Scale factor increased to: " + main.scaleFactor);
                }
            }
            Button {
                id: decreaseScaleButton
                width: increaseScaleButton.width
                height: width
                font.pixelSize: 14 * main.scaleFactor
                x: increaseScaleButton.x + increaseScaleButton.width + 10 * main.scaleFactor
                y: 10 * main.scaleFactor
                text: "-"
                onClicked: {
                    if (main.scaleFactor > 0.1) {
                        main.scaleFactor -= 0.1;
                        console.log("Scale factor decreased to: " + main.scaleFactor);
                    }
                }
            }
        }
    }

    /******************************************/
    /*****************FUNCTIONS****************/
    /******************************************/

    function getNoteDuration(tick, ticksPerQuarter) {
        var numerator = (tick / 55); //get total # of 32nd notes 
        var denominator = 16; //change to 64 in conjunction with roundNote to support 64th notes
        while (numerator % 2 === 0) {
            numerator /= 2;
            denominator /= 2;
        }
        return [numerator, denominator];
    }
    /*****given tick, round to the closest 32 note*****/
    function roundNote(num) { //supports up to a 32nd note
        return Math.ceil(num / 55) * 55; //change both to 30 to support 64th note
    }
    function moveCursorToTick(cursor, tick) {
        cursor.rewind(0); // Go to start of score
        while (cursor.tick < tick) {
            cursor.next(); // Move cursor one element to the right
        }
}

}
