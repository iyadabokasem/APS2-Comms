# helper script to add necessary files to current project

set APS2_COMMS_SCRIPT_PATH [file normalize [info script]]
set APS2_COMMS_REPO_PATH [file dirname $APS2_COMMS_SCRIPT_PATH]/../

# Rebuild user ip_repo's index with our UserIP before adding any source files
set_property ip_repo_paths $APS2_COMMS_REPO_PATH/src/ip [current_project]
update_ip_catalog -rebuild

# create dependency outputs
set cur_dir [pwd]
cd $APS2_COMMS_REPO_PATH/deps
file mkdir build
exec python verilog-axis/rtl/axis_mux.py --ports=3 --output=build/axis_mux_3.v
exec python verilog-axis/rtl/axis_arb_mux.py --ports=3 --output=build/axis_arb_mux_3.v
exec python verilog-axis/rtl/axis_demux.py --ports=2 --output=build/axis_demux_2.v

# patch demux because select is keyword in VHDL
set fp [open build/axis_demux_2.v r]
set demux [read $fp]
close $fp
regsub -all {select} $demux control demux
set fp [open build/axis_demux_2.v w]
puts -nonewline $fp $demux
close $fp

# patch the Com5402 module for UDP broadcast issue and add DHCP module
cd $APS2_COMMS_REPO_PATH/deps/ComBlock/5402
file copy -force com5402.vhd com5402_dhcp.vhd
# on Windows look for Github git
if { $tcl_platform(platform) == "windows"} {
	set git_cmd [glob ~/AppData/Local/GitHub/PortableGit*/cmd/git.exe]
} else {
	set git_cmd git
}
# ignore whitespace warnings - seems a little dangerous
exec -ignorestderr $git_cmd apply --ignore-whitespace --directory=deps/ComBlock/5402 com5402_dhcp.patch
cd $cur_dir


# BBN source files
add_files -norecurse $APS2_COMMS_REPO_PATH/src

# dependecies
add_files -norecurse $APS2_COMMS_REPO_PATH/deps/VHDL-Components/src/Synchronizer.vhd

add_files -norecurse \
	$APS2_COMMS_REPO_PATH/deps/verilog-axis/rtl/axis_adapter.v \
	$APS2_COMMS_REPO_PATH/deps/verilog-axis/rtl/axis_srl_fifo.v \
	$APS2_COMMS_REPO_PATH/deps/verilog-axis/rtl/axis_async_fifo.v \
	$APS2_COMMS_REPO_PATH/deps/verilog-axis/rtl/axis_frame_fifo.v \
	$APS2_COMMS_REPO_PATH/deps/verilog-axis/rtl/axis_async_frame_fifo.v \
	$APS2_COMMS_REPO_PATH/deps/verilog-axis/rtl/arbiter.v \
	$APS2_COMMS_REPO_PATH/deps/verilog-axis/rtl/priority_encoder.v

add_files -norecurse \
	$APS2_COMMS_REPO_PATH/deps/build/axis_demux_2.v \
	$APS2_COMMS_REPO_PATH/deps/build/axis_mux_3.v \
	$APS2_COMMS_REPO_PATH/deps/build/axis_arb_mux_3.v

add_files -norecurse \
	$APS2_COMMS_REPO_PATH/deps/verilog-ethernet/rtl/eth_mac_1g_fifo.v \
	$APS2_COMMS_REPO_PATH/deps/verilog-ethernet/rtl/eth_mac_1g.v \
	$APS2_COMMS_REPO_PATH/deps/verilog-ethernet/rtl/eth_mac_1g_rx.v \
	$APS2_COMMS_REPO_PATH/deps/verilog-ethernet/rtl/eth_mac_1g_tx.v \
	$APS2_COMMS_REPO_PATH/deps/verilog-ethernet/rtl/lfsr.v

add_files -norecurse \
	$APS2_COMMS_REPO_PATH/deps/ComBlock/5402/arp_cache2.vhd \
	$APS2_COMMS_REPO_PATH/deps/ComBlock/5402/arp.vhd \
	$APS2_COMMS_REPO_PATH/deps/ComBlock/5402/bram_dp2.vhd \
	$APS2_COMMS_REPO_PATH/deps/ComBlock/5402/com5402_dhcp.vhd \
	$APS2_COMMS_REPO_PATH/deps/ComBlock/5402/com5402pkg.vhd \
	$APS2_COMMS_REPO_PATH/deps/ComBlock/5402/dhcp_client.vhd \
	$APS2_COMMS_REPO_PATH/deps/ComBlock/5402/igmp_query.vhd \
	$APS2_COMMS_REPO_PATH/deps/ComBlock/5402/igmp_report.vhd \
	$APS2_COMMS_REPO_PATH/deps/ComBlock/5402/packet_parsing.vhd \
	$APS2_COMMS_REPO_PATH/deps/ComBlock/5402/ping.vhd \
	$APS2_COMMS_REPO_PATH/deps/ComBlock/5402/tcp_rxbufndemux2.vhd \
	$APS2_COMMS_REPO_PATH/deps/ComBlock/5402/tcp_server.vhd \
	$APS2_COMMS_REPO_PATH/deps/ComBlock/5402/tcp_txbuf.vhd \
	$APS2_COMMS_REPO_PATH/deps/ComBlock/5402/tcp_tx.vhd \
	$APS2_COMMS_REPO_PATH/deps/ComBlock/5402/timer_4us.vhd \
	$APS2_COMMS_REPO_PATH/deps/ComBlock/5402/udp_rx.vhd \
	$APS2_COMMS_REPO_PATH/deps/ComBlock/5402/udp_tx.vhd \
	$APS2_COMMS_REPO_PATH/deps/ComBlock/5402/whois2.vhd

source $APS2_COMMS_REPO_PATH/src/bd/aps2_comms_bd.tcl
regenerate_bd_layout
validate_bd_design -quiet
save_bd_design
close_bd_design [get_bd_designs aps2_comms_bd]
generate_target all [get_files aps2_comms_bd.bd] -quiet
export_ip_user_files -of_objects [get_files aps2_comms_bd.bd] -no_script -force -quiet