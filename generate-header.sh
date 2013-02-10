#! /usr/bin/env bash

cpp <<- eof | grep ^[^#] > file-header.h
	#include <time.h>
	#include <sys/types.h>
	#include <sys/stat.h>
	#include <dirent.h>
eof

