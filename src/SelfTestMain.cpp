#include <QGuiApplication>
#include <QCoreApplication>

#include "SelfTest.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QCoreApplication::setOrganizationName(QStringLiteral("PoliceRegistry"));
    QCoreApplication::setApplicationName(QStringLiteral("PoliceRegistrySelfTest"));
    return runSelfTest();
}
