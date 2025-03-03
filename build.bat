::
:: clean build directory
call ant clean

:: get additional stuff for exist-db
call ant build-plus

:: build xar
call ant xar