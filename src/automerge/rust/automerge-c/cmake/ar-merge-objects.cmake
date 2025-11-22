# CMake script to merge object files into an archive
# This script handles Windows ar.exe limitations:
# 1. No wildcard expansion
# 2. Command line length limits (8191 chars on Windows)

file(GLOB OBJECT_FILES "${BINDINGS_OBJECTS_DIR}/*.o")
if(NOT OBJECT_FILES)
    message(FATAL_ERROR "No object files found in ${BINDINGS_OBJECTS_DIR}")
endif()

# Use MRI script to avoid command line length limits
# MRI (Machine Readable Interface) is supported by GNU ar
set(MRI_SCRIPT "${PROJECT_BINARY_DIR}/ar-merge.mri")
file(WRITE ${MRI_SCRIPT} "CREATE ${LIBRARY_NAME}\n")
foreach(OBJ_FILE ${OBJECT_FILES})
    file(APPEND ${MRI_SCRIPT} "ADDMOD ${OBJ_FILE}\n")
endforeach()
file(APPEND ${MRI_SCRIPT} "SAVE\nEND\n")

execute_process(
    COMMAND ${CMAKE_AR} -M
    INPUT_FILE ${MRI_SCRIPT}
    WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
    RESULT_VARIABLE AR_RESULT
    ERROR_VARIABLE AR_ERROR
    OUTPUT_VARIABLE AR_OUTPUT
)

if(NOT AR_RESULT EQUAL 0)
    message(FATAL_ERROR "ar command failed with code ${AR_RESULT}\nError: ${AR_ERROR}\nOutput: ${AR_OUTPUT}")
endif()

file(REMOVE ${MRI_SCRIPT})
