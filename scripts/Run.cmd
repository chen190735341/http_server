ECHO on

cd /d %0/..

escript.exe run_server -name cowboy_start -host 127.0.0.1 -wait false -hiden false

pause
