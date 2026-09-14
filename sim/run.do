quit -sim

# ============================================================
# Project paths
# ============================================================

# Locate repository root automatically
set SCRIPT_DIR   [file dirname [file normalize [info script]]]
set PROJECT_ROOT [file normalize [file join $SCRIPT_DIR ..]]

cd $PROJECT_ROOT


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

vlog -sv +cover=bcesft rtl/axi_memory.v
vlog -sv +cover=bcesft rtl/axi4.v


# ============================================================
# Compile verification files
# ============================================================

vlog -sv +incdir+tb tb/axi_interface.sv
vlog -sv +incdir+tb tb/axi_package.sv

# Assertion source
vlog -sv +incdir+tb tb/axi_assertions.sv

# Top-level testbench
vlog -sv +incdir+tb tb/axi_tb_top.sv


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

coverage save sim/axi_tb_top.ucdb -onexit


# ============================================================
# Run complete test
# ============================================================

run -all


# ============================================================
# Coverage reports
# ============================================================

# Complete report
coverage report -details \
    -file sim/coverage_report.txt

# Functional coverage
coverage report -cvg \
    -details \
    -file sim/functional_coverage.txt

# Code coverage
coverage report -codeAll \
    -details \
    -file sim/code_coverage.txt

# Assertion coverage
coverage report -assert \
    -details \
    -file sim/assertion_coverage.txt


# ============================================================
# Save final UCDB explicitly
# ============================================================

coverage save sim/axi_tb_top.ucdb


# ============================================================
# Generate a complete report from saved UCDB
# ============================================================

vcover report sim/axi_tb_top.ucdb \
    -details \
    -output sim/all_coverage.txt
