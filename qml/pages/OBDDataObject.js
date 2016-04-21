.pragma library

function checkHex(n)
{
    return/^[0-9A-Fa-f]{1,64}$/.test(n);
}
function hex2Bin(n)
{
    if(!checkHex(n)){
        return 0;
    }
    return zeroFill(parseInt(n,16).toString(2),4);
}
function zeroFill( number, width )
{
  width -= number.toString().length;
  if ( width > 0 )
  {
    return new Array( width + (/\./.test( number ) ? 2 : 1) ).join( '0' ) + number;
  }
  return number + ""; // always return a string
}
function convertPIDSupported(byteA, byteB, byteC, byteD)
{
    var hexstring = byteA + byteB + byteC + byteD;
    var pidHex = hexstring.split('');
    var pidStatus = [];
    pidHex.forEach(function(hex)
    {
        var hexPerm = hex2Bin(hex).split('');
        hexPerm.forEach(function(perm)
        {
            pidStatus.push( perm === "1" ? true : false );
        });
    });
    return pidStatus;
}
function convertTemp(byte)
{
    return parseInt(byte, 16) - 40;
}


var arrayOBDData = new Array
([
    {mode: initialize, pid: "0100", len_bytes: 4, name: "pid_supp_01-20", convertFunction: convertPIDSupported},
    {mode: pageEngine, pid: "0105", len_bytes: 1, name: "engine_temp",    convertFunction: convertTemp},
    {mode: pageEngine, pid: "010F", len_bytes: 1, name: "engine_intake",  convertFunction: convertTemp},
    {mode: initialize, pid: "0120", len_bytes: 4, name: "pid_supp_21-40", convertFunction: convertPIDSupported},
    {mode: initialize, pid: "0140", len_bytes: 4, name: "pid_supp_41-60", convertFunction: convertPIDSupported},
    {mode: initialize, pid: "0160", len_bytes: 4, name: "pid_supp_61-80", convertFunction: convertPIDSupported},
    {mode: initialize, pid: "0180", len_bytes: 4, name: "pid_supp_81-A0", convertFunction: convertPIDSupported}
]);
