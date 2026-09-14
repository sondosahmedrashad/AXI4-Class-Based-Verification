quit -sim

# ============================================================
# Clean and recreate work library
# ============================================================
if {[file exists work]} {
    vdel -all
}

vlib work
vmap work work


# ============================================================
# Compile DUT with CODE COVERAGE enabled
# b = branch
# c = condition
# e = expression
# s = statement
# f = FSM
# t = toggle
# ============================================================

vlog -sv +cover=bcesft axi_memory.v
vlog -sv +cover=bcesft axi4.v


# ============================================================
# Compile verification files
# ============================================================

vlog -sv axi_interface.sv
vlog -sv axi_package.sv

# Assertion source
vlog -sv axi_assertions.sv

# Top-level testbench
vlog -sv axi_tb_top.sv


# ============================================================
# Start simulation
#
# -coverage    : enable coverage collection
# -assertdebug : enable assertion debug/coverage information
# +acc         : preserve signal visibility
# ============================================================

vsim -voptargs="+acc" \
     -coverage \
     -assertdebug \
     work.axi_tb_top


# ============================================================
# Waveform
# ============================================================

add wave -radix hex sim:/axi_tb_top/ACLK
add wave -radix hex sim:/axi_tb_top/ARESETn
add wave -radix hex sim:/axi_tb_top/intf/*
add wave -radix hex sim:/axi_tb_top/DUT/*


# ============================================================
# Save coverage database when simulation ends
# ============================================================

coverage save axi_tb_top.ucdb -onexit


# ============================================================
# Run complete test
# ============================================================

run -all


# ============================================================
# Coverage reports
# ============================================================

# Complete report
coverage report -details \
    -file coverage_report.txt

# Functional coverage
coverage report -cvg \
    -details \
    -file functional_coverage.txt

# Code coverage
coverage report -codeAll \
    -details \
    -file code_coverage.txt

# Assertion coverage
coverage report -assert \
    -details \
    -file assertion_coverage.txt


# ============================================================
# Save final UCDB explicitly
# ============================================================

coverage save axi_tb_top.ucdb


# ============================================================
# Finish simulation
# ============================================================



# ============================================================
# Generate a complete report from saved UCDB
# ============================================================

vcover report axi_tb_top.ucdb \
    -details \
    -output all_coverage.txt
