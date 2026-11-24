pragma Singleton

import QtQuick

/*
 * Глобальное состояние интерфейса: текущий пользователь, сигналы
 * навигации и уведомлений. Экраны не знают друг о друге — общаются
 * через этот объект и сигналы главного окна.
 */
QtObject {
    id: app

    property var user: ({})
    property bool isAdmin: !!(user && user.role === "admin")
    property bool isAuthenticated: !!(user && user.id)

    // Увеличивается после изменений в данных, экраны перечитывают списки.
    property int refreshToken: 0

    signal toast(string text, string kind)
    signal navigate(string page)
    signal openEntity(string entityType, int entityId)
    signal createRequested(string entityType)

    function notify(text, kind) {
        toast(text, kind || "info")
    }

    function setUser(value) {
        user = value || ({})
    }

    function refresh() {
        refreshToken++
    }

    function go(page) {
        navigate(page)
    }

    function displayName() {
        return user && user.full_name ? user.full_name : ""
    }

    function roleLabel() {
        return user && user.role === "admin" ? "Администратор" : "Сотрудник"
    }

    function hasPermissionToManage() {
        return isAdmin
    }
}
