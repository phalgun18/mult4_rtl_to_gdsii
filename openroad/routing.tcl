# ============================================================
# OpenROAD Routing
# Design: 4-bit x 4-bit Multiplier
# Technology: SKY130 HD
# ============================================================

set PDK /foss/pdks/ciel/sky130/versions/1689ac3f2dc763876eaf967227c7dfe831b031ae/sky130A/libs.ref/sky130_fd_sc_hd

set TECH_LEF $PDK/techlef/sky130_fd_sc_hd__nom.tlef
set CELL_LEF $PDK/lef/sky130_fd_sc_hd.lef
set LIB      $PDK/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

set SDC       /foss/designs/sta/multiplier.sdc
set PLACEMENT /foss/designs/openroad/placement_route.def
set ROUTED    /foss/designs/openroad/routed.def

# ------------------------------------------------------------
# 1. Read technology
# ------------------------------------------------------------

read_lef $TECH_LEF
read_lef $CELL_LEF
read_liberty $LIB

# ------------------------------------------------------------
# 2. Read placed design
# ------------------------------------------------------------

read_def $PLACEMENT

# ------------------------------------------------------------
# 3. Timing constraints
# ------------------------------------------------------------

read_sdc $SDC

# ------------------------------------------------------------
# 4. Wire RC
# ------------------------------------------------------------

set_wire_rc -signal -layer met2
set_wire_rc -clock -layer met5

# ------------------------------------------------------------
# 5. Global routing
# ------------------------------------------------------------

global_route \
    -guide_file /foss/designs/openroad/route.guide \
    -congestion_report_file /foss/designs/openroad/congestion.rpt \
    -verbose

# ------------------------------------------------------------
# 6. Detailed routing
# ------------------------------------------------------------

detailed_route \
    -output_drc /foss/designs/openroad/route_drc.rpt \
    -verbose 1

# ------------------------------------------------------------
# 7. Check routing
# ------------------------------------------------------------

check_placement

# ------------------------------------------------------------
# 8. Save routed design
# ------------------------------------------------------------

write_def $ROUTED

exit
