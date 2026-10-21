# Calculator: puter's calculator, on libqalculate. Qt Widgets, so it takes
# the same style, palette and stylesheet as every other app.
cmake_minimum_required(VERSION 3.16)
project(calc LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
find_package(Qt6 REQUIRED COMPONENTS Widgets)
find_package(PkgConfig REQUIRED)
pkg_check_modules(QALCULATE REQUIRED IMPORTED_TARGET libqalculate)
set(CMAKE_AUTOMOC ON)
add_executable(puter-calc main.cpp)
target_link_libraries(puter-calc PRIVATE Qt6::Widgets PkgConfig::QALCULATE)
install(TARGETS puter-calc RUNTIME DESTINATION bin)
install(FILES puter-calc.desktop DESTINATION share/applications)
