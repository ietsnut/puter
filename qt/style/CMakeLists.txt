# puter's Qt widget style: Fusion, with every bar, row, button and field one
# 30px module. Selected in qt6ct as "puter"; the colours and lines come from
# the stylesheet (theme/qt/puter.qss).
cmake_minimum_required(VERSION 3.16)
project(puter-style LANGUAGES CXX)
find_package(Qt6 REQUIRED COMPONENTS Widgets)
set(CMAKE_AUTOMOC ON)
add_library(puterstyle MODULE puterstyle.cpp)
target_link_libraries(puterstyle PRIVATE Qt6::Widgets)
install(TARGETS puterstyle LIBRARY DESTINATION lib/qt6/plugins/styles)
