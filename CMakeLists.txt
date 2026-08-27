cmake_minimum_required(VERSION 3.16)
project(BlueArchiveAronaWallpaper VERSION 1.0.0 LANGUAGES CXX)

# Require modern C++

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

# Find Extra CMake Modules (ECM) required by KDE

find_package(ECM 6.0 REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${CMAKE_MODULE_PATH})
include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)

# Find Qt6 and KDE Plasma Frameworks

find_package(Qt6 REQUIRED COMPONENTS Core Gui Quick Multimedia)
find_package(Plasma REQUIRED)

# ==========================================
# 1. Setup Spine C++ Runtimes
# ==========================================
# Point to the spine-cpp folder inside the cloned repo

set(SPINE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/src/spine-runtimes/spine-cpp/spine-cpp")

# Grab all Esoteric Software spine-cpp source files

file(GLOB_RECURSE SPINE_SOURCES "${SPINE_DIR}/src/spine/*.cpp")
if(NOT EXISTS "${SPINE_DIR}/include/spine/spine.h")
    message(FATAL_ERROR "Spine C++ runtime not found in src/spine-runtimes/spine-cpp!")
endif()

# ==========================================
# 2. Build the QML Plugin (C++ Backend)
# ==========================================
# This creates a module that can be imported in main.qml as:

# import BlueArchiveSpine 1.0

qt_add_qml_module(BlueArchiveSpine
    URI BlueArchiveSpine
    VERSION 1.0
    OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/qml/BlueArchiveSpine"
    SOURCES
        src/SpineExtensionImpl.cpp
        src/SpineItem.cpp
        src/SpineItem.h
        ${SPINE_SOURCES}
)

set_target_properties(BlueArchiveSpineplugin PROPERTIES PREFIX "lib")
set_target_properties(BlueArchiveSpineplugin PROPERTIES INSTALL_RPATH "$ORIGIN")

# Add the Spine include path so SpineItem.cpp can find <spine/spine.h>

target_include_directories(BlueArchiveSpine PRIVATE "${SPINE_DIR}/include" "${CMAKE_CURRENT_SOURCE_DIR}/src")

# Link against Qt6 Quick (for Scene Graph rendering) and Multimedia

target_link_libraries(BlueArchiveSpine PRIVATE Qt6::Core Qt6::Gui Qt6::Quick Qt6::Multimedia)
# ==========================================
# 3. Installation Rules
# ==========================================
# Install the QML Plugin, generated qmldir, and typeinfo to the system

# 1. Install the main backing library and the auto-generated plugin target
install(TARGETS BlueArchiveSpine BlueArchiveSpineplugin
    LIBRARY DESTINATION ${KDE_INSTALL_QMLDIR}/BlueArchiveSpine
)

# 2. Install the QML metadata files (qmldir and .qmltypes)
install(FILES 
    "${CMAKE_BINARY_DIR}/qml/BlueArchiveSpine/qmldir"
    "${CMAKE_BINARY_DIR}/qml/BlueArchiveSpine/BlueArchiveSpine.qmltypes"
    DESTINATION ${KDE_INSTALL_QMLDIR}/BlueArchiveSpine
)

# Install the Plasma package (The QML frontend, assets, and metadata)
plasma_install_package(package l2d.arona.plana.bluearchive wallpapers wallpaper)