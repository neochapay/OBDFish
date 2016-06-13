/*
 * Copyright (C) 2016 Jens Drescher, Germany
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

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
        if (sPID.substr(0, 2) === "01" || sPID.substr(0, 2) === "09")
        {
            //Separate the mask bytes into an array. Use last eight characters.
            var sHexString = sData.slice(-8);
            console.log("sHexString: " + sHexString);

            //Separate characters.
            sHexString = sHexString.split('');

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

                    if (sBinary === "1" && sPID.substr(0, 2) === "01")
                      sSupportedPIDs0100 = sSupportedPIDs0100 + fncLeadingZeros(iLoopVar.toString(16), 2) + ", ";
                    if (sBinary === "1" && sPID.substr(0, 2) === "09")
                      sSupportedPIDs0900 = sSupportedPIDs0900 + fncLeadingZeros(iLoopVar.toString(16), 2) + ", ";

                    //Write supported value to PID array
                    if (arrayLookupPID[sCurrentPID] !== undefined)
                        arrayLookupPID[sCurrentPID].supported = (sBinary === "1");

                    iLoopVar++;
                });
            });          
        }
    }
}

function fncEvaluateVINQuery(sData)
{   
    var iExpectedDataPackets = arrayLookupPID["0902"].bytescount;
    console.log("fncEvaluateVINQuery, iExpectedDataPackets: " + iExpectedDataPackets.toString());


    //Split data string
    sData = sData.split(/\r/);
    var iFoundPackets = 0;
    var sVINString = "";

    for (var i = 0; i < sData.length; i++)
    {
        if (sData[i].substr(0,4) === "4902")
        {
            sVINString = sVINString + sData[i].substr(6).trim();
            iFoundPackets++;
        }
    }

    console.log("fncEvaluateVINQuery, iFoundPackets: " + iFoundPackets.toString());
    console.log("fncEvaluateVINQuery, sVINString: " + sVINString);

    if (iFoundPackets === iExpectedDataPackets)
    {
        var sReturnString = "";
        sVINString = sVINString.match(new RegExp('.{1,2}', 'g'));

        sVINString.forEach(function(sHex)
        {
            console.log("sHex: " + sHex);

            var iValue = parseInt(sHex, 16);

            console.log("iValue: " + iValue.toString());

            if (iValue === 0)
                return;

            sReturnString = sReturnString + String.fromCharCode(iValue);

            console.log("sReturnString: " + sReturnString);
        });

        return (sReturnString);
    }
    else
        return null;
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
        return "";

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
var sSupportedPIDs0900 = "";

var arrayPIDs =
[
    { pid: "0101", supported: false, bytescount: 4, labeltext: qsTr("Engine light, error number"), unittext: "", fncConvert: fncConvertDTCCheck },
    { pid: "0103", supported: false, bytescount: 2, labeltext: qsTr("Fuel system 1 and 2"), unittext: "", fncConvert: fncConvertFuelSystem },
    { pid: "0104", supported: false, bytescount: 1, labeltext: qsTr("Engine Load"), unittext: "%", fncConvert: fncConvertLoad },
    { pid: "0105", supported: false, bytescount: 1, labeltext: qsTr("Engine Temp"), unittext: "C°", fncConvert: fncConvertTemp },
    { pid: "010b", supported: false, bytescount: 1, labeltext: qsTr("Intake Air Pressure"), unittext: "kPa", fncConvert: fncConvertIntakePressure },
    { pid: "010c", supported: false, bytescount: 2, labeltext: qsTr("Engine RPM"), unittext: qsTr("rpm"), fncConvert: fncConvertRPM },
    { pid: "010d", supported: false, bytescount: 1, labeltext: qsTr("Vehicle Speed"), unittext: "km/h", fncConvert: fncConvertSpeed },
    { pid: "010e", supported: false, bytescount: 1, labeltext: qsTr("Timing Advance"), unittext: "°", fncConvert: fncConvertTimingAdvance },
    { pid: "010f", supported: false, bytescount: 1, labeltext: qsTr("Intake Air Temp"), unittext: "C°", fncConvert: fncConvertTemp },
    { pid: "0110", supported: false, bytescount: 2, labeltext: qsTr("Air Flow Rate"), unittext: qsTr("grams/sec"), fncConvert: fncConvertAirFlow },
    { pid: "0111", supported: false, bytescount: 1, labeltext: qsTr("Throttle Position"), unittext: "%", fncConvert: fncConvertThrottlePosition },
    { pid: "011c", supported: false, bytescount: 1, labeltext: null, unittext: "", fncConvert: fncConvertOBDStandard },
    { pid: "0151", supported: false, bytescount: 1, labeltext: qsTr("Fuel Type"), unittext: "", fncConvert: fncConvertFuelType },
    { pid: "0901", supported: false, bytescount: 1, labeltext: null, unittext: "", fncConvert: fncConvertVINCount },
    { pid: "0902", supported: false, bytescount: 1, labeltext: null, unittext: "", fncConvert: "" }
];

//Here come some enums for PID data
var FuelTypes =
{
    0: qsTr("Not available"),
    1: qsTr("Gasoline"),
    2: "Methanol",
    3: "Ethanol",
    4: "Diesel",
    5: "LPG",
    6: "CNG",
    7: qsTr("Propane"),
    8: qsTr("Electric"),
    9: qsTr("Bifuel running Gasoline"),
    10: "Bifuel running Methanol",
    11: "Bifuel running Ethanol",
    12: "Bifuel running LPG",
    13: "Bifuel running CNG",
    14: "Bifuel running Propane",
    15: "Bifuel running Electricity",
    16: "Bifuel running electric and combustion engine",
    17: "Hybrid gasoline",
    18: "Hybrid Ethanol",
    19: "Hybrid Diesel",
    20: "Hybrid Electric",
    21: "Hybrid running electric and combustion engine",
    22: "Hybrid Regenerative",
    23: "Bifuel running diesel",
    24: "Undefined"
}
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
    return (parseInt(data, 16) * (100 / 256)).toFixed(1);
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
    return ((parseInt(data, 16) * 100) / 255).toFixed(1);
}
function fncConvertOBDStandard(data)
{
    data = parseInt(data);

    if (data >= 1 && data <= 33)
       return OBDStandards[data];
    else
       return OBDStandards[34]; //That's undefined
}
function fncConvertFuelType(data)
{
    data = parseInt(data);

    if (data >= 0 && data <= 23)
       return FuelTypes[data];
    else
       return FuelTypes[24]; //That's undefined
}
function fncConvertVINCount(data)
{
    data = parseInt(data);

    //Set byte count for the VIN number
    arrayLookupPID["0902"].bytescount = data;

    return data.toString();
}
function fncConvertDTCCheck(data)
{
    var sByte1 = data.substr(0, 2);

    var byteValue, mil, numberOfDTCs, reply;
    byteValue = parseInt(sByte1, 16);
    if ((byteValue >> 7) === 1)
    {
        mil = "On";
    }
    else
    {
        mil = "Off";
    }
    numberOfDTCs = byteValue % 128;

    return mil + ", " + numberOfDTCs;
}
function fncConvertFuelSystem(data)
{
    //We expect two bytes here. Extract them from data.
    var sByte1 = data.substr(0, 2);
    var sByte2 = data.substr(2, 2);

    var sSystem1 = "";
    var sSystem2 = "";

    sSystem1 = FuelSystem[bitDecoder(sByte1)];
    if( sByte2 )
    {
        sSystem2 = FuelSystem[bitDecoder(sByte2)];
    }

    return sSystem1 + ", " + sSystem2;
}
