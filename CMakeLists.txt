cmake_minimum_required(VERSION 3.16)
project(FdUpdater LANGUAGES NONE)
find_package(MavericksShipyard REQUIRED)
mavericks_resolve_version(FD_VERSION)
