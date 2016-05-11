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
        //console.log("No supported PID's: " + sPID);
    }
    else
    {      
        //Calculate first byte of PID mask
        var iFirstByte = parseInt(sPID.substr(0,2));
        iFirstByte = iFirstByte + 40;

        console.log("Looking for first byte: " + iFirstByte);

        //Try to find that first byte in the ELM answer.
        sData = sData.substring(sData.indexOf(iFirstByte.toString()));

        console.log("Found supported PID: " + sPID + " " + sData);

        //Now, if this is a PID in the 0100 area, we can sort this into the corresponding array.
        if (sPID.substr(0, 2) === "01")
        {
            //Separate the mask bytes into an array. Leave out the first four bytes.
            var sHexString = sData.substring(4).split('');
            //LoopVar is an index for the last two characters of the PID
            var iLoopVar = (parseInt(sPID.substr(2,2), 16)) + 1;

            console.log("iLoopVar: " + iLoopVar);

            sHexString.forEach(function(hex)
            {
                var sBinString = fncHexToBin(hex).split('');
                sBinString.forEach(function(sBinary)
                {
                    //Calculate
                    var sCurrentPID = sPID.substr(0,2) + fncLeadingZeros(iLoopVar.toString(16), 2);                    

                    console.log("iLoopVar: " + iLoopVar);
                    console.log("sCurrentPID: " + sCurrentPID);
                    console.log("sBinary: " + sBinary);                    

                    if (sBinary === "1")
                      sSupportedPIDs0100 = sSupportedPIDs0100 + fncLeadingZeros(iLoopVar.toString(16), 2) + ", ";

                    //Write supported value to PID array
                    if (arrayLookupPID[sCurrentPID] !== undefined)
                        arrayLookupPID[sCurrentPID].supported = (sBinary === "1");

                    iLoopVar++;
                });
            });          
        }
    }
}

function fncEvaluatePIDQuery(sData, sPID)
{
    //Make search pattern out of the query PID
    var sSearchPattern = parseInt(sPID.substr(0,2));
    sSearchPattern = (sSearchPattern + 40).toString();
    sSearchPattern = sSearchPattern + sPID.substr(2);

    console.log("fncEvaluatePIDQuery, sData " + sData);

    //Check if the search pattern is there. If this is not the case, we have incorrect data. Exit then...
    if (sData.indexOf(sSearchPattern) === -1)
        return null;

    //Read out how many data bytes there should be within the data.
    //MEMO TO MYSELF: one byte consists of two characters. This is not ASCII!!!
    var iBytesCount = arrayLookupPID[sPID.toLowerCase()].bytescount;

    console.log("fncEvaluatePIDQuery, iBytesCount " + iBytesCount.toString());

    //Get the real data. This comes behind the search pattern. Length is bytes multiplied by 2.
    sData = sData.substr((sData.indexOf(sSearchPattern) + 4), (iBytesCount * 2));
    sData = sData.trim();

    console.log("fncEvaluatePIDQuery, real sData " + sData);

    //Check if we have the expected length.
    //If this is not the case, we have incorrect data. Exit then...
    //It also might be that there is no data, e.g. the vehicle stands still and there is no speed or RPM.
    //TODO: Schlecht, das hier ein NULL zurückgegeben wird. Erst mal einen leeren String zurückgeben.
    //Ausserdem sollte das vorher abgefangen werden, wenn eine PID nicht unterstützt wird!!!
    if (sData.length !== (iBytesCount * 2))
        return "";

    return arrayLookupPID[sPID.toLowerCase()].fncConvert(sData);
}


function fncGetFoundSupportedPIDs()
{
    for (var i = 0; i < arrayPIDs.length; i++)
    {
        if (arrayPIDs[i].supported === true)
            return true;
    }

    return false;
}

//Here come data variables or arrays

var sSupportedPIDs0100 = "";

var arrayPIDs =
[
    { pid: "0101", supported: false, bytescount: 4, fncConvert: "" },
    { pid: "0104", supported: false, bytescount: 1, fncConvert: fncConvertLoad },
    { pid: "0105", supported: false, bytescount: 1, fncConvert: fncConvertTemp },
    { pid: "010a", supported: false, bytescount: 1, fncConvert: "" },
    { pid: "010b", supported: false, bytescount: 1, fncConvert: fncConvertIntakePressure },
    { pid: "010c", supported: false, bytescount: 2, fncConvert: fncConvertRPM },
    { pid: "010d", supported: false, bytescount: 1, fncConvert: fncConvertSpeed },
    { pid: "010e", supported: false, bytescount: 1, fncConvert: fncConvertTimingAdvance },
    { pid: "010f", supported: false, bytescount: 1, fncConvert: fncConvertTemp },
    { pid: "0110", supported: false, bytescount: 2, fncConvert: fncConvertAirFlow },
    { pid: "0111", supported: false, bytescount: 1, fncConvert: fncConvertThrottlePosition },
    { pid: "011c", supported: false, bytescount: 1, fncConvert: fncConvertOBDStandard },
    { pid: "0901", supported: false, bytescount: 1, fncConvert: fncConvertVINCount },
    { pid: "0902", supported: false, bytescount: 1, fncConvert: fncConvertVIN }
];

//Here come some enums for PID data
var OBDStandards =
{
    1: "OBD-II as defined by the CARB",
    2: "OBD as defined by the EPA",
    3: "OBD and OBD-II",
    4: "OBD-I",
    5: "Not OBD compliant",
    6: "EOBD (Europe)",
    7: "EOBD and OBD-II",
    8: "EOBD and OBD",
    9: "EOBD, OBD and OBD II",
    10: "JOBD (Japan)",
    11: "JOBD and OBD II",
    12: "JOBD and EOBD",
    13: "JOBD, EOBD, and OBD II",
    14: "Reserved",
    15: "Reserved",
    16: "Reserved",
    17: "Engine Manufacturer Diagnostics (EMD)",
    18: "Engine Manufacturer Diagnostics Enhanced (EMD+)",
    19: "Heavy Duty On-Board Diagnostics (Child/Partial) (HD OBD-C)",
    20: "Heavy Duty On-Board Diagnostics (HD OBD)",
    21: "World Wide Harmonized OBD (WWH OBD)",
    22: "Reserved",
    23: "Heavy Duty Euro OBD Stage I without NOx control (HD EOBD-I)",
    24: "Heavy Duty Euro OBD Stage I with NOx control (HD EOBD-I N)",
    25: "Heavy Duty Euro OBD Stage II without NOx control (HD EOBD-II)",
    26: "Heavy Duty Euro OBD Stage II with NOx control (HD EOBD-II N)",
    27: "Reserved",
    28: "Brazil OBD Phase 1 (OBDBr-1)",
    29: "Brazil OBD Phase 2 (OBDBr-2)",
    30: "Korean OBD (KOBD)",
    31: "India OBD I (IOBD I)",
    32: "India OBD II (IOBD II)",
    33: "Heavy Duty Euro OBD Stage VI (HD EOBD-IV)",
    34: "Undefined"
}

var FuelSystem =
{
    1: "Open loop due to insufficient engine temperature",
    2: "Closed loop, using oxygen sensor feedback to determine fuel mix",
    4: "Open loop due to engine load OR fuel cut due to deceleration",
    8: "Open loop due to system failure",
    16: "Closed loop, using at least one oxygen sensor but there is a fault in the feedback system"
}

//Create lookup table for PID's.
//This is a helper table to easier access the main PID table.
var arrayLookupPID = {};
for (var i = 0; i < arrayPIDs.length; i++)
{
    arrayLookupPID[arrayPIDs[i].pid] = arrayPIDs[i];
}


//Here come helper functions. Eventually outsource to other file.
//The function names should speak for themselves.0
function fncIsValueHex(n)
{
    return/^[0-9A-Fa-f]{1,64}$/.test(n);
}
function fncHexToBin(n)
{
    if(!fncIsValueHex(n))
    {
        return 0;
    }
    return fncLeadingZeros(parseInt(n,16).toString(2),4);
}
function fncLeadingZeros( number, width )
{
  width -= number.toString().length;
  if ( width > 0 )
  {
    return new Array( width + (/\./.test( number ) ? 2 : 1) ).join( '0' ) + number;
  }
  return number + "";
}


//Here come functions to convert PID hex strings into usable values.
function fncConvertTemp(data)
{   
    return (parseInt(data, 16) - 40).toString();
}
function fncConvertRPM(data)
{
    //We expect two bytes here. Extract them from data.
    var sByte1 = data.substr(0, 2);
    var sByte2 = data.substr(2, 2);

    return (((parseInt(sByte1, 16) * 256) + parseInt(sByte2, 16)) / 4).toString();
}
function fncConvertSpeed(data)
{
    return (parseInt(data, 16)).toString();
}
function fncConvertLoad(data)
{
    //TODO: Here round to one decimal place
    return (parseInt(data, 16) * (100 / 256)).toString();
}
function fncConvertIntakePressure(data)
{
    return (parseInt(data, 16)).toString();
}
function fncConvertTimingAdvance(data)
{
    return ((parseInt(data, 16) / 2) - 64).toString();
}
function fncConvertAirFlow(data)
{
    //We expect two bytes here. Extract them from data.
    var sByte1 = data.substr(0, 2);
    var sByte2 = data.substr(2, 2);
    return (((parseInt(sByte1, 16) * 256.0) + parseInt(sByte2, 16)) / 100).toString();
}
function fncConvertThrottlePosition(data)
{
    //TODO: Here round to one decimal place
    return ((parseInt(data, 16) * 100) / 255).toString();
}
function fncConvertOBDStandard(data)
{
    data = parseInt(data);

    if (data >= 1 && data <= 33)
       return OBDStandards[data];
    else
       return OBDStandards[34]; //That's undefined
}
function fncConvertVINCount(data)
{
    data = parseInt(data);

    //Set byte count for the VIN number
    arrayLookupPID["0902"].bytescount = data;

    return data.toString();
}
function fncConvertVIN(data)
{
    var sVIN = "";

    console.log("fncConvertVIN, data: " + data);

    data = data.split('');

    data.forEach(function(sTMP)
    {
        console.log("fncConvertVIN, sTMP: " + sTMP);

        var sTester = String.fromCharCode(sTMP);

        console.log("fncConvertVIN, sTester: " + sTester);

        sVIN = sVIN + sTester;
    });

    console.log("fncConvertVIN, sVIN: " + sVIN);

    return sVIN;
}
