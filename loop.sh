#!/bin/bash
for i in {1..45}
do
   echo "Running Skeets: $i"
   #ruby Skeets.rb downloadimages
   ruby Skeets.rb --command updateimages --quantity 10
   sleep $((2 + RANDOM % 10))
done
