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
            const elements = curScore.selection.elements;
            
            for (var i in curScore.selection.elements) {
                var element = curScore.selection.elements[i];
                //console.log("duration = " + element.tickLength);
                var pitch = "";
                var duration = "";

                // Check the element type to determine what to add to the MIDI track
                console.log("Elements " + [i] + " = " + elements[i].pitch);
                /*
                var keysRet = getKeys(elements[i]);
                for (var j in keysRet) {
                  console.log("keysRet " + [j] + "of" + [i] + ":" + keysRet[j]);
                  }
                 */
                //console.log(Element.CHORD);
                //console.log(curScore.selection.elements[i].value);
                switch (curScore.selection.elements[i].type) {
                    case '25':
                        pitch = "rest";
                        duration = element.duration.realValue;
                        break;
                    case '20':
                        pitch = element.pitch.toString();
                        duration = element.duration.realValue;
                        break;
                    default:
                        break;
                }

                // If the element has a "pitch" (or is given a pitch i.e. rest), add it to the MIDI array
                if (pitch !== "") {
                    midiArray.push({
                        'type': type,
                        'pitch': pitch,
                        'duration': duration
                    });
                }
            }
            
            var filePath = "/Users/adam/Documents/Capstone MuseScore Plugin/Plugin IO Test FIles/Export Test 2.txt"

            writeTest.source = filePath;

            console.log("Writing to: " + filePath);

            var textContent = midiArray.toString();

            writeTest.write(textContent);   
            
            //console.log(midiArray[2]);
            var element = elements[0].parent.duration;
             var keysRet = getKeys(element);
                  for (var j in keysRet) {
                  console.log("keysRet " + j + " of " + i + ":" + keysRet[j] + ":" + element[keysRet[j]]);
            }
            
            Qt.quit()
            }
            function getKeys(obj) {
                  var keys = [];
                  for(var key in obj){
                        keys.push(key);
                  }
            return keys;
            }
      }

