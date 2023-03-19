import QtQuick 2.0
import MuseScore 3.0
import FileIO 3.0

//This code writes the pure MIDI user selection to a file.  

MuseScore {
        menuPath: "Plugins.pluginName"
        description: "Description goes here"
        version: "1.0"
        
        FileIO { //Initialzie File IO Stream
            id: writeTest
            source: filePath
            onError: console.log(msg + "\nFilename = " + writeTest.source);
        }
        onRun: {
            var curSelection = []
            for (var i in curScore.selection.elements) //gets current selection and adds every element to an array
                  curSelection.push(curScore.selection.elements[i])
            
            var filePath = "" //REPLACE FILEPATH WITH A PATH TO A TEXT FILE

            writeTest.source = filePath;
            console.log("Writing to: " + filePath);

            var textContent = curSelection.toString(); //Converts the current selection to a string in order to write it to a file. Note that this string is comma separated. 

            writeTest.write(textContent); //writes string to file. 

            Qt.quit()
            }
      }
