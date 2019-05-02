#!/bin/bash
for i in {1..2000}
do
   echo "Running Skeets: $i"
   ruby Skeets.rb downloadimages
   sleep $((2 + RANDOM % 10)) 
done
