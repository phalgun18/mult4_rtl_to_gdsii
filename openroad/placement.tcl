# ============================================================
# OpenROAD Placement
# Design: 4-bit x 4-bit Multiplier
# Technology: SKY130 HD
# ============================================================

set PDK /foss/pdks/ciel/sky130/versions/1689ac3f2dc763876eaf967227c7dfe831b031ae/sky130A/libs.ref/sky130_fd_sc_hd

set TECH_LEF $PDK/techlef/sky130_fd_sc_hd__nom.tlef
set CELL_LEF $PDK/lef/sky130_fd_sc_hd.lef
set LIB      $PDK/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

set SDC       /foss/designs/sta/multiplier.sdc
set FLOORPLAN /foss/designs/openroad/floorplan.def
set PLACEMENT /foss/designs/openroad/placement.def

# ------------------------------------------------------------
# Read technology
# ------------------------------------------------------------

read_lef $TECH_LEF
read_lef $CELL_LEF
read_liberty $LIB

# ------------------------------------------------------------
# Read floorplan
# ------------------------------------------------------------

read_def $FLOORPLAN

# ------------------------------------------------------------
# Read timing constraints
# ------------------------------------------------------------

read_sdc $SDC

# ------------------------------------------------------------
# Wire RC
# ------------------------------------------------------------

set_wire_rc -signal -layer met2
set_wire_rc -clock -layer met5

# ------------------------------------------------------------
# Global placement
# ------------------------------------------------------------

global_placement \
    -density 0.60 \
    -timing_driven

# ------------------------------------------------------------
# Detailed placement
# ------------------------------------------------------------

detailed_placement

# ------------------------------------------------------------
# Check placement
# ------------------------------------------------------------

check_placement

# ------------------------------------------------------------
# Estimate parasitics
# ------------------------------------------------------------

estimate_parasitics -placement

# ------------------------------------------------------------
# Reports
# ------------------------------------------------------------

report_design_area

report_checks -path_delay max
report_checks -path_delay min

report_worst_slack -max
report_worst_slack -min

report_clock_skew

# ------------------------------------------------------------
# Save
# ------------------------------------------------------------

write_def $PLACEMENT

exit