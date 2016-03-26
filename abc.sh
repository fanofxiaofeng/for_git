#!/bin/bash


for ((i = 1;i <= 12;i++));
do
	temp=`printf "%4d-%02d-%02d\n" 2015 $i 01`
	echo $temp
done
