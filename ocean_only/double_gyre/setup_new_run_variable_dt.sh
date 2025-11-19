#!/bin/bash

set -eu

scaling_factor=${1}
depths=${2}

grid_size=$(( 32 * ${scaling_factor} ))
dt=$(echo "scale=3; 1200.0 / ${scaling_factor}" | bc)
dmax=$(echo "scale=3; 10.0 / ${scaling_factor}" | bc)

echo "For scaling factor ${scaling_factor}: "
echo -e "\tNew GRID_size: ${grid_size}"
echo -e "\tNew DT: ${dt}"
echo -e "\tNew DAYMAX: ${dmax}"

# Replace vars in MOM Input
sed -i -e "s/GLOBAL = 44/GLOBAL = ${grid_size}/g" -e "s/GLOBAL = 40/GLOBAL = ${grid_size}/g" -e "s/NK = 2/NK = ${depths}/g" -e "s/DT = 1200.0/DT = ${dt}/g" -e "s/DAYMAX = 10.0/DAYMAX = ${dmax}/g" MOM_input
