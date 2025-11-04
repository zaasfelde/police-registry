cmake_minimum_required(VERSION 3.16)

project(policedep VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick Sql)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(apppolicedep
    main.cpp
    DatabaseManager.cpp
)

qt_add_qml_module(apppolicedep
    URI policedep
    VERSION 1.0
    QML_FILES
        pages/AddCaseForm.qml
        pages/AddEvidenceForm.qml
        pages/AddPersonForm.qml
        pages/CaseListForm.qml
        pages/EmployeeDetailsForm.qml
        pages/EmployeeListForm.qml
        pages/LoginForm.qml
        pages/Main.qml
        pages/MainApp.qml
        pages/RegistrationForm.qml
    SOURCES
        DatabaseManager.h DatabaseManager.cpp
        QML_FILES pages/PersonListForm.qml
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(apppolicedep PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.apppolicedep
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(apppolicedep
    PRIVATE Qt6::Quick Qt6::Qml Qt6::Core Qt6::Gui Qt6::Sql
)

include(GNUInstallDirs)
install(TARGETS apppolicedep
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
