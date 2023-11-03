#ifndef SERIALPROFILE_H
#define SERIALPROFILE_H

//#include <BluezQt/Profile>
#include <KF5/BluezQt/bluezqt/profile.h>

#include <QLocalSocket>
#include <QSharedPointer>

class SerialPortProfile : public BluezQt::Profile {
    Q_OBJECT

public:
    explicit SerialPortProfile(QObject* parent);

    QDBusObjectPath objectPath() const override;
    QString uuid() const override;

    void newConnection(BluezQt::DevicePtr device,
        const QDBusUnixFileDescriptor& fd,
        const QVariantMap& properties,
        const BluezQt::Request<>& request) override;

    void
    requestDisconnection(BluezQt::DevicePtr device, const BluezQt::Request<>& request) override;
    void release() override;

    Q_INVOKABLE void sendHex(QString sString);

private Q_SLOTS:
    void socketReadyRead();
    void socketDisconnected();
    void errorSocket(QLocalSocket::LocalSocketError);

signals:
    void dataReady(QString sData);
    void error(QString sError);
    void connected();
    void disconnected();

private:
    QSharedPointer<QLocalSocket> m_socket;
};

#endif // BLUETOOTHDATA
