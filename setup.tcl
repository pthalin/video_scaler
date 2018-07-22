cd [file dirname [file normalize [info script]]]
close_project -quiet
file delete -force impl
create_project -force scaler ./impl -part xc7a35tftg256-1
add_files [glob src/*.v*]
add_files [glob ip/*/*.xci]
add_files -fileset constrs_1 ./constr/artix7_board.xdc
