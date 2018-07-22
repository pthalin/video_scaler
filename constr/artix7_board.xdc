########################################
#  Constraints
########################################
##Clock Signal
#Sch=sysclk
set_property -dict { PACKAGE_PIN N11    IOSTANDARD LVCMOS33 } [get_ports { clk50 }];  
    create_clock -add -name sys_clk_pin -period 20.00 -waveform {0 10} [get_ports clk50];

##HDMI out
set_property -dict { PACKAGE_PIN N16    IOSTANDARD TMDS_33  } [get_ports { hdmi_tx_n[0] }];
set_property -dict { PACKAGE_PIN M16    IOSTANDARD TMDS_33  } [get_ports { hdmi_tx_p[0] }];
set_property -dict { PACKAGE_PIN P16   IOSTANDARD TMDS_33  } [get_ports { hdmi_tx_n[1] }];
set_property -dict { PACKAGE_PIN P15   IOSTANDARD TMDS_33  } [get_ports { hdmi_tx_p[1] }];
set_property -dict { PACKAGE_PIN R16   IOSTANDARD TMDS_33  } [get_ports { hdmi_tx_n[2] }];
set_property -dict { PACKAGE_PIN R15   IOSTANDARD TMDS_33  } [get_ports { hdmi_tx_p[2] }];
set_property -dict { PACKAGE_PIN T15    IOSTANDARD TMDS_33  } [get_ports { hdmi_tx_clk_n }];
set_property -dict { PACKAGE_PIN T14    IOSTANDARD TMDS_33  } [get_ports { hdmi_tx_clk_p }];

#5150 video
set_property -dict { PACKAGE_PIN R7   IOSTANDARD LVCMOS33 } [get_ports { video5150[0] }];
set_property -dict { PACKAGE_PIN R6   IOSTANDARD LVCMOS33 } [get_ports { video5150[1] }];
set_property -dict { PACKAGE_PIN T5   IOSTANDARD LVCMOS33 } [get_ports { video5150[2] }];
set_property -dict { PACKAGE_PIN R5   IOSTANDARD LVCMOS33 } [get_ports { video5150[3] }];
set_property -dict { PACKAGE_PIN T10  IOSTANDARD LVCMOS33 } [get_ports { video5150[4] }];
set_property -dict { PACKAGE_PIN T9   IOSTANDARD LVCMOS33 } [get_ports { video5150[5] }];
set_property -dict { PACKAGE_PIN T8   IOSTANDARD LVCMOS33 } [get_ports { video5150[6] }];
set_property -dict { PACKAGE_PIN T7   IOSTANDARD LVCMOS33 } [get_ports { video5150[7] }];
#5150 sync
set_property -dict { PACKAGE_PIN N12   IOSTANDARD LVCMOS33 } [get_ports { clk27_5150 }];
 create_clock -add -name sys_clk_5150 -period 37.04 -waveform {0 18} [get_ports clk27_5150];

set_property -dict { PACKAGE_PIN P10   IOSTANDARD LVCMOS33 } [get_ports { AVID5150 }];
set_property -dict { PACKAGE_PIN P11   IOSTANDARD LVCMOS33 } [get_ports { VSYNC5150 }];
set_property -dict { PACKAGE_PIN R12   IOSTANDARD LVCMOS33 } [get_ports { FID5150 }];
set_property -dict { PACKAGE_PIN T13   IOSTANDARD LVCMOS33 } [get_ports { VBLK5150 }];
#5150 i2c control
set_property -dict { PACKAGE_PIN T12   IOSTANDARD LVCMOS33 } [get_ports { SDA5150 }];
set_property -dict { PACKAGE_PIN R13   IOSTANDARD LVCMOS33 } [get_ports { SCL5150 }];
set_property -dict { PACKAGE_PIN K13   IOSTANDARD LVCMOS33 } [get_ports { reset5150 }];

#mode switches
set_property -dict { PACKAGE_PIN M1   IOSTANDARD LVCMOS33 } [get_ports { mode_a }];
set_property -dict { PACKAGE_PIN M2   IOSTANDARD LVCMOS33 } [get_ports { mode_b }];



#[Place 30-876] Port 'clk27_5150'  is assigned to PACKAGE_PIN 'N12'  which can only be used as the N side of a differential clock input.
#Please use the following constraint(s) to pass this DRC check:
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets {clk27_5150_IBUF}];

#False paths
set_clock_groups -physically_exclusive -group [get_clocks -include_generated_clocks clk_out1_clk_wiz_0_2] -group [get_clocks -include_generated_clocks clk_out1_gen_pal_74_25_1]
set_false_path -through [get_pins -hierarchical *master_serdes/RST]
set_false_path -through [get_pins -hierarchical *slave_serdes/RST]