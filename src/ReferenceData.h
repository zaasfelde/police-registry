#ifndef REFERENCEDATA_H
#define REFERENCEDATA_H

#include <QObject>
#include <QStringList>

/*
 * Справочники предметной области: специальные звания, типовые должности
 * подразделений МВД, статусы дел/личностей/вещественных доказательств.
 *
 * Данные намеренно собраны в одном месте на C++ стороне, чтобы UI и
 * валидация базы использовали один и тот же источник истины.
 */
namespace Reference {

QStringList rankCategories();
QStringList ranksFor(const QString &category);
QStringList allRanks();
QStringList positions();
QStringList personStatuses();
QStringList caseStatuses();
QStringList evidenceTypes();
QStringList evidenceStatuses();
QStringList roles();

bool isValidRank(const QString &rank);
bool isValidRankCategory(const QString &category);
bool isValidPosition(const QString &position);
QString categoryForRank(const QString &rank);

} // namespace Reference

class ReferenceData : public QObject
{
    Q_OBJECT

public:
    explicit ReferenceData(QObject *parent = nullptr);

    Q_INVOKABLE QStringList rankCategories() const;
    Q_INVOKABLE QStringList ranks(const QString &category) const;
    Q_INVOKABLE QStringList allRanks() const;
    Q_INVOKABLE QStringList positions() const;
    Q_INVOKABLE QStringList personStatuses() const;
    Q_INVOKABLE QStringList caseStatuses() const;
    Q_INVOKABLE QStringList evidenceTypes() const;
    Q_INVOKABLE QStringList evidenceStatuses() const;
    Q_INVOKABLE QStringList roles() const;
    Q_INVOKABLE QString categoryForRank(const QString &rank) const;
};

#endif // REFERENCEDATA_H
