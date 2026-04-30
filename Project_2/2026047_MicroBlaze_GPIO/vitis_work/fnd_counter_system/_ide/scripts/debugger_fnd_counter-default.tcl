# Usage with Vitis IDE:
# In Vitis IDE create a Single Application Debug launch configuration,
# change the debug type to 'Attach to running target' and provide this 
# tcl script in 'Execute Script' option.
# Path of this script: D:\UVM\Project_2\2026047_MicroBlaze_GPIO\vitis_work\fnd_counter_system\_ide\scripts\debugger_fnd_counter-default.tcl
# 
# 
# Usage with xsct:
# To debug using xsct, launch xsct and run below command
# source D:\UVM\Project_2\2026047_MicroBlaze_GPIO\vitis_work\fnd_counter_system\_ide\scripts\debugger_fnd_counter-default.tcl
# 
connect -url tcp:127.0.0.1:3121
targets -set -filter {jtag_cable_name =~ "Digilent Basys3 210183BB7F45A" && level==0 && jtag_device_ctx=="jsn-Basys3-210183BB7F45A-0362d093-0"}
fpga -file D:/UVM/Project_2/2026047_MicroBlaze_GPIO/vitis_work/fnd_counter/_ide/bitstream/design_1_wrapper.bit
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
loadhw -hw D:/UVM/Project_2/2026047_MicroBlaze_GPIO/vitis_work/design_1_wrapper/export/design_1_wrapper/hw/design_1_wrapper.xsa -regs
configparams mdm-detect-bscan-mask 2
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
rst -system
after 3000
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
dow D:/UVM/Project_2/2026047_MicroBlaze_GPIO/vitis_work/fnd_counter/Debug/fnd_counter.elf
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
con
