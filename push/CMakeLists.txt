cmake_minimum_required(VERSION 3.16)

# Push helper executable
find_package(Qt5Core REQUIRED)
find_package(Qt5Gui REQUIRED)
find_package(Qt5Sql REQUIRED)
find_package(Qt5DBus REQUIRED)
find_package(Qt5Widgets REQUIRED)

set(PUSH_SOURCES
    push.cpp
    pushhelper.cpp
)

set(PUSH_HEADERS
    pushhelper.h
    i18n.h
)

add_executable(push ${PUSH_SOURCES} ${PUSH_HEADERS})

target_link_libraries(push 
    Qt5::Core 
    Qt5::Widgets 
    Qt5::DBus 
    Qt5::Sql 
    Qt5::Gui
    auxdb
)

# Install push helper files
install(FILES push-apparmor.json DESTINATION push)
install(FILES push-helper.json DESTINATION push)
install(PROGRAMS ${CMAKE_CURRENT_BINARY_DIR}/push DESTINATION push)
