# TCL File Generated by Component Editor 17.1
# Tue Dec 19 12:43:12 EST 2017
# DO NOT MODIFY


# 
# fmh_gpib_core "fmh_gpib_core" v1
# Frank Mori Hess 2017.12.19.12:43:12
# https://github.com/fmhess/fmh_gpib_core
# 

# 
# request TCL package from ACDS 16.1
# 
package require -exact qsys 16.1


# 
# module fmh_gpib_core
# 
set_module_property DESCRIPTION https://github.com/fmhess/fmh_gpib_core
set_module_property NAME fmh_gpib_core
set_module_property VERSION 1
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property GROUP GPIB
set_module_property AUTHOR "Frank Mori Hess"
set_module_property DISPLAY_NAME fmh_gpib_core
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset quartus_synth QUARTUS_SYNTH "" "Quartus Synthesis"
set_fileset_property quartus_synth TOP_LEVEL fmh_gpib_top
set_fileset_property quartus_synth ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property quartus_synth ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file fmh_gpib_top.vhd VHDL PATH ../../src/example/fmh_gpib_top.vhd TOP_LEVEL_FILE
add_fileset_file frontend_cb7210p2.vhd VHDL PATH ../../src/frontends/frontend_cb7210p2.vhd
add_fileset_file integrated_interface_functions.vhd VHDL PATH ../../src/ieee_488_1_state/integrated_interface_functions.vhd
add_fileset_file interface_function_AH.vhd VHDL PATH ../../src/ieee_488_1_state/interface_function_AH.vhd
add_fileset_file interface_function_C.vhd VHDL PATH ../../src/ieee_488_1_state/interface_function_C.vhd
add_fileset_file interface_function_DC.vhd VHDL PATH ../../src/ieee_488_1_state/interface_function_DC.vhd
add_fileset_file interface_function_DT.vhd VHDL PATH ../../src/ieee_488_1_state/interface_function_DT.vhd
add_fileset_file interface_function_LE.vhd VHDL PATH ../../src/ieee_488_1_state/interface_function_LE.vhd
add_fileset_file interface_function_PP.vhd VHDL PATH ../../src/ieee_488_1_state/interface_function_PP.vhd
add_fileset_file interface_function_RL.vhd VHDL PATH ../../src/ieee_488_1_state/interface_function_RL.vhd
add_fileset_file interface_function_SH.vhd VHDL PATH ../../src/ieee_488_1_state/interface_function_SH.vhd
add_fileset_file interface_function_SR.vhd VHDL PATH ../../src/ieee_488_1_state/interface_function_SR.vhd
add_fileset_file interface_function_TE.vhd VHDL PATH ../../src/ieee_488_1_state/interface_function_TE.vhd
add_fileset_file interface_function_common.vhd VHDL PATH ../../src/ieee_488_1_state/interface_function_common.vhd
add_fileset_file remote_message_decoder.vhd VHDL PATH ../../src/ieee_488_1_state/remote_message_decoder.vhd
add_fileset_file dma_fifos.vhd VHDL PATH ../../src/util/dma_fifos.vhd
add_fileset_file dma_translator_cb7210p2_to_pl330.vhd VHDL PATH ../../src/util/dma_translator_cb7210p2_to_pl330.vhd
add_fileset_file gpib_control_debounce_filter.vhd VHDL PATH ../../src/util/gpib_control_debounce_filter.vhd
add_fileset_file std_fifo.vhd VHDL PATH ../../src/util/std_fifo.vhd


# 
# parameters
# 


# 
# module assignments
# 
set_module_assignment embeddedsw.dts.group gpib
set_module_assignment embeddedsw.dts.name fmh_gpib_core
set_module_assignment embeddedsw.dts.params.dma-channel 0
set_module_assignment embeddedsw.dts.params.reg-shift 4
set_module_assignment embeddedsw.dts.vendor fmhess


# 
# display items
# 


# 
# connection point gpib_control_status
# 
add_interface gpib_control_status avalon end
set_interface_property gpib_control_status addressUnits WORDS
set_interface_property gpib_control_status associatedClock clock
set_interface_property gpib_control_status associatedReset reset
set_interface_property gpib_control_status bitsPerSymbol 8
set_interface_property gpib_control_status burstOnBurstBoundariesOnly false
set_interface_property gpib_control_status burstcountUnits WORDS
set_interface_property gpib_control_status explicitAddressSpan 0
set_interface_property gpib_control_status holdTime 0
set_interface_property gpib_control_status linewrapBursts false
set_interface_property gpib_control_status maximumPendingReadTransactions 0
set_interface_property gpib_control_status maximumPendingWriteTransactions 0
set_interface_property gpib_control_status readLatency 0
set_interface_property gpib_control_status readWaitTime 1
set_interface_property gpib_control_status setupTime 0
set_interface_property gpib_control_status timingUnits Cycles
set_interface_property gpib_control_status writeWaitTime 0
set_interface_property gpib_control_status ENABLED true
set_interface_property gpib_control_status EXPORT_OF ""
set_interface_property gpib_control_status PORT_NAME_MAP ""
set_interface_property gpib_control_status CMSIS_SVD_VARIABLES ""
set_interface_property gpib_control_status SVD_ADDRESS_GROUP ""

add_interface_port gpib_control_status avalon_address address Input 7
add_interface_port gpib_control_status avalon_chip_select_inverted chipselect_n Input 1
add_interface_port gpib_control_status avalon_read_inverted read_n Input 1
add_interface_port gpib_control_status avalon_write_inverted write_n Input 1
add_interface_port gpib_control_status avalon_data_out readdata Output 8
add_interface_port gpib_control_status avalon_data_in writedata Input 8
set_interface_assignment gpib_control_status embeddedsw.configuration.isFlash 0
set_interface_assignment gpib_control_status embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment gpib_control_status embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment gpib_control_status embeddedsw.configuration.isPrintableDevice 0


# 
# connection point clock
# 
add_interface clock clock end
set_interface_property clock clockRate 0
set_interface_property clock ENABLED true
set_interface_property clock EXPORT_OF ""
set_interface_property clock PORT_NAME_MAP ""
set_interface_property clock CMSIS_SVD_VARIABLES ""
set_interface_property clock SVD_ADDRESS_GROUP ""

add_interface_port clock clock clk Input 1


# 
# connection point reset
# 
add_interface reset reset end
set_interface_property reset associatedClock clock
set_interface_property reset synchronousEdges DEASSERT
set_interface_property reset ENABLED true
set_interface_property reset EXPORT_OF ""
set_interface_property reset PORT_NAME_MAP ""
set_interface_property reset CMSIS_SVD_VARIABLES ""
set_interface_property reset SVD_ADDRESS_GROUP ""

add_interface_port reset reset reset Input 1


# 
# connection point dma_fifos
# 
add_interface dma_fifos avalon end
set_interface_property dma_fifos addressUnits WORDS
set_interface_property dma_fifos associatedClock clock
set_interface_property dma_fifos associatedReset reset
set_interface_property dma_fifos bitsPerSymbol 8
set_interface_property dma_fifos burstOnBurstBoundariesOnly false
set_interface_property dma_fifos burstcountUnits WORDS
set_interface_property dma_fifos explicitAddressSpan 0
set_interface_property dma_fifos holdTime 0
set_interface_property dma_fifos linewrapBursts false
set_interface_property dma_fifos maximumPendingReadTransactions 0
set_interface_property dma_fifos maximumPendingWriteTransactions 0
set_interface_property dma_fifos readLatency 0
set_interface_property dma_fifos readWaitTime 1
set_interface_property dma_fifos setupTime 0
set_interface_property dma_fifos timingUnits Cycles
set_interface_property dma_fifos writeWaitTime 0
set_interface_property dma_fifos ENABLED true
set_interface_property dma_fifos EXPORT_OF ""
set_interface_property dma_fifos PORT_NAME_MAP ""
set_interface_property dma_fifos CMSIS_SVD_VARIABLES ""
set_interface_property dma_fifos SVD_ADDRESS_GROUP ""

add_interface_port dma_fifos dma_fifos_address address Input 2
add_interface_port dma_fifos dma_fifos_read read Input 1
add_interface_port dma_fifos dma_fifos_write write Input 1
add_interface_port dma_fifos dma_fifos_chip_select chipselect Input 1
add_interface_port dma_fifos dma_fifos_data_out readdata Output 16
add_interface_port dma_fifos dma_fifos_data_in writedata Input 16
set_interface_assignment dma_fifos embeddedsw.configuration.isFlash 0
set_interface_assignment dma_fifos embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment dma_fifos embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment dma_fifos embeddedsw.configuration.isPrintableDevice 0


# 
# connection point interrupt_sender
# 
add_interface interrupt_sender interrupt end
set_interface_property interrupt_sender associatedAddressablePoint gpib_control_status
set_interface_property interrupt_sender associatedClock clock
set_interface_property interrupt_sender associatedReset reset
set_interface_property interrupt_sender bridgedReceiverOffset ""
set_interface_property interrupt_sender bridgesToReceiver ""
set_interface_property interrupt_sender ENABLED true
set_interface_property interrupt_sender EXPORT_OF ""
set_interface_property interrupt_sender PORT_NAME_MAP ""
set_interface_property interrupt_sender CMSIS_SVD_VARIABLES ""
set_interface_property interrupt_sender SVD_ADDRESS_GROUP ""

add_interface_port interrupt_sender irq irq Output 1


# 
# connection point external_gpib_bus
# 
add_interface external_gpib_bus conduit end
set_interface_property external_gpib_bus associatedClock clock
set_interface_property external_gpib_bus associatedReset ""
set_interface_property external_gpib_bus ENABLED true
set_interface_property external_gpib_bus EXPORT_OF ""
set_interface_property external_gpib_bus PORT_NAME_MAP ""
set_interface_property external_gpib_bus CMSIS_SVD_VARIABLES ""
set_interface_property external_gpib_bus SVD_ADDRESS_GROUP ""

add_interface_port external_gpib_bus gpib_DIO_inverted gpib_data Bidir 8
add_interface_port external_gpib_bus gpib_ATN_inverted gpib_atn Bidir 1
add_interface_port external_gpib_bus gpib_NRFD_inverted gpib_nrfd Bidir 1
add_interface_port external_gpib_bus gpib_NDAC_inverted gpib_ndac Bidir 1
add_interface_port external_gpib_bus gpib_SRQ_inverted gpib_srq Bidir 1
add_interface_port external_gpib_bus gpib_REN_inverted gpib_ren Bidir 1
add_interface_port external_gpib_bus gpib_EOI_inverted gpib_eoi Bidir 1
add_interface_port external_gpib_bus gpib_DAV_inverted gpib_dav Bidir 1
add_interface_port external_gpib_bus gpib_IFC_inverted gpib_ifc Bidir 1
add_interface_port external_gpib_bus pullup_enable_inverted gpib_pe Output 1
add_interface_port external_gpib_bus talk_enable gpib_te Output 1
add_interface_port external_gpib_bus controller_in_charge gpib_dc Output 1
add_interface_port external_gpib_bus gpib_disable gpib_disable Input 1


# 
# connection point peripheral_dma_request
# 
add_interface peripheral_dma_request conduit end
set_interface_property peripheral_dma_request associatedClock ""
set_interface_property peripheral_dma_request associatedReset ""
set_interface_property peripheral_dma_request ENABLED true
set_interface_property peripheral_dma_request EXPORT_OF ""
set_interface_property peripheral_dma_request PORT_NAME_MAP ""
set_interface_property peripheral_dma_request CMSIS_SVD_VARIABLES ""
set_interface_property peripheral_dma_request SVD_ADDRESS_GROUP ""

add_interface_port peripheral_dma_request dma_req dma_req Output 1
add_interface_port peripheral_dma_request dma_single dma_single Output 1
add_interface_port peripheral_dma_request dma_ack dma_ack Input 1

