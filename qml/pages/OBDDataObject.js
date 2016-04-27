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
    //Ich brauche hier eine Erkennung, wie viele Bytes die Antwort enthält.
    //Die Anzahld der Bytes muss im Array stehen!!!
    //Die nächste Abfrage muss entsprechend umgestaltet werden!!!   TODO
    var sSearchPattern = parseInt(sPID.substr(0,2));
    sSearchPattern = (sSearchPattern + 40).toString();
    sSearchPattern = sSearchPattern + sPID.substr(2);

    console.log("fncEvaluatePIDQuery, sSearchPattern" + sSearchPattern);

    //TODO: Suche nach dem Searchpattern


    console.log("fncEvaluatePIDQuery, sData" + sData);
    console.log(sData.indexOf("4105").toString());


    if (sData.indexOf("4105") === -1)
        return null;

    sData = sData.substring((sData.indexOf("4105") + 4), 2);
    sData = sData.trim();

    //Extract number of bytes from data
    var iBytes = sData.length / 2;

    console.log("Cooling temp: " + arrayLookupPID["0105"].fncConvert(sData));

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
    { pid: "0101", supported: false, fncConvert: "" },
    { pid: "0104", supported: false, fncConvert: "" },
    { pid: "0105", supported: false, fncConvert: fncConvertTemp },
    { pid: "010a", supported: false, fncConvert: "" },
    { pid: "010b", supported: false, fncConvert: "" },
    { pid: "010c", supported: false, fncConvert: "" },
    { pid: "010d", supported: false, fncConvert: "" },
    { pid: "010e", supported: false, fncConvert: "" },
    { pid: "010f", supported: false, fncConvert: "" },
    { pid: "0110", supported: false, fncConvert: "" },
    { pid: "0111", supported: false, fncConvert: "" },
    { pid: "011c", supported: false, fncConvert: "" },
];

//Create lokup table for PID's.
//This is a helper table to easier access the main PID table.
var arrayLookupPID = {};
for (var i = 0; i < arrayPIDs.length; i++)
{
    arrayLookupPID[arrayPIDs[i].pid] = arrayPIDs[i];
}


//Here come helper functions. Eventually outsource to other file.
//The function names should speak for themselves.
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
function fncConvertRPM(data1, data2)
{
    return ((parseInt(data1, 16) * 256) + parseInt(data2, 16)) / 4;
}
function fncConvertSpeed(data)
{
    return parseInt(byte, 16);
}
