var sCommandStateMachine = "";
var bCommandRunning = false;
var sLastATcommand = "";

var sVoltage = "";
var sAdapterInfo = "";

//This function accepts a command to send to OBD adapter
//return 1: processing command
//return -1: an other command is currently active
//return -2: unknown command
//List of commands: init, adapterinfo, voltage, setprotocol
function fncStartCommand(sCommand)
{
    if (bCommandRunning) return -1;
    bCommandRunning = true;

    sCommandStateMachine = sCommand;

    //Call the state machine to decide what to do next
    return fncGetData("");
}


 //   id_BluetoothData.sendHex("ATI");
   // id_BluetoothData.sendHex("AT RV");


//Receive data from OBD adapter
//This is the OBD command state machine
function fncGetData(sData)
{        
    var iReturn = -2;

    //Get rid of any spaces
    sData = sData.trim();

    switch(sCommandStateMachine)
    {
        //*****START command sequence: init*****
        case "init":
            iReturn = 1;

            sCommandStateMachine = "init_step1"

            sLastATcommand = "AT Z";

        break;
        case "init_step1":
            Return = 1;

            sCommandStateMachine = "init_step2"

            sLastATcommand = "AT D";
        break;
        case "init_step2":
            iReturn = 1;

            sCommandStateMachine = "init_step3"

            sLastATcommand = "AT L0";
        break;
        case "init_step3":
            iReturn = 1;

            sCommandStateMachine = "init_step4"

            sLastATcommand = "AT H0";
        break;
        case "init_step4":
            iReturn = 1;

            sCommandStateMachine = ""

            sLastATcommand = "";
        break;
        //*****END command sequence: init*****

        //*****START command sequence: adapterinfo*****
        case "adapterinfo":
            iReturn = 1;

            sCommandStateMachine = "adapterinfo_step1"

            sLastATcommand = "AT I";
        break;
        case "adapterinfo_step1":
            //Example:
            //ATZ   ELM327 v2.1  >
            iReturn = 1;

            sCommandStateMachine = ""

            sLastATcommand = "";
        break;
        //*****END command sequence: adapterinfo*****

        //*****START command sequence: voltage*****
        case "adapterinfo":
            iReturn = 1;

            sCommandStateMachine = "voltage_step1"

            sLastATcommand = "AT RV";
        break;
        case "voltage_step1":
            //Example:
             //AT RV 11.4  >
            iReturn = 1;

            sCommandStateMachine = ""

            sLastATcommand = "";
        break;
        //*****END command sequence: voltage*****


    }

    //Finally send the command to ELM327
    if (sLastATcommand !== "")
        id_BluetoothData.sendHex(sLastATcommand);
    else
    {
        bCommandRunning = false;    //We are ready. No more AT to send.
    }

    return iReturn;
}

//This function checks if the ELM understood the given AT command or not.
function fncCheckCurrentCommand(sData)
{
    //The AT command must be at the beginning of answer of the ELM
    if (sData.indexOf(sLastATcommand) === 0)
        return true;
    else
        return false;
}
