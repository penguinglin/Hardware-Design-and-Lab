vlib modelsim_lib/work
vlib modelsim_lib/msim

vlib modelsim_lib/msim/xil_defaultlib

vmap xil_defaultlib modelsim_lib/msim/xil_defaultlib

vlog -work xil_defaultlib -64 -incr \
"../../../../Adv3.srcs/sources_1/ip/KeyboardCtrl_0_1/src/Ps2Interface.v" \
"../../../../Adv3.srcs/sources_1/ip/KeyboardCtrl_0_1/src/KeyboardCtrl.v" \
"../../../../Adv3.srcs/sources_1/ip/KeyboardCtrl_0_1/sim/KeyboardCtrl_0.v" \


vlog -work xil_defaultlib \
"glbl.v"

