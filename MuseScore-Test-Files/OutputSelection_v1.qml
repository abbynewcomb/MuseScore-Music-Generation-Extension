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
        console.log("hello world")
        var midiArray = new Array();
        var selection = curScore.selection;
        for (var i in curScore.selection.elements) {
            var element = curScore.selection.elements[i];
            if (!element) { //if not an element wait until next round of the loop
                continue;
            }
            var type = element.name;
            var pitch = "";
            var duration = "";
            var tick = "";
            var velocity = "";
            var outputNote = "";

            var numerator = "";
            var denominator = "";


            // Check the element type to determine what to add to the MIDI track
            switch (type) {
                /*case 'Rest':
                    pitch = "rest";
                    duration = element.duration.ticks;
                    tick = element.parent.tick.toString();
                    console.log("REST!");
                    break;
                */
                case 'Note':
                    pitch = element.pitch.toString();
                    duration = element.parent.duration.ticks;
                    //might just want to make a loop for finding tick IDK
                    if(element.noteType.toString() !== "NORMAL") { //maybe better to say if noteType == 8?
                            console.log("IRREGULAR NOTE TYPE: " + element.noteType.toString());
                        tick = element.parent.parent.parent.tick.toString();
                    }
                    else {
                        tick = element.parent.parent.tick.toString();
                    }
                    if(!element.velocity) { //if velocity is not defined
                        if(!element.veloOffset) { //check if velOffset is defined, and if not
                            velocity = "80"; //set velocity to 80.
                        } else { //if velOffset exists, set velocity to it
                            console.log("velo offset" + element.veloOffset.toString());
                            velocity = element.veloOffset.toString(); 
                        }
                    } else { //if velocity exists, set it
                        velocity = element.velocity.toString();
                    }
                    
                    outputNote = "1, " + tick + ", Note_on_c, 0, " + pitch + ", " + velocity;
                    midiArray.push({'output': outputNote, 'tick': tick});
                    outputNote = "1, " + (parseInt(tick) + parseInt(duration) - 13) + ", Note_on_c, 0, " + pitch + ", " + "0"
                    midiArray.push({'output': outputNote, 'tick': (parseInt(tick) + parseInt(duration) - 13)});
                    
                    break;

                case 'TimeSig':
                    numerator = element.timesig.numerator.toString();
                    denominator = getBaseLog(2, element.timesig.denominator).toString();
                    tick = element.parent.tick.toString();
                    outputNote = "1, " + tick + ", Time_signature, " +numerator + ", " + denominator + ", 24, 8";
                    midiArray.push({'output': outputNote, 'tick': tick});

                default:
                    console.log("TYPE: " + type);
                    break;
            }
        }

       console.log(midiArray[0].tick)
       
       midiArray.sort(function(a, b) {
            return parseInt(a['tick']) - parseInt(b['tick']);
        });

        for(var i in midiArray) {
            console.log(midiArray[i].output);
        }

        Qt.quit()
    }
    function getBaseLog(x, y) {
            return (Math.log(y) / Math.log(x));
    }   
}

