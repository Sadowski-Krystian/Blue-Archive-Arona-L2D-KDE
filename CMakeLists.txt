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

# Set RPATH so the wrapper plugin knows to look in the exact same folder for the backing library
set_target_properties(BlueArchiveSpineplugin PROPERTIES 
    PREFIX "lib"
    BUILD_RPATH "$ORIGIN"
    INSTALL_RPATH "$ORIGIN"
)

# Ensure the backing library also has the correct RPATH
set_target_properties(BlueArchiveSpine PROPERTIES 
    BUILD_RPATH "$ORIGIN"
    INSTALL_RPATH "$ORIGIN"
)

target_include_directories(BlueArchiveSpine PRIVATE "${SPINE_DIR}/include" "${CMAKE_CURRENT_SOURCE_DIR}/src")
target_link_libraries(BlueArchiveSpine PRIVATE Qt6::Core Qt6::Gui Qt6::Quick Qt6::Multimedia)

# ==========================================
# 3. Ship the QML plugin INSIDE the Plasma package (self-contained).
# No system QML install path or env vars required for end users.
# ==========================================
set(BA_SPINE_PKG_DIR "${CMAKE_CURRENT_SOURCE_DIR}/package/contents/ui/BlueArchiveSpine")

add_custom_command(TARGET BlueArchiveSpineplugin POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory "${BA_SPINE_PKG_DIR}"
    
    # Copies the QML wrapper plugin
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "$<TARGET_FILE:BlueArchiveSpineplugin>"
        "${BA_SPINE_PKG_DIR}/"
        
    # Copies the actual C++ backing library 
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "$<TARGET_FILE:BlueArchiveSpine>"
        "${BA_SPINE_PKG_DIR}/"
        
    # Copies QML module definitions
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${CMAKE_BINARY_DIR}/qml/BlueArchiveSpine/qmldir"
        "${BA_SPINE_PKG_DIR}/"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${CMAKE_BINARY_DIR}/qml/BlueArchiveSpine/BlueArchiveSpine.qmltypes"
        "${BA_SPINE_PKG_DIR}/"
        
    COMMENT "Copying BlueArchiveSpine plugin and backing library into the Plasma package (self-contained)"
)

plasma_install_package(package l2d.arona.plana.bluearchive wallpapers wallpaper)
target_compile_options(BlueArchiveSpine PRIVATE -Wno-type-limits -Wno-suggest-override -Wno-deprecated-declarations)