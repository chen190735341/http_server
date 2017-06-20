ECHO on

cd /d %0/..

:del ..\ebin\*.beam

copy Emakefile.win Emakefile

escript.exe erl_make

pause 
