#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>
#include <QCryptographicHash>
#include "DatabaseManager.h"

class MyObject : public QObject {
    Q_OBJECT
public:
    explicit MyObject(QObject *parent = nullptr) : QObject(parent) {}

    Q_INVOKABLE void myCppFunction(const QString& msg) {
        qDebug() << "function called from qml: " << msg;
    }
};

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;

    // Создаем объекты ДО загрузки QML
    MyObject myCppObject;
    DatabaseManager dbManager;

    // Регистрируем объекты в контексте QML
    engine.rootContext()->setContextProperty("cppObject", &myCppObject);
    engine.rootContext()->setContextProperty("dbManager", &dbManager);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    // Загружаем QML после регистрации объектов
    engine.loadFromModule("policedep", "Main");

    return app.exec();
}

#include "main.moc"
