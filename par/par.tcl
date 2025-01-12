## tcl Place and Route script
## AMS 0.35um
## Author : Camille Leroux
## IMS Laboratory
## camille.leroux@ims-bordeaux.fr
## July 2017

#########################
###
### 1. DESIGN IMPORT
###
#########################

set AMS_DIR /opt/ams

setDesignMode -process 130 -flowEffort high

set_global _enable_mmmc_by_default_flow      $CTE::mmmc_default

set set_message_limit 100

# On définit le nom de notre Design
set DESIGN_NAME "VGA"

set defHierChar /

set synth_dir syn

### Define netlist paths
# On spécifie ou se trouve la netlist synthétisée ainsi que la netlist "top level" qui inclue les PAD d'entrée sortie
set init_verilog  "../../${synth_dir}/VGA_syn.v"

set init_design_settop 1
set init_design_netlisttype Verilog

### Define LEF Technology paths
# On sépcifie ou se trouvent les fichiers .lef (Library Exchange Format)
# Le premier contient des informations sur la technologie qu'on utilise (règles de dessins, géométries, nombres de niveaux de métaux,...)
# Le second contient une description géométrique des cellules standards
# Le troisième contient une description géométrique des cellules IO
set init_lef_file "$AMS_DIR/cds/HK_C35/LEF/c35b3/c35b3.lef \
$AMS_DIR/cds/HK_C35/LEF/c35b3/CORELIB.lef \
$AMS_DIR/cds/HK_C35/LEF/c35b3/IOLIB_3B_3M.lef"

#set init_oa_ref_lib "TECH_C35B3 \
#CORELIB"
#setExtractRCMode -lefTechFileMap /opt/ams/cds/HK_C35/LEF/c35b3/qrclay.map

### Define Multiple Mode Multiple Corner (MMMC) file path
# Le fichier mmmc définit les conditions PVT que l'on souhaite utiliser pour la vérification des timings
set init_mmmc_file "../mmmc_definition.tcl"
set init_cpf_file {}
set init_import_mode {-treatUndefinedCellAsBbox 0 -keepEmptyModule 1}
set init_assign_buffer 0

### Define global nets
# On définit le vdd et le gnd pour tout le circuit
#set init_pwr_net {vdd! vdd3r1! vdd3r2! vdd3o!}
#set init_gnd_net {gnd! gnd3r! gnd3o! vsubo!}
# TODO : CLEAN vdd gnd etc
set init_pwr_net {vdd!}
set init_gnd_net {gnd!}


set init_oa_search_lib {}

### Import design
init_design

#########################
###
### 2. IO PLACEMENT
###
#########################

### Power/Ground IO & CORNERS specification

### IO placement

redraw

### Used grid definition
### Make IOs on the IO placement grid for correct
### filler peri placement
setPreference ConstraintUserXGrid 0.1
setPreference ConstraintUserXOffset 0.1
setPreference ConstraintUserYGrid 0.1
setPreference ConstraintUserYOffset 0.1
setPreference SnapAllCorners 1
setPreference BlockSnapRule 2

snapFPlanIO -usergrid

#########################
###
### 3. FLOORPLANNING
###
#########################

floorPlan -site standard -r 0.377358490566 0.699887 20.0 20.0 20.0 20.0
redraw

saveDesign ./$DESIGN_NAME.fp.enc
#source ./$DESIGN_NAME.fp.enc

#########################
###
### 4. POWER PLANNING
###
#########################

### Add Core Ring
addRing -stacked_via_top_layer MET3 -around core -jog_distance 1.7 -threshold 1.7 -nets {gnd! vdd!} -stacked_via_bottom_layer MET1 -layer {bottom MET1 top MET1 right MET2 left MET2} -width 1.6 -spacing 1.6 -offset 1.7

### Check floorplan
verifyGeometry
verify_drc
verifyConnectivity
clearDrc

saveDesign ./PAD_${DESIGN_NAME}_fp_pow.enc
#saveDesign ./PAD_${DESIGN_NAME}_fp_pow.enc

#########################
###
### 5. PLACEMENT
###
#########################

### set placement options
setMultiCpuUsage -localCpu 2 -cpuPerRemoteHost 1 -remoteHost 0 -keepLicense true
setDistributeHost -local

setPlaceMode -congEffort medium -timingDriven 0 -modulePlan 0 \
-clkGateAware 0 -powerDriven 0 -ignoreScan 0 -reorderScan 0 \
-ignoreSpare 0 -placeIOPins 0 -moduleAwareSpare 0 \
-preserveRouting 0 -rmAffectedRouting 0 -checkRoute 0 -swapEEQ 0

setPlaceMode -fp false

### Cells placement
placeDesign -prePlaceOpt

### Check Placement
checkPlace $DESIGN_NAME.checkPlace
setDrawView place

### Refine Placement (if there are any violations)
refinePlace

### Check Final Placement
checkPlace $DESIGN_NAME.checkPlace
setDrawView place

saveDesign ./PAD_${DESIGN_NAME}.placed.enc
#source ./PAD_${DESIGN_NAME}.placed.enc

fit

### Pre-CTS Timing Optimization (Check timing before and after to see if it helps)
### usefull to remove fanout violation especially on high fanout nets such as enable and rst
setOptMode -fixFanoutLoad true
optDesign -preCTS


#########################
###
### 6. CLOCK TREE SYNTHESIS (CTS)
###
#########################

cleanupSpecifyClockTree

### Clock tree specification
specifyClockTree -file ../Clock.ctstch

### CTS
clockDesign -specFile ../Clock.ctstch -outDir clock_report

### Delete routing except for the clock tree
deleteTrialRoute

saveDesign ./PAD_${DESIGN_NAME}.CTS.enc
#source ./PAD_${DESIGN_NAME}.CTS.enc

## Post-CTS Timing Optimization
optDesign -postCTS

###############################
###
### 7. POWER ROUTING (Special route)
###
###############################
# TODO :clean
### Connect global nets gnd/vdd to 0 (tielo) / 1 (tiehigh)
globalNetConnect gnd! -type tielo -verbose
#globalNetConnect gnd3r! -type tielo -verbose
#globalNetConnect gnd3o! -type tielo -verbose
#globalNetConnect vsubo! -type tielo -verbose

globalNetConnect vdd! -type tiehi -verbose
#globalNetConnect vdd3r1! -type tiehi -verbose
#globalNetConnect vdd3r2! -type tiehi -verbose
#globalNetConnect vdd3o! -type tiehi -verbose


### Connect global nets gnd/vdd to the power pins of all standards cells
globalNetConnect vdd! -type pgpin -pin vdd! -inst * -verbose
globalNetConnect vdd! -type pgpin -pin A -inst * -verbose

#globalNetConnect vdd3r1! -type pgpin -pin vdd3r1! -inst * -verbose
#globalNetConnect vdd! -type pgpin -pin vdd3r1! -inst * -verbose
#globalNetConnect vdd3r2! -type pgpin -pin vdd3r2! -inst * -verbose
#globalNetConnect vdd3o! -type pgpin -pin vdd3o! -inst * -verbose

globalNetConnect gnd! -type pgpin -pin gnd! -inst * -verbose
globalNetConnect gnd! -type pgpin -pin A -inst * -verbose
#globalNetConnect gnd3r! -type pgpin -pin gnd3r! -inst * -verbose
#globalNetConnect gnd3o! -type pgpin -pin gnd3o! -inst * -verbose
#globalNetConnect vsubo! -type pgpin -pin vsubo! -inst * -verbose

# Create Global Nets
applyGlobalNets

saveDesign ./PAD_${DESIGN_NAME}.filler.enc
#source ./PAD_${DESIGN_NAME}.filler.enc

sroute -connect { blockPin padPin corePin floatingStripe }

verifyGeometry
verify_drc
clearDrc

saveDesign ./PAD_${DESIGN_NAME}.preroute.enc
#source ./PAD_${DESIGN_NAME}.preroute.enc


#########################
###
### 8. ROUTING
###
#########################

### Global routing
routeDesign -globalDetail

### Post-route timing optimization
setOptMode -fixFanoutLoad true
setAnalysisMode -analysisType onChipVariation -cppr both
optDesign -postRoute -hold

saveDesign ./PAD_TOP_FIR.postroute.enc
#source ./PAD_TOP_FIR.postroute.enc


#########################
###
### 9. ADD FILLER CELLS
###
#########################

# Filler Cell Between Std-Cells 
addFiller -cell \
FILL1 \
FILL2 \
FILL5 \
FILL10 \
-prefix FILLER
 
verifyGeometry
verify_drc
verifyConnectivity -type regular -error 1000 -warning 50
verifyProcessAntenna
clearDrc

#########################
###
### 10. REPORTING
###
#########################


setAnalysisMode -checkType setup
report_timing
setAnalysisMode -checkType hold
report_timing

report_power

#########################
###
### 11. EXPORT (Verilog / SDF )
###
#########################

if { ! [ file exists  ../Results] } {file mkdir ../Results} 

### **** VERILOG **** ###
saveNetlist ../Results/$DESIGN_NAME\_routed.v  -excludeLeafCell -excludeCellInst CORNERP_3B

### **** SDF **** ###
rcOut -setload $DESIGN_NAME.setload -rc_corner rc_corner_worst
rcOut -setres $DESIGN_NAME.setres -rc_corner rc_corner_worst
rcOut -spf $DESIGN_NAME.spf -rc_corner rc_corner_worst
rcOut -spef $DESIGN_NAME.spef -rc_corner rc_corner_worst
redirect -quiet {set honorDomain [getAnalysisMode -honorClockDomains]} > /dev/null
timeDesign -reportOnly -pathReports -drvReports -slackReports -numPaths 50 -prefix PAD_TOP_FIR -outDir timingReports

write_sdf ../Results/$DESIGN_NAME\_routed.sdf

echo "End of place and route script"
