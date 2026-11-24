#ifndef DATABASEMANAGER_H
#define DATABASEMANAGER_H

#include <QDateTime>
#include <QObject>
#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>
#include <QStringList>
#include <QUrl>
#include <QVariantList>
#include <QVariantMap>

/*
 * Единая точка доступа к SQLite: сессия, сотрудники, личности, дела,
 * вещественные доказательства, фотографии, поиск и 2FA.
 *
 * Все изменяющие методы возвращают QVariantMap вида
 * { ok: bool, error: string, ... } — это позволяет QML показывать
 * пользователю понятную причину ошибки вместо bool.
 */
class DatabaseManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString databasePath READ databasePath CONSTANT)

public:
    explicit DatabaseManager(QObject *parent = nullptr, const QString &databasePath = QString());
    ~DatabaseManager();

    QString databasePath() const;

    // ---------- Сессия и аутентификация ----------
    Q_INVOKABLE bool hasUsers();
    Q_INVOKABLE bool isAuthenticated() const;
    Q_INVOKABLE QVariantMap authenticate(const QString &login, const QString &password);
    Q_INVOKABLE QVariantMap verifyTwoFactor(const QString &code);
    Q_INVOKABLE QVariantMap cancelTwoFactor();
    Q_INVOKABLE QVariantMap currentUser();
    Q_INVOKABLE void logout();

    // ---------- Регистрация и сотрудники ----------
    Q_INVOKABLE QVariantMap createOfficer(const QVariantMap &data);
    Q_INVOKABLE QVariantList getOfficers();
    Q_INVOKABLE QVariantMap getOfficer(int officerId);
    Q_INVOKABLE QVariantMap updateOfficer(const QVariantMap &data);
    Q_INVOKABLE QVariantMap removeOfficer(int officerId);
    Q_INVOKABLE QVariantMap setOfficerApproval(int officerId, bool approved);
    Q_INVOKABLE QVariantMap setOfficerRole(int officerId, const QString &role);
    Q_INVOKABLE bool isLoginFree(const QString &login, int exceptOfficerId = 0);

    // ---------- Личности ----------
    Q_INVOKABLE QVariantList getPersons();
    Q_INVOKABLE QVariantMap getPerson(int personId);
    Q_INVOKABLE QVariantMap createPerson(const QVariantMap &data);
    Q_INVOKABLE QVariantMap updatePerson(const QVariantMap &data);
    Q_INVOKABLE QVariantMap removePerson(int personId);

    // ---------- Дела ----------
    Q_INVOKABLE QVariantList getCases();
    Q_INVOKABLE QVariantMap getCase(int caseId);
    Q_INVOKABLE QVariantList getCaseOptions();
    Q_INVOKABLE QVariantMap createCase(const QVariantMap &data);
    Q_INVOKABLE QVariantMap updateCase(const QVariantMap &data);
    Q_INVOKABLE QVariantMap removeCase(int caseId, bool cascade = false);

    // ---------- Вещественные доказательства ----------
    Q_INVOKABLE QVariantList getEvidence();
    Q_INVOKABLE QVariantMap getEvidenceItem(int evidenceId);
    Q_INVOKABLE QVariantMap createEvidence(const QVariantMap &data);
    Q_INVOKABLE QVariantMap updateEvidence(const QVariantMap &data);
    Q_INVOKABLE QVariantMap removeEvidence(int evidenceId);

    // ---------- Фотографии ----------
    Q_INVOKABLE QVariantMap setOfficerPhoto(int officerId, const QUrl &source);
    Q_INVOKABLE QVariantMap removeOfficerPhoto(int officerId);
    Q_INVOKABLE QVariantMap setPersonPhoto(int personId, const QUrl &source);
    Q_INVOKABLE QVariantMap removePersonPhoto(int personId);

    // ---------- Безопасность учётной записи ----------
    Q_INVOKABLE QVariantMap changePassword(const QString &currentPassword, const QString &newPassword);
    Q_INVOKABLE QVariantMap beginTwoFactorSetup();
    Q_INVOKABLE QVariantMap confirmTwoFactorSetup(const QString &code);
    Q_INVOKABLE QVariantMap disableTwoFactor(const QString &password, const QString &code);
    Q_INVOKABLE QVariantMap regenerateRecoveryCodes();
    Q_INVOKABLE int remainingRecoveryCodes();

    // ---------- Дашборд и поиск ----------
    Q_INVOKABLE QVariantMap getDashboardStats();
    Q_INVOKABLE QVariantMap searchAll(const QString &query);

    private:
    bool initDatabase();
    bool createTables();
    bool migrateSchema();
    bool execSql(QSqlQuery &query, const QString &sql);
    bool execSql(const QString &sql);

    QVariantMap errorResult(const QString &message) const;
    QVariantMap successResult() const;
    QVariantMap requireAuth() const;
    QVariantMap requireAdmin() const;

    QString hashPassword(const QString &password) const;
    bool verifyPassword(const QString &password, const QString &stored) const;
    static bool constantTimeEquals(const QByteArray &left, const QByteArray &right);
    static QString generateSalt();

    QVariantMap userMap(int officerId) const;
    void applyLogin(const QString &login);

    static QString normalizeDate(const QString &value, bool *ok);
    static QString normalizeDateTime(const QString &value, bool *ok);
    static QString nowIso();
    static int yearsSince(const QString &isoDate);
    static bool isValidLogin(const QString &login);
    static bool isValidPassword(const QString &password, QString *reason = nullptr);
    static bool isValidEmail(const QString &email);
    static bool isValidPhone(const QString &phone);

    QString photoDirectory() const;
    QString writePhotoFile(const QString &prefix, int id, const QUrl &source, QString *error);
    QString photoUrlForFile(const QString &fileName) const;
    bool deletePhotoFile(const QString &fileName);
    void migrateLegacyPhotos();
    bool ensureColumn(const QString &table, const QString &column, const QString &definition);

    int currentOfficerId() const { return m_currentOfficerId; }
    int countAdmins(int exceptOfficerId = 0) const;
    QString loginForOfficer(int officerId) const;

    QSqlDatabase m_database;
    QString m_databasePath;

    int m_currentOfficerId = 0;
    int m_pendingOfficerId = 0;
    int m_pending2faAttempts = 0;
    QDateTime m_pendingCreatedAt;
    QString m_pendingTotpSecret;
};

#endif // DATABASEMANAGER_H
