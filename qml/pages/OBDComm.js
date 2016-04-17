var sCommandStateMachine = "";
var bCommandRunning = false;
var bCommandOK = false;
var sLastATcommand = "";
var iRepeatCommand = 0;
var sReceiveBuffer = "";

var sVoltage = "Voltage";
var sAdapterInfo = "Info";

//This function accepts a command to send to OBD adapter
//List of commands: init, adapterinfo, voltage, setprotocol
function fncStartCommand(sCommand)
{
    if (bCommandRunning) return;
    bCommandRunning = true;

    sReceiveBuffer = "";
    sCommandStateMachine = sCommand;

    //Call the state machine to decide what to do next
    fncGetData("");
}

//Receive data from OBD adapter
//This is the OBD command state machine
function fncGetData(sData)
{
    //Get rid of any spaces
    sData = sData.trim();

    sReceiveBuffer = sReceiveBuffer + sData;
    var sPIDRequest = "";
    var bWaitForNewData = false;   

    //Write to file
    id_FileWriter.vWriteData(sData);

    switch(sCommandStateMachine)
    {
        //*****START command sequence: init*****
        case "init":           
            sCommandStateMachine = "init_step1";
            sLastATcommand = "AT Z";            
        break;
        case "init_step1":
            if (fncCheckCurrentCommand(sData) === true)
            {
                sCommandStateMachine = "init_step2";
                sLastATcommand = "ATS0";
                bWaitForNewData = false;
            }
            else
                bWaitForNewData = true;
        break;
        case "init_step2":
            if (fncCheckCurrentCommand(sData) === true)
            {
                sCommandStateMachine = "init_step3";
                sLastATcommand = "ATL0";
                bWaitForNewData = false;
            }
            else
                bWaitForNewData = true;
        break;
        case "init_step3":
            if (fncCheckCurrentCommand(sData) === true)
            {
                sCommandStateMachine = "init_step4";
                sLastATcommand = "ATH0";
                bWaitForNewData = false;
            }
            else
                bWaitForNewData = true;
        break;
        case "init_step4":
            if (fncCheckCurrentCommand(sData) === true)
            {
                sCommandStateMachine = "init_step5";
                sLastATcommand = "ATE0";
                bWaitForNewData = false;
            }
            else
                bWaitForNewData = true;
        break;
        case "init_step5":
            if (fncCheckCurrentCommand(sData) === true)
            {
                //Sequence is done now. Everything good.
                sCommandStateMachine = "";
                sLastATcommand = "";
                bCommandOK = true;
                bCommandRunning = false;
                bWaitForNewData = false;
                return;
            }
            else
                bWaitForNewData = true;
        break;
        //*****END command sequence: init*****

        //*****START command sequence: adapterinfo*****       
        case "adapterinfo":
            sCommandStateMachine = "adapterinfo_step1";
            sLastATcommand = "AT I";
        break;
        case "adapterinfo_step1":
            if (fncCheckCurrentCommand(sData) === true)
            {
                //Sequence is done now. Extract value.
                sAdapterInfo = fncGetValue(sData);
                sCommandStateMachine = "";
                sLastATcommand = "";
                bCommandOK = true;
                bCommandRunning = false;
                bWaitForNewData = false;
                return;
            }
            else
                bWaitForNewData = true;
        break;
        //*****END command sequence: adapterinfo*****

        //*****START command sequence: voltage*****
        case "voltage":
            sCommandStateMachine = "voltage_step1";
            sLastATcommand = "AT RV";
        break;
        case "voltage_step1":
            if (fncCheckCurrentCommand(sData) === true)
            {
                //Sequence is done now. Extract value.
                sVoltage = fncGetValue(sData);
                sCommandStateMachine = "";
                sLastATcommand = "";
                bCommandOK = true;
                bCommandRunning = false;
                bWaitForNewData = false;
                return;
            }
            else
                bWaitForNewData = true;
        break;
        //*****END command sequence: voltage*****

        //*****START command sequence: find protocol*****
        case "findprotocol":
            sCommandStateMachine = "findprotocol_step1";
            iRepeatCommand = 3;
            sLastATcommand = "ATSP0";
        break;
        case "findprotocol_step1":
            if (fncCheckProtocolRequest(sData) === true)     //Command OK, next one...
            {
                sCommandStateMachine = "findprotocol_step2";
                iRepeatCommand = 3;
                sLastATcommand = "0100";
            }
            else if(iRepeatCommand > 0)
                iRepeatCommand--;
            else
            {
                bCommandOK = false;
                bCommandRunning = false;
                return;
            }
        break;
        case "findprotocol_step2":           
            sPIDRequest = fncCheckPIDRequest(sData);
            if (sPIDRequest === "ready" || sPIDRequest === "error")
            {
                sCommandStateMachine = "findprotocol_step3";
                bWaitForNewData = false;
                iRepeatCommand = 3;
                sLastATcommand = "0120";
            }
            else if (sPIDRequest === "wait")
            {
                //We have to wait for further data.
                bWaitForNewData = true;
            }
            else if(sPIDRequest === "command_error" && iRepeatCommand > 0)
                iRepeatCommand--;
            else
            {
                bCommandOK = false;
                bCommandRunning = false;
                return;
            }
        break;
        case "findprotocol_step3":
            sPIDRequest = fncCheckPIDRequest(sData);
            if (sPIDRequest === "ready" || sPIDRequest === "error")
            {
                sCommandStateMachine = "findprotocol_step4";
                bWaitForNewData = false;
                iRepeatCommand = 3;
                sLastATcommand = "0140";
            }
            else if (sPIDRequest === "wait")
            {
                bWaitForNewData = true;
            }
            else if(sPIDRequest === "command_error" && iRepeatCommand > 0)
                iRepeatCommand--;
            else
            {
                bCommandOK = false;
                bCommandRunning = false;
                return;
            }
        break;
        case "findprotocol_step4":
            sPIDRequest = fncCheckPIDRequest(sData);
            if (sPIDRequest === "ready" || sPIDRequest === "error")
            {
                sCommandStateMachine = "findprotocol_step5";
                bWaitForNewData = false;
                iRepeatCommand = 3;
                sLastATcommand = "0160";
            }
            else if (sPIDRequest === "wait")
            {
                bWaitForNewData = true;
            }
            else if(sPIDRequest === "command_error" && iRepeatCommand > 0)
                iRepeatCommand--;
            else
            {
                bCommandOK = false;
                bCommandRunning = false;
                return;
            }
        break;
        case "findprotocol_step5":
            sPIDRequest = fncCheckPIDRequest(sData);
            if (sPIDRequest === "ready" || sPIDRequest === "error")
            {
                sCommandStateMachine = "findprotocol_step6";
                bWaitForNewData = false;
                iRepeatCommand = 3;
                sLastATcommand = "0180";
            }
            else if (sPIDRequest === "wait")
            {
                bWaitForNewData = true;
            }
            else if(sPIDRequest === "command_error" && iRepeatCommand > 0)
                iRepeatCommand--;
            else
            {
                bCommandOK = false;
                bCommandRunning = false;
                return;
            }
        break;
        case "findprotocol_step6":
            sPIDRequest = fncCheckPIDRequest(sData);
            if (sPIDRequest === "ready" || sPIDRequest === "error")
            {
                sCommandStateMachine = "";
                bWaitForNewData = false;
                sLastATcommand = "";
                bCommandOK = true;
                bCommandRunning = false;
            }
            else if (sPIDRequest === "wait")
            {
                bWaitForNewData = true;
            }
            else if(sPIDRequest === "command_error" && iRepeatCommand > 0)
                iRepeatCommand--;
            else
            {
                bCommandOK = false;
                bCommandRunning = false;
                return;
            }
        break;
        //*****END command sequence: find protocol*****
    }

    //Finally send the command to ELM327
    if (bWaitForNewData)        //Don't send any command. There will be more data coming in soon.
        console.log("Send Command: wait for new data...");
    else if(sLastATcommand === "")
    {
        console.log("Send ready. Leaving...");
        bCommandRunning = false;    //We are ready. No more AT commands to send.
    }
    else
    {
        console.log("Send Command: " + sLastATcommand);
        id_BluetoothData.sendHex(sLastATcommand);
    }
}

//Check if ELM is ready with current command
function fncCheckCurrentCommand(sData)
{  
    if (sData.search(/\r\r>/g) === -1)
        return false;
    else
        return true;
}

//This function checks if the protocol request was successful
function fncCheckProtocolRequest(sData)
{
    //The AT command must be at the beginning of answer of the ELM
    if (sData.indexOf(sLastATcommand) === 0 && sData.indexOf("OK") !== -1)
        return true;
    else
        return false;
}

//This function checks if the PID request is ready.
//"ready"         -> request is ready, data is OK
//"wait"          -> request is not ready, e.g bus gets initialized or ELM is searching
//"error"         -> request returned error, e.g. the mode is not supported
//"command_error" -> ELM did not understand the command
function fncCheckPIDRequest(sData)
{        
    var iMode = parseInt(sLastATcommand.substr(0, 2));
    var iAnswerMode = iMode + 40;

    if (sData.indexOf("NO DATA") !== -1 || sData.indexOf("UNABLE TO CONNECT") !== -1 || sData.indexOf("BUS INIT: ... ERROR") !== -1)
        return "error";
    else if (sData.indexOf("SEARCHING...") !== -1 || sData.indexOf("BUS INIT: OK") !== -1)
        return "wait";
    else if (sData.substr(0,2) === iAnswerMode.toString())
        return "ready";
    else if (sData.indexOf(sLastATcommand) === -1)
        return "command_error";
    else
        return "error";
}

//This function extracts data from an answer string from the ELM327.
function fncGetValue(sData)
{
    var sReturnValue = "";

    sReturnValue = sData.substring(0, sData.search(/\r/g));

    sReturnValue = sReturnValue.trim();

    return sReturnValue;
}


