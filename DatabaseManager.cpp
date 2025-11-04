#include "DatabaseManager.h"

DatabaseManager::DatabaseManager(QObject *parent)
    : QObject(parent)
{
    if (!initDatabase()) {
        qDebug() << "Failed to initialize database";
    }
}

DatabaseManager::~DatabaseManager()
{
    if (m_database.isOpen()) {
        m_database.close();
    }
}

bool DatabaseManager::initDatabase()
{
    m_database = QSqlDatabase::addDatabase("QSQLITE");
    m_database.setDatabaseName("policedepartment.db");

    if (!m_database.open()) {
        qDebug() << "Error: connection with database failed - " << m_database.lastError().text();
        return false;
    }

    // qDebug() << "Database created at:" << QDir::currentPath() + "/policedepartment.db";
    qDebug() << "Full database path:" << QFileInfo(m_database.databaseName()).absoluteFilePath();

    return createTables();
}

bool DatabaseManager::createTables()
{
    QSqlQuery query;

    // Таблица officers
    QString createOfficersTable =
        "CREATE TABLE IF NOT EXISTS officers ("
        "officer_id INTEGER PRIMARY KEY AUTOINCREMENT, "
        "last_name VARCHAR(50) NOT NULL, "
        "name VARCHAR(50) NOT NULL, "
        "patronymic VARCHAR(50), "
        "rank VARCHAR(50), "
        "position VARCHAR(50), "
        "birth_date DATE, "
        "personnel_number NVARCHAR(50), "
        "hire_date DATE DEFAULT CURRENT_DATE, "
        "experience INT, "
        "system_login VARCHAR(255), "
        "password_hash VARCHAR(255),"
        "photo_path TEXT"
        ");";

    if (!query.exec(createOfficersTable)) {
        qDebug() << "Error creating officers table:" << query.lastError().text();
        return false;
    }

    // Таблица cases
    QString createCasesTable =
        "CREATE TABLE IF NOT EXISTS cases ("
        "case_id INTEGER PRIMARY KEY AUTOINCREMENT, "
        "case_number VARCHAR(10) NOT NULL UNIQUE, "
        "title VARCHAR(100) NOT NULL, "
        "description TEXT, "
        "date_opened DATE NOT NULL, "
        "date_closed DATE, "
        "status TEXT CHECK(status IN ('Возбуждено', 'Расследование', 'Закрыто', 'Приостановлено')), "
        "investigator_id INTEGER, "
        "FOREIGN KEY(investigator_id) REFERENCES officers(officer_id)"
        ");";

    if (!query.exec(createCasesTable)) {
        qDebug() << "Error creating cases table:" << query.lastError().text();
        return false;
    }

    // Таблица persons
    QString createPersonsTable =
        "CREATE TABLE IF NOT EXISTS persons ("
        "person_id INTEGER PRIMARY KEY AUTOINCREMENT, "
        "last_name VARCHAR(50) NOT NULL, "
        "name VARCHAR(50) NOT NULL, "
        "patronymic VARCHAR(50), "
        "birth_date DATE, "
        "address TEXT, "
        "phone VARCHAR(255), "
        "description TEXT, "
        "criminal_record BOOLEAN, "
        "status TEXT CHECK(status IN ('Подозреваемый', 'Свидетель', 'Обвиняемый', 'Потерпевший')), "
        "case_id INTEGER, "
        "FOREIGN KEY(case_id) REFERENCES cases(case_id)"
        ");";

    if (!query.exec(createPersonsTable)) {
        qDebug() << "Error creating persons table:" << query.lastError().text();
        return false;
    }

    // Таблица evidence
    QString createEvidenceTable =
        "CREATE TABLE IF NOT EXISTS evidence ("
        "evidence_id INTEGER PRIMARY KEY AUTOINCREMENT, "
        "type TEXT CHECK(type IN ('Оружие', 'Транспортное средство', 'Одежда', 'Биологический образец', 'Прочее')), "
        "description TEXT NOT NULL, "
        "registration_date DATETIME NOT NULL, "
        "current_status TEXT CHECK(current_status IN ('Изъято', 'На экспертизе', 'Утеряно', 'Приобщено к делу')), "
        "case_id INTEGER, "
        "FOREIGN KEY(case_id) REFERENCES cases(case_id)"
        ");";

    if (!query.exec(createEvidenceTable)) {
        qDebug() << "Error creating evidence table:" << query.lastError().text();
        return false;
    }

    qDebug() << "All tables created successfully";
    return true;
}

QString DatabaseManager::hashPassword(const QString &password)
{
    return QCryptographicHash::hash(password.toUtf8(), QCryptographicHash::Sha256).toHex();
}

// Методы аутентификации
bool DatabaseManager::registerOfficer(const QVariantMap &officerData)
{
    QString login = officerData["login"].toString().trimmed();
    QString password = officerData["password"].toString();

    if (login.isEmpty() || password.isEmpty()) {
        qDebug() << "Login or password is empty";
        return false;
    }

    // Проверяем, не занят ли логин
    if (isLoginExists(login)) {
        qDebug() << "Login already exists:" << login;
        return false;
    }

    QSqlQuery query;
    query.prepare(
        "INSERT INTO officers (last_name, name, patronymic, rank, position, birth_date, personnel_number, experience, system_login, password_hash) "
        "VALUES (:last_name, :name, :patronymic, :rank, :position, :birth_date, :personnel_number, :experience, :system_login, :password_hash)"
        );

    query.bindValue(":last_name", officerData["surname"].toString());
    query.bindValue(":name", officerData["name"].toString());
    query.bindValue(":patronymic", officerData["patronymic"].toString());
    query.bindValue(":rank", officerData["rank"].toString());
    query.bindValue(":position", officerData["position"].toString());
    query.bindValue(":birth_date", officerData["birth_date"].toString()); // ДОБАВЛЕНО
    query.bindValue(":personnel_number", officerData["personnel_number"].toString()); // ДОБАВЛЕНО
    query.bindValue(":experience", officerData["experience"].toInt()); // ДОБАВЛЕНО
    query.bindValue(":system_login", login);
    query.bindValue(":password_hash", hashPassword(password));

    if (!query.exec()) {
        qDebug() << "Error registering officer:" << query.lastError().text();
        return false;
    }

    qDebug() << "Officer registered successfully with ID:" << query.lastInsertId();
    return true;
}

bool DatabaseManager::verifyLogin(const QString &login, const QString &password)
{
    QSqlQuery query;
    query.prepare("SELECT password_hash FROM officers WHERE system_login = :login");
    query.bindValue(":login", login.trimmed());

    if (!query.exec()) {
        qDebug() << "Error verifying login:" << query.lastError().text();
        return false;
    }

    if (query.next()) {
        QString storedHash = query.value(0).toString();
        QString inputHash = hashPassword(password);
        return storedHash == inputHash;
    }

    return false;
}

bool DatabaseManager::isLoginExists(const QString &login)
{
    QSqlQuery query;
    query.prepare("SELECT COUNT(*) FROM officers WHERE system_login = :login");
    query.bindValue(":login", login.trimmed());

    if (!query.exec() || !query.next()) {
        return false;
    }

    if (query.value(0).toInt() > 0) return true; else return false;
}

// Методы для работы с таблицей officers
bool DatabaseManager::addOfficer(const QVariantMap &officerData)
{
    QSqlQuery query;
    query.prepare(
        "INSERT INTO officers (last_name, name, patronymic, rank, position, birth_date, personnel_number, hire_date, experience, system_login, password_hash) "
        "VALUES (:last_name, :name, :patronymic, :rank, :position, :birth_date, :personnel_number, :hire_date, :experience, :system_login, :password_hash)"
        );

    query.bindValue(":last_name", officerData["surname"].toString());
    query.bindValue(":name", officerData["name"].toString());
    query.bindValue(":patronymic", officerData["patronymic"].toString());
    query.bindValue(":rank", officerData["rank"].toString());
    query.bindValue(":position", officerData["position"].toString());
    query.bindValue(":birth_date", officerData["birth_date"].toString());
    query.bindValue(":personnel_number", officerData["personnel_number"].toString());
    query.bindValue(":hire_date", officerData["hire_date"].toString());
    query.bindValue(":experience", officerData["experience"].toInt());
    query.bindValue(":system_login", officerData["surname"].toString().toLower() + "." + officerData["name"].toString().toLower());
    query.bindValue(":password_hash", QCryptographicHash::hash(officerData["name"].toString().toUtf8(), QCryptographicHash::Md5).toHex());

    if (!query.exec()) {
        qDebug() << "Error adding officer:" << query.lastError().text();
        return false;
    }

    qDebug() << "Officer added successfully with ID:" << query.lastInsertId();
    return true;
}

QVariantList DatabaseManager::getAllOfficers()
{
    QVariantList officers;
    QSqlQuery query("SELECT * FROM officers ORDER BY last_name, name");

    while (query.next()) {
        QVariantMap officer;
        officer["officer_id"] = query.value("officer_id");
        officer["last_name"] = query.value("last_name");
        officer["name"] = query.value("name");
        officer["patronymic"] = query.value("patronymic");
        officer["rank"] = query.value("rank");
        officer["position"] = query.value("position");
        officer["birth_date"] = query.value("birth_date");
        officer["personnel_number"] = query.value("personnel_number");
        officer["hire_date"] = query.value("hire_date");
        officer["experience"] = query.value("experience").toInt();
        officer["system_login"] = query.value("system_login");
        officer["photo_path"] = query.value("photo_path"); // ДОБАВЛЕНО

        officers.append(officer);
    }

    return officers;
}

bool DatabaseManager::deleteOfficer(int officerId)
{
    QSqlQuery query;
    query.prepare("DELETE FROM officers WHERE officer_id = :officer_id");
    query.bindValue(":officer_id", officerId);

    return query.exec();
}

// Методы для работы с таблицей persons
bool DatabaseManager::addPerson(const QVariantMap &personData)
{
    QSqlQuery query;
    query.prepare(
        "INSERT INTO persons (last_name, name, patronymic, birth_date, address, phone, description, criminal_record, status, case_id) "
        "VALUES (:last_name, :name, :patronymic, :birth_date, :address, :phone, :description, :criminal_record, :status, "
        "(SELECT case_id FROM cases WHERE case_number = :case_number))"
        );

    query.bindValue(":last_name", personData["surname"].toString());
    query.bindValue(":name", personData["name"].toString());
    query.bindValue(":patronymic", personData["patronymic"].toString());
    query.bindValue(":birth_date", personData["birthDate"].toString());
    query.bindValue(":address", personData["address"].toString());
    query.bindValue(":phone", personData["phone"].toString());
    query.bindValue(":description", personData["description"].toString());
    query.bindValue(":criminal_record", personData["criminal_record"].toBool());
    query.bindValue(":status", personData["status"].toString());
    query.bindValue(":case_number", personData["caseNumber"].toString());

    if (!query.exec()) {
        qDebug() << "Error adding person:" << query.lastError().text();
        return false;
    }

    qDebug() << "Person added successfully with ID:" << query.lastInsertId();
    return true;
}

QVariantList DatabaseManager::getAllPersons()
{
    QVariantList persons;
    QSqlQuery query("SELECT p.*, c.case_number FROM persons p LEFT JOIN cases c ON p.case_id = c.case_id ORDER BY p.last_name, p.name");

    while (query.next()) {
        QVariantMap person;
        person["person_id"] = query.value("person_id");
        person["last_name"] = query.value("last_name");
        person["name"] = query.value("name");
        person["patronymic"] = query.value("patronymic");
        person["birth_date"] = query.value("birth_date");
        person["address"] = query.value("address");
        person["phone"] = query.value("phone");
        person["description"] = query.value("description");
        person["criminal_record"] = query.value("criminal_record");
        person["status"] = query.value("status");
        person["case_number"] = query.value("case_number");

        persons.append(person);
    }

    return persons;
}

bool DatabaseManager::deletePerson(int personId)
{
    QSqlQuery query;
    query.prepare("DELETE FROM persons WHERE person_id = :person_id");
    query.bindValue(":person_id", personId);

    return query.exec();
}

// Методы для работы с таблицей cases
bool DatabaseManager::addCase(const QVariantMap &caseData)
{
    QSqlQuery query;
    query.prepare(
        "INSERT INTO cases (case_number, title, description, date_opened, date_closed, status, investigator_id) "
        "VALUES (:case_number, :title, :description, :date_opened, :date_closed, :status, :investigator_id)"
        );

    query.bindValue(":case_number", caseData["caseNumber"].toString());
    query.bindValue(":title", caseData["title"].toString());
    query.bindValue(":description", caseData["description"].toString());
    query.bindValue(":date_opened", caseData["dateOpened"].toString());
    query.bindValue(":date_closed", caseData["dateClosed"].toString());
    query.bindValue(":status", caseData["status"].toString());
    query.bindValue(":investigator_id", caseData["investigatorId"].toInt());

    if (!query.exec()) {
        qDebug() << "Error adding case:" << query.lastError().text();
        return false;
    }

    qDebug() << "Case added successfully with ID:" << query.lastInsertId();
    return true;
}

QVariantList DatabaseManager::getAllCases()
{
    QVariantList cases;
    QSqlQuery query("SELECT c.*, o.last_name || ' ' || o.name as investigator_name FROM cases c LEFT JOIN officers o ON c.investigator_id = o.officer_id ORDER BY c.date_opened DESC");

    while (query.next()) {
        QVariantMap caseItem;
        caseItem["case_id"] = query.value("case_id");
        caseItem["case_number"] = query.value("case_number");
        caseItem["title"] = query.value("title");
        caseItem["description"] = query.value("description");
        caseItem["date_opened"] = query.value("date_opened");
        caseItem["date_closed"] = query.value("date_closed");
        caseItem["status"] = query.value("status");
        caseItem["investigator_name"] = query.value("investigator_name");

        cases.append(caseItem);
    }

    return cases;
}

bool DatabaseManager::deleteCase(int caseId)
{
    QSqlQuery query;
    query.prepare("DELETE FROM cases WHERE case_id = :case_id");
    query.bindValue(":case_id", caseId);

    return query.exec();
}

// Методы для работы с таблицей evidence
bool DatabaseManager::addEvidence(const QVariantMap &evidenceData)
{
    QSqlQuery query;
    query.prepare(
        "INSERT INTO evidence (type, description, registration_date, current_status, case_id) "
        "VALUES (:type, :description, :registration_date, :current_status, "
        "(SELECT case_id FROM cases WHERE case_number = :case_number))"
        );

    query.bindValue(":type", evidenceData["type"].toString());
    query.bindValue(":description", evidenceData["description"].toString());
    query.bindValue(":registration_date", evidenceData["registrationDate"].toString());
    query.bindValue(":current_status", evidenceData["currentStatus"].toString());
    query.bindValue(":case_number", evidenceData["caseNumber"].toString());

    if (!query.exec()) {
        qDebug() << "Error adding evidence:" << query.lastError().text();
        return false;
    }

    qDebug() << "Evidence added successfully with ID:" << query.lastInsertId();
    return true;
}

QVariantList DatabaseManager::getAllEvidence()
{
    QVariantList evidenceList;
    QSqlQuery query("SELECT e.*, c.case_number FROM evidence e LEFT JOIN cases c ON e.case_id = c.case_id ORDER BY e.registration_date DESC");

    while (query.next()) {
        QVariantMap evidence;
        evidence["evidence_id"] = query.value("evidence_id");
        evidence["type"] = query.value("type");
        evidence["description"] = query.value("description");
        evidence["registration_date"] = query.value("registration_date");
        evidence["current_status"] = query.value("current_status");
        evidence["case_number"] = query.value("case_number");

        evidenceList.append(evidence);
    }

    return evidenceList;
}

bool DatabaseManager::deleteEvidence(int evidenceId)
{
    QSqlQuery query;
    query.prepare("DELETE FROM evidence WHERE evidence_id = :evidence_id");
    query.bindValue(":evidence_id", evidenceId);

    return query.exec();
}

// Методы для работы с фото сотрудников
bool DatabaseManager::updateEmployeePhoto(int officerId, const QString &photoPath)
{
    QSqlQuery query;
    query.prepare("UPDATE officers SET photo_path = :photo_path WHERE officer_id = :officer_id");
    query.bindValue(":photo_path", photoPath);
    query.bindValue(":officer_id", officerId);

    if (!query.exec()) {
        qDebug() << "Error updating employee photo:" << query.lastError().text();
        return false;
    }

    qDebug() << "Employee photo updated successfully for officer ID:" << officerId;
    return true;
}

bool DatabaseManager::removeEmployeePhoto(int officerId)
{
    QSqlQuery query;
    query.prepare("UPDATE officers SET photo_path = NULL WHERE officer_id = :officer_id");
    query.bindValue(":officer_id", officerId);

    if (!query.exec()) {
        qDebug() << "Error removing employee photo:" << query.lastError().text();
        return false;
    }

    qDebug() << "Employee photo removed successfully for officer ID:" << officerId;
    return true;
}

QString DatabaseManager::getEmployeePhoto(int officerId)
{
    QSqlQuery query;
    query.prepare("SELECT photo_path FROM officers WHERE officer_id = :officer_id");
    query.bindValue(":officer_id", officerId);

    if (query.exec() && query.next()) {
        return query.value(0).toString();
    }

    return "";
}

