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
        var startTick = 1000;
        var endTick = 3000;
        var filteredTxt = "";
        var inputTxt = "";
        var filePath = ""; //ADD FILE PATH FOR SOURCE FILE
        readTest.source = filePath;
        console.log("Reading from: " + filePath);
        //readTest.read(inputTxt);
        inputTxt = readTest.read();
        var strArray = inputTxt.split(/\r?\n/);
        console.log("strArray[1]:" + strArray[1]);
        console.log(strArray.length);
        for (var i = 0; i < strArray.length; i++) {
            var lineArr = strArray[i].split(",");
            var tickVal = parseInt(lineArr[1]);
            var tempStr = "";

            if(lineArr[2]) { //if it exists
                if ((tickVal >= startTick && tickVal <= endTick) || (tickVal == 0 && lineArr[2].trim() !== "Note_on_c")) {
                    filteredTxt += strArray[i];
                    filteredTxt += '\n';
                    var prevTick = tickVal;
                }
            
                if ((lineArr[2].trim() == "End_track")) {
                    console.log("Success!");
                    tempStr = lineArr[0] + ", " + (prevTick + 1) + ", End_track\n";
                    filteredTxt += tempStr;
                }
            }
        }
        console.log(filteredTxt);

        Qt.quit();
    }
}
