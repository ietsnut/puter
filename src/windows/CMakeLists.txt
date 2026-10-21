cmake_minimum_required(VERSION 3.16)
project(puter-windows C)

find_package(PkgConfig REQUIRED)
pkg_check_modules(WAYLAND REQUIRED wayland-client)
pkg_get_variable(PROTOCOLS wayland-protocols pkgdatadir)
find_program(SCANNER wayland-scanner REQUIRED)

set(XML ${PROTOCOLS}/staging/ext-foreign-toplevel-list/ext-foreign-toplevel-list-v1.xml)
set(HEADER ${CMAKE_CURRENT_BINARY_DIR}/ext-foreign-toplevel-list-v1-client-protocol.h)
set(CODE ${CMAKE_CURRENT_BINARY_DIR}/ext-foreign-toplevel-list-v1-protocol.c)
add_custom_command(OUTPUT ${HEADER} COMMAND ${SCANNER} client-header ${XML} ${HEADER} DEPENDS ${XML})
add_custom_command(OUTPUT ${CODE} COMMAND ${SCANNER} private-code ${XML} ${CODE} DEPENDS ${XML})

add_executable(puter-windows main.c ${HEADER} ${CODE})
target_include_directories(puter-windows PRIVATE ${CMAKE_CURRENT_BINARY_DIR} ${WAYLAND_INCLUDE_DIRS})
target_link_libraries(puter-windows PRIVATE ${WAYLAND_LIBRARIES})
install(TARGETS puter-windows DESTINATION bin)
