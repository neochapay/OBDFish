#include "filewriter.h"
#include <QFile>
#include <QTextStream>

FileWriter::FileWriter(QObject *parent) : QObject(parent)
{
}

void FileWriter::vWriteData(const QString &msg)
{
    QFile file("/home/nemo/Documents/obd_log.txt");

    if(file.open(QIODevice::WriteOnly))
    {
        QTextStream stream(&file);
        stream << msg << endl;
    }

    return;
}
