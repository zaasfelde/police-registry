#ifndef DATABASEMANAGER_H
#define DATABASEMANAGER_H

#include <QObject>
#include <QtSql/QSqlDatabase>
#include <QtSql/QSqlQuery>
#include <QtSql/QSqlError>
#include <QCryptographicHash>
#include <QVariantMap>
#include <QDebug>
#include <QDir>
#include <QStandardPaths>

class DatabaseManager : public QObject
{
    Q_OBJECT

public:
    explicit DatabaseManager(QObject *parent = nullptr);
    ~DatabaseManager();

    // Методы аутентификации
    Q_INVOKABLE bool registerOfficer(const QVariantMap &officerData);
    Q_INVOKABLE bool verifyLogin(const QString &login, const QString &password);
    Q_INVOKABLE bool isLoginExists(const QString &login);

    // Методы для работы с таблицей officers
    Q_INVOKABLE bool addOfficer(const QVariantMap &officerData);
    Q_INVOKABLE QVariantList getAllOfficers();
    Q_INVOKABLE bool deleteOfficer(int officerId);

    // Методы для работы с таблицей persons
    Q_INVOKABLE bool addPerson(const QVariantMap &personData);
    Q_INVOKABLE QVariantList getAllPersons();
    Q_INVOKABLE bool deletePerson(int personId);

    // Методы для работы с таблицей cases
    Q_INVOKABLE bool addCase(const QVariantMap &caseData);
    Q_INVOKABLE QVariantList getAllCases();
    Q_INVOKABLE bool deleteCase(int caseId);

    // Методы для работы с таблицей evidence
    Q_INVOKABLE bool addEvidence(const QVariantMap &evidenceData);
    Q_INVOKABLE QVariantList getAllEvidence();
    Q_INVOKABLE bool deleteEvidence(int evidenceId);

    // Методы для работы с фото сотрудников
    Q_INVOKABLE bool updateEmployeePhoto(int officerId, const QString &photoPath);
    Q_INVOKABLE bool removeEmployeePhoto(int officerId);
    Q_INVOKABLE QString getEmployeePhoto(int officerId);

private:
    bool initDatabase();
    bool createTables();
    QString hashPassword(const QString &password);
    QSqlDatabase m_database;
};

#endif // DATABASEMANAGER_H
