#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>

#include "DatabaseManager.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QCoreApplication::setOrganizationName(QStringLiteral("PoliceRegistry"));
    QCoreApplication::setOrganizationDomain(QStringLiteral("police-registry.local"));
    QCoreApplication::setApplicationName(QStringLiteral("PoliceRegistry"));
    QCoreApplication::setApplicationVersion(QStringLiteral(APP_VERSION));

    QQmlApplicationEngine engine;

    DatabaseManager dbManager;
    engine.rootContext()->setContextProperty(QStringLiteral("dbManager"), &dbManager);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.loadFromModule("policedep", "Main");

    return app.exec();
}
