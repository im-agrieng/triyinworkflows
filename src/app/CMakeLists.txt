find_package(Qt6QuickCompiler QUIET)

if(MSVC)
  configure_file("${CMAKE_SOURCE_DIR}/platform/windows/appicon.rc.in"
                 "${CMAKE_CURRENT_BINARY_DIR}/appicon.rc")
  set(ICON_SRC "${CMAKE_CURRENT_BINARY_DIR}/appicon.rc")
endif()

if(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
  set(qfield_ICON ${CMAKE_SOURCE_DIR}/platform/macos/qfield_logo.icns)
  set_source_files_properties(${qfield_ICON} PROPERTIES MACOSX_PACKAGE_LOCATION
                                                        "Resources")
  list(APPEND RESOURCES ${qfield_ICON})
endif()

# lrelease .ts files
find_package(Qt6 COMPONENTS LinguistTools)

# include manually copied .qm files
file(GLOB QM_FILES_MANUAL ${CMAKE_SOURCE_DIR}/i18n/*.qm)

configure_file(${CMAKE_SOURCE_DIR}/images/logo.qrc.in
               ${CMAKE_BINARY_DIR}/images/logo.qrc @ONLY)

find_package(
  Qt6
  COMPONENTS Core5Compat
  REQUIRED)

function(create_executable)
  cmake_parse_arguments(exe "" "TARGET" "EXTRA_ARGS" "" ${ARGN})

  set(QFIELD_SOURCES
      main.cpp ${RESOURCES} ${CMAKE_SOURCE_DIR}/images/images.qrc
      ${CMAKE_BINARY_DIR}/images/logo.qrc
      ${CMAKE_SOURCE_DIR}/resources/resources.qrc ${ICON_SRC})

function(create_executable)
  cmake_parse_arguments(exe "" "TARGET" "EXTRA_ARGS" "" ${ARGN})

  set(QFIELD_SOURCES
      main.cpp ${RESOURCES} ${CMAKE_SOURCE_DIR}/images/images.qrc
      ${CMAKE_BINARY_DIR}/images/logo.qrc
      ${CMAKE_SOURCE_DIR}/resources/resources.qrc ${ICON_SRC})

  # Set Qt policy for Android paths if available
  if(POLICY QTP0002)
    cmake_policy(SET QTP0002 NEW)
  endif()

  if(ANDROID)
    # Create the app target for Android
    qt_add_executable(app ${QFIELD_SOURCES})
    set(exe_TARGET "app")
    set_property(TARGET app PROPERTY QT_ANDROID_PACKAGE_SOURCE_DIR
                                           ${ANDROID_PACKAGE_SOURCE_DIR})
    set_property(TARGET app PROPERTY QT_QML_IMPORT_PATH
                                           $ENV{Qt6_DIR}/qml)
    set_property(TARGET app PROPERTY QT_QML_ROOT_PATH
                                           ${CMAKE_SOURCE_DIR}/src/qml)

    set(PROJECT_NAME ${exe_TARGET})
  else()
    add_executable(${exe_TARGET} ${exe_EXTRA_ARGS} ${QFIELD_SOURCES})
  endif()

  file(GLOB TS_FILES ${CMAKE_SOURCE_DIR}/i18n/*.ts)
  set_source_files_properties(
    ${TS_FILES} PROPERTIES OUTPUT_LOCATION
                           "${CMAKE_BINARY_DIR}/i18n${exe_TARGET}")
  qt_add_translation(QM_FILES ${TS_FILES})

  qt_add_resources(
    ${exe_TARGET}
    "translations${exe_TARGET}"
    PREFIX
    "/i18n"
    BASE
    "${CMAKE_BINARY_DIR}/i18n${exe_TARGET}"
    FILES
    ${QM_FILES})

  target_link_libraries(${exe_TARGET} PRIVATE qfield_core qfield_qml)

  if(ANDROID)
    target_link_libraries(${exe_TARGET} PRIVATE qfield_service)
  endif()

  if(WITH_SENTRY)
    target_link_libraries(${exe_TARGET} PRIVATE qfield_sentry)
  endif()

  get_target_property(QT_TARGET_TYPE Qt::Core TYPE)
  if(${QT_TARGET_TYPE} STREQUAL "STATIC_LIBRARY")
    find_package(Qt6 COMPONENTS QmlImportScanner)

    get_target_property(qfield_qmlfiles qfield_qml QML_FILES)
    file(COPY ${qfield_qmlfiles}
         DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/qmldrop/app")

    if(NOT WITH_BLUETOOTH)
      file(REMOVE
           "${CMAKE_CURRENT_BINARY_DIR}/qmldrop/app/BluetoothDeviceChooser.qml")
    endif()
    if(NOT WITH_SERIALPORT)
      file(REMOVE
           "${CMAKE_CURRENT_BINARY_DIR}/qmldrop/app/SerialPortChooser.qml")
    endif()

    qt_import_qml_plugins(${exe_TARGET} PATH_TO_SCAN
                          "${CMAKE_CURRENT_BINARY_DIR}/qmldrop/app")
  endif()

  target_link_libraries(${exe_TARGET} PUBLIC Qt::Core5Compat)
  qt_import_plugins(${exe_TARGET} INCLUDE Qt::QSvgPlugin)
  qt_import_plugins(${exe_TARGET} INCLUDE Qt::Core5Compat)

  set_target_properties(${exe_TARGET} PROPERTIES AUTORCC TRUE)
endfunction()

  if(IOS OR CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    target_link_libraries(
      ${exe_TARGET}
      PUBLIC Qt6::QDarwinCameraPermissionPlugin
             Qt6::QDarwinMicrophonePermissionPlugin
             Qt6::QDarwinLocationPermissionPlugin)
    qt_import_plugins(
      ${exe_TARGET} INCLUDE Qt6::QDarwinCameraPermissionPlugin
      Qt6::QDarwinMicrophonePermissionPlugin
      Qt6::QDarwinLocationPermissionPlugin)
  endif()

  if(WITH_VCPKG) # this triggers the initialisation of static qca ossl plugin.
    target_compile_definitions(${exe_TARGET} PUBLIC HAVE_STATIC_QCA_PLUGINS)
  endif()

  set_target_properties(${exe_TARGET} PROPERTIES AUTORCC TRUE)
  if(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    # Handles platform-specific tasks, including insuring permission plugins
    qt_finalize_executable(qfield)

    set_target_properties(
      ${exe_TARGET}
      PROPERTIES MACOSX_BUNDLE_BUNDLE_NAME "${PROJECT_NAME}"
                 MACOSX_BUNDLE_INFO_STRING "${PROJECT_NAME} OPENGIS.ch"
                 MACOSX_BUNDLE_ICON_FILE "qfield_logo.icns"
                 MACOSX_BUNDLE_GUI_IDENTIFIER "${PROJECT_NAME}"
                 MACOSX_BUNDLE_LONG_VERSION_STRING "${PROJECT_VERSION}"
                 MACOSX_BUNDLE_SHORT_VERSION_STRING
                 "${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}"
                 MACOSX_BUNDLE_BUNDLE_VERSION "${PROJECT_VERSION}"
                 MACOSX_BUNDLE_COPYRIGHT "Copyright (c) OPENGIS.ch")
  endif()
endfunction()

if(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
  set(EXTRA_ARGS MACOSX_BUNDLE)
endif()

# Create the executable with the appropriate target name
create_executable(TARGET qfield EXTRA_ARGS ${EXTRA_ARGS})

# Update the install command to use the correct target name
if(ANDROID)
  install(
    TARGETS app
    BUNDLE DESTINATION ${QFIELD_BIN_DIR}
    RUNTIME DESTINATION ${QFIELD_BIN_DIR}
    LIBRARY DESTINATION ${QFIELD_LIB_DIR}
    ARCHIVE DESTINATION ${QFIELD_LIB_DIR}
    FRAMEWORK DESTINATION ${QFIELD_FW_SUBDIR}
    PUBLIC_HEADER DESTINATION ${QFIELD_INCLUDE_DIR})
else()
  install(
    TARGETS qfield
    BUNDLE DESTINATION ${QFIELD_BIN_DIR}
    RUNTIME DESTINATION ${QFIELD_BIN_DIR}
    LIBRARY DESTINATION ${QFIELD_LIB_DIR}
    ARCHIVE DESTINATION ${QFIELD_LIB_DIR}
    FRAMEWORK DESTINATION ${QFIELD_FW_SUBDIR}
    PUBLIC_HEADER DESTINATION ${QFIELD_INCLUDE_DIR})
endif()

if(WITH_SPIX)
  create_executable(TARGET qfield_spix)
  target_link_libraries(qfield_spix PRIVATE Spix::Spix)
  target_compile_definitions(qfield_spix PUBLIC WITH_SPIX)
endif()


if(IOS)
  # QFIELD_APP_ICON_SUFFIX should be set from command line to either _pr or
  # _beta

  include("${CMAKE_SOURCE_DIR}/cmake/AddQtIosApp.cmake")
  add_qt_ios_app(
    qfield
    NAME "QField"
    VERSION "${APK_VERSION_CODE}"
    SHORT_VERSION "${APK_VERSION_CODE}"
    LONG_VERSION "${APK_VERSION_CODE}"
    ASSET_DIR "${PROJECT_SOURCE_DIR}/platform/ios/Assets.xcassets"
    CATALOG_APPICON "AppIcon${QFIELD_APP_ICON_SUFFIX}"
    LAUNCHSCREEN_STORYBOARD
      "${PROJECT_SOURCE_DIR}/platform/ios/LaunchScreen.storyboard"
    RESOURCE_FILES "${SHARE_DIR}"
    CUSTOM_PLIST "${PROJECT_SOURCE_DIR}/platform/ios/Info.plist.in"
    BUNDLE_IDENTIFIER "${IOS_APP_IDENTIFIER}"
    ORIENTATION_PORTRAIT
    ORIENTATION_PORTRAIT_UPDOWN
    ORIENTATION_LANDSCAPE_LEFT
    ORIENTATION_LANDSCAPE_RIGHT
    REQUIRES_FULL_SCREEN
    HIDDEN_STATUS_BAR
    IPA
    UPLOAD_SYMBOL
    VERBOSE)
endif()
