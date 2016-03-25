#include "bluetoothdata.h"
#include <qbluetoothsocket.h>

BluetoothData::BluetoothData (QObject *parent):QObject(parent)
{

}

BluetoothData::~BluetoothData ()
{
    if(this->_socket)
        delete this->_socket;
}

void BluetoothData::connect(QString address, int port)
{
    this->_port = port;
    qDebug("Trying to connect to: %s_%d", address.toUtf8().constData(), _port);

    if(this->_socket)
        delete this->_socket;

    this->_socket = new QBluetoothSocket(QBluetoothServiceInfo::RfcommProtocol);

    QObject::connect(this->_socket, SIGNAL(connected()), this, SLOT(connected()));
    QObject::connect(this->_socket, SIGNAL(disconnected()), this, SLOT(disconnected()));
    QObject::connect(this->_socket, SIGNAL(error(QBluetoothSocket::SocketError)), this, SLOT(error(QBluetoothSocket::SocketError)));
    QObject::connect(this->_socket, SIGNAL(readyRead()), this, SLOT(readData()));

    qDebug("Connecting...");
    this->_socket->connectToService(QBluetoothAddress(address), this->_port);
}

void BluetoothData::connected()
{
    qDebug() << "Connected: " << this->_socket->peerName();

    //emit connected(socket->peerName());
}
void BluetoothData::disconnected()
{
    qDebug() << "Disconnected!";
}
void BluetoothData::error(QBluetoothSocket::SocketError errorCode)
{
    qDebug() << "Error: " << this->_socket->errorString();
    qDebug() << "Errorcode: " << errorCode;
}


void BluetoothData::disconnect()
{
    qDebug("Disconnecting...");

    if(!this->_socket)
        return;

    if(this->_socket->isOpen())
        this->_socket->close();

    delete this->_socket;
    this->_socket = 0;

    qDebug("Disconnected.");
}

void BluetoothData::readData()
{
    qDebug("Entering readData...");

    QByteArray data = _socket->readAll();
    qDebug() << "Data size:" << data.size();
    qDebug() << "Data[" + QString::number(_port) + "]:" << data.toHex();

    //TODO!!!
}

void BluetoothData::sendHex(QString hexString)
{
    QByteArray data = QByteArray::fromHex(hexString.toLatin1());
    this->write(data);
}

qint64 BluetoothData::write(QByteArray data)
{
    qDebug() << "Writing:" << data.toHex();
    //qint64 ret = this->_socket->write(data);
    qint64 ret = this->_socket->write("ATZ\r\n");
    qDebug() << "Write returned:" << ret;
    return ret;
}
