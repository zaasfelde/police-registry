#include "ReferenceData.h"

namespace {

const QStringList &policeRanks()
{
    static const QStringList ranks = {
        QStringLiteral("Рядовой полиции"),
        QStringLiteral("Младший сержант полиции"),
        QStringLiteral("Сержант полиции"),
        QStringLiteral("Старший сержант полиции"),
        QStringLiteral("Старшина полиции"),
        QStringLiteral("Прапорщик полиции"),
        QStringLiteral("Старший прапорщик полиции"),
        QStringLiteral("Младший лейтенант полиции"),
        QStringLiteral("Лейтенант полиции"),
        QStringLiteral("Старший лейтенант полиции"),
        QStringLiteral("Капитан полиции"),
        QStringLiteral("Майор полиции"),
        QStringLiteral("Подполковник полиции"),
        QStringLiteral("Полковник полиции"),
        QStringLiteral("Генерал-майор полиции"),
        QStringLiteral("Генерал-лейтенант полиции"),
        QStringLiteral("Генерал-полковник полиции"),
        QStringLiteral("Генерал полиции Российской Федерации")
    };
    return ranks;
}

const QStringList &internalServiceRanks()
{
    static const QStringList ranks = {
        QStringLiteral("Рядовой внутренней службы"),
        QStringLiteral("Младший сержант внутренней службы"),
        QStringLiteral("Сержант внутренней службы"),
        QStringLiteral("Старший сержант внутренней службы"),
        QStringLiteral("Старшина внутренней службы"),
        QStringLiteral("Прапорщик внутренней службы"),
        QStringLiteral("Старший прапорщик внутренней службы"),
        QStringLiteral("Младший лейтенант внутренней службы"),
        QStringLiteral("Лейтенант внутренней службы"),
        QStringLiteral("Старший лейтенант внутренней службы"),
        QStringLiteral("Капитан внутренней службы"),
        QStringLiteral("Майор внутренней службы"),
        QStringLiteral("Подполковник внутренней службы"),
        QStringLiteral("Полковник внутренней службы"),
        QStringLiteral("Генерал-майор внутренней службы"),
        QStringLiteral("Генерал-лейтенант внутренней службы"),
        QStringLiteral("Генерал-полковник внутренней службы")
    };
    return ranks;
}

const QStringList &justiceRanks()
{
    static const QStringList ranks = {
        QStringLiteral("Младший лейтенант юстиции"),
        QStringLiteral("Лейтенант юстиции"),
        QStringLiteral("Старший лейтенант юстиции"),
        QStringLiteral("Капитан юстиции"),
        QStringLiteral("Майор юстиции"),
        QStringLiteral("Подполковник юстиции"),
        QStringLiteral("Полковник юстиции"),
        QStringLiteral("Генерал-майор юстиции"),
        QStringLiteral("Генерал-лейтенант юстиции"),
        QStringLiteral("Генерал-полковник юстиции")
    };
    return ranks;
}

const QStringList &allPositionsList()
{
    static const QStringList positions = {
        // Руководство
        QStringLiteral("Начальник отдела"),
        QStringLiteral("Заместитель начальника отдела"),
        QStringLiteral("Помощник начальника отдела"),
        QStringLiteral("Начальник отделения"),
        QStringLiteral("Заместитель начальника отделения"),
        QStringLiteral("Начальник штаба"),
        QStringLiteral("Инспектор штаба"),
        QStringLiteral("Начальник дежурной части"),
        QStringLiteral("Заместитель начальника дежурной части"),
        QStringLiteral("Оперативный дежурный"),
        QStringLiteral("Помощник оперативного дежурного"),
        QStringLiteral("Начальник изолятора временного содержания"),
        // Уголовный розыск
        QStringLiteral("Старший оперуполномоченный по особо важным делам"),
        QStringLiteral("Оперуполномоченный по особо важным делам"),
        QStringLiteral("Старший оперуполномоченный"),
        QStringLiteral("Оперуполномоченный"),
        QStringLiteral("Кинолог"),
        QStringLiteral("Старший кинолог"),
        // Следствие и дознание
        QStringLiteral("Старший следователь"),
        QStringLiteral("Следователь"),
        QStringLiteral("Следователь-криминалист"),
        QStringLiteral("Старший дознаватель"),
        QStringLiteral("Дознаватель"),
        // Участковые уполномоченные
        QStringLiteral("Старший участковый уполномоченный полиции"),
        QStringLiteral("Участковый уполномоченный полиции"),
        QStringLiteral("Помощник участкового уполномоченного полиции"),
        // Патрульно-постовая служба
        QStringLiteral("Командир роты"),
        QStringLiteral("Заместитель командира роты"),
        QStringLiteral("Командир взвода"),
        QStringLiteral("Заместитель командира взвода"),
        QStringLiteral("Командир отделения"),
        QStringLiteral("Старший полицейский"),
        QStringLiteral("Полицейский"),
        QStringLiteral("Полицейский-водитель"),
        // Дорожно-патрульная служба
        QStringLiteral("Старший инспектор ДПС"),
        QStringLiteral("Инспектор ДПС"),
        QStringLiteral("Старший государственный инспектор безопасности дорожного движения"),
        QStringLiteral("Государственный инспектор безопасности дорожного движения"),
        // Подразделения по делам несовершеннолетних
        QStringLiteral("Старший инспектор по делам несовершеннолетних"),
        QStringLiteral("Инспектор по делам несовершеннолетних"),
        // Административная практика
        QStringLiteral("Старший инспектор по исполнению административного законодательства"),
        QStringLiteral("Инспектор по исполнению административного законодательства"),
        // Экспертно-криминалистическое подразделение
        QStringLiteral("Старший эксперт-криминалист"),
        QStringLiteral("Эксперт-криминалист"),
        // Кадры и тыл
        QStringLiteral("Инспектор отдела кадров"),
        QStringLiteral("Специалист по кадрам"),
        QStringLiteral("Старший специалист по работе с личным составом"),
        QStringLiteral("Специалист по связям с общественностью"),
        QStringLiteral("Юрисконсульт"),
        QStringLiteral("Психолог"),
        QStringLiteral("Инженер-программист"),
        // Дежурная часть
        QStringLiteral("Старший инспектор-дежурный"),
        QStringLiteral("Инспектор-дежурный"),
        QStringLiteral("Дежурный"),
        QStringLiteral("Помощник дежурного")
    };
    return positions;
}

} // namespace

namespace Reference {

QStringList rankCategories()
{
    return { QStringLiteral("Полиция"),
             QStringLiteral("Внутренняя служба"),
             QStringLiteral("Юстиция") };
}

QStringList ranksFor(const QString &category)
{
    if (category.compare(QStringLiteral("Полиция"), Qt::CaseInsensitive) == 0)
        return policeRanks();
    if (category.compare(QStringLiteral("Внутренняя служба"), Qt::CaseInsensitive) == 0)
        return internalServiceRanks();
    if (category.compare(QStringLiteral("Юстиция"), Qt::CaseInsensitive) == 0)
        return justiceRanks();
    return {};
}

QStringList allRanks()
{
    return policeRanks() + internalServiceRanks() + justiceRanks();
}

QStringList positions()
{
    return allPositionsList();
}

QStringList personStatuses()
{
    return { QStringLiteral("Подозреваемый"),
             QStringLiteral("Обвиняемый"),
             QStringLiteral("Свидетель"),
             QStringLiteral("Потерпевший") };
}

QStringList caseStatuses()
{
    return { QStringLiteral("Возбуждено"),
             QStringLiteral("Расследование"),
             QStringLiteral("Приостановлено"),
             QStringLiteral("Закрыто") };
}

QStringList evidenceTypes()
{
    return { QStringLiteral("Оружие"),
             QStringLiteral("Транспортное средство"),
             QStringLiteral("Одежда"),
             QStringLiteral("Биологический образец"),
             QStringLiteral("Документы"),
             QStringLiteral("Электронный носитель"),
             QStringLiteral("Прочее") };
}

QStringList evidenceStatuses()
{
    return { QStringLiteral("Изъято"),
             QStringLiteral("На экспертизе"),
             QStringLiteral("Приобщено к делу"),
             QStringLiteral("Возвращено владельцу"),
             QStringLiteral("Утеряно") };
}

QStringList roles()
{
    return { QStringLiteral("admin"), QStringLiteral("officer") };
}

bool isValidRankCategory(const QString &category)
{
    return rankCategories().contains(category, Qt::CaseInsensitive);
}

bool isValidRank(const QString &rank)
{
    return allRanks().contains(rank, Qt::CaseInsensitive);
}

bool isValidPosition(const QString &position)
{
    return allPositionsList().contains(position, Qt::CaseInsensitive);
}

QString categoryForRank(const QString &rank)
{
    if (policeRanks().contains(rank, Qt::CaseInsensitive))
        return QStringLiteral("Полиция");
    if (internalServiceRanks().contains(rank, Qt::CaseInsensitive))
        return QStringLiteral("Внутренняя служба");
    if (justiceRanks().contains(rank, Qt::CaseInsensitive))
        return QStringLiteral("Юстиция");
    return {};
}

} // namespace Reference

ReferenceData::ReferenceData(QObject *parent)
    : QObject(parent)
{
}

QStringList ReferenceData::rankCategories() const
{
    return Reference::rankCategories();
}

QStringList ReferenceData::ranks(const QString &category) const
{
    return Reference::ranksFor(category);
}

QStringList ReferenceData::allRanks() const
{
    return Reference::allRanks();
}

QStringList ReferenceData::positions() const
{
    return Reference::positions();
}

QStringList ReferenceData::personStatuses() const
{
    return Reference::personStatuses();
}

QStringList ReferenceData::caseStatuses() const
{
    return Reference::caseStatuses();
}

QStringList ReferenceData::evidenceTypes() const
{
    return Reference::evidenceTypes();
}

QStringList ReferenceData::evidenceStatuses() const
{
    return Reference::evidenceStatuses();
}

QStringList ReferenceData::roles() const
{
    return Reference::roles();
}

QString ReferenceData::categoryForRank(const QString &rank) const
{
    return Reference::categoryForRank(rank);
}
