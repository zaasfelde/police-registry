#ifndef UISMOKE_H
#define UISMOKE_H

class DatabaseManager;
class QQmlApplicationEngine;

/*
 * Служебный режим разработчика: создаёт временную базу с демонстрационными
 * данными, открывает основное окно и сохраняет скриншоты разделов.
 * Запускается только с флагом --ui-smoke и не трогает рабочую базу.
 */
int runUiSmoke(DatabaseManager &db, QQmlApplicationEngine &engine);

#endif // UISMOKE_H
