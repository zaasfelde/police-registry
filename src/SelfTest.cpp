#include "SelfTest.h"

#include "DatabaseManager.h"
#include "TotpAuth.h"

#include <QDateTime>
#include <QDebug>
#include <QDir>
#include <QImage>
#include <QUrl>

namespace {

int g_failures = 0;

void check(bool condition, const QString &name)
{
    if (condition) {
        qInfo().noquote() << "[ OK ]" << name;
    } else {
        qCritical().noquote() << "[FAIL]" << name;
        ++g_failures;
    }
}

} // namespace

int runSelfTest()
{
    qInfo() << "=== Police Registry: self-test ===";
    g_failures = 0;

    const QString testRoot = QDir::currentPath() + QStringLiteral("/.selftest-data");
    QDir(testRoot).removeRecursively();
    if (!QDir().mkpath(testRoot)) {
        qCritical() << "Не удалось создать каталог для теста:" << testRoot;
        return 1;
    }
    qInfo() << "Каталог теста:" << testRoot;

    {
        DatabaseManager db(nullptr, testRoot + QStringLiteral("/test.db"));
        check(!db.hasUsers(), QStringLiteral("свежая БД не содержит пользователей"));

        QVariantMap adminData;
        adminData[QStringLiteral("last_name")] = QStringLiteral("Иванов");
        adminData[QStringLiteral("name")] = QStringLiteral("Иван");
        adminData[QStringLiteral("patronymic")] = QStringLiteral("Иванович");
        adminData[QStringLiteral("rank")] = QStringLiteral("Капитан полиции");
        adminData[QStringLiteral("rank_category")] = QStringLiteral("Полиция");
        adminData[QStringLiteral("position")] = QStringLiteral("Следователь");
        adminData[QStringLiteral("birth_date")] = QStringLiteral("1990-05-15");
        adminData[QStringLiteral("hire_date")] = QStringLiteral("2015-03-01");
        adminData[QStringLiteral("personnel_number")] = QStringLiteral("A-0001");
        adminData[QStringLiteral("phone")] = QStringLiteral("+7 999 123-45-67");
        adminData[QStringLiteral("email")] = QStringLiteral("admin@example.com");
        adminData[QStringLiteral("experience")] = 10;
        adminData[QStringLiteral("login")] = QStringLiteral("admin");
        adminData[QStringLiteral("password")] = QStringLiteral("Admin12345");

        const QVariantMap admin = db.createOfficer(adminData);
        check(admin.value(QStringLiteral("ok")).toBool(), QStringLiteral("регистрация первого сотрудника"));
        check(admin.value(QStringLiteral("isAdmin")).toBool(), QStringLiteral("первый сотрудник — администратор"));
        const int adminId = admin.value(QStringLiteral("id")).toInt();

        check(db.hasUsers(), QStringLiteral("после регистрации есть пользователи"));
        check(!db.isLoginFree(QStringLiteral("ADMIN")), QStringLiteral("логин проверяется без учёта регистра"));

        const QVariantMap badLogin = db.authenticate(QStringLiteral("admin"), QStringLiteral("wrong"));
        check(!badLogin.value(QStringLiteral("ok")).toBool(), QStringLiteral("неверный пароль отклонён"));
        check(badLogin.value(QStringLiteral("attemptsLeft")).toInt() == 4, QStringLiteral("счётчик попыток уменьшается"));

        const QVariantMap login = db.authenticate(QStringLiteral("admin"), QStringLiteral("Admin12345"));
        check(login.value(QStringLiteral("ok")).toBool(), QStringLiteral("успешный вход администратора"));
        check(!login.value(QStringLiteral("requires2fa")).toBool(), QStringLiteral("2FA по умолчанию выключена"));
        check(db.currentUser().value(QStringLiteral("role")).toString() == QStringLiteral("admin"),
              QStringLiteral("сессия содержит роль"));

        QVariantMap officerData = adminData;
        officerData[QStringLiteral("last_name")] = QStringLiteral("Петров");
        officerData[QStringLiteral("name")] = QStringLiteral("Пётр");
        officerData[QStringLiteral("personnel_number")] = QStringLiteral("A-0002");
        officerData[QStringLiteral("login")] = QStringLiteral("petrov");
        officerData[QStringLiteral("password")] = QStringLiteral("Petrov12345");
        officerData[QStringLiteral("rank")] = QStringLiteral("Лейтенант полиции");
        const QVariantMap second = db.createOfficer(officerData);
        check(second.value(QStringLiteral("ok")).toBool(), QStringLiteral("регистрация второго сотрудника"));
        check(second.value(QStringLiteral("requiresApproval")).toBool(), QStringLiteral("второй сотрудник ждёт подтверждения"));
        const int secondId = second.value(QStringLiteral("id")).toInt();

        db.logout();
        const QVariantMap pendingLogin = db.authenticate(QStringLiteral("petrov"), QStringLiteral("Petrov12345"));
        check(!pendingLogin.value(QStringLiteral("ok")).toBool(), QStringLiteral("неподтверждённый вход запрещён"));
        check(pendingLogin.value(QStringLiteral("errorCode")).toString() == QStringLiteral("pending"),
              QStringLiteral("возвращается код pending"));

        // --- Дела, личности, материалы ---
        db.authenticate(QStringLiteral("admin"), QStringLiteral("Admin12345"));

        QVariantMap caseData;
        caseData[QStringLiteral("case_number")] = QStringLiteral("TEST-001");
        caseData[QStringLiteral("title")] = QStringLiteral("Тестовое дело");
        caseData[QStringLiteral("description")] = QStringLiteral("Проверка модуля дел");
        caseData[QStringLiteral("date_opened")] = QStringLiteral("2026-01-10");
        caseData[QStringLiteral("status")] = QStringLiteral("Возбуждено");
        caseData[QStringLiteral("investigator_id")] = adminId;
        const QVariantMap createdCase = db.createCase(caseData);
        check(createdCase.value(QStringLiteral("ok")).toBool(), QStringLiteral("создание дела"));
        const int caseId = createdCase.value(QStringLiteral("id")).toInt();

        QVariantMap personData;
        personData[QStringLiteral("last_name")] = QStringLiteral("Сидоров");
        personData[QStringLiteral("name")] = QStringLiteral("Сидор");
        personData[QStringLiteral("birth_date")] = QStringLiteral("1985-07-20");
        personData[QStringLiteral("status")] = QStringLiteral("Подозреваемый");
        personData[QStringLiteral("criminal_record")] = true;
        personData[QStringLiteral("case_id")] = caseId;
        const QVariantMap createdPerson = db.createPerson(personData);
        check(createdPerson.value(QStringLiteral("ok")).toBool(), QStringLiteral("создание личности"));
        const int personId = createdPerson.value(QStringLiteral("id")).toInt();
        check(db.getPerson(personId).value(QStringLiteral("criminal_record")).toBool(),
              QStringLiteral("судимость сохраняется"));

        QVariantMap evidenceData;
        evidenceData[QStringLiteral("type")] = QStringLiteral("Оружие");
        evidenceData[QStringLiteral("description")] = QStringLiteral("Пистолет Макарова");
        evidenceData[QStringLiteral("current_status")] = QStringLiteral("Изъято");
        evidenceData[QStringLiteral("case_id")] = caseId;
        evidenceData[QStringLiteral("storage_location")] = QStringLiteral("Сейф №3");
        const QVariantMap createdEvidence = db.createEvidence(evidenceData);
        check(createdEvidence.value(QStringLiteral("ok")).toBool(), QStringLiteral("создание материала"));
        const int evidenceId = createdEvidence.value(QStringLiteral("id")).toInt();

        const QVariantMap stats = db.getDashboardStats();
        check(stats.value(QStringLiteral("cases")).toInt() == 1, QStringLiteral("статистика: одно дело"));
        check(stats.value(QStringLiteral("persons")).toInt() == 1, QStringLiteral("статистика: одна личность"));
        check(stats.value(QStringLiteral("evidence")).toInt() == 1, QStringLiteral("статистика: один материал"));

        const QVariantMap search = db.searchAll(QStringLiteral("Сидор"));
        check(search.value(QStringLiteral("total")).toInt() >= 1, QStringLiteral("поиск находит личность"));

        const QVariantMap blockedDelete = db.removeCase(caseId, false);
        check(blockedDelete.value(QStringLiteral("requiresCascade")).toBool(),
              QStringLiteral("удаление связанного дела требует подтверждения"));
        const QVariantMap forcedDelete = db.removeCase(caseId, true);
        check(forcedDelete.value(QStringLiteral("ok")).toBool(), QStringLiteral("каскадное удаление дела"));
        check(db.getPerson(personId).value(QStringLiteral("case_id")).toInt() == 0,
              QStringLiteral("личность остаётся без дела после каскада"));
        check(!db.removeEvidence(evidenceId).value(QStringLiteral("ok")).toBool(),
              QStringLiteral("удалённый материал уже недоступен"));

        // --- 2FA ---
        const QVariantMap setup = db.beginTwoFactorSetup();
        check(setup.value(QStringLiteral("ok")).toBool() && !setup.value(QStringLiteral("secret")).toString().isEmpty(),
              QStringLiteral("генерация секрета 2FA"));
        const QString secret = setup.value(QStringLiteral("secret")).toString();
        const QByteArray rawSecret = TotpAuth::base32Decode(secret);
        const QString code = TotpAuth::codeFor(rawSecret, QDateTime::currentSecsSinceEpoch());
        check(TotpAuth::verify(secret, code), QStringLiteral("TOTP-код проходит проверку"));
        const QVariantMap confirmed = db.confirmTwoFactorSetup(code);
        check(confirmed.value(QStringLiteral("ok")).toBool(), QStringLiteral("включение 2FA"));
        const QVariantList recoveryCodes = confirmed.value(QStringLiteral("recoveryCodes")).toList();
        check(recoveryCodes.size() == 8, QStringLiteral("выдано 8 резервных кодов"));

        db.logout();
        const QVariantMap twoFactorLogin = db.authenticate(QStringLiteral("admin"), QStringLiteral("Admin12345"));
        check(twoFactorLogin.value(QStringLiteral("requires2fa")).toBool(),
              QStringLiteral("вход требует второй фактор"));
        const QVariantMap wrongCode = db.verifyTwoFactor(QStringLiteral("123456"));
        check(!wrongCode.value(QStringLiteral("ok")).toBool(), QStringLiteral("неверный 2FA-код отклонён"));
        const QString freshCode = TotpAuth::codeFor(rawSecret, QDateTime::currentSecsSinceEpoch());
        const QVariantMap goodCode = db.verifyTwoFactor(freshCode);
        check(goodCode.value(QStringLiteral("ok")).toBool(), QStringLiteral("вход по TOTP-коду"));

        db.logout();
        db.authenticate(QStringLiteral("admin"), QStringLiteral("Admin12345"));
        const QString recoveryCode = recoveryCodes.first().toString();
        const QVariantMap recoveryLogin = db.verifyTwoFactor(recoveryCode);
        check(recoveryLogin.value(QStringLiteral("ok")).toBool(), QStringLiteral("вход по резервному коду"));
        check(db.remainingRecoveryCodes() == 7, QStringLiteral("резервный код помечен использованным"));

        // --- Смена пароля ---
        check(db.changePassword(QStringLiteral("Admin12345"), QStringLiteral("NewPassword123")).value(QStringLiteral("ok")).toBool(),
              QStringLiteral("смена пароля"));
        db.logout();
        check(!db.authenticate(QStringLiteral("admin"), QStringLiteral("Admin12345")).value(QStringLiteral("ok")).toBool(),
              QStringLiteral("старый пароль больше не работает"));
        check(db.authenticate(QStringLiteral("admin"), QStringLiteral("NewPassword123")).value(QStringLiteral("requires2fa")).toBool(),
              QStringLiteral("новый пароль работает"));

        // --- Фотографии ---
        db.authenticate(QStringLiteral("admin"), QStringLiteral("NewPassword123"));
        db.verifyTwoFactor(TotpAuth::codeFor(rawSecret, QDateTime::currentSecsSinceEpoch()));

        QImage avatar(60, 80, QImage::Format_RGB32);
        avatar.fill(Qt::darkBlue);
        const QString avatarPath = testRoot + QStringLiteral("/avatar.png");
        check(avatar.save(avatarPath, "PNG"), QStringLiteral("тестовое изображение сохранено"));
        const QVariantMap photoResult = db.setOfficerPhoto(adminId, QUrl::fromLocalFile(avatarPath));
        check(photoResult.value(QStringLiteral("ok")).toBool(), QStringLiteral("установка фото сотрудника"));
        check(!db.currentUser().value(QStringLiteral("photo_url")).toString().isEmpty(),
              QStringLiteral("URL фото возвращается в профиле"));
        check(db.removeOfficerPhoto(adminId).value(QStringLiteral("ok")).toBool(),
              QStringLiteral("удаление фото сотрудника"));

        // --- Подтверждение и роли ---
        check(db.setOfficerApproval(secondId, true).value(QStringLiteral("ok")).toBool(),
              QStringLiteral("администратор подтверждает сотрудника"));
        db.logout();
        check(db.authenticate(QStringLiteral("petrov"), QStringLiteral("Petrov12345")).value(QStringLiteral("ok")).toBool(),
              QStringLiteral("подтверждённый сотрудник входит"));
        db.logout();
        db.authenticate(QStringLiteral("admin"), QStringLiteral("NewPassword123"));
        db.verifyTwoFactor(TotpAuth::codeFor(rawSecret, QDateTime::currentSecsSinceEpoch()));
        check(db.setOfficerRole(secondId, QStringLiteral("admin")).value(QStringLiteral("ok")).toBool(),
              QStringLiteral("назначение администратором"));
        check(!db.setOfficerRole(adminId, QStringLiteral("officer")).value(QStringLiteral("ok")).toBool(),
              QStringLiteral("нельзя снять последнего администратора"));
        check(db.removeOfficer(secondId).value(QStringLiteral("ok")).toBool(),
              QStringLiteral("удаление сотрудника"));
        check(!db.removeOfficer(adminId).value(QStringLiteral("ok")).toBool(),
              QStringLiteral("нельзя удалить самого себя"));

        db.logout();
    }

    if (g_failures == 0)
        qInfo() << "=== Все проверки пройдены ===";
    else
        qCritical() << "=== Провалено проверок:" << g_failures << "===";

    QDir(testRoot).removeRecursively();
    return g_failures == 0 ? 0 : 1;
}

