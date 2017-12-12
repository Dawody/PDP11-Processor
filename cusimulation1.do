vsim -gui work.cu
add wave -position insertpoint  \
sim:/cu/CONTROL_CLK \
sim:/cu/PROCESSING_CLK \
sim:/cu/ENABLE_MAIN_COUNTER \
sim:/cu/ENABLE_INSTRUCTION_COUNTER \
sim:/cu/NEW_INSTRUCTION \
sim:/cu/IR \
sim:/cu/MODE \
sim:/cu/MAIN_COUNTER_OUTPUT \
sim:/cu/MAIN_COUNTER_INCREMENT \
sim:/cu/INSTRUCTION_COUNTER_OUTPUT \
sim:/cu/INITIAL_ADDRESS \
sim:/cu/INSTRUCTION_FETCHING_BLOCK_OUTPUT \
sim:/cu/SRC_FETCHING_BLOCK_OUTPUT \
sim:/cu/DEST_FETCHING_BLOCK_OUTPUT \
sim:/cu/EXECUTE_BLOCK_OUTPUT \
sim:/cu/EXECUTE_BRANCH_BLOCK_OUTPUT \
sim:/cu/INSTRUCTION_FETCHING_BLOCK_INITIAL_ADDRESS_OUTPUT \
sim:/cu/SRC_FETCHING_BLOCK_INITIAL_ADDRESS_OUTPUT \
sim:/cu/DEST_FETCHING_BLOCK_INITIAL_ADDRESS_OUTPUT \
sim:/cu/EXECUTE_BLOCK_INITIAL_ADDRESS_OUTPUT \
sim:/cu/EXECUTE_BRANCH_BLOCK_INITIAL_ADDRESS_OUTPUT \
sim:/cu/FLAG_REGISTER \
sim:/cu/ROM_BLOCKS_OUTPUT 

force -freeze sim:/cu/IR 0001 0
force -freeze sim:/cu/FLAG_REGISTER 0 0
run 100
run 50
force -freeze sim:/cu/IR 81ff 0
run 50
run 100