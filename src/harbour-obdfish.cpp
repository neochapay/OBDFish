/*
 * Copyright (C) 2016 Jens Drescher, Germany
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#ifdef QT_QML_DEBUG
#include <QtQuick>
#endif

#include <sailfishapp.h>
#include "../src/bluetoothconnection.h"
#include "../src/bluetoothdata.h"
#include "../src/filewriter.h"
#include "../src/projectsettings.h"
#include "../src/plotwidget.h"


int main(int argc, char *argv[])
{
    qmlRegisterType<PlotWidget,1>("harbour.obdfish", 1, 0, "PlotWidget");
    qmlRegisterType<BluetoothConnection,1>("harbour.obdfish", 1, 0, "BluetoothConnection");
    qmlRegisterType<BluetoothData,1>("harbour.obdfish", 1, 0, "BluetoothData");
    qmlRegisterType<FileWriter,1>("harbour.obdfish", 1, 0, "FileWriter");
    qmlRegisterType<ProjectSettings,1>("harbour.obdfish", 1, 0, "ProjectSettings");
    return SailfishApp::main(argc, argv);
}

