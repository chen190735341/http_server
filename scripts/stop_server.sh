#!/bin/sh

escript stop_server -name cowboy_stop -host 127.0.0.1 -stop_node cowboy_start@127.0.0.1 -hiden true -wait true