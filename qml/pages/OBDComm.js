var sCommandStateMachine = "";
var bCommandRunning = false;
var bCommandOK = false;
var sLastATcommand = "";
var iRepeatCommand = 0;

var sVoltage = "Voltage";
var sAdapterInfo = "Info";

//This function accepts a command to send to OBD adapter
//List of commands: init, adapterinfo, voltage, setprotocol
function fncStartCommand(sCommand)
{
    if (bCommandRunning) return;
    bCommandRunning = true;

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

    switch(sCommandStateMachine)
    {
        //*****START command sequence: init*****
        case "init":           
            sCommandStateMachine = "init_step1"
            iRepeatCommand = 3;
            sLastATcommand = "AT Z";            
        break;
        case "init_step1":          
            sCommandStateMachine = "init_step2"

            //Check if last step was OK
            if (fncCheckCurrentCommand(sData) === true)
                sLastATcommand = "AT D";
            else if(iRepeatCommand > 0)
                iRepeatCommand--;
            else
            {
                bCommandOK = false;
                bCommandRunning = false;
                return;
            }
        break;
        case "init_step2":            
            sCommandStateMachine = "init_step3"

            sLastATcommand = "AT L0";
        break;
        case "init_step3":           
            sCommandStateMachine = "init_step4"

            sLastATcommand = "AT H0";
        break;
        case "init_step4":           
            sCommandStateMachine = ""

            sLastATcommand = "";
        break;
        //*****END command sequence: init*****

        //*****START command sequence: adapterinfo*****
        case "adapterinfo":           
            sCommandStateMachine = "adapterinfo_step1"

            sLastATcommand = "AT I";
        break;
        case "adapterinfo_step1":
            //Example:
            //ATZ   ELM327 v2.1  >           
            sCommandStateMachine = ""

            sLastATcommand = "";
        break;
        //*****END command sequence: adapterinfo*****

        //*****START command sequence: voltage*****
        case "adapterinfo":           
            sCommandStateMachine = "voltage_step1"

            sLastATcommand = "AT RV";
        break;
        case "voltage_step1":
            //Example:
             //AT RV 11.4  >           
            sCommandStateMachine = ""

            sLastATcommand = "";
        break;
        //*****END command sequence: voltage*****


    }

    //Finally send the command to ELM327
    if (sLastATcommand !== "")
        id_BluetoothData.sendHex(sLastATcommand);
    else
        bCommandRunning = false;    //We are ready. No more AT commands to send.
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
