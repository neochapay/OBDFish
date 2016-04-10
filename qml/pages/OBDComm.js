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
            sCommandStateMachine = "init_step1";
            iRepeatCommand = 3;
            sLastATcommand = "AT Z";            
        break;
        case "init_step1":
            if (fncCheckCurrentCommand(sData) === true)     //Command OK, next one...
            {
                sCommandStateMachine = "init_step2";
                iRepeatCommand = 3;
                sLastATcommand = "AT D";                
            }
            else if(iRepeatCommand > 0)                 //Not OK. Repeat same command.
                iRepeatCommand--;
            else                                        //Multiple times not OK.
            {
                bCommandOK = false;
                bCommandRunning = false;
                return;
            }
        break;
        case "init_step2":
            if (fncCheckCurrentCommand(sData) === true)
            {
                sCommandStateMachine = "init_step3";
                iRepeatCommand = 3;
                sLastATcommand = "AT L0";
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
        case "init_step3":                       
            if (fncCheckCurrentCommand(sData) === true)
            {
                sCommandStateMachine = "init_step4";
                iRepeatCommand = 3;
                sLastATcommand = "AT H0";
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
        case "init_step4":                       
            if (fncCheckCurrentCommand(sData) === true)
            {
                //Sequence is done now. Everything good.
                sCommandStateMachine = "";
                sLastATcommand = "";
                bCommandOK = true;
                bCommandRunning = false;
                return;
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
        //*****END command sequence: init*****

        //*****START command sequence: adapterinfo*****       
        case "adapterinfo":
            sCommandStateMachine = "adapterinfo_step1";
            iRepeatCommand = 3;
            sLastATcommand = "AT I";
        break;
        case "adapterinfo_step1":
            //Example: AT I   ELM327 v2.1  >
            if (fncCheckCurrentCommand(sData) === true)     //Command OK, next one...
            {
                //Sequence is done now. Extract value.
                sAdapterInfo = fncGetValue(sData);

                sCommandStateMachine = "";
                sLastATcommand = "";
                bCommandOK = true;
                bCommandRunning = false;
                return;
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
        //*****END command sequence: adapterinfo*****

        //*****START command sequence: voltage*****
        case "voltage":
            sCommandStateMachine = "voltage_step1";
            iRepeatCommand = 3;
            sLastATcommand = "AT RV";
        break;
        case "voltage_step1":
             //AT RV 11.4  >
            if (fncCheckCurrentCommand(sData) === true)     //Command OK, next one...
            {
                //Sequence is done now. Extract value.
                sVoltage = fncGetValue(sData);

                sCommandStateMachine = "";
                sLastATcommand = "";
                bCommandOK = true;
                bCommandRunning = false;
                return;
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
        //*****END command sequence: voltage*****


    }

    //Finally send the command to ELM327
    if (sLastATcommand !== "")
    {
        console.log("Send Command: " + sLastATcommand);
        id_BluetoothData.sendHex(sLastATcommand);
    }
    else
    {
        console.log("Send ready. Leaving...");
        bCommandRunning = false;    //We are ready. No more AT commands to send.
    }
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

//This function extracts data from an answer string from the ELM327.
function fncGetValue(sData)
{
    var sReturnValue = "";

    console.log("fncGetValue: " + sData);

    sReturnValue = sData.substr(sLastATcommand.length); //cut off command at the beginning
    console.log("fncGetValue: " + sReturnValue);

    sReturnValue = sReturnValue.substring(0, (sReturnValue.lastIndexOf(">") - 1));
    console.log("fncGetValue: " + sReturnValue);

    sReturnValue = sReturnValue.trim();
    console.log("fncGetValue: " + sReturnValue);


    return sReturnValue;
}


