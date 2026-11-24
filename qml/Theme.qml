pragma Singleton

import QtQuick

/*
 * Единая тема приложения: цвета, типографика, отступы и небольшие
 * функции форматирования. Все экраны используют только эти значения,
 * поэтому визуальный стиль меняется в одном месте.
 */
QtObject {
    id: theme

    // ---------- Палитра ----------
    readonly property color bg: "#F2F5FA"
    readonly property color surface: "#FFFFFF"
    readonly property color surfaceAlt: "#F7F9FC"
    readonly property color surfaceMuted: "#EAF0F7"
    readonly property color sidebar: "#0B1E33"
    readonly property color sidebarHover: "#132C49"
    readonly property color sidebarActive: "#1B3D62"
    readonly property color sidebarText: "#A9BED4"
    readonly property color sidebarTextActive: "#FFFFFF"

    readonly property color primary: "#1F5FA8"
    readonly property color primaryHover: "#1A5394"
    readonly property color primaryPressed: "#154578"
    readonly property color accent: "#2F80ED"
    readonly property color gold: "#C7A34B"

    readonly property color text: "#15243A"
    readonly property color textMuted: "#5D6E84"
    readonly property color textFaint: "#93A3B6"
    readonly property color border: "#DCE4EE"
    readonly property color borderStrong: "#C6D2E0"
    readonly property color overlay: "#660B1E33"

    readonly property color danger: "#D64545"
    readonly property color dangerBg: "#FDECEC"
    readonly property color success: "#1F9D63"
    readonly property color successBg: "#E7F6EE"
    readonly property color warning: "#B7791F"
    readonly property color warningBg: "#FCF3E2"
    readonly property color info: "#2F6FED"
    readonly property color infoBg: "#EAF1FE"
    readonly property color neutralBg: "#EEF2F7"

    // ---------- Геометрия ----------
    readonly property int radiusSm: 6
    readonly property int radius: 10
    readonly property int radiusLg: 14
    readonly property int radiusPill: 999

    readonly property int gapXs: 4
    readonly property int gapSm: 8
    readonly property int gap: 12
    readonly property int gapLg: 16
    readonly property int gapXl: 24
    readonly property int gapXxl: 32

    // ---------- Типографика ----------
    readonly property string fontFamily: "Segoe UI"
    readonly property int fontCaption: 11
    readonly property int fontSmall: 12
    readonly property int fontBody: 13
    readonly property int fontMedium: 14
    readonly property int fontTitle: 18
    readonly property int fontHeading: 22
    readonly property int fontDisplay: 28

    // ---------- Статусы ----------
    function statusColor(status) {
        switch (status) {
        case "Возбуждено": return theme.danger
        case "Расследование": return theme.warning
        case "Приостановлено": return theme.textMuted
        case "Закрыто": return theme.success
        case "Подозреваемый": return theme.danger
        case "Обвиняемый": return "#7C4DBE"
        case "Свидетель": return theme.warning
        case "Потерпевший": return theme.info
        case "Изъято": return theme.info
        case "На экспертизе": return theme.warning
        case "Приобщено к делу": return theme.success
        case "Возвращено владельцу": return theme.success
        case "Утеряно": return theme.danger
        default: return theme.textMuted
        }
    }

    function statusBackground(status) {
        switch (status) {
        case "Возбуждено": return theme.dangerBg
        case "Расследование": return theme.warningBg
        case "Приостановлено": return theme.neutralBg
        case "Закрыто": return theme.successBg
        case "Подозреваемый": return theme.dangerBg
        case "Обвиняемый": return "#F1EAFB"
        case "Свидетель": return theme.warningBg
        case "Потерпевший": return theme.infoBg
        case "Изъято": return theme.infoBg
        case "На экспертизе": return theme.warningBg
        case "Приобщено к делу": return theme.successBg
        case "Возвращено владельцу": return theme.successBg
        case "Утеряно": return theme.dangerBg
        default: return theme.neutralBg
        }
    }

    function statusIcon(status) {
        switch (status) {
        case "Возбуждено": return "🚨"
        case "Расследование": return "🔍"
        case "Приостановлено": return "⏸"
        case "Закрыто": return "✓"
        case "Подозреваемый": return "🔍"
        case "Обвиняемый": return "⚖"
        case "Свидетель": return "👁"
        case "Потерпевший": return "🛡"
        case "Изъято": return "📦"
        case "На экспертизе": return "🧪"
        case "Приобщено к делу": return "📎"
        case "Возвращено владельцу": return "↩"
        case "Утеряно": return "⚠"
        default: return "•"
        }
    }

    function roleLabel(role) {
        return role === "admin" ? qsTr("Администратор") : qsTr("Сотрудник")
    }

    // ---------- Форматирование ----------
    function isoDatePart(value) {
        if (!value)
            return ""
        var text = String(value)
        return text.length >= 10 ? text.substring(0, 10) : text
    }

    function formatDate(value) {
        var text = isoDatePart(value)
        if (!text)
            return "—"
        var parts = text.split("-")
        if (parts.length !== 3)
            return text
        return parts[2] + "." + parts[1] + "." + parts[0]
    }

    function formatDateTime(value) {
        if (!value)
            return "—"
        var text = String(value)
        var date = new Date(text)
        if (isNaN(date.getTime())) {
            var datePart = isoDatePart(text)
            var timePart = text.length >= 16 ? text.substring(11, 16) : ""
            return formatDate(datePart) + (timePart ? " " + timePart : "")
        }
        return Qt.formatDateTime(date, "dd.MM.yyyy HH:mm")
    }

    function formatTime(value) {
        if (!value)
            return "—"
        var date = new Date(String(value))
        if (isNaN(date.getTime()))
            return "—"
        return Qt.formatDateTime(date, "HH:mm")
    }

    function todayIso() {
        return Qt.formatDate(new Date(), "yyyy-MM-dd")
    }

    function formatIsoDate(date) {
        return date ? Qt.formatDate(date, "yyyy-MM-dd") : ""
    }

    function initials(lastName, firstName, patronymic) {
        var result = ""
        if (lastName)
            result += String(lastName).charAt(0)
        if (firstName)
            result += String(firstName).charAt(0)
        if (!result && patronymic)
            result += String(patronymic).charAt(0)
        return result.toUpperCase()
    }

    function plural(count, one, few, many) {
        var value = Math.abs(Number(count)) % 100
        if (value >= 11 && value <= 19)
            return many
        var last = value % 10
        if (last === 1)
            return one
        if (last >= 2 && last <= 4)
            return few
        return many
    }

    function ageText(age) {
        if (age === undefined || age === null || age < 0)
            return ""
        return age + " " + plural(age, "год", "года", "лет")
    }

    function experienceText(years) {
        var value = Number(years)
        if (!value || value <= 0)
            return "—"
        return value + " " + plural(value, "год", "года", "лет")
    }

    function greeting() {
        var hour = new Date().getHours()
        if (hour < 6)
            return "Доброй ночи"
        if (hour < 12)
            return "Доброе утро"
        if (hour < 18)
            return "Добрый день"
        return "Добрый вечер"
    }
}
