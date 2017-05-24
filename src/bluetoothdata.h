#ifndef BLUETOOTHDATA
#define BLUETOOTHDATA

#include <QObject>
//#include <QtBluetooth/QBluetoothSocket>
//#include <QtBluetooth/QBluetoothAddress>
#include <../qtconnectivity-5.2_sailfish_backport/src/bluetooth/qbluetoothsocket.h>
#include <../qtconnectivity-5.2_sailfish_backport/src/bluetooth/qbluetoothaddress.h>

class BluetoothData : public QObject
{
    Q_OBJECT
public:
    explicit BluetoothData(QObject *parent = 0);
    ~BluetoothData();    
    Q_INVOKABLE void connect(QString address, int port);
    Q_INVOKABLE void sendHex(QString sString);
    Q_INVOKABLE void disconnect();
private slots:
    void readData();
    void connected();
    void disconnected();
    void error(QBluetoothSocket::SocketError errorCode);
private:
    QBluetoothSocket *_socket;
    int _port;
    qint64 write(QByteArray data);
signals:
    void sigReadDataReady(QString sData);
    void sigConnected();
    void sigDisconnected();
    void sigError(QString sError);
};


#endif // BLUETOOTHDATA
