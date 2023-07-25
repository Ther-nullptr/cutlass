#!/bin/bash

# Define the range of values for 'target_iter' and 'num_stage'
target_iter_values=(1 2 3 4)
num_stage_values=(5 6 7 8)

mma_file_locate="main.cpp"
test_file_locate="test.cpp"

binary_name="build/main"
binary_dir="build"

# Loop over 'target_iter' values
for target_iter in "${target_iter_values[@]}"; do
    # Loop over 'num_stage' values
    for num_stage in "${num_stage_values[@]}"; do
        # Use 'sed' to locate the 'constexpr' lines and replace their values
        sed -i "s/constexpr int target_iter = [0-9]\+;/constexpr int target_iter = $target_iter;/" $mma_file_locate
        sed -i "s/constexpr int NumStages   = [0-9]\+;/constexpr int NumStages   = $num_stage;/" $test_file_locate

        # Compile the modified files
        g++ $mma_file_locate -o $binary_name

        # Run the program with the current values
        echo "Running with target_iter = $target_iter, NumStages = $num_stage"
        $binary_name > tmp.txt
        awk '/^time:/{sum+=$2; count++} END{print "Average time:", sum/count}' tmp.txt
    done
done
