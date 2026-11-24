#include "DatabaseManager.h"
#include "ReferenceData.h"
#include "TotpAuth.h"

#include <QCryptographicHash>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QImage>
#include <QImageReader>
#include <QPainter>
#include <QPasswordDigestor>
#include <QRandomGenerator>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QUrl>
#include <QVector>
#include <cstring>

namespace {

constexpr int kPbkdf2Iterations = 210000;
constexpr int kMaxFailedAttempts = 5;
constexpr int kLockMinutes = 5;
constexpr int kPending2faMinutes = 5;
constexpr int kMaxPhotoDimension = 1400;
constexpr qint64 kMaxPhotoBytes = 15LL * 1024 * 1024;

QString mapString(const QVariantMap &map, const char *key)
{
    return map.value(QLatin1String(key)).toString().trimmed();
}

QString mapString(const QVariantMap &map, const char *key, const char *fallbackKey)
{
    const QString value = mapString(map, key);
    return value.isEmpty() ? mapString(map, fallbackKey) : value;
}

QString fullName(const QString &last, const QString &first, const QString &middle)
{
    QStringList parts;
    if (!last.trimmed().isEmpty())
        parts << last.trimmed();
    if (!first.trimmed().isEmpty())
        parts << first.trimmed();
    if (!middle.trimmed().isEmpty())
        parts << middle.trimmed();
    return parts.join(QLatin1Char(' '));
}

QString makeShortFio(const QString &last, const QString &first, const QString &middle)
{
    QString result = last.trimmed();
    if (!first.trimmed().isEmpty())
        result += QLatin1Char(' ') + first.trimmed().left(1) + QLatin1Char('.');
    if (!middle.trimmed().isEmpty())
        result += QLatin1Char(' ') + middle.trimmed().left(1) + QLatin1Char('.');
    return result.trimmed();
}

} // namespace

DatabaseManager::DatabaseManager(QObject *parent, const QString &databasePath)
    : QObject(parent)
    , m_databasePath(databasePath)
{
    if (!initDatabase())
        qWarning() << "Не удалось инициализировать базу данных";
}

DatabaseManager::~DatabaseManager()
{
    if (m_database.isOpen())
        m_database.close();
}

QString DatabaseManager::databasePath() const
{
    return m_databasePath;
}

// ---------------------------------------------------------------------------
// Инициализация и схема
// ---------------------------------------------------------------------------

bool DatabaseManager::initDatabase()
{
    if (m_databasePath.isEmpty()) {
        // Основное место — общий каталог данных приложения. Если он
        // недоступен (например, запуск из защищённой папки), пробуем
        // резервные варианты, чтобы приложение оставалось рабочим.
        QStringList candidates;
        const QString genericData = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation);
        if (!genericData.isEmpty())
            candidates << genericData + QStringLiteral("/PoliceRegistry");
        candidates << QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
        candidates << QDir::currentPath() + QStringLiteral("/data");
        candidates << QStandardPaths::writableLocation(QStandardPaths::TempLocation) + QStringLiteral("/PoliceRegistry");

        for (const QString &dir : candidates) {
            if (dir.isEmpty())
                continue;
            if (QDir().mkpath(dir)) {
                m_databasePath = dir + QStringLiteral("/policedepartment.db");
                break;
            }
        }

        if (m_databasePath.isEmpty()) {
            qWarning() << "Не удалось найти каталог для базы данных";
            return false;
        }
    }

    const QFileInfo dbInfo(m_databasePath);
    if (!QDir().mkpath(dbInfo.absolutePath())) {
        qWarning() << "Не удалось создать каталог для БД:" << dbInfo.absolutePath();
        return false;
    }
    m_databasePath = dbInfo.absoluteFilePath();

    m_database = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"));
    m_database.setDatabaseName(m_databasePath);

    if (!m_database.open()) {
        qWarning() << "Не удалось открыть БД:" << m_database.lastError().text();
        return false;
    }

    QSqlQuery pragma(m_database);
    pragma.exec(QStringLiteral("PRAGMA foreign_keys = ON"));
    pragma.exec(QStringLiteral("PRAGMA journal_mode = WAL"));
    pragma.exec(QStringLiteral("PRAGMA busy_timeout = 5000"));

    if (!createTables())
        return false;

    qInfo() << "База данных:" << m_databasePath;
    return migrateSchema();
}

bool DatabaseManager::execSql(QSqlQuery &query, const QString &sql)
{
    if (!query.prepare(sql)) {
        qWarning() << "SQL prepare error:" << query.lastError().text() << sql;
        return false;
    }
    if (!query.exec()) {
        qWarning() << "SQL exec error:" << query.lastError().text() << query.lastQuery();
        return false;
    }
    return true;
}

bool DatabaseManager::execSql(const QString &sql)
{
    QSqlQuery query(m_database);
    return execSql(query, sql);
}

bool DatabaseManager::createTables()
{
    const QStringList statements = {
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS officers ("
            "officer_id INTEGER PRIMARY KEY AUTOINCREMENT, "
            "last_name TEXT NOT NULL, "
            "name TEXT NOT NULL, "
            "patronymic TEXT, "
            "rank TEXT NOT NULL DEFAULT '', "
            "rank_category TEXT NOT NULL DEFAULT 'Полиция', "
            "position TEXT NOT NULL DEFAULT '', "
            "birth_date TEXT, "
            "personnel_number TEXT, "
            "hire_date TEXT, "
            "experience INTEGER DEFAULT 0, "
            "phone TEXT, "
            "email TEXT, "
            "system_login TEXT, "
            "password_hash TEXT, "
            "photo_path TEXT, "
            "role TEXT NOT NULL DEFAULT 'officer', "
            "is_approved INTEGER NOT NULL DEFAULT 0, "
            "totp_secret TEXT, "
            "totp_enabled INTEGER NOT NULL DEFAULT 0, "
            "failed_attempts INTEGER NOT NULL DEFAULT 0, "
            "locked_until TEXT, "
            "last_login TEXT, "
            "created_at TEXT, "
            "updated_at TEXT)"),
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS cases ("
            "case_id INTEGER PRIMARY KEY AUTOINCREMENT, "
            "case_number TEXT NOT NULL UNIQUE, "
            "title TEXT NOT NULL, "
            "description TEXT, "
            "date_opened TEXT NOT NULL, "
            "date_closed TEXT, "
            "status TEXT NOT NULL DEFAULT 'Возбуждено', "
            "investigator_id INTEGER, "
            "created_at TEXT, "
            "updated_at TEXT, "
            "FOREIGN KEY(investigator_id) REFERENCES officers(officer_id) ON DELETE SET NULL)"),
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS persons ("
            "person_id INTEGER PRIMARY KEY AUTOINCREMENT, "
            "last_name TEXT NOT NULL, "
            "name TEXT NOT NULL, "
            "patronymic TEXT, "
            "birth_date TEXT, "
            "address TEXT, "
            "phone TEXT, "
            "description TEXT, "
            "criminal_record INTEGER NOT NULL DEFAULT 0, "
            "status TEXT NOT NULL DEFAULT 'Подозреваемый', "
            "case_id INTEGER, "
            "photo_path TEXT, "
            "created_at TEXT, "
            "updated_at TEXT, "
            "FOREIGN KEY(case_id) REFERENCES cases(case_id) ON DELETE SET NULL)"),
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS evidence ("
            "evidence_id INTEGER PRIMARY KEY AUTOINCREMENT, "
            "type TEXT NOT NULL DEFAULT 'Прочее', "
            "description TEXT NOT NULL, "
            "registration_date TEXT NOT NULL, "
            "current_status TEXT NOT NULL DEFAULT 'Изъято', "
            "case_id INTEGER, "
            "storage_location TEXT, "
            "created_by INTEGER, "
            "created_at TEXT, "
            "updated_at TEXT, "
            "FOREIGN KEY(case_id) REFERENCES cases(case_id) ON DELETE SET NULL, "
            "FOREIGN KEY(created_by) REFERENCES officers(officer_id) ON DELETE SET NULL)"),
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS recovery_codes ("
            "code_id INTEGER PRIMARY KEY AUTOINCREMENT, "
            "officer_id INTEGER NOT NULL, "
            "code_hash TEXT NOT NULL, "
            "used_at TEXT, "
            "created_at TEXT, "
            "FOREIGN KEY(officer_id) REFERENCES officers(officer_id) ON DELETE CASCADE)"),
        QStringLiteral("CREATE INDEX IF NOT EXISTS ix_officers_approved ON officers(is_approved, last_name)"),
        QStringLiteral("CREATE INDEX IF NOT EXISTS ix_persons_case ON persons(case_id)"),
        QStringLiteral("CREATE INDEX IF NOT EXISTS ix_persons_name ON persons(last_name, name)"),
        QStringLiteral("CREATE INDEX IF NOT EXISTS ix_cases_status ON cases(status)"),
        QStringLiteral("CREATE INDEX IF NOT EXISTS ix_cases_investigator ON cases(investigator_id)"),
        QStringLiteral("CREATE INDEX IF NOT EXISTS ix_evidence_case ON evidence(case_id)"),
        QStringLiteral("CREATE INDEX IF NOT EXISTS ix_recovery_officer ON recovery_codes(officer_id)")
    };

    for (const QString &statement : statements) {
        if (!execSql(statement))
            return false;
    }
    return true;
}

bool DatabaseManager::ensureColumn(const QString &table, const QString &column, const QString &definition)
{
    QSqlQuery info(m_database);
    if (!info.exec(QStringLiteral("PRAGMA table_info(%1)").arg(table))) {
        qWarning() << "PRAGMA table_info failed:" << info.lastError().text();
        return false;
    }

    while (info.next()) {
        if (info.value(1).toString().compare(column, Qt::CaseInsensitive) == 0)
            return true;
    }

    QSqlQuery alter(m_database);
    const QString sql = QStringLiteral("ALTER TABLE %1 ADD COLUMN %2 %3").arg(table, column, definition);
    if (!execSql(alter, sql)) {
        qWarning() << "Не удалось добавить колонку" << column << "в" << table;
        return false;
    }
    return true;
}

bool DatabaseManager::migrateSchema()
{
    QSqlQuery versionQuery(m_database);
    int version = 0;
    if (versionQuery.exec(QStringLiteral("PRAGMA user_version")) && versionQuery.next())
        version = versionQuery.value(0).toInt();

    if (version >= 2)
        return true;

    qInfo() << "Миграция схемы БД, версия" << version << "-> 2";

    const QVector<QPair<QString, QPair<QString, QString>>> columns = {
        { QStringLiteral("officers"), { QStringLiteral("rank_category"), QStringLiteral("TEXT DEFAULT 'Полиция'") } },
        { QStringLiteral("officers"), { QStringLiteral("phone"), QStringLiteral("TEXT") } },
        { QStringLiteral("officers"), { QStringLiteral("email"), QStringLiteral("TEXT") } },
        { QStringLiteral("officers"), { QStringLiteral("role"), QStringLiteral("TEXT DEFAULT 'officer'") } },
        { QStringLiteral("officers"), { QStringLiteral("is_approved"), QStringLiteral("INTEGER DEFAULT 0") } },
        { QStringLiteral("officers"), { QStringLiteral("totp_secret"), QStringLiteral("TEXT") } },
        { QStringLiteral("officers"), { QStringLiteral("totp_enabled"), QStringLiteral("INTEGER DEFAULT 0") } },
        { QStringLiteral("officers"), { QStringLiteral("failed_attempts"), QStringLiteral("INTEGER DEFAULT 0") } },
        { QStringLiteral("officers"), { QStringLiteral("locked_until"), QStringLiteral("TEXT") } },
        { QStringLiteral("officers"), { QStringLiteral("last_login"), QStringLiteral("TEXT") } },
        { QStringLiteral("officers"), { QStringLiteral("created_at"), QStringLiteral("TEXT") } },
        { QStringLiteral("officers"), { QStringLiteral("updated_at"), QStringLiteral("TEXT") } },
        { QStringLiteral("persons"), { QStringLiteral("photo_path"), QStringLiteral("TEXT") } },
        { QStringLiteral("persons"), { QStringLiteral("created_at"), QStringLiteral("TEXT") } },
        { QStringLiteral("persons"), { QStringLiteral("updated_at"), QStringLiteral("TEXT") } },
        { QStringLiteral("cases"), { QStringLiteral("created_at"), QStringLiteral("TEXT") } },
        { QStringLiteral("cases"), { QStringLiteral("updated_at"), QStringLiteral("TEXT") } },
        { QStringLiteral("evidence"), { QStringLiteral("storage_location"), QStringLiteral("TEXT") } },
        { QStringLiteral("evidence"), { QStringLiteral("created_by"), QStringLiteral("INTEGER") } },
        { QStringLiteral("evidence"), { QStringLiteral("created_at"), QStringLiteral("TEXT") } },
        { QStringLiteral("evidence"), { QStringLiteral("updated_at"), QStringLiteral("TEXT") } }
    };

    for (const auto &entry : columns) {
        if (!ensureColumn(entry.first, entry.second.first, entry.second.second))
            return false;
    }

    // Для существующей базы: все старые учётные записи считаются
    // подтверждёнными, самый первый сотрудник становится администратором.
    execSql(QStringLiteral("UPDATE officers SET is_approved = 1 WHERE is_approved = 0 OR is_approved IS NULL"));
    execSql(QStringLiteral("UPDATE officers SET role = 'officer' WHERE role IS NULL OR role = ''"));
    execSql(QStringLiteral(
        "UPDATE officers SET role = 'admin' WHERE officer_id = "
        "(SELECT MIN(officer_id) FROM officers WHERE system_login IS NOT NULL AND system_login <> '')"));
    execSql(QStringLiteral("UPDATE officers SET rank_category = 'Внутренняя служба' "
                           "WHERE (rank_category IS NULL OR rank_category = '') AND rank LIKE '%внутренней службы%'"));
    execSql(QStringLiteral("UPDATE officers SET rank_category = 'Юстиция' "
                           "WHERE (rank_category IS NULL OR rank_category = '') AND rank LIKE '%юстиции%'"));
    execSql(QStringLiteral("UPDATE officers SET rank_category = 'Полиция' "
                           "WHERE rank_category IS NULL OR rank_category = ''"));
    execSql(QStringLiteral("UPDATE officers SET created_at = COALESCE(created_at, datetime('now'))"));
    execSql(QStringLiteral("UPDATE officers SET updated_at = COALESCE(updated_at, datetime('now'))"));
    execSql(QStringLiteral("UPDATE persons SET created_at = COALESCE(created_at, datetime('now'))"));
    execSql(QStringLiteral("UPDATE cases SET created_at = COALESCE(created_at, datetime('now'))"));
    execSql(QStringLiteral("UPDATE evidence SET created_at = COALESCE(created_at, datetime('now'))"));

    execSql(QStringLiteral("CREATE UNIQUE INDEX IF NOT EXISTS ux_officers_login ON officers(LOWER(system_login))"));
    execSql(QStringLiteral("CREATE UNIQUE INDEX IF NOT EXISTS ux_officers_personnel ON officers(personnel_number) "
                           "WHERE personnel_number IS NOT NULL AND personnel_number <> ''"));
    execSql(QStringLiteral("CREATE INDEX IF NOT EXISTS ix_officers_approved ON officers(is_approved, last_name)"));
    execSql(QStringLiteral("CREATE INDEX IF NOT EXISTS ix_persons_case ON persons(case_id)"));
    execSql(QStringLiteral("CREATE INDEX IF NOT EXISTS ix_cases_status ON cases(status)"));
    execSql(QStringLiteral("CREATE INDEX IF NOT EXISTS ix_evidence_case ON evidence(case_id)"));

    execSql(QStringLiteral("PRAGMA user_version = 2"));
    migrateLegacyPhotos();
    return true;
}

// ---------------------------------------------------------------------------
// Пароли
// ---------------------------------------------------------------------------

QString DatabaseManager::generateSalt()
{
    QByteArray salt(16, Qt::Uninitialized);
    auto *generator = QRandomGenerator::system();
    for (int i = 0; i < salt.size(); i += 4) {
        const quint32 value = generator->generate();
        const int chunk = qMin(4, salt.size() - i);
        std::memcpy(salt.data() + i, &value, static_cast<size_t>(chunk));
    }
    return QString::fromLatin1(salt.toBase64());
}

QString DatabaseManager::hashPassword(const QString &password) const
{
    const QString saltString = generateSalt();
    const QByteArray salt = QByteArray::fromBase64(saltString.toLatin1());
    const QByteArray derived = QPasswordDigestor::deriveKeyPbkdf2(
        QCryptographicHash::Sha256, password.toUtf8(), salt, kPbkdf2Iterations, 32);
    return QStringLiteral("pbkdf2_sha256$%1$%2$%3")
        .arg(kPbkdf2Iterations)
        .arg(saltString, QString::fromLatin1(derived.toBase64()));
}

bool DatabaseManager::constantTimeEquals(const QByteArray &left, const QByteArray &right)
{
    if (left.size() != right.size())
        return false;
    unsigned char diff = 0;
    for (int i = 0; i < left.size(); ++i)
        diff |= static_cast<unsigned char>(left.at(i) ^ right.at(i));
    return diff == 0;
}

bool DatabaseManager::verifyPassword(const QString &password, const QString &stored) const
{
    if (stored.startsWith(QStringLiteral("pbkdf2_sha256$"))) {
        const QStringList parts = stored.split(QLatin1Char('$'));
        if (parts.size() != 4)
            return false;
        bool ok = false;
        const int iterations = parts.at(1).toInt(&ok);
        if (!ok || iterations <= 0)
            return false;
        const QByteArray salt = QByteArray::fromBase64(parts.at(2).toLatin1());
        const QByteArray expected = QByteArray::fromBase64(parts.at(3).toLatin1());
        const QByteArray derived = QPasswordDigestor::deriveKeyPbkdf2(
            QCryptographicHash::Sha256, password.toUtf8(), salt, iterations, expected.size());
        return constantTimeEquals(derived, expected);
    }

    // Старые хэши: sha256 (64 hex) и md5 (32 hex) без соли.
    const QByteArray raw = password.toUtf8();
    if (stored.size() == 64) {
        return constantTimeEquals(
            QCryptographicHash::hash(raw, QCryptographicHash::Sha256).toHex(),
            stored.toLatin1());
    }
    if (stored.size() == 32) {
        return constantTimeEquals(
            QCryptographicHash::hash(raw, QCryptographicHash::Md5).toHex(),
            stored.toLatin1());
    }
    return false;
}

// ---------------------------------------------------------------------------
// Валидация и служебные функции
// ---------------------------------------------------------------------------

QVariantMap DatabaseManager::errorResult(const QString &message) const
{
    return { { QStringLiteral("ok"), false }, { QStringLiteral("error"), message } };
}

QVariantMap DatabaseManager::successResult() const
{
    return { { QStringLiteral("ok"), true } };
}

QVariantMap DatabaseManager::requireAuth() const
{
    if (m_currentOfficerId <= 0)
        return errorResult(QStringLiteral("Требуется вход в систему"));
    return successResult();
}

QVariantMap DatabaseManager::requireAdmin() const
{
    const QVariantMap auth = requireAuth();
    if (!auth.value(QStringLiteral("ok")).toBool())
        return auth;

    QSqlQuery query(m_database);
    query.prepare(QStringLiteral("SELECT role FROM officers WHERE officer_id = :id"));
    query.bindValue(QStringLiteral(":id"), m_currentOfficerId);
    if (!query.exec() || !query.next() || query.value(0).toString() != QStringLiteral("admin"))
        return errorResult(QStringLiteral("Недостаточно прав: требуется администратор"));
    return successResult();
}

QString DatabaseManager::normalizeDate(const QString &value, bool *ok)
{
    if (ok)
        *ok = true;
    const QString trimmed = value.trimmed();
    if (trimmed.isEmpty())
        return {};

    QDate date = QDate::fromString(trimmed, QStringLiteral("yyyy-MM-dd"));
    if (!date.isValid())
        date = QDate::fromString(trimmed, QStringLiteral("dd.MM.yyyy"));
    if (!date.isValid())
        date = QDate::fromString(trimmed, QStringLiteral("dd/MM/yyyy"));
    if (!date.isValid()) {
        if (ok)
            *ok = false;
        return {};
    }
    return date.toString(QStringLiteral("yyyy-MM-dd"));
}

QString DatabaseManager::normalizeDateTime(const QString &value, bool *ok)
{
    if (ok)
        *ok = true;
    const QString trimmed = value.trimmed();
    if (trimmed.isEmpty())
        return {};

    QDateTime dateTime = QDateTime::fromString(trimmed, Qt::ISODate);
    if (!dateTime.isValid())
        dateTime = QDateTime::fromString(trimmed, QStringLiteral("dd.MM.yyyy HH:mm"));
    if (!dateTime.isValid()) {
        bool dateOk = false;
        const QString dateOnly = normalizeDate(trimmed, &dateOk);
        if (dateOk && !dateOnly.isEmpty()) {
            dateTime = QDateTime::fromString(dateOnly + QStringLiteral("T12:00:00"), Qt::ISODate);
        }
    }
    if (!dateTime.isValid()) {
        if (ok)
            *ok = false;
        return {};
    }
    if (dateTime.timeSpec() == Qt::LocalTime)
        dateTime = dateTime.toUTC();
    return dateTime.toUTC().toString(Qt::ISODate);
}

QString DatabaseManager::nowIso()
{
    return QDateTime::currentDateTimeUtc().toString(Qt::ISODate);
}

int DatabaseManager::yearsSince(const QString &isoDate)
{
    const QDate date = QDate::fromString(isoDate, QStringLiteral("yyyy-MM-dd"));
    if (!date.isValid())
        return -1;
    const QDate today = QDate::currentDate();
    int years = today.year() - date.year();
    if (today.month() < date.month() || (today.month() == date.month() && today.day() < date.day()))
        --years;
    return years;
}

bool DatabaseManager::isValidLogin(const QString &login)
{
    static const QRegularExpression regex(QStringLiteral("^[A-Za-z0-9][A-Za-z0-9._-]{3,31}$"));
    return regex.match(login).hasMatch();
}

bool DatabaseManager::isValidPassword(const QString &password, QString *reason)
{
    if (password.size() < 8) {
        if (reason)
            *reason = QStringLiteral("Пароль должен содержать не менее 8 символов");
        return false;
    }
    if (password.size() > 128) {
        if (reason)
            *reason = QStringLiteral("Пароль слишком длинный (максимум 128 символов)");
        return false;
    }
    bool hasLetter = false;
    bool hasDigit = false;
    bool hasSpecial = false;
    for (const QChar ch : password) {
        if (ch.isLetter())
            hasLetter = true;
        else if (ch.isDigit())
            hasDigit = true;
        else
            hasSpecial = true;
    }
    if (!hasLetter || !hasDigit) {
        if (reason)
            *reason = QStringLiteral("Пароль должен содержать хотя бы одну букву и одну цифру");
        return false;
    }
    Q_UNUSED(hasSpecial);
    return true;
}

bool DatabaseManager::isValidEmail(const QString &email)
{
    if (email.isEmpty())
        return true;
    static const QRegularExpression regex(QStringLiteral("^[^@\\s]+@[^@\\s]+\\.[^@\\s]{2,}$"));
    return regex.match(email).hasMatch();
}

bool DatabaseManager::isValidPhone(const QString &phone)
{
    if (phone.isEmpty())
        return true;
    static const QRegularExpression allowed(QStringLiteral("^[0-9+()\\-\\s]{5,25}$"));
    if (!allowed.match(phone).hasMatch())
        return false;
    int digits = 0;
    for (const QChar ch : phone) {
        if (ch.isDigit())
            ++digits;
    }
    return digits >= 10 && digits <= 15;
}

int DatabaseManager::countAdmins(int exceptOfficerId) const
{
    QSqlQuery query(m_database);
    query.prepare(QStringLiteral("SELECT COUNT(*) FROM officers WHERE role = 'admin' AND officer_id <> :id"));
    query.bindValue(QStringLiteral(":id"), exceptOfficerId);
    if (query.exec() && query.next())
        return query.value(0).toInt();
    return 0;
}

QString DatabaseManager::loginForOfficer(int officerId) const
{
    QSqlQuery query(m_database);
    query.prepare(QStringLiteral("SELECT system_login FROM officers WHERE officer_id = :id"));
    query.bindValue(QStringLiteral(":id"), officerId);
    if (query.exec() && query.next())
        return query.value(0).toString();
    return {};
}

// ---------------------------------------------------------------------------
// Фотографии
// ---------------------------------------------------------------------------

QString DatabaseManager::photoDirectory() const
{
    return QFileInfo(m_databasePath).absolutePath() + QStringLiteral("/photos");
}

QString DatabaseManager::photoUrlForFile(const QString &fileName) const
{
    if (fileName.trimmed().isEmpty())
        return {};
    const QString safeName = QFileInfo(fileName).fileName();
    const QFileInfo file(photoDirectory() + QLatin1Char('/') + safeName);
    if (!file.exists() || !file.isFile())
        return {};
    // Версия в пути сбрасывает кэш QML после замены фотографии.
    return QStringLiteral("image://photo/%1/%2")
        .arg(file.lastModified().toMSecsSinceEpoch())
        .arg(safeName);
}

bool DatabaseManager::deletePhotoFile(const QString &fileName)
{
    if (fileName.trimmed().isEmpty())
        return true;
    const QString safeName = QFileInfo(fileName).fileName();
    QFile file(photoDirectory() + QLatin1Char('/') + safeName);
    if (!file.exists())
        return true;
    return file.remove();
}

QString DatabaseManager::writePhotoFile(const QString &prefix, int id, const QUrl &source, QString *error)
{
    auto fail = [error](const QString &message) {
        if (error)
            *error = message;
        return QString();
    };

    QString path;
    if (source.isLocalFile())
        path = source.toLocalFile();
    else if (source.scheme().compare(QStringLiteral("file"), Qt::CaseInsensitive) == 0)
        path = QUrl(source.toString()).toLocalFile();
    else
        path = source.toString();

    if (path.startsWith(QStringLiteral("file:"), Qt::CaseInsensitive))
        path = QUrl(path).toLocalFile();

    const QFileInfo info(path);
    if (!info.exists() || !info.isFile())
        return fail(QStringLiteral("Файл фотографии не найден"));
    if (info.size() > kMaxPhotoBytes)
        return fail(QStringLiteral("Файл слишком большой (максимум 15 МБ)"));
    if (info.size() == 0)
        return fail(QStringLiteral("Файл фотографии пустой"));

    QImageReader reader(info.absoluteFilePath());
    reader.setAutoTransform(true);
    const QSize originalSize = reader.size();
    if (!originalSize.isValid())
        return fail(QStringLiteral("Не удалось прочитать изображение"));

    QImage image;
    if (originalSize.width() > kMaxPhotoDimension || originalSize.height() > kMaxPhotoDimension) {
        QSize target = originalSize;
        target.scale(kMaxPhotoDimension, kMaxPhotoDimension, Qt::KeepAspectRatio);
        reader.setScaledSize(target);
    }
    image = reader.read();
    if (image.isNull())
        return fail(QStringLiteral("Неподдерживаемый формат изображения"));

    if (image.hasAlphaChannel()) {
        QImage flattened(image.size(), QImage::Format_RGB32);
        flattened.fill(Qt::white);
        QPainter painter(&flattened);
        painter.drawImage(0, 0, image);
        painter.end();
        image = flattened;
    }

    if (!QDir().mkpath(photoDirectory()))
        return fail(QStringLiteral("Не удалось создать каталог для фотографий"));

    const QString fileName = QStringLiteral("%1_%2.jpg").arg(prefix).arg(id);
    const QString fullPath = photoDirectory() + QLatin1Char('/') + fileName;
    if (!image.save(fullPath, "JPEG", 88))
        return fail(QStringLiteral("Не удалось сохранить фотографию"));

    return fileName;
}

QVariantMap DatabaseManager::setOfficerPhoto(int officerId, const QUrl &source)
{
    const QVariantMap auth = requireAuth();
    if (!auth.value(QStringLiteral("ok")).toBool())
        return auth;

    QSqlQuery query(m_database);
    query.prepare(QStringLiteral("SELECT photo_path FROM officers WHERE officer_id = :id"));
    query.bindValue(QStringLiteral(":id"), officerId);
    if (!query.exec() || !query.next())
        return errorResult(QStringLiteral("Сотрудник не найден"));
    const QString oldFile = query.value(0).toString();

    QString error;
    const QString fileName = writePhotoFile(QStringLiteral("officer"), officerId, source, &error);
    if (fileName.isEmpty())
        return errorResult(error);

    QSqlQuery update(m_database);
    update.prepare(QStringLiteral("UPDATE officers SET photo_path = :photo, updated_at = :updated WHERE officer_id = :id"));
    update.bindValue(QStringLiteral(":photo"), fileName);
    update.bindValue(QStringLiteral(":updated"), nowIso());
    update.bindValue(QStringLiteral(":id"), officerId);
    if (!update.exec())
        return errorResult(QStringLiteral("Не удалось сохранить фотографию в базе данных"));

    if (!oldFile.isEmpty() && oldFile != fileName)
        deletePhotoFile(oldFile);

    return { { QStringLiteral("ok"), true },
             { QStringLiteral("photo_url"), photoUrlForFile(fileName) } };
}

QVariantMap DatabaseManager::removeOfficerPhoto(int officerId)
{
    const QVariantMap auth = requireAuth();
    if (!auth.value(QStringLiteral("ok")).toBool())
        return auth;

    QSqlQuery query(m_database);
    query.prepare(QStringLiteral("SELECT photo_path FROM officers WHERE officer_id = :id"));
    query.bindValue(QStringLiteral(":id"), officerId);
    if (!query.exec() || !query.next())
        return errorResult(QStringLiteral("Сотрудник не найден"));

    const QString fileName = query.value(0).toString();
    QSqlQuery update(m_database);
    update.prepare(QStringLiteral("UPDATE officers SET photo_path = NULL, updated_at = :updated WHERE officer_id = :id"));
    update.bindValue(QStringLiteral(":updated"), nowIso());
    update.bindValue(QStringLiteral(":id"), officerId);
    if (!update.exec())
        return errorResult(QStringLiteral("Не удалось удалить фотографию"));

    deletePhotoFile(fileName);
    return successResult();
}

QVariantMap DatabaseManager::setPersonPhoto(int personId, const QUrl &source)
{
    const QVariantMap auth = requireAuth();
    if (!auth.value(QStringLiteral("ok")).toBool())
        return auth;

    QSqlQuery query(m_database);
    query.prepare(QStringLiteral("SELECT photo_path FROM persons WHERE person_id = :id"));
    query.bindValue(QStringLiteral(":id"), personId);
    if (!query.exec() || !query.next())
        return errorResult(QStringLiteral("Личность не найдена"));
    const QString oldFile = query.value(0).toString();

    QString error;
    const QString fileName = writePhotoFile(QStringLiteral("person"), personId, source, &error);
    if (fileName.isEmpty())
        return errorResult(error);

    QSqlQuery update(m_database);
    update.prepare(QStringLiteral("UPDATE persons SET photo_path = :photo, updated_at = :updated WHERE person_id = :id"));
    update.bindValue(QStringLiteral(":photo"), fileName);
    update.bindValue(QStringLiteral(":updated"), nowIso());
    update.bindValue(QStringLiteral(":id"), personId);
    if (!update.exec())
        return errorResult(QStringLiteral("Не удалось сохранить фотографию в базе данных"));

    if (!oldFile.isEmpty() && oldFile != fileName)
        deletePhotoFile(oldFile);

    return { { QStringLiteral("ok"), true },
             { QStringLiteral("photo_url"), photoUrlForFile(fileName) } };
}

QVariantMap DatabaseManager::removePersonPhoto(int personId)
{
    const QVariantMap auth = requireAuth();
    if (!auth.value(QStringLiteral("ok")).toBool())
        return auth;

    QSqlQuery query(m_database);
    query.prepare(QStringLiteral("SELECT photo_path FROM persons WHERE person_id = :id"));
    query.bindValue(QStringLiteral(":id"), personId);
    if (!query.exec() || !query.next())
        return errorResult(QStringLiteral("Личность не найдена"));

    const QString fileName = query.value(0).toString();
    QSqlQuery update(m_database);
    update.prepare(QStringLiteral("UPDATE persons SET photo_path = NULL, updated_at = :updated WHERE person_id = :id"));
    update.bindValue(QStringLiteral(":updated"), nowIso());
    update.bindValue(QStringLiteral(":id"), personId);
    if (!update.exec())
        return errorResult(QStringLiteral("Не удалось удалить фотографию"));

    deletePhotoFile(fileName);
    return successResult();
}

void DatabaseManager::migrateLegacyPhotos()
{
    // Раньше в photo_path писали абсолютный путь к исходному файлу.
    // Копируем такие фотографии в каталог приложения, чтобы они не
    // пропадали при перемещении/удалении исходников.
    struct Target {
        const char *table;
        const char *idColumn;
        const char *prefix;
    };
    const Target targets[] = {
        { "officers", "officer_id", "officer" },
        { "persons", "person_id", "person" }
    };

    for (const Target &target : targets) {
        QSqlQuery query(m_database);
        if (!query.exec(QStringLiteral("SELECT %1, photo_path FROM %2 WHERE photo_path IS NOT NULL AND photo_path <> ''")
                            .arg(QLatin1String(target.idColumn), QLatin1String(target.table))))
            continue;

        while (query.next()) {
            const int id = query.value(0).toInt();
            const QString stored = query.value(1).toString();
            if (stored.isEmpty())
                continue;
            // Новый формат — просто имя файла, миграция не нужна.
            if (!stored.contains(QLatin1Char('/')) && !stored.contains(QLatin1Char('\\')))
                continue;

            QString sourcePath = stored;
            if (sourcePath.startsWith(QStringLiteral("file:"), Qt::CaseInsensitive))
                sourcePath = QUrl(sourcePath).toLocalFile();

            const QFileInfo info(sourcePath);
            QString newName;
            if (info.exists() && info.isFile()) {
                QString error;
                newName = writePhotoFile(QLatin1String(target.prefix), id, QUrl::fromLocalFile(info.absoluteFilePath()), &error);
            }

            QSqlQuery update(m_database);
            if (!newName.isEmpty()) {
                update.prepare(QStringLiteral("UPDATE %1 SET photo_path = :photo WHERE %2 = :id")
                                   .arg(QLatin1String(target.table), QLatin1String(target.idColumn)));
                update.bindValue(QStringLiteral(":photo"), newName);
            } else {
                update.prepare(QStringLiteral("UPDATE %1 SET photo_path = NULL WHERE %2 = :id")
                                   .arg(QLatin1String(target.table), QLatin1String(target.idColumn)));
            }
            update.bindValue(QStringLiteral(":id"), id);
            update.exec();
        }
    }
}

// ---------------------------------------------------------------------------
// Пользователи и сессия
// ---------------------------------------------------------------------------

bool DatabaseManager::hasUsers()
{
    QSqlQuery query(m_database);
    if (query.exec(QStringLiteral("SELECT COUNT(*) FROM officers")) && query.next())
        return query.value(0).toInt() > 0;
    return false;
}

bool DatabaseManager::isAuthenticated() const
{
    return m_currentOfficerId > 0;
}

QVariantMap DatabaseManager::userMap(int officerId) const
{
    if (officerId <= 0)
        return {};

    QSqlQuery query(m_database);
    query.prepare(QStringLiteral(
        "SELECT o.*, "
        "(SELECT COUNT(*) FROM cases c WHERE c.investigator_id = o.officer_id) AS case_count, "
        "(SELECT COUNT(*) FROM recovery_codes r WHERE r.officer_id = o.officer_id AND r.used_at IS NULL) AS recovery_left "
        "FROM officers o WHERE o.officer_id = :id"));
    query.bindValue(QStringLiteral(":id"), officerId);
    if (!query.exec() || !query.next())
        return {};

    const QString lastName = query.value(QStringLiteral("last_name")).toString();
    const QString firstName = query.value(QStringLiteral("name")).toString();
    const QString patronymic = query.value(QStringLiteral("patronymic")).toString();
    const QString birthDate = query.value(QStringLiteral("birth_date")).toString();
    const QString photoFile = query.value(QStringLiteral("photo_path")).toString();

    QVariantMap officer;
    officer[QStringLiteral("id")] = officerId;
    officer[QStringLiteral("officer_id")] = officerId;
    officer[QStringLiteral("last_name")] = lastName;
    officer[QStringLiteral("name")] = firstName;
    officer[QStringLiteral("patronymic")] = patronymic;
    officer[QStringLiteral("full_name")] = fullName(lastName, firstName, patronymic);
    officer[QStringLiteral("short_name")] = makeShortFio(lastName, firstName, patronymic);
    officer[QStringLiteral("rank")] = query.value(QStringLiteral("rank")).toString();
    officer[QStringLiteral("rank_category")] = query.value(QStringLiteral("rank_category")).toString();
    officer[QStringLiteral("position")] = query.value(QStringLiteral("position")).toString();
    officer[QStringLiteral("birth_date")] = birthDate;
    officer[QStringLiteral("age")] = yearsSince(birthDate);
    officer[QStringLiteral("personnel_number")] = query.value(QStringLiteral("personnel_number")).toString();
    officer[QStringLiteral("hire_date")] = query.value(QStringLiteral("hire_date")).toString();
    officer[QStringLiteral("experience")] = query.value(QStringLiteral("experience")).toInt();
    officer[QStringLiteral("phone")] = query.value(QStringLiteral("phone")).toString();
    officer[QStringLiteral("email")] = query.value(QStringLiteral("email")).toString();
    officer[QStringLiteral("login")] = query.value(QStringLiteral("system_login")).toString();
    officer[QStringLiteral("photo_url")] = photoUrlForFile(photoFile);
    officer[QStringLiteral("photo_path")] = photoFile;
    officer[QStringLiteral("role")] = query.value(QStringLiteral("role")).toString();
    officer[QStringLiteral("is_approved")] = query.value(QStringLiteral("is_approved")).toInt() != 0;
    officer[QStringLiteral("totp_enabled")] = query.value(QStringLiteral("totp_enabled")).toInt() != 0;
    officer[QStringLiteral("last_login")] = query.value(QStringLiteral("last_login")).toString();
    officer[QStringLiteral("created_at")] = query.value(QStringLiteral("created_at")).toString();
    officer[QStringLiteral("case_count")] = query.value(QStringLiteral("case_count")).toInt();
    officer[QStringLiteral("recovery_codes_left")] = query.value(QStringLiteral("recovery_left")).toInt();
    return officer;
}

QVariantMap DatabaseManager::currentUser()
{
    return userMap(m_currentOfficerId);
}

void DatabaseManager::applyLogin(const QString &login)
{
    QSqlQuery update(m_database);
    update.prepare(QStringLiteral(
        "UPDATE officers SET last_login = :now, failed_attempts = 0, locked_until = NULL WHERE officer_id = :id"));
    update.bindValue(QStringLiteral(":now"), nowIso());
    update.bindValue(QStringLiteral(":id"), m_currentOfficerId);
    update.exec();
    Q_UNUSED(login);
}

QVariantMap DatabaseManager::authenticate(const QString &login, const QString &password)
{
    const QString normalizedLogin = login.trimmed();
    if (normalizedLogin.isEmpty() || password.isEmpty())
        return errorResult(QStringLiteral("Введите логин и пароль"));

    QSqlQuery query(m_database);
    query.prepare(QStringLiteral(
        "SELECT officer_id, password_hash, is_approved, totp_enabled, failed_attempts, locked_until, "
        "last_name, name, patronymic FROM officers WHERE system_login = :login COLLATE NOCASE"));
    query.bindValue(QStringLiteral(":login"), normalizedLogin);
    if (!query.exec()) {
        qWarning() << "Ошибка запроса входа:" << query.lastError().text();
        return errorResult(QStringLiteral("Ошибка базы данных"));
    }

    if (!query.next())
        return errorResult(QStringLiteral("Неверный логин или пароль"));

    const int officerId = query.value(0).toInt();
    const QString storedHash = query.value(1).toString();
    const bool approved = query.value(2).toInt() != 0;
    const bool totpEnabled = query.value(3).toInt() != 0;
    int failedAttempts = query.value(4).toInt();
    const QString lockedUntilRaw = query.value(5).toString();

    if (!lockedUntilRaw.isEmpty()) {
        const QDateTime lockedUntil = QDateTime::fromString(lockedUntilRaw, Qt::ISODate);
        if (lockedUntil.isValid() && lockedUntil > QDateTime::currentDateTimeUtc()) {
            const qint64 seconds = QDateTime::currentDateTimeUtc().secsTo(lockedUntil);
            return { { QStringLiteral("ok"), false },
                     { QStringLiteral("errorCode"), QStringLiteral("locked") },
                     { QStringLiteral("error"),
                       QStringLiteral("Слишком много неудачных попыток. Повторите через %1 с.").arg(qMax<qint64>(1, seconds)) },
                     { QStringLiteral("retryAfter"), static_cast<int>(qMax<qint64>(1, seconds)) } };
        }
    }

    if (!verifyPassword(password, storedHash)) {
        ++failedAttempts;
        QString lockedUntil;
        if (failedAttempts >= kMaxFailedAttempts) {
            lockedUntil = QDateTime::currentDateTimeUtc().addSecs(kLockMinutes * 60).toString(Qt::ISODate);
            failedAttempts = 0;
        }

        QSqlQuery update(m_database);
        update.prepare(QStringLiteral(
            "UPDATE officers SET failed_attempts = :attempts, locked_until = :locked WHERE officer_id = :id"));
        update.bindValue(QStringLiteral(":attempts"), failedAttempts);
        update.bindValue(QStringLiteral(":locked"), lockedUntil.isEmpty() ? QVariant(QMetaType(QMetaType::QString)) : QVariant(lockedUntil));
        update.bindValue(QStringLiteral(":id"), officerId);
        update.exec();

        if (!lockedUntil.isEmpty()) {
            return { { QStringLiteral("ok"), false },
                     { QStringLiteral("errorCode"), QStringLiteral("locked") },
                     { QStringLiteral("error"),
                       QStringLiteral("Слишком много неудачных попыток. Вход заблокирован на %1 минут.").arg(kLockMinutes) },
                     { QStringLiteral("retryAfter"), kLockMinutes * 60 } };
        }

        return { { QStringLiteral("ok"), false },
                 { QStringLiteral("errorCode"), QStringLiteral("invalid_credentials") },
                 { QStringLiteral("error"), QStringLiteral("Неверный логин или пароль") },
                 { QStringLiteral("attemptsLeft"), kMaxFailedAttempts - failedAttempts } };
    }

    if (!approved)
        return { { QStringLiteral("ok"), false },
                 { QStringLiteral("errorCode"), QStringLiteral("pending") },
                 { QStringLiteral("error"),
                   QStringLiteral("Учётная запись ожидает подтверждения администратором") } };

    // Успешный пароль — сбрасываем счётчик неудач.
    QSqlQuery reset(m_database);
    reset.prepare(QStringLiteral("UPDATE officers SET failed_attempts = 0, locked_until = NULL WHERE officer_id = :id"));
    reset.bindValue(QStringLiteral(":id"), officerId);
    reset.exec();

    // Прозрачно обновляем старый хэш (sha256/md5) на PBKDF2 при входе.
    if (!storedHash.startsWith(QStringLiteral("pbkdf2_sha256$"))) {
        QSqlQuery upgrade(m_database);
        upgrade.prepare(QStringLiteral("UPDATE officers SET password_hash = :hash WHERE officer_id = :id"));
        upgrade.bindValue(QStringLiteral(":hash"), hashPassword(password));
        upgrade.bindValue(QStringLiteral(":id"), officerId);
        upgrade.exec();
    }

    if (totpEnabled) {
        m_pendingOfficerId = officerId;
        m_pendingCreatedAt = QDateTime::currentDateTimeUtc();
        m_pending2faAttempts = 0;
        m_pendingTotpSecret.clear();
        return { { QStringLiteral("ok"), true },
                 { QStringLiteral("requires2fa"), true },
                 { QStringLiteral("login"), normalizedLogin },
                 { QStringLiteral("displayName"),
                   fullName(query.value(6).toString(), query.value(7).toString(), query.value(8).toString()) } };
    }

    m_currentOfficerId = officerId;
    applyLogin(normalizedLogin);
    return { { QStringLiteral("ok"), true },
             { QStringLiteral("requires2fa"), false },
             { QStringLiteral("user"), userMap(officerId) } };
}

QVariantMap DatabaseManager::verifyTwoFactor(const QString &code)
{
    if (m_pendingOfficerId <= 0)
        return errorResult(QStringLiteral("Сессия входа истекла, попробуйте снова"));
    if (m_pendingCreatedAt.secsTo(QDateTime::currentDateTimeUtc()) > kPending2faMinutes * 60) {
        m_pendingOfficerId = 0;
        m_pending2faAttempts = 0;
        return errorResult(QStringLiteral("Сессия входа истекла, попробуйте снова"));
    }

    QSqlQuery query(m_database);
    query.prepare(QStringLiteral("SELECT totp_secret, totp_enabled FROM officers WHERE officer_id = :id"));
    query.bindValue(QStringLiteral(":id"), m_pendingOfficerId);
    if (!query.exec() || !query.next())
        return errorResult(QStringLiteral("Сотрудник не найден"));

    const QString secret = query.value(0).toString();
    const bool enabled = query.value(1).toInt() != 0;
    if (!enabled || secret.isEmpty()) {
        m_pendingOfficerId = 0;
        return errorResult(QStringLiteral("Двухфакторная аутентификация не настроена"));
    }

    bool verified = false;
    const QString trimmed = code.trimmed();
    if (TotpAuth::verify(secret, trimmed))
        verified = true;

    if (!verified) {
        const QString normalized = TotpAuth::normalizeRecoveryCode(trimmed);
        if (normalized.size() >= 8) {
            const QByteArray hash = TotpAuth::hashRecoveryCode(trimmed);
            QSqlQuery codes(m_database);
            codes.prepare(QStringLiteral(
                "SELECT code_id, code_hash FROM recovery_codes WHERE officer_id = :id AND used_at IS NULL"));
            codes.bindValue(QStringLiteral(":id"), m_pendingOfficerId);
            if (codes.exec()) {
                while (codes.next()) {
                    const QByteArray stored = QByteArray::fromHex(codes.value(1).toString().toLatin1());
                    if (constantTimeEquals(stored, hash)) {
                        QSqlQuery mark(m_database);
                        mark.prepare(QStringLiteral("UPDATE recovery_codes SET used_at = :now WHERE code_id = :id"));
                        mark.bindValue(QStringLiteral(":now"), nowIso());
                        mark.bindValue(QStringLiteral(":id"), codes.value(0).toInt());
                        mark.exec();
                        verified = true;
                        break;
                    }
                }
            }
        }
    }

    if (!verified) {
        ++m_pending2faAttempts;
        if (m_pending2faAttempts >= kMaxFailedAttempts) {
            m_pendingOfficerId = 0;
            m_pending2faAttempts = 0;
            return errorResult(QStringLiteral("Слишком много неверных кодов. Войдите заново"));
        }
        return { { QStringLiteral("ok"), false },
                 { QStringLiteral("error"), QStringLiteral("Неверный код подтверждения") },
                 { QStringLiteral("attemptsLeft"), kMaxFailedAttempts - m_pending2faAttempts } };
    }

    const int officerId = m_pendingOfficerId;
    const QString login = loginForOfficer(officerId);
    m_pendingOfficerId = 0;
    m_pending2faAttempts = 0;
    m_currentOfficerId = officerId;
    applyLogin(login);
    return { { QStringLiteral("ok"), true }, { QStringLiteral("user"), userMap(officerId) } };
}

QVariantMap DatabaseManager::cancelTwoFactor()
{
    m_pendingOfficerId = 0;
    m_pending2faAttempts = 0;
    return successResult();
}

void DatabaseManager::logout()
{
    m_currentOfficerId = 0;
    m_pendingOfficerId = 0;
    m_pending2faAttempts = 0;
    m_pendingTotpSecret.clear();
}

// ---------------------------------------------------------------------------
// Регистрация и сотрудники
// ---------------------------------------------------------------------------

bool DatabaseManager::isLoginFree(const QString &login, int exceptOfficerId)
{
    if (login.trimmed().isEmpty())
        return true;
    QSqlQuery query(m_database);
    query.prepare(QStringLiteral(
        "SELECT COUNT(*) FROM officers WHERE system_login = :login COLLATE NOCASE AND officer_id <> :id"));
    query.bindValue(QStringLiteral(":login"), login.trimmed());
    query.bindValue(QStringLiteral(":id"), exceptOfficerId);
    if (!query.exec() || !query.next())
        return true;
    return query.value(0).toInt() == 0;
}

QVariantMap DatabaseManager::createOfficer(const QVariantMap &data)
{
    const QString lastName = mapString(data, "last_name", "surname");
    const QString firstName = mapString(data, "name", "first_name");
    const QString patronymic = mapString(data, "patronymic");
    const QString login = mapString(data, "login").toLower();
    const QString password = data.value(QStringLiteral("password")).toString();

    if (lastName.isEmpty() || firstName.isEmpty())
        return errorResult(QStringLiteral("Укажите фамилию и имя сотрудника"));
    if (!isValidLogin(login))
        return errorResult(QStringLiteral("Логин: 4–32 символа, латинские буквы, цифры, «.», «_», «-»"));
    QString passwordError;
    if (!isValidPassword(password, &passwordError))
        return errorResult(passwordError);
    if (!isLoginFree(login))
        return errorResult(QStringLiteral("Этот логин уже занят"));

    QString rank = mapString(data, "rank");
    QString rankCategory = mapString(data, "rank_category");
    if (rankCategory.isEmpty() && !rank.isEmpty())
        rankCategory = Reference::categoryForRank(rank);
    if (rankCategory.isEmpty())
        rankCategory = QStringLiteral("Полиция");
    if (!Reference::isValidRankCategory(rankCategory))
        return errorResult(QStringLiteral("Некорректная категория звания"));
    if (!Reference::isValidRank(rank))
        return errorResult(QStringLiteral("Выберите специальное звание из списка"));

    const QString position = mapString(data, "position");
    if (!Reference::isValidPosition(position))
        return errorResult(QStringLiteral("Выберите должность из списка"));

    bool birthOk = false;
    const QString birthDate = normalizeDate(mapString(data, "birth_date"), &birthOk);
    if (!birthOk)
        return errorResult(QStringLiteral("Некорректная дата рождения"));
    if (!birthDate.isEmpty() && (yearsSince(birthDate) < 18 || yearsSince(birthDate) > 75))
        return errorResult(QStringLiteral("Проверьте дату рождения сотрудника"));

    bool hireOk = false;
    const QString hireDate = normalizeDate(mapString(data, "hire_date"), &hireOk);
    if (!hireOk)
        return errorResult(QStringLiteral("Некорректная дата приёма на службу"));
    if (!hireDate.isEmpty() && hireDate > QDate::currentDate().toString(QStringLiteral("yyyy-MM-dd")))
        return errorResult(QStringLiteral("Дата приёма не может быть в будущем"));

    const QString personnelNumber = mapString(data, "personnel_number");
    if (!personnelNumber.isEmpty()) {
        QSqlQuery check(m_database);
        check.prepare(QStringLiteral("SELECT COUNT(*) FROM officers WHERE personnel_number = :number"));
        check.bindValue(QStringLiteral(":number"), personnelNumber);
        if (check.exec() && check.next() && check.value(0).toInt() > 0)
            return errorResult(QStringLiteral("Сотрудник с таким табельным номером уже существует"));
    }

    const QString phone = mapString(data, "phone");
    if (!isValidPhone(phone))
        return errorResult(QStringLiteral("Некорректный номер телефона"));
    const QString email = mapString(data, "email");
    if (!isValidEmail(email))
        return errorResult(QStringLiteral("Некорректный адрес электронной почты"));

    int experience = data.value(QStringLiteral("experience")).toInt();
    experience = qBound(0, experience, 60);

    QSqlQuery countQuery(m_database);
    countQuery.exec(QStringLiteral("SELECT COUNT(*) FROM officers"));
    const bool firstUser = !(countQuery.next() && countQuery.value(0).toInt() > 0);

    const QString role = firstUser ? QStringLiteral("admin") : QStringLiteral("officer");
    const int approved = firstUser ? 1 : 0;
    const QString timestamp = nowIso();

    QSqlQuery insert(m_database);
    insert.prepare(QStringLiteral(
        "INSERT INTO officers (last_name, name, patronymic, rank, rank_category, position, birth_date, "
        "personnel_number, hire_date, experience, phone, email, system_login, password_hash, role, is_approved, "
        "created_at, updated_at) "
        "VALUES (:last_name, :name, :patronymic, :rank, :rank_category, :position, :birth_date, "
        ":personnel_number, :hire_date, :experience, :phone, :email, :login, :password_hash, :role, :approved, "
        ":created_at, :updated_at)"));
    insert.bindValue(QStringLiteral(":last_name"), lastName);
    insert.bindValue(QStringLiteral(":name"), firstName);
    insert.bindValue(QStringLiteral(":patronymic"), patronymic);
    insert.bindValue(QStringLiteral(":rank"), rank);
    insert.bindValue(QStringLiteral(":rank_category"), rankCategory);
    insert.bindValue(QStringLiteral(":position"), position);
    insert.bindValue(QStringLiteral(":birth_date"), birthDate.isEmpty() ? QVariant(QMetaType(QMetaType::QString)) : QVariant(birthDate));
    insert.bindValue(QStringLiteral(":personnel_number"), personnelNumber.isEmpty() ? QVariant(QMetaType(QMetaType::QString)) : QVariant(personnelNumber));
    insert.bindValue(QStringLiteral(":hire_date"), hireDate.isEmpty() ? QVariant(QMetaType(QMetaType::QString)) : QVariant(hireDate));
    insert.bindValue(QStringLiteral(":experience"), experience);
    insert.bindValue(QStringLiteral(":phone"), phone);
    insert.bindValue(QStringLiteral(":email"), email);
    insert.bindValue(QStringLiteral(":login"), login);
    insert.bindValue(QStringLiteral(":password_hash"), hashPassword(password));
    insert.bindValue(QStringLiteral(":role"), role);
    insert.bindValue(QStringLiteral(":approved"), approved);
    insert.bindValue(QStringLiteral(":created_at"), timestamp);
    insert.bindValue(QStringLiteral(":updated_at"), timestamp);

    if (!insert.exec()) {
        qWarning() << "Ошибка регистрации:" << insert.lastError().text();
        return errorResult(QStringLiteral("Не удалось создать учётную запись. Возможно, логин уже занят."));
    }

    const int officerId = insert.lastInsertId().toInt();

    const QUrl photoUrl(data.value(QStringLiteral("photo_url")).toString());
    if (!photoUrl.isEmpty() && !photoUrl.toString().isEmpty()) {
        QString photoError;
        const QString fileName = writePhotoFile(QStringLiteral("officer"), officerId, photoUrl, &photoError);
        if (!fileName.isEmpty()) {
            QSqlQuery update(m_database);
            update.prepare(QStringLiteral("UPDATE officers SET photo_path = :photo WHERE officer_id = :id"));
            update.bindValue(QStringLiteral(":photo"), fileName);
            update.bindValue(QStringLiteral(":id"), officerId);
            update.exec();
        }
    }

    return { { QStringLiteral("ok"), true },
             { QStringLiteral("id"), officerId },
             { QStringLiteral("isAdmin"), firstUser },
             { QStringLiteral("requiresApproval"), !firstUser },
             { QStringLiteral("user"), userMap(officerId) } };
}

QVariantList DatabaseManager::getOfficers()
{
    QVariantList result;
    QSqlQuery query(m_database);
    if (!query.exec(QStringLiteral(
            "SELECT o.*, "
            "(SELECT COUNT(*) FROM cases c WHERE c.investigator_id = o.officer_id) AS case_count, "
            "(SELECT COUNT(*) FROM recovery_codes r WHERE r.officer_id = o.officer_id AND r.used_at IS NULL) AS recovery_left "
            "FROM officers o ORDER BY o.is_approved DESC, o.last_name COLLATE NOCASE, o.name COLLATE NOCASE"))) {
        qWarning() << "Ошибка выборки сотрудников:" << query.lastError().text();
        return result;
    }

    while (query.next()) {
        const int id = query.value(QStringLiteral("officer_id")).toInt();
        const QString lastName = query.value(QStringLiteral("last_name")).toString();
        const QString firstName = query.value(QStringLiteral("name")).toString();
        const QString patronymic = query.value(QStringLiteral("patronymic")).toString();
        const QString birthDate = query.value(QStringLiteral("birth_date")).toString();
        const QString photoFile = query.value(QStringLiteral("photo_path")).toString();

        QVariantMap officer;
        officer[QStringLiteral("id")] = id;
        officer[QStringLiteral("officer_id")] = id;
        officer[QStringLiteral("last_name")] = lastName;
        officer[QStringLiteral("name")] = firstName;
        officer[QStringLiteral("patronymic")] = patronymic;
        officer[QStringLiteral("full_name")] = fullName(lastName, firstName, patronymic);
        officer[QStringLiteral("short_name")] = makeShortFio(lastName, firstName, patronymic);
        officer[QStringLiteral("rank")] = query.value(QStringLiteral("rank")).toString();
        officer[QStringLiteral("rank_category")] = query.value(QStringLiteral("rank_category")).toString();
        officer[QStringLiteral("position")] = query.value(QStringLiteral("position")).toString();
        officer[QStringLiteral("birth_date")] = birthDate;
        officer[QStringLiteral("age")] = yearsSince(birthDate);
        officer[QStringLiteral("personnel_number")] = query.value(QStringLiteral("personnel_number")).toString();
        officer[QStringLiteral("hire_date")] = query.value(QStringLiteral("hire_date")).toString();
        officer[QStringLiteral("experience")] = query.value(QStringLiteral("experience")).toInt();
        officer[QStringLiteral("phone")] = query.value(QStringLiteral("phone")).toString();
        officer[QStringLiteral("email")] = query.value(QStringLiteral("email")).toString();
        officer[QStringLiteral("login")] = query.value(QStringLiteral("system_login")).toString();
        officer[QStringLiteral("photo_url")] = photoUrlForFile(photoFile);
        officer[QStringLiteral("photo_path")] = photoFile;
        officer[QStringLiteral("role")] = query.value(QStringLiteral("role")).toString();
        officer[QStringLiteral("is_approved")] = query.value(QStringLiteral("is_approved")).toInt() != 0;
        officer[QStringLiteral("totp_enabled")] = query.value(QStringLiteral("totp_enabled")).toInt() != 0;
        officer[QStringLiteral("last_login")] = query.value(QStringLiteral("last_login")).toString();
        officer[QStringLiteral("created_at")] = query.value(QStringLiteral("created_at")).toString();
        officer[QStringLiteral("case_count")] = query.value(QStringLiteral("case_count")).toInt();
        officer[QStringLiteral("recovery_codes_left")] = query.value(QStringLiteral("recovery_left")).toInt();
        result.append(officer);
    }
    return result;
}

QVariantMap DatabaseManager::getOfficer(int officerId)
{
    QVariantMap officer = userMap(officerId);
    if (officer.isEmpty())
        return errorResult(QStringLiteral("Сотрудник не найден"));

    QVariantList relatedCases;
    QSqlQuery query(m_database);
    query.prepare(QStringLiteral(
        "SELECT case_id, case_number, title, status, date_opened FROM cases "
        "WHERE investigator_id = :id ORDER BY date_opened DESC LIMIT 20"));
    query.bindValue(QStringLiteral(":id"), officerId);
    if (query.exec()) {
        while (query.next()) {
            relatedCases.append(QVariantMap{
                { QStringLiteral("id"), query.value(0).toInt() },
                { QStringLiteral("case_number"), query.value(1).toString() },
                { QStringLiteral("title"), query.value(2).toString() },
                { QStringLiteral("status"), query.value(3).toString() },
                { QStringLiteral("date_opened"), query.value(4).toString() } });
        }
    }

    officer[QStringLiteral("ok")] = true;
    officer[QStringLiteral("cases")] = relatedCases;
    return officer;
}

QVariantMap DatabaseManager::updateOfficer(const QVariantMap &data)
{
    const QVariantMap auth = requireAuth();
    if (!auth.value(QStringLiteral("ok")).toBool())
        return auth;

    const int officerId = data.value(QStringLiteral("id"),
                                     data.value(QStringLiteral("officer_id"))).toInt();
    if (officerId <= 0)
        return errorResult(QStringLiteral("Сотрудник не найден"));

    QVariantMap existing = userMap(officerId);
    if (existing.isEmpty())
        return errorResult(QStringLiteral("Сотрудник не найден"));

    const bool isAdmin = currentUser().value(QStringLiteral("role")).toString() == QStringLiteral("admin");
    if (!isAdmin && officerId != m_currentOfficerId)
        return errorResult(QStringLiteral("Можно редактировать только свой профиль"));

    const QString timestamp = nowIso();

    if (!isAdmin) {
        const QString phone = mapString(data, "phone");
        if (!isValidPhone(phone))
            return errorResult(QStringLiteral("Некорректный номер телефона"));
        const QString email = mapString(data, "email");
        if (!isValidEmail(email))
            return errorResult(QStringLiteral("Некорректный адрес электронной почты"));

        QSqlQuery update(m_database);
        update.prepare(QStringLiteral("UPDATE officers SET phone = :phone, email = :email, updated_at = :updated WHERE officer_id = :id"));
        update.bindValue(QStringLiteral(":phone"), phone);
        update.bindValue(QStringLiteral(":email"), email);
        update.bindValue(QStringLiteral(":updated"), timestamp);
        update.bindValue(QStringLiteral(":id"), officerId);
        if (!update.exec())
            return errorResult(QStringLiteral("Не удалось сохранить профиль"));
        return { { QStringLiteral("ok"), true }, { QStringLiteral("user"), userMap(officerId) } };
    }

    for (auto it = data.constBegin(); it != data.constEnd(); ++it)
        existing[it.key()] = it.value();

    const QString lastName = mapString(existing, "last_name");
    const QString firstName = mapString(existing, "name");
    if (lastName.isEmpty() || firstName.isEmpty())
        return errorResult(QStringLiteral("Укажите фамилию и имя сотрудника"));

    QString rank = mapString(existing, "rank");
    QString rankCategory = mapString(existing, "rank_category");
    if (rankCategory.isEmpty())
        rankCategory = Reference::categoryForRank(rank);
    if (!Reference::isValidRank(rank))
        return errorResult(QStringLiteral("Выберите специальное звание из списка"));
    if (!Reference::isValidRankCategory(rankCategory))
        rankCategory = Reference::categoryForRank(rank);

    const QString position = mapString(existing, "position");
    if (!Reference::isValidPosition(position))
        return errorResult(QStringLiteral("Выберите должность из списка"));

    bool birthOk = false;
    const QString birthDate = normalizeDate(mapString(existing, "birth_date"), &birthOk);
    if (!birthOk)
        return errorResult(QStringLiteral("Некорректная дата рождения"));
    if (!birthDate.isEmpty() && (yearsSince(birthDate) < 18 || yearsSince(birthDate) > 75))
        return errorResult(QStringLiteral("Проверьте дату рождения сотрудника"));
    bool hireOk = false;
    const QString hireDate = normalizeDate(mapString(existing, "hire_date"), &hireOk);
    if (!hireOk)
        return errorResult(QStringLiteral("Некорректная дата приёма на службу"));
    if (!hireDate.isEmpty() && hireDate > QDate::currentDate().toString(QStringLiteral("yyyy-MM-dd")))
        return errorResult(QStringLiteral("Дата приёма не может быть в будущем"));

    const QString personnelNumber = mapString(existing, "personnel_number");
    if (!personnelNumber.isEmpty()) {
        QSqlQuery check(m_database);
        check.prepare(QStringLiteral(
            "SELECT COUNT(*) FROM officers WHERE personnel_number = :number AND officer_id <> :id"));
        check.bindValue(QStringLiteral(":number"), personnelNumber);
        check.bindValue(QStringLiteral(":id"), officerId);
        if (check.exec() && check.next() && check.value(0).toInt() > 0)
            return errorResult(QStringLiteral("Сотрудник с таким табельным номером уже существует"));
    }

    const QString phone = mapString(existing, "phone");
    if (!isValidPhone(phone))
        return errorResult(QStringLiteral("Некорректный номер телефона"));
    const QString email = mapString(existing, "email");
    if (!isValidEmail(email))
        return errorResult(QStringLiteral("Некорректный адрес электронной почты"));

    int experience = existing.value(QStringLiteral("experience")).toInt();
    experience = qBound(0, experience, 60);

    QSqlQuery update(m_database);
    update.prepare(QStringLiteral(
        "UPDATE officers SET last_name = :last_name, name = :name, patronymic = :patronymic, "
        "rank = :rank, rank_category = :rank_category, position = :position, birth_date = :birth_date, "
        "personnel_number = :personnel_number, hire_date = :hire_date, experience = :experience, "
        "phone = :phone, email = :email, updated_at = :updated WHERE officer_id = :id"));
    update.bindValue(QStringLiteral(":last_name"), lastName);
    update.bindValue(QStringLiteral(":name"), firstName);
    update.bindValue(QStringLiteral(":patronymic"), mapString(existing, "patronymic"));
    update.bindValue(QStringLiteral(":rank"), rank);
    update.bindValue(QStringLiteral(":rank_category"), rankCategory);
    update.bindValue(QStringLiteral(":position"), position);
    update.bindValue(QStringLiteral(":birth_date"), birthDate.isEmpty() ? QVariant(QMetaType(QMetaType::QString)) : QVariant(birthDate));
    update.bindValue(QStringLiteral(":personnel_number"), personnelNumber.isEmpty() ? QVariant(QMetaType(QMetaType::QString)) : QVariant(personnelNumber));
    update.bindValue(QStringLiteral(":hire_date"), hireDate.isEmpty() ? QVariant(QMetaType(QMetaType::QString)) : QVariant(hireDate));
    update.bindValue(QStringLiteral(":experience"), experience);
    update.bindValue(QStringLiteral(":phone"), phone);
    update.bindValue(QStringLiteral(":email"), email);
    update.bindValue(QStringLiteral(":updated"), timestamp);
    update.bindValue(QStringLiteral(":id"), officerId);

    if (!update.exec())
        return errorResult(QStringLiteral("Не удалось сохранить данные сотрудника"));

    return { { QStringLiteral("ok"), true }, { QStringLiteral("user"), userMap(officerId) } };
}

QVariantMap DatabaseManager::removeOfficer(int officerId)
{
    const QVariantMap auth = requireAdmin();
    if (!auth.value(QStringLiteral("ok")).toBool())
        return auth;
    if (officerId == m_currentOfficerId)
        return errorResult(QStringLiteral("Нельзя удалить собственную учётную запись"));

    const QVariantMap target = userMap(officerId);
    if (target.isEmpty())
        return errorResult(QStringLiteral("Сотрудник не найден"));
    if (target.value(QStringLiteral("role")).toString() == QStringLiteral("admin") && countAdmins(officerId) == 0)
        return errorResult(QStringLiteral("Нельзя удалить последнего администратора"));

    QSqlQuery detach(m_database);
    detach.prepare(QStringLiteral("UPDATE cases SET investigator_id = NULL WHERE investigator_id = :id"));
    detach.bindValue(QStringLiteral(":id"), officerId);
    detach.exec();

    QSqlQuery codes(m_database);
    codes.prepare(QStringLiteral("DELETE FROM recovery_codes WHERE officer_id = :id"));
    codes.bindValue(QStringLiteral(":id"), officerId);
    codes.exec();

    const QString photoFile = target.value(QStringLiteral("photo_path")).toString();

    QSqlQuery remove(m_database);
    remove.prepare(QStringLiteral("DELETE FROM officers WHERE officer_id = :id"));
    remove.bindValue(QStringLiteral(":id"), officerId);
    if (!remove.exec() || remove.numRowsAffected() == 0)
        return errorResult(QStringLiteral("Сотрудник не найден"));

    deletePhotoFile(photoFile);
    return successResult();
}

QVariantMap DatabaseManager::setOfficerApproval(int officerId, bool approved)
{
    const QVariantMap auth = requireAdmin();
    if (!auth.value(QStringLiteral("ok")).toBool())
        return auth;

    QSqlQuery update(m_database);
    update.prepare(QStringLiteral("UPDATE officers SET is_approved = :approved, updated_at = :updated WHERE officer_id = :id"));
    update.bindValue(QStringLiteral(":approved"), approved ? 1 : 0);
    update.bindValue(QStringLiteral(":updated"), nowIso());
    update.bindValue(QStringLiteral(":id"), officerId);
    if (!update.exec())
        return errorResult(QStringLiteral("Не удалось изменить статус учётной записи"));
    return successResult();
}

QVariantMap DatabaseManager::setOfficerRole(int officerId, const QString &role)
{
    const QVariantMap auth = requireAdmin();
    if (!auth.value(QStringLiteral("ok")).toBool())
        return auth;
    if (!Reference::roles().contains(role))
        return errorResult(QStringLiteral("Неизвестная роль"));
    if (officerId == m_currentOfficerId && role != QStringLiteral("admin"))
        return errorResult(QStringLiteral("Нельзя снять права администратора с самого себя"));
    if (role != QStringLiteral("admin")) {
        const QVariantMap target = userMap(officerId);
        if (target.value(QStringLiteral("role")).toString() == QStringLiteral("admin") && countAdmins(officerId) == 0)
            return errorResult(QStringLiteral("В системе должен остаться хотя бы один администратор"));
    }

    QSqlQuery update(m_database);
    update.prepare(QStringLiteral("UPDATE officers SET role = :role, updated_at = :updated WHERE officer_id = :id"));
    update.bindValue(QStringLiteral(":role"), role);
    update.bindValue(QStringLiteral(":updated"), nowIso());
    update.bindValue(QStringLiteral(":id"), officerId);
    if (!update.exec())
        return errorResult(QStringLiteral("Не удалось изменить роль"));
    return successResult();
}

// ---------------------------------------------------------------------------
// Личности
// ---------------------------------------------------------------------------

QVariantList DatabaseManager::getPersons()
{
    QVariantList result;
    QSqlQuery query(m_database);
    if (!query.exec(QStringLiteral(
            "SELECT p.*, c.case_number, c.title AS case_title FROM persons p "
            "LEFT JOIN cases c ON p.case_id = c.case_id "
            "ORDER BY p.last_name COLLATE NOCASE, p.name COLLATE NOCASE"))) {
        qWarning() << "Ошибка выборки личностей:" << query.lastError().text();
        return result;
    }

    while (query.next()) {
        const QString birthDate = query.value(QStringLiteral("birth_date")).toString();
        QVariantMap person;
        person[QStringLiteral("id")] = query.value(QStringLiteral("person_id")).toInt();
        person[QStringLiteral("person_id")] = query.value(QStringLiteral("person_id")).toInt();
        person[QStringLiteral("last_name")] = query.value(QStringLiteral("last_name")).toString();
        person[QStringLiteral("name")] = query.value(QStringLiteral("name")).toString();
        person[QStringLiteral("patronymic")] = query.value(QStringLiteral("patronymic")).toString();
        person[QStringLiteral("full_name")] = fullName(
            query.value(QStringLiteral("last_name")).toString(),
            query.value(QStringLiteral("name")).toString(),
            query.value(QStringLiteral("patronymic")).toString());
        person[QStringLiteral("birth_date")] = birthDate;
        person[QStringLiteral("age")] = yearsSince(birthDate);
        person[QStringLiteral("address")] = query.value(QStringLiteral("address")).toString();
        person[QStringLiteral("phone")] = query.value(QStringLiteral("phone")).toString();
        person[QStringLiteral("description")] = query.value(QStringLiteral("description")).toString();
        person[QStringLiteral("criminal_record")] = query.value(QStringLiteral("criminal_record")).toInt() != 0;
        person[QStringLiteral("status")] = query.value(QStringLiteral("status")).toString();
        person[QStringLiteral("case_id")] = query.value(QStringLiteral("case_id")).toInt();
        person[QStringLiteral("case_number")] = query.value(QStringLiteral("case_number")).toString();
        person[QStringLiteral("case_title")] = query.value(QStringLiteral("case_title")).toString();
        person[QStringLiteral("photo_url")] = photoUrlForFile(query.value(QStringLiteral("photo_path")).toString());
        person[QStringLiteral("photo_path")] = query.value(QStringLiteral("photo_path")).toString();
        person[QStringLiteral("created_at")] = query.value(QStringLiteral("created_at")).toString();
        result.append(person);
    }
    return result;
}

QVariantMap DatabaseManager::getPerson(int personId)
{
    QSqlQuery query(m_database);
    query.prepare(QStringLiteral(
        "SELECT p.*, c.case_number, c.title AS case_title FROM persons p "
        "LEFT JOIN cases c ON p.case_id = c.case_id WHERE p.person_id = :id"));
    query.bindValue(QStringLiteral(":id"), personId);
    if (!query.exec() || !query.next())
        return errorResult(QStringLiteral("Личность не найдена"));

    const QString birthDate = query.value(QStringLiteral("birth_date")).toString();
    QVariantMap person;
    person[QStringLiteral("ok")] = true;
    person[QStringLiteral("id")] = personId;
    person[QStringLiteral("person_id")] = personId;
    person[QStringLiteral("last_name")] = query.value(QStringLiteral("last_name")).toString();
    person[QStringLiteral("name")] = query.value(QStringLiteral("name")).toString();
    person[QStringLiteral("patronymic")] = query.value(QStringLiteral("patronymic")).toString();
    person[QStringLiteral("full_name")] = fullName(
        query.value(QStringLiteral("last_name")).toString(),
        query.value(QStringLiteral("name")).toString(),
        query.value(QStringLiteral("patronymic")).toString());
    person[QStringLiteral("birth_date")] = birthDate;
    person[QStringLiteral("age")] = yearsSince(birthDate);
    person[QStringLiteral("address")] = query.value(QStringLiteral("address")).toString();
    person[QStringLiteral("phone")] = query.value(QStringLiteral("phone")).toString();
    person[QStringLiteral("description")] = query.value(QStringLiteral("description")).toString();
    person[QStringLiteral("criminal_record")] = query.value(QStringLiteral("criminal_record")).toInt() != 0;
    person[QStringLiteral("status")] = query.value(QStringLiteral("status")).toString();
    person[QStringLiteral("case_id")] = query.value(QStringLiteral("case_id")).toInt();
    person[QStringLiteral("case_number")] = query.value(QStringLiteral("case_number")).toString();
    person[QStringLiteral("case_title")] = query.value(QStringLiteral("case_title")).toString();
    person[QStringLiteral("photo_url")] = photoUrlForFile(query.value(QStringLiteral("photo_path")).toString());
    person[QStringLiteral("photo_path")] = query.value(QStringLiteral("photo_path")).toString();
    person[QStringLiteral("created_at")] = query.value(QStringLiteral("created_at")).toString();
    return person;
}

QVariantMap DatabaseManager::createPerson(const QVariantMap &data)
{
    const QVariantMap auth = requireAuth();
    if (!auth.value(QStringLiteral("ok")).toBool())
        return auth;

    const QString lastName = mapString(data, "last_name", "surname");
    const QString firstName = mapString(data, "name");
    if (lastName.isEmpty() || firstName.isEmpty())
        return errorResult(QStringLiteral("Укажите фамилию и имя личности"));

    bool birthOk = false;
    const QString birthDate = normalizeDate(mapString(data, "birth_date", "birthDate"), &birthOk);
    if (!birthOk)
        return errorResult(QStringLiteral("Некорректная дата рождения"));

    const QString status = mapString(data, "status");
    if (!Reference::personStatuses().contains(status))
        return errorResult(QStringLiteral("Выберите статус личности"));

    int caseId = data.value(QStringLiteral("case_id")).toInt();
    if (caseId <= 0 && !mapString(data, "case_number").isEmpty()) {
        QSqlQuery caseQuery(m_database);
        caseQuery.prepare(QStringLiteral("SELECT case_id FROM cases WHERE case_number = :number"));
        caseQuery.bindValue(QStringLiteral(":number"), mapString(data, "case_number"));
        if (caseQuery.exec() && caseQuery.next())
            caseId = caseQuery.value(0).toInt();
    }
    if (caseId > 0) {
        QSqlQuery exists(m_database);
        exists.prepare(QStringLiteral("SELECT COUNT(*) FROM cases WHERE case_id = :id"));
        exists.bindValue(QStringLiteral(":id"), caseId);
        if (!exists.exec() || !exists.next() || exists.value(0).toInt() == 0)
            return errorResult(QStringLiteral("Уголовное дело не найдено"));
    }

    const QString timestamp = nowIso();
    QSqlQuery insert(m_database);
    insert.prepare(QStringLiteral(
        "INSERT INTO persons (last_name, name, patronymic, birth_date, address, phone, description, "
        "criminal_record, status, case_id, created_at, updated_at) "
        "VALUES (:last_name, :name, :patronymic, :birth_date, :address, :phone, :description, "
        ":criminal_record, :status, :case_id, :created_at, :updated_at)"));
    insert.bindValue(QStringLiteral(":last_name"), lastName);
    insert.bindValue(QStringLiteral(":name"), firstName);
    insert.bindValue(QStringLiteral(":patronymic"), mapString(data, "patronymic"));
    insert.bindValue(QStringLiteral(":birth_date"), birthDate.isEmpty() ? QVariant(QMetaType(QMetaType::QString)) : QVariant(birthDate));
    insert.bindValue(QStringLiteral(":address"), mapString(data, "address"));
    insert.bindValue(QStringLiteral(":phone"), mapString(data, "phone"));
    insert.bindValue(QStringLiteral(":description"), mapString(data, "description"));
    insert.bindValue(QStringLiteral(":criminal_record"), data.value(QStringLiteral("criminal_record")).toBool() ? 1 : 0);
    insert.bindValue(QStringLiteral(":status"), status);
    insert.bindValue(QStringLiteral(":case_id"), caseId > 0 ? QVariant(caseId) : QVariant(QMetaType(QMetaType::Int)));
    insert.bindValue(QStringLiteral(":created_at"), timestamp);
    insert.bindValue(QStringLiteral(":updated_at"), timestamp);

    if (!insert.exec()) {
        qWarning() << "Ошибка добавления личности:" << insert.lastError().text();
        return errorResult(QStringLiteral("Не удалось сохранить личность"));
    }

    const int personId = insert.lastInsertId().toInt();
    const QUrl photoUrl(data.value(QStringLiteral("photo_url")).toString());
    if (!photoUrl.isEmpty() && !photoUrl.toString().isEmpty()) {
        QSqlQuery update(m_database);
        QString error;
        const QString fileName = writePhotoFile(QStringLiteral("person"), personId, photoUrl, &error);
        if (!fileName.isEmpty()) {
            update.prepare(QStringLiteral("UPDATE persons SET photo_path = :photo WHERE person_id = :id"));
            update.bindValue(QStringLiteral(":photo"), fileName);
            update.bindValue(QStringLiteral(":id"), personId);
            update.exec();
        }
    }

    return { { QStringLiteral("ok"), true }, { QStringLiteral("id"), personId } };
}

QVariantMap DatabaseManager::updatePerson(const QVariantMap &data)
{
    const QVariantMap auth = requireAuth();
    if (!auth.value(QStringLiteral("ok")).toBool())
        return auth;

    const int personId = data.value(QStringLiteral("id"),
                                    data.value(QStringLiteral("person_id"))).toInt();
    const QVariantMap existing = getPerson(personId);
    if (personId <= 0 || !existing.value(QStringLiteral("ok")).toBool())
        return errorResult(QStringLiteral("Личность не найдена"));

    QVariantMap merged = existing;
    for (auto it = data.constBegin(); it != data.constEnd(); ++it)
        merged[it.key()] = it.value();

    const QString lastName = mapString(merged, "last_name");
    const QString firstName = mapString(merged, "name");
    if (lastName.isEmpty() || firstName.isEmpty())
        return errorResult(QStringLiteral("Укажите фамилию и имя личности"));

    bool birthOk = false;
    const QString birthDate = normalizeDate(mapString(merged, "birth_date"), &birthOk);
    if (!birthOk)
        return errorResult(QStringLiteral("Некорректная дата рождения"));

    const QString status = mapString(merged, "status");
    if (!Reference::personStatuses().contains(status))
        return errorResult(QStringLiteral("Выберите статус личности"));

    int caseId = merged.value(QStringLiteral("case_id")).toInt();
    if (caseId > 0) {
        QSqlQuery check(m_database);
        check.prepare(QStringLiteral("SELECT COUNT(*) FROM cases WHERE case_id = :id"));
        check.bindValue(QStringLiteral(":id"), caseId);
        if (!check.exec() || !check.next() || check.value(0).toInt() == 0)
            return errorResult(QStringLiteral("Уголовное дело не найдено"));
    }

    QSqlQuery update(m_database);
    update.prepare(QStringLiteral(
        "UPDATE persons SET last_name = :last_name, name = :name, patronymic = :patronymic, "
        "birth_date = :birth_date, address = :address, phone = :phone, description = :description, "
        "criminal_record = :criminal_record, status = :status, case_id = :case_id, updated_at = :updated "
        "WHERE person_id = :id"));
    update.bindValue(QStringLiteral(":last_name"), lastName);
    update.bindValue(QStringLiteral(":name"), firstName);
    update.bindValue(QStringLiteral(":patronymic"), mapString(merged, "patronymic"));
    update.bindValue(QStringLiteral(":birth_date"), birthDate.isEmpty() ? QVariant(QMetaType(QMetaType::QString)) : QVariant(birthDate));
    update.bindValue(QStringLiteral(":address"), mapString(merged, "address"));
    update.bindValue(QStringLiteral(":phone"), mapString(merged, "phone"));
    update.bindValue(QStringLiteral(":description"), mapString(merged, "description"));
    update.bindValue(QStringLiteral(":criminal_record"), merged.value(QStringLiteral("criminal_record")).toBool() ? 1 : 0);
    update.bindValue(QStringLiteral(":status"), status);
    update.bindValue(QStringLiteral(":case_id"), caseId > 0 ? QVariant(caseId) : QVariant(QMetaType(QMetaType::Int)));
    update.bindValue(QStringLiteral(":updated"), nowIso());
    update.bindValue(QStringLiteral(":id"), personId);

    if (!update.exec())
        return errorResult(QStringLiteral("Не удалось сохранить личность"));

    return successResult();
}

QVariantMap DatabaseManager::removePerson(int personId)
{
    const QVariantMap auth = requireAuth();
    if (!auth.value(QStringLiteral("ok")).toBool())
        return auth;

    QSqlQuery query(m_database);
    query.prepare(QStringLiteral("SELECT photo_path FROM persons WHERE person_id = :id"));
    query.bindValue(QStringLiteral(":id"), personId);
    if (!query.exec() || !query.next())
        return errorResult(QStringLiteral("Личность не найдена"));
    const QString photoFile = query.value(0).toString();

    QSqlQuery remove(m_database);
    remove.prepare(QStringLiteral("DELETE FROM persons WHERE person_id = :id"));
    remove.bindValue(QStringLiteral(":id"), personId);
    if (!remove.exec() || remove.numRowsAffected() == 0)
        return errorResult(QStringLiteral("Личность не найдена"));

    deletePhotoFile(photoFile);
    return successResult();
}

// ---------------------------------------------------------------------------
// Дела
// ---------------------------------------------------------------------------

QVariantList DatabaseManager::getCases()
{
    QVariantList result;
    QSqlQuery query(m_database);
    if (!query.exec(QStringLiteral(
            "SELECT c.*, "
            "TRIM(COALESCE(o.last_name, '') || ' ' || COALESCE(o.name, '') || ' ' || COALESCE(o.patronymic, '')) AS investigator_name, "
            "o.rank AS investigator_rank, o.photo_path AS investigator_photo, "
            "(SELECT COUNT(*) FROM persons p WHERE p.case_id = c.case_id) AS persons_count, "
            "(SELECT COUNT(*) FROM evidence e WHERE e.case_id = c.case_id) AS evidence_count "
            "FROM cases c LEFT JOIN officers o ON c.investigator_id = o.officer_id "
            "ORDER BY c.date_opened DESC, c.case_id DESC"))) {
        qWarning() << "Ошибка выборки дел:" << query.lastError().text();
        return result;
    }

    while (query.next()) {
        QVariantMap item;
        item[QStringLiteral("id")] = query.value(QStringLiteral("case_id")).toInt();
        item[QStringLiteral("case_id")] = query.value(QStringLiteral("case_id")).toInt();
        item[QStringLiteral("case_number")] = query.value(QStringLiteral("case_number")).toString();
        item[QStringLiteral("title")] = query.value(QStringLiteral("title")).toString();
        item[QStringLiteral("description")] = query.value(QStringLiteral("description")).toString();
        item[QStringLiteral("date_opened")] = query.value(QStringLiteral("date_opened")).toString();
        item[QStringLiteral("date_closed")] = query.value(QStringLiteral("date_closed")).toString();
        item[QStringLiteral("status")] = query.value(QStringLiteral("status")).toString();
        item[QStringLiteral("investigator_id")] = query.value(QStringLiteral("investigator_id")).toInt();
        item[QStringLiteral("investigator_name")] = query.value(QStringLiteral("investigator_name")).toString().simplified();
        item[QStringLiteral("investigator_rank")] = query.value(QStringLiteral("investigator_rank")).toString();
        item[QStringLiteral("investigator_photo_url")] = photoUrlForFile(query.value(QStringLiteral("investigator_photo")).toString());
        item[QStringLiteral("persons_count")] = query.value(QStringLiteral("persons_count")).toInt();
        item[QStringLiteral("evidence_count")] = query.value(QStringLiteral("evidence_count")).toInt();
        item[QStringLiteral("created_at")] = query.value(QStringLiteral("created_at")).toString();
        result.append(item);
    }
    return result;
}

QVariantMap DatabaseManager::getCase(int caseId)
{
    QVariantMap found;
    const QVariantList cases = getCases();
    for (const QVariant &value : cases) {
        const QVariantMap item = value.toMap();
        if (item.value(QStringLiteral("case_id")).toInt() == caseId) {
            found = item;
            break;
        }
    }
    if (found.isEmpty())
        return errorResult(QStringLiteral("Уголовное дело не найдено"));
    found[QStringLiteral("ok")] = true;
    return found;
}

QVariantList DatabaseManager::getCaseOptions()
{
    QVariantList result;
    QSqlQuery query(m_database);
    if (!query.exec(QStringLiteral("SELECT case_id, case_number, title, status FROM cases ORDER BY date_opened DESC")))
        return result;

    while (query.next()) {
        const QString number = query.value(1).toString();
        const QString title = query.value(2).toString();
        result.append(QVariantMap{
            { QStringLiteral("id"), query.value(0).toInt() },
            { QStringLiteral("case_number"), number },
            { QStringLiteral("title"), title },
            { QStringLiteral("status"), query.value(3).toString() },
            { QStringLiteral("label"), QStringLiteral("№ %1 — %2").arg(number, title) } });
    }
    return result;
}

QVariantMap DatabaseManager::createCase(const QVariantMap &data)
{
    const QVariantMap auth = requireAuth();
    if (!auth.value(QStringLiteral("ok")).toBool())
        return auth;

    const QString caseNumber = mapString(data, "case_number", "caseNumber");
    const QString title = mapString(data, "title");
    if (caseNumber.isEmpty() || title.isEmpty())
        return errorResult(QStringLiteral("Укажите номер и название дела"));
    if (caseNumber.size() > 32)
        return errorResult(QStringLiteral("Номер дела слишком длинный"));

    const QString status = mapString(data, "status");
    if (!Reference::caseStatuses().contains(status))
        return errorResult(QStringLiteral("Выберите статус дела"));

    bool openedOk = false;
    QString dateOpened = normalizeDate(mapString(data, "date_opened", "dateOpened"), &openedOk);
    if (!openedOk)
        return errorResult(QStringLiteral("Некорректная дата возбуждения дела"));
    if (dateOpened.isEmpty())
        dateOpened = QDate::currentDate().toString(QStringLiteral("yyyy-MM-dd"));
    if (dateOpened > QDate::currentDate().toString(QStringLiteral("yyyy-MM-dd")))
        return errorResult(QStringLiteral("Дата возбуждения не может быть в будущем"));

    bool closedOk = false;
    QString dateClosed = normalizeDate(mapString(data, "date_closed", "dateClosed"), &closedOk);
    if (!closedOk)
        return errorResult(QStringLiteral("Некорректная дата закрытия дела"));
    if (status == QStringLiteral("Закрыто") && dateClosed.isEmpty())
        dateClosed = QDate::currentDate().toString(QStringLiteral("yyyy-MM-dd"));
    if (status != QStringLiteral("Закрыто"))
        dateClosed.clear();
    if (!dateClosed.isEmpty() && dateClosed < dateOpened)
        return errorResult(QStringLiteral("Дата закрытия не может быть раньше даты возбуждения"));

    int investigatorId = data.value(QStringLiteral("investigator_id"),
                                    data.value(QStringLiteral("investigatorId"))).toInt();
    if (investigatorId > 0) {
        QSqlQuery check(m_database);
        check.prepare(QStringLiteral("SELECT COUNT(*) FROM officers WHERE officer_id = :id AND is_approved = 1"));
        check.bindValue(QStringLiteral(":id"), investigatorId);
        if (!check.exec() || !check.next() || check.value(0).toInt() == 0)
            investigatorId = 0;
    }

    const QString timestamp = nowIso();
    QSqlQuery insert(m_database);
    insert.prepare(QStringLiteral(
        "INSERT INTO cases (case_number, title, description, date_opened, date_closed, status, "
        "investigator_id, created_at, updated_at) "
        "VALUES (:case_number, :title, :description, :date_opened, :date_closed, :status, "
        ":investigator_id, :created_at, :updated_at)"));
    insert.bindValue(QStringLiteral(":case_number"), caseNumber);
    insert.bindValue(QStringLiteral(":title"), title);
    insert.bindValue(QStringLiteral(":description"), mapString(data, "description"));
    insert.bindValue(QStringLiteral(":date_opened"), dateOpened);
    insert.bindValue(QStringLiteral(":date_closed"), dateClosed.isEmpty() ? QVariant(QMetaType(QMetaType::QString)) : QVariant(dateClosed));
    insert.bindValue(QStringLiteral(":status"), status);
    insert.bindValue(QStringLiteral(":investigator_id"), investigatorId > 0 ? QVariant(investigatorId) : QVariant(QMetaType(QMetaType::Int)));
    insert.bindValue(QStringLiteral(":created_at"), timestamp);
    insert.bindValue(QStringLiteral(":updated_at"), timestamp);

    if (!insert.exec()) {
        qWarning() << "Ошибка добавления дела:" << insert.lastError().text();
        return errorResult(QStringLiteral("Не удалось сохранить дело. Возможно, такой номер уже существует."));
    }

    return { { QStringLiteral("ok"), true }, { QStringLiteral("id"), insert.lastInsertId().toInt() } };
}

QVariantMap DatabaseManager::updateCase(const QVariantMap &data)
{
    const QVariantMap auth = requireAuth();
    if (!auth.value(QStringLiteral("ok")).toBool())
        return auth;

    const int caseId = data.value(QStringLiteral("id"),
                                  data.value(QStringLiteral("case_id"))).toInt();
    if (caseId <= 0)
        return errorResult(QStringLiteral("Уголовное дело не найдено"));

    const QVariantMap existing = getCase(caseId);
    if (!existing.value(QStringLiteral("ok")).toBool())
        return errorResult(QStringLiteral("Уголовное дело не найдено"));

    QVariantMap merged = existing;
    for (auto it = data.constBegin(); it != data.constEnd(); ++it)
        merged[it.key()] = it.value();

    const QString caseNumber = mapString(merged, "case_number");
    const QString title = mapString(merged, "title");
    if (caseNumber.isEmpty() || title.isEmpty())
        return errorResult(QStringLiteral("Укажите номер и название дела"));

    const QString status = mapString(merged, "status");
    if (!Reference::caseStatuses().contains(status))
        return errorResult(QStringLiteral("Выберите статус дела"));

    bool openedOk = false;
    const QString dateOpened = normalizeDate(mapString(merged, "date_opened"), &openedOk);
    if (!openedOk || dateOpened.isEmpty())
        return errorResult(QStringLiteral("Некорректная дата возбуждения дела"));
    if (dateOpened > QDate::currentDate().toString(QStringLiteral("yyyy-MM-dd")))
        return errorResult(QStringLiteral("Дата возбуждения не может быть в будущем"));

    bool closedOk = false;
    QString dateClosed = normalizeDate(mapString(merged, "date_closed"), &closedOk);
    if (!closedOk)
        return errorResult(QStringLiteral("Некорректная дата закрытия дела"));
    if (status == QStringLiteral("Закрыто") && dateClosed.isEmpty())
        dateClosed = QDate::currentDate().toString(QStringLiteral("yyyy-MM-dd"));
    if (status != QStringLiteral("Закрыто"))
        dateClosed.clear();
    if (!dateClosed.isEmpty() && dateClosed < dateOpened)
        return errorResult(QStringLiteral("Дата закрытия не может быть раньше даты возбуждения"));

    int investigatorId = merged.value(QStringLiteral("investigator_id")).toInt();

    QSqlQuery update(m_database);
    update.prepare(QStringLiteral(
        "UPDATE cases SET case_number = :case_number, title = :title, description = :description, "
        "date_opened = :date_opened, date_closed = :date_closed, status = :status, "
        "investigator_id = :investigator_id, updated_at = :updated WHERE case_id = :id"));
    update.bindValue(QStringLiteral(":case_number"), caseNumber);
    update.bindValue(QStringLiteral(":title"), title);
    update.bindValue(QStringLiteral(":description"), mapString(merged, "description"));
    update.bindValue(QStringLiteral(":date_opened"), dateOpened);
    update.bindValue(QStringLiteral(":date_closed"), dateClosed.isEmpty() ? QVariant(QMetaType(QMetaType::QString)) : QVariant(dateClosed));
    update.bindValue(QStringLiteral(":status"), status);
    update.bindValue(QStringLiteral(":investigator_id"), investigatorId > 0 ? QVariant(investigatorId) : QVariant(QMetaType(QMetaType::Int)));
    update.bindValue(QStringLiteral(":updated"), nowIso());
    update.bindValue(QStringLiteral(":id"), caseId);

    if (!update.exec())
        return errorResult(QStringLiteral("Не удалось сохранить дело. Возможно, номер уже занят."));

    return successResult();
}

QVariantMap DatabaseManager::removeCase(int caseId, bool cascade)
{
    const QVariantMap auth = requireAuth();
    if (!auth.value(QStringLiteral("ok")).toBool())
        return auth;

    QSqlQuery counts(m_database);
    counts.prepare(QStringLiteral(
        "SELECT (SELECT COUNT(*) FROM persons WHERE case_id = :id), "
        "(SELECT COUNT(*) FROM evidence WHERE case_id = :id)"));
    counts.bindValue(QStringLiteral(":id"), caseId);
    if (!counts.exec() || !counts.next())
        return errorResult(QStringLiteral("Уголовное дело не найдено"));

    const int personsCount = counts.value(0).toInt();
    const int evidenceCount = counts.value(1).toInt();

    if (!cascade && (personsCount > 0 || evidenceCount > 0)) {
        return { { QStringLiteral("ok"), false },
                 { QStringLiteral("requiresCascade"), true },
                 { QStringLiteral("persons"), personsCount },
                 { QStringLiteral("evidence"), evidenceCount },
                 { QStringLiteral("error"),
                   QStringLiteral("К делу привязаны материалы (%1) и личности (%2)")
                       .arg(evidenceCount)
                       .arg(personsCount) } };
    }

    if (!cascade) {
        QSqlQuery remove(m_database);
        remove.prepare(QStringLiteral("DELETE FROM cases WHERE case_id = :id"));
        remove.bindValue(QStringLiteral(":id"), caseId);
        if (!remove.exec())
            return errorResult(QStringLiteral("Не удалось удалить дело"));
        return successResult();
    }

    m_database.transaction();
    QSqlQuery evidenceDelete(m_database);
    evidenceDelete.prepare(QStringLiteral("DELETE FROM evidence WHERE case_id = :id"));
    evidenceDelete.bindValue(QStringLiteral(":id"), caseId);
    const bool evidenceOk = evidenceDelete.exec();

    QSqlQuery personsDetach(m_database);
    personsDetach.prepare(QStringLiteral("UPDATE persons SET case_id = NULL WHERE case_id = :id"));
    personsDetach.bindValue(QStringLiteral(":id"), caseId);
    const bool personsOk = personsDetach.exec();

    QSqlQuery remove(m_database);
    remove.prepare(QStringLiteral("DELETE FROM cases WHERE case_id = :id"));
    remove.bindValue(QStringLiteral(":id"), caseId);
    const bool removed = remove.exec();

    if (!evidenceOk || !personsOk || !removed) {
        m_database.rollback();
        return errorResult(QStringLiteral("Не удалось удалить дело"));
    }
    m_database.commit();
    return successResult();
}

// ---------------------------------------------------------------------------
// Вещественные доказательства
// ---------------------------------------------------------------------------

QVariantList DatabaseManager::getEvidence()
{
    QVariantList result;
    QSqlQuery query(m_database);
    if (!query.exec(QStringLiteral(
            "SELECT e.*, c.case_number, c.title AS case_title, "
            "TRIM(COALESCE(o.last_name, '') || ' ' || COALESCE(o.name, '')) AS officer_name "
            "FROM evidence e "
            "LEFT JOIN cases c ON e.case_id = c.case_id "
            "LEFT JOIN officers o ON e.created_by = o.officer_id "
            "ORDER BY e.registration_date DESC, e.evidence_id DESC"))) {
        qWarning() << "Ошибка выборки материалов:" << query.lastError().text();
        return result;
    }

    while (query.next()) {
        QVariantMap item;
        item[QStringLiteral("id")] = query.value(QStringLiteral("evidence_id")).toInt();
        item[QStringLiteral("evidence_id")] = query.value(QStringLiteral("evidence_id")).toInt();
        item[QStringLiteral("type")] = query.value(QStringLiteral("type")).toString();
        item[QStringLiteral("description")] = query.value(QStringLiteral("description")).toString();
        item[QStringLiteral("registration_date")] = query.value(QStringLiteral("registration_date")).toString();
        item[QStringLiteral("current_status")] = query.value(QStringLiteral("current_status")).toString();
        item[QStringLiteral("case_id")] = query.value(QStringLiteral("case_id")).toInt();
        item[QStringLiteral("case_number")] = query.value(QStringLiteral("case_number")).toString();
        item[QStringLiteral("case_title")] = query.value(QStringLiteral("case_title")).toString();
        item[QStringLiteral("storage_location")] = query.value(QStringLiteral("storage_location")).toString();
        item[QStringLiteral("officer_name")] = query.value(QStringLiteral("officer_name")).toString();
        item[QStringLiteral("created_by")] = query.value(QStringLiteral("created_by")).toInt();
        item[QStringLiteral("created_at")] = query.value(QStringLiteral("created_at")).toString();
        result.append(item);
    }
    return result;
}

QVariantMap DatabaseManager::getEvidenceItem(int evidenceId)
{
    const QVariantList items = getEvidence();
    for (const QVariant &value : items) {
        QVariantMap item = value.toMap();
        if (item.value(QStringLiteral("evidence_id")).toInt() == evidenceId) {
            item[QStringLiteral("ok")] = true;
            return item;
        }
    }
    return errorResult(QStringLiteral("Материал не найден"));
}

QVariantMap DatabaseManager::createEvidence(const QVariantMap &data)
{
    const QVariantMap auth = requireAuth();
    if (!auth.value(QStringLiteral("ok")).toBool())
        return auth;

    const QString type = mapString(data, "type");
    if (!Reference::evidenceTypes().contains(type))
        return errorResult(QStringLiteral("Выберите тип материала"));
    const QString description = mapString(data, "description");
    if (description.isEmpty())
        return errorResult(QStringLiteral("Добавьте описание материала"));

    QString status = mapString(data, "current_status", "currentStatus");
    if (status.isEmpty())
        status = QStringLiteral("Изъято");
    if (!Reference::evidenceStatuses().contains(status))
        return errorResult(QStringLiteral("Выберите статус материала"));

    bool dateOk = false;
    QString registrationDate = normalizeDateTime(mapString(data, "registration_date", "registrationDate"), &dateOk);
    if (!dateOk)
        return errorResult(QStringLiteral("Некорректная дата регистрации"));
    if (registrationDate.isEmpty())
        registrationDate = nowIso();

    int caseId = data.value(QStringLiteral("case_id"),
                            data.value(QStringLiteral("caseId"))).toInt();
    if (caseId <= 0 && !mapString(data, "caseNumber").isEmpty()) {
        QSqlQuery caseQuery(m_database);
        caseQuery.prepare(QStringLiteral("SELECT case_id FROM cases WHERE case_number = :number"));
        caseQuery.bindValue(QStringLiteral(":number"), mapString(data, "caseNumber"));
        if (caseQuery.exec() && caseQuery.next())
            caseId = caseQuery.value(0).toInt();
    }

    if (caseId > 0) {
        QSqlQuery caseQuery(m_database);
        caseQuery.prepare(QStringLiteral("SELECT COUNT(*) FROM cases WHERE case_id = :id"));
        caseQuery.bindValue(QStringLiteral(":id"), caseId);
        if (!caseQuery.exec() || !caseQuery.next() || caseQuery.value(0).toInt() == 0)
            return errorResult(QStringLiteral("Уголовное дело не найдено"));
    }

    const QString timestamp = nowIso();
    QSqlQuery insert(m_database);
    insert.prepare(QStringLiteral(
        "INSERT INTO evidence (type, description, registration_date, current_status, case_id, "
        "storage_location, created_by, created_at, updated_at) "
        "VALUES (:type, :description, :registration_date, :current_status, :case_id, "
        ":storage_location, :created_by, :created_at, :updated_at)"));
    insert.bindValue(QStringLiteral(":type"), type);
    insert.bindValue(QStringLiteral(":description"), description);
    insert.bindValue(QStringLiteral(":registration_date"), registrationDate);
    insert.bindValue(QStringLiteral(":current_status"), status);
    insert.bindValue(QStringLiteral(":case_id"), caseId > 0 ? QVariant(caseId) : QVariant(QMetaType(QMetaType::Int)));
    insert.bindValue(QStringLiteral(":storage_location"), mapString(data, "storage_location"));
    insert.bindValue(QStringLiteral(":created_by"), m_currentOfficerId > 0 ? QVariant(m_currentOfficerId) : QVariant(QMetaType(QMetaType::Int)));
    insert.bindValue(QStringLiteral(":created_at"), timestamp);
    insert.bindValue(QStringLiteral(":updated_at"), timestamp);

    if (!insert.exec()) {
        qWarning() << "Ошибка добавления материала:" << insert.lastError().text();
        return errorResult(QStringLiteral("Не удалось сохранить материал"));
    }
    return { { QStringLiteral("ok"), true }, { QStringLiteral("id"), insert.lastInsertId().toInt() } };
}

QVariantMap DatabaseManager::updateEvidence(const QVariantMap &data)
{
    const QVariantMap auth = requireAuth();
    if (!auth.value(QStringLiteral("ok")).toBool())
        return auth;

    const int evidenceId = data.value(QStringLiteral("id"),
                                      data.value(QStringLiteral("evidence_id"))).toInt();
    const QVariantMap existing = getEvidenceItem(evidenceId);
    if (evidenceId <= 0 || !existing.value(QStringLiteral("ok")).toBool())
        return errorResult(QStringLiteral("Материал не найден"));

    QVariantMap merged = existing;
    for (auto it = data.constBegin(); it != data.constEnd(); ++it)
        merged[it.key()] = it.value();

    const QString type = mapString(merged, "type");
    if (!Reference::evidenceTypes().contains(type))
        return errorResult(QStringLiteral("Выберите тип материала"));
    const QString description = mapString(merged, "description");
    if (description.isEmpty())
        return errorResult(QStringLiteral("Добавьте описание материала"));
    const QString status = mapString(merged, "current_status");
    if (!Reference::evidenceStatuses().contains(status))
        return errorResult(QStringLiteral("Выберите статус материала"));

    bool dateOk = false;
    const QString registrationDate = normalizeDateTime(mapString(merged, "registration_date"), &dateOk);
    if (!dateOk || registrationDate.isEmpty())
        return errorResult(QStringLiteral("Некорректная дата регистрации"));

    int caseId = merged.value(QStringLiteral("case_id")).toInt();
    if (caseId > 0) {
        QSqlQuery check(m_database);
        check.prepare(QStringLiteral("SELECT COUNT(*) FROM cases WHERE case_id = :id"));
        check.bindValue(QStringLiteral(":id"), caseId);
        if (!check.exec() || !check.next() || check.value(0).toInt() == 0)
            return errorResult(QStringLiteral("Уголовное дело не найдено"));
    }

    QSqlQuery update(m_database);
    update.prepare(QStringLiteral(
        "UPDATE evidence SET type = :type, description = :description, registration_date = :registration_date, "
        "current_status = :current_status, case_id = :case_id, storage_location = :storage_location, "
        "updated_at = :updated WHERE evidence_id = :id"));
    update.bindValue(QStringLiteral(":type"), type);
    update.bindValue(QStringLiteral(":description"), description);
    update.bindValue(QStringLiteral(":registration_date"), registrationDate);
    update.bindValue(QStringLiteral(":current_status"), status);
    update.bindValue(QStringLiteral(":case_id"), caseId > 0 ? QVariant(caseId) : QVariant(QMetaType(QMetaType::Int)));
    update.bindValue(QStringLiteral(":storage_location"), mapString(merged, "storage_location"));
    update.bindValue(QStringLiteral(":updated"), nowIso());
    update.bindValue(QStringLiteral(":id"), evidenceId);

    if (!update.exec())
        return errorResult(QStringLiteral("Не удалось сохранить материал"));
    return successResult();
}

QVariantMap DatabaseManager::removeEvidence(int evidenceId)
{
    const QVariantMap auth = requireAuth();
    if (!auth.value(QStringLiteral("ok")).toBool())
        return auth;

    QSqlQuery remove(m_database);
    remove.prepare(QStringLiteral("DELETE FROM evidence WHERE evidence_id = :id"));
    remove.bindValue(QStringLiteral(":id"), evidenceId);
    if (!remove.exec() || remove.numRowsAffected() == 0)
        return errorResult(QStringLiteral("Материал не найден"));
    return successResult();
}

// ---------------------------------------------------------------------------
// Безопасность учётной записи
// ---------------------------------------------------------------------------

QVariantMap DatabaseManager::changePassword(const QString &currentPassword, const QString &newPassword)
{
    const QVariantMap auth = requireAuth();
    if (!auth.value(QStringLiteral("ok")).toBool())
        return auth;

    QSqlQuery query(m_database);
    query.prepare(QStringLiteral("SELECT password_hash FROM officers WHERE officer_id = :id"));
    query.bindValue(QStringLiteral(":id"), m_currentOfficerId);
    if (!query.exec() || !query.next())
        return errorResult(QStringLiteral("Сотрудник не найден"));

    if (!verifyPassword(currentPassword, query.value(0).toString()))
        return errorResult(QStringLiteral("Текущий пароль указан неверно"));

    QString reason;
    if (!isValidPassword(newPassword, &reason))
        return errorResult(reason);
    if (currentPassword == newPassword)
        return errorResult(QStringLiteral("Новый пароль должен отличаться от текущего"));

    QSqlQuery update(m_database);
    update.prepare(QStringLiteral("UPDATE officers SET password_hash = :hash, updated_at = :updated WHERE officer_id = :id"));
    update.bindValue(QStringLiteral(":hash"), hashPassword(newPassword));
    update.bindValue(QStringLiteral(":updated"), nowIso());
    update.bindValue(QStringLiteral(":id"), m_currentOfficerId);
    if (!update.exec())
        return errorResult(QStringLiteral("Не удалось изменить пароль"));
    return successResult();
}

QVariantMap DatabaseManager::beginTwoFactorSetup()
{
    const QVariantMap auth = requireAuth();
    if (!auth.value(QStringLiteral("ok")).toBool())
        return auth;

    m_pendingTotpSecret = TotpAuth::generateSecret(20);
    const QString login = loginForOfficer(m_currentOfficerId);
    const QString uri = TotpAuth::otpauthUri(m_pendingTotpSecret, login);

    QString grouped;
    for (int i = 0; i < m_pendingTotpSecret.size(); ++i) {
        if (i > 0 && i % 4 == 0)
            grouped += QLatin1Char(' ');
        grouped += m_pendingTotpSecret.at(i);
    }

    return { { QStringLiteral("ok"), true },
             { QStringLiteral("secret"), m_pendingTotpSecret },
             { QStringLiteral("secretGrouped"), grouped },
             { QStringLiteral("otpauth"), uri },
             { QStringLiteral("account"), login } };
}

QVariantMap DatabaseManager::confirmTwoFactorSetup(const QString &code)
{
    const QVariantMap auth = requireAuth();
    if (!auth.value(QStringLiteral("ok")).toBool())
        return auth;
    if (m_pendingTotpSecret.isEmpty())
        return errorResult(QStringLiteral("Сначала начните настройку 2FA"));
    if (!TotpAuth::verify(m_pendingTotpSecret, code))
        return errorResult(QStringLiteral("Неверный код. Проверьте время на устройстве и попробуйте снова"));

    QSqlQuery update(m_database);
    update.prepare(QStringLiteral("UPDATE officers SET totp_secret = :secret, totp_enabled = 1, updated_at = :updated "
                                  "WHERE officer_id = :id"));
    update.bindValue(QStringLiteral(":secret"), m_pendingTotpSecret);
    update.bindValue(QStringLiteral(":updated"), nowIso());
    update.bindValue(QStringLiteral(":id"), m_currentOfficerId);
    if (!update.exec())
        return errorResult(QStringLiteral("Не удалось включить 2FA"));

    const QString secret = m_pendingTotpSecret;
    m_pendingTotpSecret.clear();

    QSqlQuery clear(m_database);
    clear.prepare(QStringLiteral("DELETE FROM recovery_codes WHERE officer_id = :id"));
    clear.bindValue(QStringLiteral(":id"), m_currentOfficerId);
    clear.exec();

    QStringList codes;
    for (int i = 0; i < 8; ++i) {
        const QString codeValue = TotpAuth::generateRecoveryCode();
        QSqlQuery insert(m_database);
        insert.prepare(QStringLiteral("INSERT INTO recovery_codes (officer_id, code_hash, created_at) "
                                      "VALUES (:id, :hash, :created)"));
        insert.bindValue(QStringLiteral(":id"), m_currentOfficerId);
        insert.bindValue(QStringLiteral(":hash"),
                         QString::fromLatin1(TotpAuth::hashRecoveryCode(codeValue).toHex()));
        insert.bindValue(QStringLiteral(":created"), nowIso());
        insert.exec();
        codes << codeValue;
    }

    Q_UNUSED(secret);
    QVariantList codeList;
    for (const QString &value : codes)
        codeList.append(value);

    return { { QStringLiteral("ok"), true }, { QStringLiteral("recoveryCodes"), codeList } };
}

QVariantMap DatabaseManager::disableTwoFactor(const QString &password, const QString &code)
{
    const QVariantMap auth = requireAuth();
    if (!auth.value(QStringLiteral("ok")).toBool())
        return auth;

    QSqlQuery query(m_database);
    query.prepare(QStringLiteral("SELECT password_hash, totp_secret, totp_enabled FROM officers WHERE officer_id = :id"));
    query.bindValue(QStringLiteral(":id"), m_currentOfficerId);
    if (!query.exec() || !query.next())
        return errorResult(QStringLiteral("Сотрудник не найден"));

    if (!verifyPassword(password, query.value(0).toString()))
        return errorResult(QStringLiteral("Пароль указан неверно"));

    const bool enabled = query.value(2).toInt() != 0;
    if (!enabled)
        return errorResult(QStringLiteral("Двухфакторная аутентификация не включена"));

    const QString secret = query.value(1).toString();
    bool codeValid = TotpAuth::verify(secret, code);
    if (!codeValid) {
        const QByteArray hash = TotpAuth::hashRecoveryCode(code);
        QSqlQuery codes(m_database);
        codes.prepare(QStringLiteral("SELECT code_id, code_hash FROM recovery_codes WHERE officer_id = :id AND used_at IS NULL"));
        codes.bindValue(QStringLiteral(":id"), m_currentOfficerId);
        if (codes.exec()) {
            while (codes.next()) {
                if (constantTimeEquals(QByteArray::fromHex(codes.value(1).toString().toLatin1()), hash)) {
                    QSqlQuery mark(m_database);
                    mark.prepare(QStringLiteral("UPDATE recovery_codes SET used_at = :now WHERE code_id = :id"));
                    mark.bindValue(QStringLiteral(":now"), nowIso());
                    mark.bindValue(QStringLiteral(":id"), codes.value(0).toInt());
                    mark.exec();
                    codeValid = true;
                    break;
                }
            }
        }
    }
    if (!codeValid)
        return errorResult(QStringLiteral("Неверный код подтверждения"));

    QSqlQuery update(m_database);
    update.prepare(QStringLiteral("UPDATE officers SET totp_secret = NULL, totp_enabled = 0, updated_at = :updated "
                                  "WHERE officer_id = :id"));
    update.bindValue(QStringLiteral(":updated"), nowIso());
    update.bindValue(QStringLiteral(":id"), m_currentOfficerId);
    if (!update.exec())
        return errorResult(QStringLiteral("Не удалось отключить 2FA"));

    QSqlQuery clear(m_database);
    clear.prepare(QStringLiteral("DELETE FROM recovery_codes WHERE officer_id = :id"));
    clear.bindValue(QStringLiteral(":id"), m_currentOfficerId);
    clear.exec();
    return successResult();
}

QVariantMap DatabaseManager::regenerateRecoveryCodes()
{
    const QVariantMap auth = requireAuth();
    if (!auth.value(QStringLiteral("ok")).toBool())
        return auth;

    QSqlQuery query(m_database);
    query.prepare(QStringLiteral("SELECT totp_enabled FROM officers WHERE officer_id = :id"));
    query.bindValue(QStringLiteral(":id"), m_currentOfficerId);
    if (!query.exec() || !query.next() || query.value(0).toInt() == 0)
        return errorResult(QStringLiteral("Сначала включите двухфакторную аутентификацию"));

    QSqlQuery clear(m_database);
    clear.prepare(QStringLiteral("DELETE FROM recovery_codes WHERE officer_id = :id"));
    clear.bindValue(QStringLiteral(":id"), m_currentOfficerId);
    clear.exec();

    QVariantList result;
    for (int i = 0; i < 8; ++i) {
        const QString code = TotpAuth::generateRecoveryCode();
        QSqlQuery insert(m_database);
        insert.prepare(QStringLiteral("INSERT INTO recovery_codes (officer_id, code_hash, created_at) "
                                      "VALUES (:id, :hash, :created)"));
        insert.bindValue(QStringLiteral(":id"), m_currentOfficerId);
        insert.bindValue(QStringLiteral(":hash"), QString::fromLatin1(TotpAuth::hashRecoveryCode(code).toHex()));
        insert.bindValue(QStringLiteral(":created"), nowIso());
        insert.exec();
        result.append(code);
    }
    return { { QStringLiteral("ok"), true }, { QStringLiteral("recoveryCodes"), result } };
}

int DatabaseManager::remainingRecoveryCodes()
{
    if (m_currentOfficerId <= 0)
        return 0;
    QSqlQuery query(m_database);
    query.prepare(QStringLiteral(
        "SELECT COUNT(*) FROM recovery_codes WHERE officer_id = :id AND used_at IS NULL"));
    query.bindValue(QStringLiteral(":id"), m_currentOfficerId);
    if (query.exec() && query.next())
        return query.value(0).toInt();
    return 0;
}

// ---------------------------------------------------------------------------
// Дашборд и поиск
// ---------------------------------------------------------------------------

QVariantMap DatabaseManager::getDashboardStats()
{
    auto scalar = [this](const QString &sql) {
        QSqlQuery query(m_database);
        if (query.exec(sql) && query.next())
            return query.value(0).toInt();
        return 0;
    };

    QVariantMap stats;
    stats[QStringLiteral("ok")] = true;
    stats[QStringLiteral("officers")] = scalar(QStringLiteral("SELECT COUNT(*) FROM officers"));
    stats[QStringLiteral("pendingOfficers")] =
        scalar(QStringLiteral("SELECT COUNT(*) FROM officers WHERE is_approved = 0"));
    stats[QStringLiteral("persons")] = scalar(QStringLiteral("SELECT COUNT(*) FROM persons"));
    stats[QStringLiteral("cases")] = scalar(QStringLiteral("SELECT COUNT(*) FROM cases"));
    stats[QStringLiteral("casesOpen")] =
        scalar(QStringLiteral("SELECT COUNT(*) FROM cases WHERE status <> 'Закрыто'"));
    stats[QStringLiteral("casesClosed")] =
        scalar(QStringLiteral("SELECT COUNT(*) FROM cases WHERE status = 'Закрыто'"));
    stats[QStringLiteral("evidence")] = scalar(QStringLiteral("SELECT COUNT(*) FROM evidence"));

    const QVariantList cases = getCases();
    stats[QStringLiteral("recentCases")] = cases.mid(0, 5);
    const QVariantList persons = getPersons();
    stats[QStringLiteral("recentPersons")] = persons.mid(0, 5);
    return stats;
}

QVariantMap DatabaseManager::searchAll(const QString &queryText)
{
    QVariantMap result;
    result[QStringLiteral("ok")] = true;
    QVariantList officers;
    QVariantList persons;
    QVariantList cases;
    QVariantList evidence;
    result[QStringLiteral("officers")] = officers;
    result[QStringLiteral("persons")] = persons;
    result[QStringLiteral("cases")] = cases;
    result[QStringLiteral("evidence")] = evidence;

    const QString trimmed = queryText.trimmed();
    if (trimmed.size() < 2)
        return result;

    QString escaped = trimmed;
    escaped.replace(QLatin1Char('\\'), QStringLiteral("\\\\"));
    escaped.replace(QLatin1Char('%'), QStringLiteral("\\%"));
    escaped.replace(QLatin1Char('_'), QStringLiteral("\\_"));
    const QString pattern = QLatin1Char('%') + escaped + QLatin1Char('%');

    {
        QSqlQuery q(m_database);
        q.prepare(QStringLiteral(
            "SELECT officer_id, last_name, name, patronymic, rank, position, photo_path FROM officers "
            "WHERE last_name LIKE :p ESCAPE '\\' OR name LIKE :p ESCAPE '\\' OR patronymic LIKE :p ESCAPE '\\' "
            "OR rank LIKE :p ESCAPE '\\' OR position LIKE :p ESCAPE '\\' OR system_login LIKE :p ESCAPE '\\' "
            "ORDER BY last_name LIMIT 6"));
        q.bindValue(QStringLiteral(":p"), pattern);
        if (q.exec()) {
            while (q.next()) {
                officers.append(QVariantMap{
                    { QStringLiteral("type"), QStringLiteral("officer") },
                    { QStringLiteral("id"), q.value(0).toInt() },
                    { QStringLiteral("title"), fullName(q.value(1).toString(), q.value(2).toString(), q.value(3).toString()) },
                    { QStringLiteral("subtitle"), q.value(4).toString() + QStringLiteral(", ") + q.value(5).toString() },
                    { QStringLiteral("photo_url"), photoUrlForFile(q.value(6).toString()) } });
            }
        }
        result[QStringLiteral("officers")] = officers;
    }

    {
        QSqlQuery q(m_database);
        q.prepare(QStringLiteral(
            "SELECT person_id, last_name, name, patronymic, status, phone, photo_path FROM persons "
            "WHERE last_name LIKE :p ESCAPE '\\' OR name LIKE :p ESCAPE '\\' OR patronymic LIKE :p ESCAPE '\\' "
            "OR address LIKE :p ESCAPE '\\' OR phone LIKE :p ESCAPE '\\' OR description LIKE :p ESCAPE '\\' "
            "ORDER BY last_name LIMIT 6"));
        q.bindValue(QStringLiteral(":p"), pattern);
        if (q.exec()) {
            while (q.next()) {
                persons.append(QVariantMap{
                    { QStringLiteral("type"), QStringLiteral("person") },
                    { QStringLiteral("id"), q.value(0).toInt() },
                    { QStringLiteral("title"), fullName(q.value(1).toString(), q.value(2).toString(), q.value(3).toString()) },
                    { QStringLiteral("subtitle"), q.value(4).toString() + (q.value(5).toString().isEmpty() ? QString() : QStringLiteral(" · ") + q.value(5).toString()) },
                    { QStringLiteral("photo_url"), photoUrlForFile(q.value(6).toString()) } });
            }
        }
        result[QStringLiteral("persons")] = persons;
    }

    {
        QSqlQuery q(m_database);
        q.prepare(QStringLiteral(
            "SELECT case_id, case_number, title, status FROM cases "
            "WHERE case_number LIKE :p ESCAPE '\\' OR title LIKE :p ESCAPE '\\' OR description LIKE :p ESCAPE '\\' "
            "ORDER BY date_opened DESC LIMIT 6"));
        q.bindValue(QStringLiteral(":p"), pattern);
        if (q.exec()) {
            while (q.next()) {
                cases.append(QVariantMap{
                    { QStringLiteral("type"), QStringLiteral("case") },
                    { QStringLiteral("id"), q.value(0).toInt() },
                    { QStringLiteral("title"), QStringLiteral("Дело № %1 — %2").arg(q.value(1).toString(), q.value(2).toString()) },
                    { QStringLiteral("subtitle"), q.value(3).toString() } });
            }
        }
        result[QStringLiteral("cases")] = cases;
    }

    {
        QSqlQuery q(m_database);
        q.prepare(QStringLiteral(
            "SELECT evidence_id, type, description, current_status FROM evidence "
            "WHERE description LIKE :p ESCAPE '\\' OR type LIKE :p ESCAPE '\\' OR storage_location LIKE :p ESCAPE '\\' "
            "ORDER BY registration_date DESC LIMIT 6"));
        q.bindValue(QStringLiteral(":p"), pattern);
        if (q.exec()) {
            while (q.next()) {
                evidence.append(QVariantMap{
                    { QStringLiteral("type"), QStringLiteral("evidence") },
                    { QStringLiteral("id"), q.value(0).toInt() },
                    { QStringLiteral("title"), q.value(2).toString() },
                    { QStringLiteral("subtitle"), q.value(1).toString() + QStringLiteral(" · ") + q.value(3).toString() } });
            }
        }
        result[QStringLiteral("evidence")] = evidence;
    }

    result[QStringLiteral("total")] = officers.size() + persons.size() + cases.size() + evidence.size();
    return result;
}
