var bCommandRunning = false;
var sReceiveBuffer = "";

//This function accepts an AT command to be send to the ELM
function fncStartCommand(sCommand)
{
    //Don't do anything if there is already an active command.
    if (bCommandRunning) return;
    
    //Set active command bit
    bCommandRunning = true;

    //Cleare receive buffer
    sReceiveBuffer = "";
    
    //Send the AT command via bluetooth
    id_BluetoothData.sendHex(sLastATcommand);
}

//Data which is received via bluetooth is passed into this function
function fncGetData(sData)
{
    //Get rid of any leading/trailing spaces
    sData = sData.trim();

    //Fill in new data into buffer
    sReceiveBuffer = sReceiveBuffer + sData;       

    //If the ELM is ready with sending a command, it always sends the same end characters.
    //These are three characters: two carriage returns (\r) followed by >
    //Check if the end characters are already in the buffer.
    if (sReceiveBuffer.search(/\r\r>/g) === -1)
    {
        //The ELM is not ready. Wait for more data to come in.        
    }
    else
    {
        //The ELM has completely answered the command.
        //Received data is now in sReceiveBuffer.
        
        //Set ready bit
        bCommandRunning = false;
    }
}
