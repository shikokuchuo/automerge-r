# CMake script to merge object files into an archive
# This script handles both GNU ar (with MRI script support) and BSD ar

file(GLOB OBJECT_FILES "${BINDINGS_OBJECTS_DIR}/*.o")
if(NOT OBJECT_FILES)
    message(FATAL_ERROR "No object files found in ${BINDINGS_OBJECTS_DIR}")
endif()

# Test if ar supports MRI mode (GNU ar)
execute_process(
    COMMAND ${CMAKE_AR} -M
    INPUT_FILE /dev/null
    RESULT_VARIABLE AR_MRI_TEST
    ERROR_QUIET
    OUTPUT_QUIET
)

if(AR_MRI_TEST EQUAL 0)
    # GNU ar with MRI support
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

    file(REMOVE ${MRI_SCRIPT})
else()
    # BSD ar (macOS) - use traditional commands
    execute_process(
        COMMAND ${CMAKE_AR} -r -s ${LIBRARY_NAME} ${OBJECT_FILES}
        WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
        RESULT_VARIABLE AR_RESULT
        ERROR_VARIABLE AR_ERROR
        OUTPUT_VARIABLE AR_OUTPUT
    )
endif()

if(NOT AR_RESULT EQUAL 0)
    message(FATAL_ERROR "ar command failed with code ${AR_RESULT}\nError: ${AR_ERROR}\nOutput: ${AR_OUTPUT}")
endif()
