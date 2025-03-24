#!/bin/bash
engine=$1

path1="./config/${engine}/request"
_requests=$(ls $path1)


echo "|----------|---------------------| "
for _rq in ${_requests[*]}
do
#echo " ${_rq}  | " $(grep description $path1/${_rq}/param)
echo " ${_rq}  | " $(. $path1/${_rq}/param && echo $test_description )
done
