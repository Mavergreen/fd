cmake_minimum_required(VERSION 3.16)
set(CMAKE_OSX_DEPLOYMENT_TARGET 10.9 CACHE STRING "")
set(CMAKE_OSX_ARCHITECTURES x86_64 CACHE STRING "")
project(FdUpdater LANGUAGES OBJC)
find_package(MavericksShipyard REQUIRED)
include(Mavericks)
include(MavericksSparkle)
mavericks_resolve_version(FD_VERSION)
# spec: updater/ICON-CREDIT.txt -- the generic icon on purpose, with the reason and the exit
mavericks_add_updater_app(
  PRODUCT fd
  PRODUCT_NAME "Mavericks fd"
  VERSION "${FD_VERSION}"
  LOG_PREFIX "MavFdUpdater"
  CONFIRM_TITLE "Mavericks fd updated"
  CONFIRM_BODY "fd for Mavericks in /usr/local/mavergreen/fd was updated."
  ALLOW_GENERIC
)
