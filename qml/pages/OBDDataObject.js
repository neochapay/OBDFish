.pragma library

//This function receives an answer from the ELM and tries to extract supported PID's
//There are two scenarios:
//1 - ELM has answered completely and there is valid data
//2 - ELM has answered completely but there is no data
function fncSetSupportedPIDs(sData, sPID)
{    
    //Recognize if there are supported PID's in this block
    if (sData.indexOf("NO DATA") !== -1 || sData.indexOf("UNABLE TO CONNECT") !== -1 || sData.indexOf("BUS INIT: ... ERROR") !== -1)
    {
        //There are no supported PID's
        console.log("No supported PID's: " + sPID);
    }
    else
    {                
        //Calculate first byte of PID mask
        var iFirstByte = parseInt(sPID.substr(0,2));
        iFirstByte = iFirstByte + 40;

        console.log("Looking for first byte: " + iFirstByte);

        //Try to find that first byte in the ELM answer.
        sData = sData.substring(sData.indexOf(iFirstByte.toString()));

        //Cut off the rest
        sData = sData.substring(0, sData.search(/\r>/g)).trim();

        console.log("Found supported PID: " + sPID + " " + sData);

        //We have a bit mask of supported PID's
        var valuePIDSupportedMask = { };
        valuePIDSupportedMask["sPID"] = sPID;
        valuePIDSupportedMask["Mask"] = sData;
        arrayOBDSupportedPIDs.push(valuePIDSupportedMask);
    }
}

function fncGetFoundSupportedPIDs()
{
   if (arrayOBDSupportedPIDs.length > 0)
       return true;
   else
       return false;
}

var sELMVersion = "";
var sVoltage = "";
var arrayOBDSupportedPIDs = new Array;
