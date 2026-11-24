#include "UiSmoke.h"

#include "DatabaseManager.h"

#include <QCoreApplication>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QImage>
#include <QKeyEvent>
#include <QQuickWindow>
#include <QScopedPointer>
#include <QTimer>
#include <QUrl>
#include <QVariantMap>
#include <QQmlApplicationEngine>
#include <QQmlComponent>
#include <QQmlEngine>

namespace {

QVariantMap personData(const QString &last, const QString &first, const QString &middle,
                       const QString &birth, const QString &status, bool criminal)
{
    return {
        { QStringLiteral("last_name"), last },
        { QStringLiteral("name"), first },
        { QStringLiteral("patronymic"), middle },
        { QStringLiteral("birth_date"), birth },
        { QStringLiteral("status"), status },
        { QStringLiteral("criminal_record"), criminal },
        { QStringLiteral("phone"), QStringLiteral("+7 999 000-00-00") },
        { QStringLiteral("address"), QStringLiteral("г. Москва, ул. Полицейская, д. 1") },
        { QStringLiteral("description"), QStringLiteral("Демонстрационная запись картотеки.") }
    };
}

QVariantMap officerData(const QString &last, const QString &first, const QString &middle,
                        const QString &rank, const QString &category, const QString &position,
                        const QString &login, const QString &number)
{
    return {
        { QStringLiteral("last_name"), last },
        { QStringLiteral("name"), first },
        { QStringLiteral("patronymic"), middle },
        { QStringLiteral("rank"), rank },
        { QStringLiteral("rank_category"), category },
        { QStringLiteral("position"), position },
        { QStringLiteral("birth_date"), QStringLiteral("1990-05-15") },
        { QStringLiteral("hire_date"), QStringLiteral("2015-03-01") },
        { QStringLiteral("experience"), 10 },
        { QStringLiteral("personnel_number"), number },
        { QStringLiteral("phone"), QStringLiteral("+7 999 123-45-67") },
        { QStringLiteral("email"), login + QStringLiteral("@police.local") },
        { QStringLiteral("login"), login },
        { QStringLiteral("password"), QStringLiteral("Police12345") }
    };
}

void seedData(DatabaseManager &db, int *adminId, int *officerId, int *personId, int *caseId, int *evidenceId)
{
    const QVariantMap admin = db.createOfficer(officerData(
        QStringLiteral("Иванов"), QStringLiteral("Иван"), QStringLiteral("Иванович"),
        QStringLiteral("Капитан полиции"), QStringLiteral("Полиция"), QStringLiteral("Следователь"),
        QStringLiteral("admin"), QStringLiteral("A-0001")));
    *adminId = admin.value(QStringLiteral("id")).toInt();

    const QVariantMap officer = db.createOfficer(officerData(
        QStringLiteral("Петров"), QStringLiteral("Пётр"), QStringLiteral("Петрович"),
        QStringLiteral("Лейтенант полиции"), QStringLiteral("Полиция"), QStringLiteral("Оперуполномоченный"),
        QStringLiteral("petrov"), QStringLiteral("A-0002")));
    *officerId = officer.value(QStringLiteral("id")).toInt();

    db.createOfficer(officerData(
        QStringLiteral("Сидорова"), QStringLiteral("Анна"), QStringLiteral("Сергеевна"),
        QStringLiteral("Младший лейтенант юстиции"), QStringLiteral("Юстиция"), QStringLiteral("Дознаватель"),
        QStringLiteral("sidorova"), QStringLiteral("A-0003")));

    db.authenticate(QStringLiteral("admin"), QStringLiteral("Police12345"));
    db.setOfficerApproval(*officerId, true);

    QVariantMap caseOne = {
        { QStringLiteral("case_number"), QStringLiteral("2026-00145") },
        { QStringLiteral("title"), QStringLiteral("Кража из квартиры на ул. Ленина") },
        { QStringLiteral("description"), QStringLiteral("Проникновение в жилище, похищены бытовая техника и документы.") },
        { QStringLiteral("date_opened"), QStringLiteral("2026-10-12") },
        { QStringLiteral("status"), QStringLiteral("Расследование") },
        { QStringLiteral("investigator_id"), *adminId }
    };
    *caseId = db.createCase(caseOne).value(QStringLiteral("id")).toInt();

    QVariantMap caseTwo = {
        { QStringLiteral("case_number"), QStringLiteral("2026-00146") },
        { QStringLiteral("title"), QStringLiteral("Дорожно-транспортное происшествие") },
        { QStringLiteral("description"), QStringLiteral("Столкновение двух автомобилей, пострадал пешеход.") },
        { QStringLiteral("date_opened"), QStringLiteral("2026-10-20") },
        { QStringLiteral("status"), QStringLiteral("Возбуждено") },
        { QStringLiteral("investigator_id"), *officerId }
    };
    db.createCase(caseTwo);

    QVariantMap caseThree = {
        { QStringLiteral("case_number"), QStringLiteral("2026-00131") },
        { QStringLiteral("title"), QStringLiteral("Незаконный оборот документов") },
        { QStringLiteral("description"), QStringLiteral("Дело закрыто после завершения расследования.") },
        { QStringLiteral("date_opened"), QStringLiteral("2026-09-02") },
        { QStringLiteral("date_closed"), QStringLiteral("2026-10-01") },
        { QStringLiteral("status"), QStringLiteral("Закрыто") },
        { QStringLiteral("investigator_id"), *adminId }
    };
    db.createCase(caseThree);

    QVariantMap personOne = personData(QStringLiteral("Сидоров"), QStringLiteral("Сидор"),
                                       QStringLiteral("Сидорович"), QStringLiteral("1985-07-20"),
                                       QStringLiteral("Подозреваемый"), true);
    personOne[QStringLiteral("case_id")] = *caseId;
    *personId = db.createPerson(personOne).value(QStringLiteral("id")).toInt();

    QVariantMap personTwo = personData(QStringLiteral("Кузнецова"), QStringLiteral("Ольга"),
                                       QStringLiteral("Игоревна"), QStringLiteral("1992-02-11"),
                                       QStringLiteral("Потерпевший"), false);
    personTwo[QStringLiteral("case_id")] = *caseId;
    db.createPerson(personTwo);

    QVariantMap personThree = personData(QStringLiteral("Смирнов"), QStringLiteral("Алексей"),
                                         QStringLiteral("Владимирович"), QStringLiteral("1978-11-30"),
                                         QStringLiteral("Свидетель"), false);
    personThree[QStringLiteral("case_id")] = *caseId;
    db.createPerson(personThree);

    QVariantMap personFour = personData(QStringLiteral("Волков"), QStringLiteral("Дмитрий"),
                                        QStringLiteral("Андреевич"), QStringLiteral("2001-04-05"),
                                        QStringLiteral("Обвиняемый"), true);
    personFour[QStringLiteral("case_id")] = *caseId;
    db.createPerson(personFour);

    QVariantMap evidenceOne = {
        { QStringLiteral("type"), QStringLiteral("Оружие") },
        { QStringLiteral("description"), QStringLiteral("Пистолет Макарова, серия ПМ-1234") },
        { QStringLiteral("current_status"), QStringLiteral("На экспертизе") },
        { QStringLiteral("case_id"), *caseId },
        { QStringLiteral("storage_location"), QStringLiteral("Сейф №3, оружейная комната") }
    };
    *evidenceId = db.createEvidence(evidenceOne).value(QStringLiteral("id")).toInt();

    QVariantMap evidenceTwo = {
        { QStringLiteral("type"), QStringLiteral("Документы") },
        { QStringLiteral("description"), QStringLiteral("Паспорт гражданина РФ, копия договора купли-продажи") },
        { QStringLiteral("current_status"), QStringLiteral("Приобщено к делу") },
        { QStringLiteral("case_id"), *caseId },
        { QStringLiteral("storage_location"), QStringLiteral("Архив, папка №12") }
    };
    db.createEvidence(evidenceTwo);

    QVariantMap evidenceThree = {
        { QStringLiteral("type"), QStringLiteral("Электронный носитель") },
        { QStringLiteral("description"), QStringLiteral("USB-накопитель с видеозаписью") },
        { QStringLiteral("current_status"), QStringLiteral("Изъято") },
        { QStringLiteral("case_id"), *caseId },
        { QStringLiteral("storage_location"), QStringLiteral("Сейф №1") }
    };
    db.createEvidence(evidenceThree);

    // Демонстрационные фотографии
    QImage avatar(240, 300, QImage::Format_RGB32);
    avatar.fill(QColor(QStringLiteral("#2F5D8A")));
    const QString avatarPath = QDir::currentPath() + QStringLiteral("/ui-smoke-avatar.png");
    if (avatar.save(avatarPath, "PNG")) {
        db.setOfficerPhoto(*adminId, QUrl::fromLocalFile(avatarPath));
    }

    QImage personPhoto(240, 300, QImage::Format_RGB32);
    personPhoto.fill(QColor(QStringLiteral("#5B6E8A")));
    const QString personPath = QDir::currentPath() + QStringLiteral("/ui-smoke-person.png");
    if (personPhoto.save(personPath, "PNG"))
        db.setPersonPhoto(*personId, QUrl::fromLocalFile(personPath));

    QFile::remove(avatarPath);
    QFile::remove(personPath);
}

} // namespace

int runUiSmoke(DatabaseManager &db, QQmlApplicationEngine &engine)
{
    qInfo() << "=== UI smoke ===";

    int adminId = 0;
    int officerId = 0;
    int personId = 0;
    int caseId = 0;
    int evidenceId = 0;
    seedData(db, &adminId, &officerId, &personId, &caseId, &evidenceId);

    // Загружаем модуль, чтобы получить доступ к синглтону App.
    QQmlComponent probe(&engine);
    probe.setData("import QtQuick\nimport policedep\nItem { }",
                  QUrl(QStringLiteral("qrc:/qt/qml/policedep/UiSmokeProbe.qml")));
    QScopedPointer<QObject> probeObject(probe.create());
    if (!probeObject) {
        qCritical() << "Не удалось загрузить модуль policedep:" << probe.errorString();
        return 1;
    }

    QObject *app = engine.singletonInstance<QObject *>(QStringLiteral("policedep"), QStringLiteral("App"));
    if (!app) {
        qCritical() << "Не удалось получить синглтон App";
        return 1;
    }
    app->setProperty("user", db.currentUser());
    QMetaObject::invokeMethod(app, "refresh");

    engine.loadFromModule(QStringLiteral("policedep"), QStringLiteral("Main"));
    if (engine.rootObjects().isEmpty()) {
        qCritical() << "Не удалось загрузить главное окно";
        return 1;
    }

    QObject *window = engine.rootObjects().first();

    const QString outputDir = QDir::currentPath() + QStringLiteral("/ui-smoke");
    QDir().mkpath(outputDir);

    auto screenshot = [window, outputDir](const QString &name) {
        auto *quickWindow = qobject_cast<QQuickWindow *>(window);
        if (!quickWindow) {
            qWarning() << "Окно не является QQuickWindow";
            return;
        }
        const QImage image = quickWindow->grabWindow();
        if (image.isNull()) {
            qWarning() << "Не удалось получить скриншот" << name;
            return;
        }
        const QString path = outputDir + QLatin1Char('/') + name + QStringLiteral(".png");
        if (image.save(path))
            qInfo() << "Скриншот:" << path;
        else
            qWarning() << "Не удалось сохранить скриншот" << path;
    };

    // Сначала фиксируем экраны входа и регистрации, затем — основное окно.
    QTimer::singleShot(900, &engine, [window, screenshot]() {
        screenshot(QStringLiteral("00-login"));
        window->setProperty("currentView", QStringLiteral("register"));
    });
    QTimer::singleShot(1800, &engine, [window, screenshot]() {
        screenshot(QStringLiteral("00-registration"));
        QObject *registration = window->findChild<QObject *>(QStringLiteral("registrationForm"));
        if (registration)
            QMetaObject::invokeMethod(registration, "submit");
    });
    QTimer::singleShot(2600, &engine, [window, screenshot]() {
        screenshot(QStringLiteral("00-registration-errors"));
        window->setProperty("currentView", QStringLiteral("main"));
    });

    const QStringList pages = {
        QStringLiteral("dashboard"),
        QStringLiteral("employees"),
        QStringLiteral("persons"),
        QStringLiteral("cases"),
        QStringLiteral("evidence"),
        QStringLiteral("profile")
    };

    auto *timer = new QTimer(&engine);
    timer->setInterval(1700);
    int step = 0;

    QObject::connect(timer, &QTimer::timeout, [&, timer, pages, app, window, screenshot]() mutable {
        if (step == 0) {
            QTimer::singleShot(900, [screenshot]() { screenshot(QStringLiteral("01-dashboard")); });
            step = 1;
            return;
        }

        const int pageCount = pages.size();
        if (step <= pageCount) {
            const QString key = pages.at(step - 1);
            QMetaObject::invokeMethod(app, "navigate", Q_ARG(QString, key));
            const int shotIndex = step + 1;
            QTimer::singleShot(900, [screenshot, key, shotIndex]() {
                screenshot(QStringLiteral("%1-%2").arg(shotIndex, 2, 10, QLatin1Char('0')).arg(key));
            });
            ++step;
            return;
        }

        if (step == pageCount + 1) {
            QMetaObject::invokeMethod(app, "navigate", Q_ARG(QString, QStringLiteral("employees")));
            QMetaObject::invokeMethod(app, "openEntity",
                                      Q_ARG(QString, QStringLiteral("officer")),
                                      Q_ARG(int, adminId));
            QTimer::singleShot(900, [screenshot]() { screenshot(QStringLiteral("08-employee-dialog")); });
            ++step;
            return;
        }

        if (step == pageCount + 2) {
            QKeyEvent escape(QEvent::KeyPress, Qt::Key_Escape, Qt::NoModifier);
            QCoreApplication::sendEvent(window, &escape);
            QMetaObject::invokeMethod(app, "openEntity",
                                      Q_ARG(QString, QStringLiteral("person")),
                                      Q_ARG(int, personId));
            QTimer::singleShot(900, [screenshot]() { screenshot(QStringLiteral("09-person-dialog")); });
            ++step;
            return;
        }

        if (step == pageCount + 3) {
            QKeyEvent escape(QEvent::KeyPress, Qt::Key_Escape, Qt::NoModifier);
            QCoreApplication::sendEvent(window, &escape);
            QMetaObject::invokeMethod(app, "openEntity",
                                      Q_ARG(QString, QStringLiteral("case")),
                                      Q_ARG(int, caseId));
            QTimer::singleShot(900, [screenshot]() { screenshot(QStringLiteral("10-case-dialog")); });
            ++step;
            return;
        }

        if (step == pageCount + 4) {
            QKeyEvent escape(QEvent::KeyPress, Qt::Key_Escape, Qt::NoModifier);
            QCoreApplication::sendEvent(window, &escape);
            QMetaObject::invokeMethod(app, "openEntity",
                                      Q_ARG(QString, QStringLiteral("evidence")),
                                      Q_ARG(int, evidenceId));
            QTimer::singleShot(900, [screenshot]() { screenshot(QStringLiteral("11-evidence-dialog")); });
            ++step;
            return;
        }

        if (step == pageCount + 5) {
            QKeyEvent escape(QEvent::KeyPress, Qt::Key_Escape, Qt::NoModifier);
            QCoreApplication::sendEvent(window, &escape);
            QMetaObject::invokeMethod(app, "navigate", Q_ARG(QString, QStringLiteral("profile")));
            QTimer::singleShot(500, [window, screenshot]() {
                QObject *profile = window->findChild<QObject *>(QStringLiteral("profilePage"));
                if (profile)
                    QMetaObject::invokeMethod(profile, "openTwoFactorSetup");
                QTimer::singleShot(700, [screenshot]() {
                    screenshot(QStringLiteral("12-2fa-setup"));
                });
            });
            ++step;
            return;
        }

        if (step == pageCount + 6) {
            QKeyEvent escape(QEvent::KeyPress, Qt::Key_Escape, Qt::NoModifier);
            QCoreApplication::sendEvent(window, &escape);
            QTimer::singleShot(300, [window, screenshot]() {
                QObject *search = window->findChild<QObject *>(QStringLiteral("globalSearch"));
                if (search) {
                    QMetaObject::invokeMethod(search, "search",
                                              Q_ARG(QVariant, QVariant(QStringLiteral("Иванов"))));
                }
                QTimer::singleShot(900, [screenshot]() {
                    screenshot(QStringLiteral("13-search"));
                });
            });
            ++step;
            return;
        }

        if (step == pageCount + 7) {
            timer->stop();
            QTimer::singleShot(500, qApp, &QCoreApplication::quit);
        }
    });

    QTimer::singleShot(3300, timer, [timer]() { timer->start(); });
    return QCoreApplication::exec();
}
