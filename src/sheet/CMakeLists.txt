# Sheet: puter's table editor, for CSV and TSV files. Qt Widgets, so it takes
# the same style, palette and stylesheet as every other app.
cmake_minimum_required(VERSION 3.16)
project(sheet LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
find_package(Qt6 REQUIRED COMPONENTS Widgets)
set(CMAKE_AUTOMOC ON)
add_executable(puter-sheet main.cpp)
target_link_libraries(puter-sheet PRIVATE Qt6::Widgets)
install(TARGETS puter-sheet RUNTIME DESTINATION bin)
install(FILES puter-sheet.desktop DESTINATION share/applications)
