if {[file isdirectory work]} {vdel -all -lib work}
vlib work
vmap work work

set TOP_ENTITY {work.hx711driver_test}

vlog -work work +cover=bcesfx ../rtl/hx711driver.sv
vlog -work work +cover=bcesfx ../rtl/hx711driver_test.sv

vsim -voptargs=+acc ${TOP_ENTITY} -coverage

quietly set StdArithNoWarnings 1
quietly set StdVitalGlitchNoWarnings 1

add wave -position insertpoint sim:/hx711driver_test/*

run -all

echo "==> Simulação finalizada."

