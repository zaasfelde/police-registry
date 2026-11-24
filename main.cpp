#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QDebug>
#include <QDir>
#include <QFileInfo>

#include "DatabaseManager.h"
#include "PhotoImageProvider.h"
#include "ReferenceData.h"
#include "UiSmoke.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QCoreApplication::setOrganizationName(QStringLiteral("PoliceRegistry"));
    QCoreApplication::setOrganizationDomain(QStringLiteral("police-registry.local"));
    QCoreApplication::setApplicationName(QStringLiteral("PoliceRegistry"));
    QCoreApplication::setApplicationVersion(QStringLiteral(APP_VERSION));

    // Базовая стилизация Qt Quick Controls: наш интерфейс полностью
    // кастомный, нативная тема Windows не поддерживает переопределение.
    QQuickStyle::setStyle(QStringLiteral("Basic"));

    const bool uiSmoke = app.arguments().contains(QStringLiteral("--ui-smoke"));
    QString databasePath;
    if (uiSmoke) {
        const QString smokeDir = QDir::currentPath() + QStringLiteral("/.ui-smoke");
        QDir(smokeDir).removeRecursively();
        databasePath = smokeDir + QStringLiteral("/policedepartment.db");
    }

    DatabaseManager dbManager(nullptr, databasePath);
    ReferenceData referenceData;
    QQmlApplicationEngine engine;

    engine.rootContext()->setContextProperty(QStringLiteral("dbManager"), &dbManager);
    engine.rootContext()->setContextProperty(QStringLiteral("refData"), &referenceData);

    if (!dbManager.databasePath().isEmpty()) {
        const QString photoDir = QFileInfo(dbManager.databasePath()).absolutePath()
                                 + QStringLiteral("/photos");
        engine.addImageProvider(QStringLiteral("photo"), new PhotoImageProvider(photoDir));
    }

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    if (uiSmoke)
        return runUiSmoke(dbManager, engine);

    engine.loadFromModule("policedep", "Main");

    return app.exec();
}
