#!/bin/sh


olddir=`pwd`
current_dir=$(cd "$(dirname "${0}")"; pwd)
cd $current_dir
echo "enter ${current_dir}"

EBINDIR="../ebin"

chmod +x *.sh
chmod +x run_server
chmod +x erl_make

if [ ! -d "$EBINDIR" ]; then
        mkdir "$EBINDIR"
fi

echo 
if [ $1 ]
	then
		echo "cp Emakefile.win Emakefile"
		cp Emakefile.win Emakefile
	else
		echo "cp Emakefile.linux Emakefile"
		cp Emakefile.linux Emakefile
fi

echo "escript erl_make"
escript erl_make


cd ../../



if [ -f "$EBIN_DIR/erl_crash.dump" ]; then
   rm -rf "$EBIN_DIR/erl_crash.dump"
fi

if [ -f "$current_dir/erl_crash.dump" ]; then
   rm -rf "$current_dir/erl_crash.dump"
fi

cd $olddir
echo 
echo "leave ${current_dir}"
