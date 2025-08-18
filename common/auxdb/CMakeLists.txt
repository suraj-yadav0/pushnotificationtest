cmake_minimum_required(VERSION 3.16)

# AuxDB library for database and postal client functionality
find_package(Qt5Core REQUIRED)
find_package(Qt5Sql REQUIRED)
find_package(Qt5DBus REQUIRED)

set(AUXDB_SOURCES
    postal-client.cpp
    auxdatabase.cpp
    avatarmaptable.cpp
)

set(AUXDB_HEADERS
    postal-client.h
    auxdatabase.h
    avatarmaptable.h
)

add_library(auxdb STATIC ${AUXDB_SOURCES} ${AUXDB_HEADERS})

target_link_libraries(auxdb 
    Qt5::Core 
    Qt5::Sql 
    Qt5::DBus
)

target_include_directories(auxdb PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
