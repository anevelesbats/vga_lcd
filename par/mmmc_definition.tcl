## LIBRARIES SET
# MAX
create_library_set -name libset_max \
   -timing \
   [list ${AMS_DIR}/liberty/c35_1.8V/c35_CORELIB_WC.lib ${AMS_DIR}/liberty/c35_1.8V/c35_IOLIB_3B_WC.lib ]
# MIN
create_library_set -name libset_min \
   -timing \
    [list ${AMS_DIR}/liberty/c35_1.8V/c35_CORELIB_BC.lib ${AMS_DIR}/liberty/c35_1.8V/c35_IOLIB_3B_BC.lib]

## RC CORNER
# MAX
create_rc_corner -name rc_corner_worst \
   -cap_table /opt/ams/cds/HK_C35/LEF/encounter/c35b3-worst.capTable
   #-qx_tech_file ${AMS_DIR}/assura/c35b3/c35b3all/RCX-worst/qrcTechFile \
   #-T 150

# MIN
create_rc_corner -name rc_corner_best \
   -cap_table /opt/ams/cds/HK_C35/LEF/encounter/c35b3-best.capTable
   #-qx_tech_file ${AMS_DIR}/assura/c35b3/c35b3all/RCX-best/qrcTechFile \
   #-T -50

## DELAY CORNER = LIB SET + RC CORNER
# MAX
create_delay_corner -name delay_corner_max \
   -library_set libset_max \
   -rc_corner rc_corner_worst
# OCV (On Chip Variation)
create_delay_corner -name delay_corner_ocv \
   -rc_corner rc_corner_worst \
   -early_library_set libset_min \
   -late_library_set libset_max
# MIN
create_delay_corner -name delay_corner_min \
   -library_set libset_min \
   -rc_corner rc_corner_best

## CONSTRAINT MODE
create_constraint_mode -name constraint_mode \
   -sdc_files ../../syn/VGA_syn.sdc

## ANALYSIS VIEWS
# SETUP
create_analysis_view -name analysis_view_setup -constraint_mode constraint_mode -delay_corner delay_corner_max
# HOLD
create_analysis_view -name analysis_view_hold -constraint_mode constraint_mode -delay_corner delay_corner_min

set_analysis_view -setup [list analysis_view_setup] -hold [list analysis_view_hold]
