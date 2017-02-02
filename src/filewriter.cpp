#include "filewriter.h"
#include <QFile>
#include <QTextStream>

FileWriter::FileWriter(QObject *parent) : QObject(parent)
{
}

void FileWriter::vWriteStart(const QString &msg)
{
    QFile file("$HOME/Documents/obd_log.txt");

    if(file.open(QIODevice::WriteOnly))
    {
        QTextStream stream(&file);
        stream << msg << endl;
    }

    file.flush();   //write at once!
    file.close();   //close file!

    return;
}

void FileWriter::vWriteData(const QString &msg)
{
    QFile file("$HOME/Documents/obd_log.txt");

    //if(file.open(QIODevice::WriteOnly))
    if(file.open(QIODevice::Append))
    {
        QTextStream stream(&file);
        stream << QTime::currentTime().toString() << " " << msg << endl;
    }

    file.flush();   //write at once!
    file.close();   //close file!

    return;
}
