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

#include "filewriter.h"
#include "plotwidget.h"
#include "projectsettings.h"
#include "serialportprofile.h"

#include <sailfishapp.h>

#include <KF5/BluezQt/bluezqt/initmanagerjob.h>
#include <KF5/BluezQt/bluezqt/manager.h>
#include <KF5/BluezQt/bluezqt/pendingcall.h>

int main(int argc, char* argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    app->setApplicationVersion(QString(APP_VERSION));
    app->setApplicationName("obdfish");
    app->setOrganizationName("org.harbour");

    BluezQt::Manager* manager = new BluezQt::Manager();
    BluezQt::InitManagerJob* initJob = manager->init();
    initJob->exec();

    if (initJob->error()) {
        qWarning() << "Error initializing manager:" << initJob->errorText();
        return 1;
    }

    SerialPortProfile* profile = new SerialPortProfile(app.data());
    BluezQt::PendingCall* spp = manager->registerProfile(profile);
    spp->waitForFinished();

    if (spp->error()) {
        qWarning() << "Error registering profile" << spp->errorText();
        return 1;
    }

    qDebug() << "Profile registered";

    qmlRegisterType<PlotWidget, 1>("harbour.obdfish", 1, 0, "PlotWidget");
    qmlRegisterType<FileWriter, 1>("harbour.obdfish", 1, 0, "FileWriter");
    qmlRegisterType<ProjectSettings, 1>("harbour.obdfish", 1, 0, "ProjectSettings");

    QQuickView* view = SailfishApp::createView();
    view->rootContext()->setContextProperty("obdConnection", profile);

    view->setSource(SailfishApp::pathTo("qml/org.harbour.obdfish.qml"));
    view->show();

    return app->exec();
}
