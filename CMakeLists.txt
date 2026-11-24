cmake_minimum_required(VERSION 3.21)

project(policedep VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.8 REQUIRED COMPONENTS Core Gui Qml Quick Sql Network QuickControls2)

qt_standard_project_setup(REQUIRES 6.8)

set_source_files_properties(
    qml/Theme.qml
    qml/App.qml
    PROPERTIES QT_QML_SINGLETON_TYPE TRUE
)

qt_add_executable(apppolicedep
    main.cpp
)

qt_add_qml_module(apppolicedep
    URI policedep
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/Theme.qml
        qml/App.qml
        qml/components/AppButton.qml
        qml/components/AppComboBox.qml
        qml/components/AppTextArea.qml
        qml/components/AppTextField.qml
        qml/components/Avatar.qml
        qml/components/Badge.qml
        qml/components/Card.qml
        qml/components/ConfirmDialog.qml
        qml/components/DateField.qml
        qml/components/EmptyState.qml
        qml/components/GlobalSearch.qml
        qml/components/InfoRow.qml
        qml/components/MiniCalendar.qml
        qml/components/PageHeader.qml
        qml/components/PasswordStrength.qml
        qml/components/PhotoPicker.qml
        qml/components/QrPanel.qml
        qml/components/RecoveryCodesDialog.qml
        qml/components/SearchField.qml
        qml/components/StatCard.qml
        qml/components/ToastHost.qml
        qml/pages/AddCaseForm.qml
        qml/pages/AddEvidenceForm.qml
        qml/pages/AddPersonForm.qml
        qml/pages/CaseDialog.qml
        qml/pages/CaseListForm.qml
        qml/pages/CasesPage.qml
        qml/pages/DashboardPage.qml
        qml/pages/EmployeeDetailsForm.qml
        qml/pages/EmployeeDialog.qml
        qml/pages/EmployeeListForm.qml
        qml/pages/EmployeesPage.qml
        qml/pages/EvidenceDialog.qml
        qml/pages/EvidencePage.qml
        qml/pages/LoginForm.qml
        qml/pages/MainApp.qml
        qml/pages/PersonDialog.qml
        qml/pages/PersonListForm.qml
        qml/pages/PersonsPage.qml
        qml/pages/ProfilePage.qml
        qml/pages/RegistrationForm.qml
    SOURCES
        src/DatabaseManager.h
        src/DatabaseManager.cpp
        src/ReferenceData.h
        src/ReferenceData.cpp
        src/TotpAuth.h
        src/TotpAuth.cpp
        src/QrCodeItem.h
        src/QrCodeItem.cpp
        src/PhotoImageProvider.h
        src/PhotoImageProvider.cpp
        src/UiSmoke.h
        src/UiSmoke.cpp
        src/third_party/qrcodegen.hpp
        src/third_party/qrcodegen.cpp
)

set_target_properties(apppolicedep PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_compile_definitions(apppolicedep PRIVATE
    APP_VERSION="${PROJECT_VERSION}"
)

target_include_directories(apppolicedep PRIVATE src)

target_link_libraries(apppolicedep
    PRIVATE Qt6::Quick Qt6::Qml Qt6::Core Qt6::Gui Qt6::Sql Qt6::Network Qt6::QuickControls2
)

# Консольный прогон проверок логики (без QML): apppolicedep_selftest
add_executable(policedep_selftest
    src/SelfTestMain.cpp
    src/SelfTest.h
    src/SelfTest.cpp
    src/DatabaseManager.h
    src/DatabaseManager.cpp
    src/ReferenceData.h
    src/ReferenceData.cpp
    src/TotpAuth.h
    src/TotpAuth.cpp
)
target_include_directories(policedep_selftest PRIVATE src)
target_link_libraries(policedep_selftest PRIVATE Qt6::Core Qt6::Gui Qt6::Sql Qt6::Network)
set_target_properties(policedep_selftest PROPERTIES WIN32_EXECUTABLE FALSE)

include(GNUInstallDirs)
install(TARGETS apppolicedep
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
