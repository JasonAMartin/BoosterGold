#!/bin/bash
for i in {1..420}
do
   echo "Running Skeets: $i"
   #ruby Skeets.rb downloadimages
   ruby Skeets.rb --command downloadimages --quantity 20
   sleep $((2 + RANDOM % 30))
done
