cmake_minimum_required(VERSION 3.10)

project(advent-of-code-2024 C)

add_compile_options(-Wall -g)

# Include util directory for all targets
include_directories(util)
file(GLOB_RECURSE UTIL_FILES util/*.c)

# Function to add executables for each solution file in a given day directory
function(add_day_solutions day_dir)
    file(GLOB_RECURSE SOLUTION_FILES "${day_dir}/solution*.c")
    foreach(SOLUTION_FILE ${SOLUTION_FILES})
        get_filename_component(SOLUTION_NAME ${SOLUTION_FILE} NAME_WE)
        get_filename_component(DAY_NAME ${day_dir} NAME)
        add_executable(${SOLUTION_NAME} ${SOLUTION_FILE} ${UTIL_FILES})
        target_include_directories(${SOLUTION_NAME} PRIVATE util ${day_dir})
        set_target_properties(${SOLUTION_NAME} PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${DAY_NAME}")
    endforeach()
endfunction()

# Add all day directories
file(GLOB DAY_DIRECTORIES day*)

foreach(DAY_DIR ${DAY_DIRECTORIES})
    if(IS_DIRECTORY ${DAY_DIR})
        add_day_solutions(${DAY_DIR})
    endif()
endforeach()

# Option to build a single day or single solution
option(DAY "Specify a day directory to build" "")
option(SOLUTION "Specify a specific solution file to build" "")

if(DAY)
    if(IS_DIRECTORY ${DAY})
        add_day_solutions(${DAY})
    else()
        message(FATAL_ERROR "Specified day directory does not exist: ${DAY}")
    endif()
endif()

if(SOLUTION)
    if(EXISTS ${SOLUTION})
        get_filename_component(SOLUTION_NAME ${SOLUTION} NAME_WE)
        get_filename_component(SOLUTION_DIR ${SOLUTION} DIRECTORY)
        add_executable(${SOLUTION_NAME} ${SOLUTION})
        target_include_directories(${SOLUTION_NAME} PRIVATE util ${SOLUTION_DIR})
    else()
        message(FATAL_ERROR "Specified solution file does not exist: ${SOLUTION}")
    endif()
endif()
