# Author Camille Leroux
# IMS Laboratory Bordeaux
# script de synthèse logique pour design_vision
################################################


################################################
# 1. INITIALIZATION
################################################


# execute a script containing standard cells library path and other things
source ./synopsys_dc.setup

# define the Vdd value for report generation
# NB: the real Vdd value is set by choosing the proper design library in the synopsys_dc.setup file
set VDD 3V3

# define the tol level name
set MON_TOP_LEVEL VGA

#define the architecture
set MON_ARCHI dataflow

# define the name of the clock port in the VHDL
set CLK_PORT CLK_I

# define the target frequency (MHz)
set FREQ_MHZ  50

# calculte the clock period (ns)
set CLK_PERIOD [expr 1000.0 / $FREQ_MHZ]

# define some timing constraints for the clock
set CLK_SKEW 0.0
set JITTER 0.0
set MARGIN 0.0
set CLK_UNCERTAINTY [expr $CLK_SKEW + $JITTER + $MARGIN]

# define the delay values to be applied on input and output ports (except the clock port)
set INPUT_DELAY [expr 0.1 * $CLK_PERIOD]
set OUTPUT_DELAY [expr 0.1 * $CLK_PERIOD]

################################################################################################
# 2. FIRST LOGIC SYNTHESIS : NO TECHNOLOGY MAPPING
################################################################################################

# "Compilation " of the VHDL description
analyze -f vhdl -autoread ../rtl/vhdl/

# first logic synthesis without technology mapping
elaborate $MON_TOP_LEVEL -arch $MON_ARCHI -lib WORK -update
uniquify

################################################################################################
# 3. APPLY TIMING CONSTRAINTS
################################################################################################

# define a clock (my_clock) with a period of $CLK_PERIOD and link it to our design clock port : $CLK_PORT
create_clock -name my_clock [get_ports $CLK_PORT] -period $CLK_PERIOD

# tell the tool not to optimize the clock tree. This will be done during Place and Route
set_dont_touch_network my_clock

set_wire_load_mode segmented

# Time budget

set_clock_uncertainty -hold $CLK_UNCERTAINTY $CLK_PORT
set_clock_uncertainty -setup $CLK_UNCERTAINTY $CLK_PORT

set_input_delay $INPUT_DELAY -clock my_clock [remove_from_collection [all_inputs] [get_ports $CLK_PORT]]
set_output_delay $OUTPUT_DELAY -clock my_clock [all_outputs]

# check the generated design
check_design

################################################################################################
# 4. SECOND LOGIC SYNTHESIS : TECHNOLOGY MAPPING + OPTIMIZATION
################################################################################################

# perform technology mapping + optimizations
# options may improve the performance of the circuit
compile


################################################################################################
# 5. EXPORT NETLIST, TIMING AND SYNTHESIS REPORTS
################################################################################################

# export timing annotations
write_sdf ./$MON_TOP_LEVEL\_syn.sdf

# export the synthesized netlist in verilog format :
write -hierarchy -format verilog -output ./$MON_TOP_LEVEL\_syn.v

# export constraints for PAR
write_sdc ./$MON_TOP_LEVEL\_syn.sdc

# reports generation
report_timing > ./report/$MON_ARCHI/$MON_TOP_LEVEL\_$FREQ_MHZ\MHz_$VDD.timing
report_area > ./report/$MON_ARCHI/$MON_TOP_LEVEL\_$FREQ_MHZ\MHz_$VDD.area
report_power > ./report/$MON_ARCHI/$MON_TOP_LEVEL\_$FREQ_MHZ\MHz_$VDD.power
report_clock > ./report/$MON_ARCHI/$MON_TOP_LEVEL\_$FREQ_MHZ\MHz_$VDD.clk
report_qor > ./report/$MON_ARCHI/$MON_TOP_LEVEL\_$FREQ_MHZ\MHz_$VDD.qor

