var bCommandRunning = false;
var sReceiveBuffer2 = "";

//This function accepts an AT command to be send to the ELM
function fncStartCommand(sCommand)
{
    //Don't do anything if there is already an active command.
    if (bCommandRunning) return;
    
    //Set active command bit
    bCommandRunning = true;

    console.log("sReceiveBuffer2: " + sReceiveBuffer2);

    //Cleare receive buffer
    sReceiveBuffer2 = "";

    console.log("sReceiveBuffer2: " + sReceiveBuffer2);
    
    //Send the AT command via bluetooth
    id_BluetoothData.sendHex(sCommand);
}

//Data which is received via bluetooth is passed into this function
function fncGetData(sData)
{
    //WARNING: Don't trim here. ELM might send leading/trailing spaces/carriage returns.
    //They might get lost but are needed!!!

    console.log("fncGetData, sReceiveBuffer2: " + sReceiveBuffer2);

    //Fill in new data into buffer
    sReceiveBuffer2 = sReceiveBuffer2 + sData;

    console.log("fncGetData, sReceiveBuffer2: " + sReceiveBuffer2);


    //If the ELM is ready with sending a command, it always sends the same end characters.
    //These are three characters: two carriage returns (\r) followed by >
    //Check if the end characters are already in the buffer.
    if (sReceiveBuffer2.search(/\r>/g) !== -1)
    {
        //The ELM has completely answered the command.
        //Received data is now in sReceiveBuffer2.

        //Cut off the end characters
        sReceiveBuffer2 = sReceiveBuffer2.substring(0, sReceiveBuffer2.search(/\r>/g));
        sReceiveBuffer2 = sReceiveBuffer2.trim();

        //Set ready bit
        bCommandRunning = false;
    }
}
