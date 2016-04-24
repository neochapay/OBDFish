.pragma library

//This function receives an answer from the ELM and tries to extract supported PID's
//There are two scenarios:
//1 - ELM has answered completely and there is valid data
//2 - ELM has answered completely but there is no data
function fncSetSupportedPIDs(sData, sPID)
{
    //Get rid of all the carriage returns
    sData = sData.replace(/\r/g, " ");
    //Recognize if there are supported PID's in this block
    if (sData.indexOf("NO DATA") !== -1 || sData.indexOf("UNABLE TO CONNECT") !== -1 || sData.indexOf("BUS INIT: ... ERROR"))
    {
        arrayOBDData[sPID] = "NOTHING";
        arrayOBDData[sPID].supported_pid = "no";
    }
    else
    {
        //We have a bit mask of supported PID's
        arrayOBDData[sPID] = (sData.substring(0, sData.indexOf(" >"))).trim();
        arrayOBDData[sPID].supported_pid = "yes";
    }
}

function fncGetFoundSupportedPIDs()
{
    var iLoop = 0;
    for (iLoop = 0; iLoop < arrayOBDData.length; iLoop++)
    {
        if (arrayOBDData[iLoop].supported_pid === "yes")
            return true;
    }
    return false;
}

var sELMVersion = "";
var sVoltage = "";

var arrayOBDData = new Array
([
    {"0100":"", supported_pid: "no", len_bytes: 4},
    {"0120":"", supported_pid: "no", len_bytes: 4},
    {"0900":"", supported_pid: "no", len_bytes: 4}
]);
