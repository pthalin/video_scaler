
########################################
#  Constraints
########################################

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
#POSSIBLE RATES: 3 6 9 12 16 22 26 33 40 50 66
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property CONFIG_MODE SPIx4 [current_design]

##Clock Signal
#Sch=sysclk
set_property -dict {PACKAGE_PIN N11 IOSTANDARD LVCMOS33} [get_ports clk50]
create_clock -period 20.000 -name sys_clk_pin -waveform {0.000 10.000} -add [get_ports clk50]

##HDMI out
set_property -dict {PACKAGE_PIN C2 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_n[0]}]
set_property -dict {PACKAGE_PIN C3 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_p[0]}]
set_property -dict {PACKAGE_PIN A2 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_n[1]}]
set_property -dict {PACKAGE_PIN B2 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_p[1]}]
set_property -dict {PACKAGE_PIN B1 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_n[2]}]
set_property -dict {PACKAGE_PIN C1 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_p[2]}]
set_property -dict {PACKAGE_PIN D1 IOSTANDARD TMDS_33} [get_ports hdmi_tx_clk_n]
set_property -dict {PACKAGE_PIN E2 IOSTANDARD TMDS_33} [get_ports hdmi_tx_clk_p]
#5150 video
set_property -dict {PACKAGE_PIN A5 IOSTANDARD LVCMOS33} [get_ports {video5150[0]}]
set_property -dict {PACKAGE_PIN A4 IOSTANDARD LVCMOS33} [get_ports {video5150[1]}]
set_property -dict {PACKAGE_PIN D6 IOSTANDARD LVCMOS33} [get_ports {video5150[2]}]
set_property -dict {PACKAGE_PIN D5 IOSTANDARD LVCMOS33} [get_ports {video5150[3]}]
set_property -dict {PACKAGE_PIN C7 IOSTANDARD LVCMOS33} [get_ports {video5150[4]}]
set_property -dict {PACKAGE_PIN C6 IOSTANDARD LVCMOS33} [get_ports {video5150[5]}]
set_property -dict {PACKAGE_PIN G5 IOSTANDARD LVCMOS33} [get_ports {video5150[6]}]
set_property -dict {PACKAGE_PIN G4 IOSTANDARD LVCMOS33} [get_ports {video5150[7]}]
#5150 sync
set_property -dict {PACKAGE_PIN J4 IOSTANDARD LVCMOS33} [get_ports clk27_5150]
create_clock -period 37.040 -name sys_clk_5150 -waveform {0.000 18.000} -add [get_ports clk27_5150]

#MODULE PIN: ID
set_property -dict {PACKAGE_PIN N2 IOSTANDARD LVCMOS33} [get_ports AVID5150]

#MODULE PIN: VS
set_property -dict {PACKAGE_PIN K5 IOSTANDARD LVCMOS33} [get_ports VSYNC5150]

#MODULE PIN: FID
set_property -dict {PACKAGE_PIN B4 IOSTANDARD LVCMOS33} [get_ports FID5150]

#MODULE PIN: INT
set_property -dict {PACKAGE_PIN N3 IOSTANDARD LVCMOS33} [get_ports VBLK5150]

#5150 i2c control
set_property -dict {PACKAGE_PIN B6 IOSTANDARD LVCMOS33} [get_ports SDA5150]
set_property -dict {PACKAGE_PIN B5 IOSTANDARD LVCMOS33} [get_ports SCL5150]
set_property -dict {PACKAGE_PIN M4 IOSTANDARD LVCMOS33} [get_ports reset5150]

#mode switches
set_property -dict {PACKAGE_PIN A8 IOSTANDARD LVCMOS33} [get_ports mode_a]
#set_property -dict {PACKAGE_PIN K2 IOSTANDARD LVCMOS33} [get_ports mode_b]

#LED
set_property -dict {PACKAGE_PIN C8 IOSTANDARD LVCMOS33} [get_ports led]



#[Place 30-876] Port 'clk27_5150'  is assigned to PACKAGE_PIN 'N12'  which can only be used as the N side of a differential clock input.
#Please use the following constraint(s) to pass this DRC check:
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets clk27_5150_IBUF]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets AVID5150_IBUF]

#False paths
set_clock_groups -physically_exclusive -group [get_clocks -include_generated_clocks -of_objects [get_nets clk74_25]] -group [get_clocks -include_generated_clocks -of_objects [get_nets clk74_17]]
set_false_path -through [get_pins -hierarchical *master_serdes/RST]
set_false_path -through [get_pins -hierarchical *slave_serdes/RST]


