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

        //console.log("Looking for first byte: " + iFirstByte);

        //Try to find that first byte in the ELM answer.
        sData = sData.substring(sData.indexOf(iFirstByte.toString()));

        //console.log("Found supported PID: " + sPID + " " + sData);

        //Now, if this is a PID in the 0100 area, we can sort this into the corresponding array.
        if (sPID.substr(0, 2) === "01")
        {
            //Separate the mask bytes into an array. Leave out the first four bytes.
            var sHexString = sData.substring(4).split('');
            //LoopVar is an index for the last two characters of the PID
            var iLoopVar = parseInt(sPID.substr(2,2)) + 1;

            sHexString.forEach(function(hex)
            {
                var sBinString = fncHexToBin(hex).split('');
                sBinString.forEach(function(sBinary)
                {
                    //Calculate
                    var sCurrentPID = sPID.substr(0,2) + fncLeadingZeros(iLoopVar.toString(16), 2);

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
    if (sData.length !== (iBytesCount * 2))
        return null;

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
var sELMVersion = "";
var sVoltage = "";

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
    { pid: "011c", supported: false, bytescount: 1, fncConvert: "" },
];

//Create lokup table for PID's.
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
    return ((parseInt(data, 16) * 100) / 255).toString();
}
