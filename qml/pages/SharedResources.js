.pragma library

var arrayMainDevicesArray = new Array();

function fncAddDevice(sBTName, sBTAddress)
{
    var iPosition = arrayMainDevicesArray.length;

    arrayMainDevicesArray[iPosition] = new Object();
    arrayMainDevicesArray[iPosition]["BTName"] = sBTName;
    arrayMainDevicesArray[iPosition]["BTAddress"] = sBTAddress;
}

function fncDeleteDevices()
{
    arrayMainDevicesArray = new Array();
}

function fncGetDevicesNumber()
{
    return arrayMainDevicesArray.length;
}

function fncGetDeviceBTName(iIndex)
{
    return arrayMainDevicesArray[iIndex]["BTName"];
}

function fncGetDeviceBTAddress(iIndex)
{
    return arrayMainDevicesArray[iIndex]["BTAddress"];
}
