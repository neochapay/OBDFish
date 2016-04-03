var sCommandStateMachine = "";
var bCommandRunning = false;

var sVoltage = "";
var sAdapterInfo = "";

function fncInitOBD()
{
    if (bCommandRunning) return;
    bCommandRunning = true;

    sCommandStateMachine = "initobd";
    id_BluetoothData.sendHex("AT L0");
}

function fncReadAdapterInfo()
{
    if (bCommandRunning) return;
    bCommandRunning = true;

    sCommandStateMachine = "adapterinfo";
    id_BluetoothData.sendHex("ATI");
}

function fncReadVoltage()
{
    if (bCommandRunning) return;
    bCommandRunning = true;

    sCommandStateMachine = "voltage";
    id_BluetoothData.sendHex("AT RV");
}

//Receive data from OBD adapter
function fncGetData(sData)
{
    //this is the OBD command state machine

    if (sCommandStateMachine === "voltage")
    {
        //Example:
        //AT RV 11.4  >
        sData = sData.trim();

        if (sData.indexOf("AT RV") === 0)
        {
            sVoltage = sData.substr(6);
            sVoltage = sVoltage.substr(0, sVoltage - 1);
            sVoltage = sVoltage.trim();
        }
        else
        {
            //Error reading. Did not receive correct echo from ELM
        }

        bCommandRunning = false;
    }
    if (sCommandStateMachine === "adapterinfo")
    {
        //Example:
        //ATZ   ELM327 v2.1  >

        bCommandRunning = false;
    }
    if (sCommandStateMachine === "initobd")
    {
        //Example:
        //AT L0 OK  >

        bCommandRunning = false;
    }
}
