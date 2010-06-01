# SimVision Command Script

#
# Groups
#
if {[catch {group new -name {System Signals} -overlay 0}] != ""} {
    group using {System Signals}
    group set -overlay 0
    group set -comment {}
    group clear 0 end
}
group insert \
    :testbench.reset \
    :testbench.gtx_clk \
    :testbench.host_clk

if {[catch {group new -name {TX Client Interface} -overlay 0}] != ""} {
    group using {TX Client Interface}
    group set -overlay 0
    group set -comment {}
    group clear 0 end
}
group insert \
    :testbench.dut.tx_clk \
    :testbench.dut.\\v6_emac_v1_3_locallink_inst/tx_data_i \
    :testbench.dut.\\v6_emac_v1_3_locallink_inst/tx_data_valid_i \
    :testbench.dut.\\v6_emac_v1_3_locallink_inst/tx_ack_i \
    :testbench.tx_ifg_delay

if {[catch {group new -name {RX Client Interface} -overlay 0}] != ""} {
    group using {RX Client Interface}
    group set -overlay 0
    group set -comment {}
    group clear 0 end
}
group insert \
    :testbench.dut.rx_clk_i \
    :testbench.dut.\\v6_emac_v1_3_locallink_inst/rx_data_i \
    :testbench.dut.EMACCLIENTRXDVLD \
    :testbench.dut.\\v6_emac_v1_3_locallink_inst/rx_good_frame_i \
    :testbench.dut.\\v6_emac_v1_3_locallink_inst/rx_bad_frame_i

if {[catch {group new -name {Flow Control} -overlay 0}] != ""} {
    group using {Flow Control}
    group set -overlay 0
    group set -comment {}
    group clear 0 end
}
group insert \
    :testbench.pause_val \
    :testbench.pause_req

if {[catch {group new -name {TX GMII/MII Interface} -overlay 0}] != ""} {
    group using {TX GMII/MII Interface}
    group set -overlay 0
    group set -comment {}
    group clear 0 end
}
group insert \
    :testbench.gmii_tx_clk \
    :testbench.gmii_txd \
    :testbench.gmii_tx_en \
    :testbench.gmii_tx_er 
if {[catch {group new -name {RX GMII/MII Interface} -overlay 0}] != ""} {
    group using {RX GMII/MII Interface}
    group set -overlay 0
    group set -comment {}
    group clear 0 end
}
group insert \
    :testbench.gmii_rx_clk \
    :testbench.gmii_rxd \
    :testbench.gmii_rx_dv \
    :testbench.gmii_rx_er

if {[catch {group new -name {MDIO Interface} -overlay 0}] != ""} {
    group using {MDIO Interface}
    group set -overlay 0
    group set -comment {}
    group clear 0 end
}
group insert \
    :testbench.mdc \
    :testbench.mdio_in \
    :testbench.mdio_out \
    :testbench.mdio_tri


if {[catch {group new -name {Management Interface} -overlay 0}] != ""} {
    group using {Management Interface}
    group set -overlay 0
    group set -comment {}
    group clear 0 end
}
group insert \
    :testbench.host_clk \
    :testbench.host_opcode \
    :testbench.host_addr \
    :testbench.host_wr_data \
    :testbench.host_rd_data \
    :testbench.host_miim_sel \
    :testbench.host_req \
    :testbench.host_miim_rdy \

if {[catch {group new -name {Test semaphores} -overlay 0}] != ""} {
    group using {Test semaphores}
    group set -overlay 0
    group set -comment {}
    group clear 0 end
}
group insert \
    :testbench.configuration_busy \
    :testbench.monitor_finished_1g \
    :testbench.monitor_finished_100m \
    :testbench.monitor_finished_10m

#
# Waveform windows
#
if {[window find -match exact -name "Waveform 1"] == {}} {
    window new WaveWindow -name "Waveform 1" -geometry 906x585+25+55
} else {
    window geometry "Waveform 1" 906x585+25+55
}
window target "Waveform 1" on
waveform using {Waveform 1}
waveform sidebar visibility partial
waveform set \
    -primarycursor TimeA \
    -signalnames name \
    -signalwidth 175 \
    -units fs \
    -valuewidth 75
cursor set -using TimeA -time 50,000,000,000fs
cursor set -using TimeA -marching 1
waveform baseline set -time 0

set id [waveform add -signals [list :testbench.reset \
        :testbench.gtx_clk ]]

set groupId [waveform add -groups {{System Signals}}]

set groupId [waveform add -groups {{TX Client Interface}}]

set groupId [waveform add -groups {{RX Client Interface}}]

set groupId [waveform add -groups {{TX GMII/MII Interface}}]

set groupId [waveform add -groups {{RX GMII/MII Interface}}]

set groupId [waveform add -groups {{MDIO Interface}}]

set groupId [waveform add -groups {{Management Interface}}]

set groupId [waveform add -groups {{Test semaphores}}]

waveform xview limits 0fs 10us

simcontrol run -time 2000us

