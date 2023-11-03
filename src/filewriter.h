#ifndef FILEWRITER
#define FILEWRITER

#include <QGuiApplication>
#include <QObject>
#include <QQuickView>
#include <QtQml>

class FileWriter : public QObject {
    Q_OBJECT
public:
    explicit FileWriter(QObject* parent = 0);
    Q_INVOKABLE void vWriteData(const QString& msg);
    Q_INVOKABLE void vWriteStart(const QString& msg);
};

#endif // FILEWRITER
