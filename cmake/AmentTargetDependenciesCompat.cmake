# ament_cmake no longer provides ament_target_dependencies() at all (it isn't just deprecated or
# hidden behind an opt-in find_package() the way it was in earlier ROS 2 distros - the macro has
# been removed from the ament_cmake source outright). This defines a compatible replacement so
# the existing ament_target_dependencies() calls in this project keep working: it mirrors the
# original macro's behaviour of resolving each dependency's modern CMake target (<pkg>_TARGETS)
# where available, falling back to the legacy INCLUDE_DIRS/LIBRARIES/DEFINITIONS variables
# otherwise, and it honours an optional leading PUBLIC/PRIVATE/INTERFACE visibility keyword
# (defaulting to PUBLIC, matching the original) so it stays compatible with targets that already
# use the keyword signature of target_link_libraries() elsewhere - CMake does not allow mixing
# the keyword and plain signatures for the same target across separate calls.
if(NOT COMMAND ament_target_dependencies)
  macro(ament_target_dependencies target)
    set(_atd_args ${ARGN})
    set(_atd_visibility PUBLIC)
    list(LENGTH _atd_args _atd_len)
    if(_atd_len GREATER 0)
      list(GET _atd_args 0 _atd_first)
      if(_atd_first STREQUAL "PUBLIC" OR _atd_first STREQUAL "PRIVATE" OR _atd_first STREQUAL "INTERFACE")
        set(_atd_visibility ${_atd_first})
        list(REMOVE_AT _atd_args 0)
      endif()
    endif()
    foreach(_atd_dep ${_atd_args})
      if(DEFINED ${_atd_dep}_TARGETS)
        target_link_libraries(${target} ${_atd_visibility} ${${_atd_dep}_TARGETS})
      else()
        if(DEFINED ${_atd_dep}_INCLUDE_DIRS)
          target_include_directories(${target} ${_atd_visibility} ${${_atd_dep}_INCLUDE_DIRS})
        endif()
        if(DEFINED ${_atd_dep}_LIBRARIES)
          target_link_libraries(${target} ${_atd_visibility} ${${_atd_dep}_LIBRARIES})
        endif()
        if(DEFINED ${_atd_dep}_DEFINITIONS)
          target_compile_definitions(${target} ${_atd_visibility} ${${_atd_dep}_DEFINITIONS})
        endif()
      endif()
    endforeach()
  endmacro()
endif()
