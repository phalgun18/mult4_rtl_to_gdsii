# 4-bit Array Multiplier: RTL to GDSII with Open-Source Tools

A complete digital VLSI design flow for a **4-bit × 4-bit unsigned array multiplier**, taken from Verilog RTL all the way to a DRC-clean, LVS-clean **GDSII layout** using only open-source tools on the **SkyWater SKY130 (130 nm)** process.

![Technology](https://img.shields.io/badge/PDK-SKY130-blue)
![Library](https://img.shields.io/badge/cells-sky130__fd__sc__hd-lightgrey)
![RTL sim](https://img.shields.io/badge/RTL%20sim-256%2F256%20PASS-brightgreen)
![Gate-level sim](https://img.shields.io/badge/gate--level%20sim-256%2F256%20PASS-brightgreen)
![DRC](https://img.shields.io/badge/DRC-0%20errors-brightgreen)
![LVS](https://img.shields.io/badge/LVS-0%20errors-brightgreen)

Course project for **Digital VLSI Design**.

| Authors | Roll Number |
| --- | --- |
| K. Phalgun | 2026702011 |
| Adabala Naveen | 2026702001 |

---

## Table of Contents

1. [Design Overview](#1-design-overview)
2. [Repository Structure](#2-repository-structure)
3. [Tool Flow and Prerequisites](#3-tool-flow-and-prerequisites)
4. [Part A: RTL Design and Verification](#4-part-a-rtl-design-and-verification)
5. [Part B: Logic Synthesis (Yosys)](#5-part-b-logic-synthesis-yosys)
6. [Part C: Static Timing Analysis (OpenSTA)](#6-part-c-static-timing-analysis-opensta)
7. [Part D: Physical Design, RTL to GDSII (LibreLane)](#7-part-d-physical-design-rtl-to-gdsii-librelane)
8. [Results Summary](#8-results-summary)
9. [Analysis and Discussion](#9-analysis-and-discussion)
10. [Quick Start: Reproducing Everything](#10-quick-start-reproducing-everything)
11. [Acknowledgements](#12-acknowledgements)

---

## 1. Design Overview

| Item | Detail |
| --- | --- |
| Design | 4-bit × 4-bit unsigned array multiplier (8-bit product) |
| Top module | `mult_array` |
| Technology | SkyWater SKY130, `sky130_fd_sc_hd` standard cell library |
| Registers | 4-bit `a` register, 4-bit `b` register, 8-bit `p` register (16 flip-flops) |
| Reset | Asynchronous, active low (`rst_n`) |
| Latency | 2 clock cycles |
| Throughput | 1 result per clock cycle |
| Array logic | 16 AND gates and 12 full adders (no `*` operator used) |

### Ports of `mult_array`

| Port | Direction | Width | Description |
| --- | --- | --- | --- |
| `clk` | input | 1 | Clock, rising edge |
| `rst_n` | input | 1 | Asynchronous reset, active low |
| `a` | input | 4 | Multiplicand |
| `b` | input | 4 | Multiplier |
| `p` | output | 8 | Registered product `a × b` |

### Architecture

The multiplier is a classic carry-save style **array multiplier** wrapped in input and output registers, so the design is fully synchronous and its timing can be analysed register-to-register.

| Stage / Row | Operation | Output |
| --- | --- | --- |
| Input registers | `a_reg <= a`, `b_reg <= b` on every rising clock edge | `a_reg`, `b_reg` |
| Row 0 | 4 AND gates (`pp0 = a_reg AND b_reg[0]`) | `p[0] = pp0[0]`, passes `pp0[3:1]` down |
| Row 1 | 4 AND gates + 4 full adders | `p[1] = sum1[0]`, passes `{c1[4], sum1[3:1]}` down |
| Row 2 | 4 AND gates + 4 full adders | `p[2] = sum2[0]`, passes `{c2[4], sum2[3:1]}` down |
| Row 3 | 4 AND gates + 4 full adders | `p[3] = sum3[0]`, `p[7:4] = {c3[4], sum3[3:1]}` |
| Output register | `p <= array result` on every rising clock edge | `p[7:0]` |

| Component | Count |
| --- | --- |
| AND gates | 16 |
| Full adders | 12 |
| Flip-flops | 16 (4 for `a`, 4 for `b`, 8 for `p`) |

The full adder is written with plain `assign` statements:

| Output | Equation |
| --- | --- |
| `sum` | `a ^ b ^ cin` |
| `cout` | `(a & b) \| (cin & (a ^ b))` |

---

## 2. Repository Structure

```
mult4_rtl_to_gdsii/
├── rtl/        Verilog source: full_adder.v, mult_array.v
├── tb/         Self-checking exhaustive testbench: tb_mult.v
├── sim/        Simulation outputs and logs (RTL and gate-level)
├── synth/      Yosys script, gate-level netlist and cell/area report
├── sta/        OpenSTA script and critical-path timing report
├── pnr/        LibreLane configuration (config.json) and run outputs
├── openroad/   OpenROAD-related files from the physical design stage
├── report/     Project report
└── README.md
```

Key files:

| File | Purpose |
| --- | --- |
| `rtl/full_adder.v` | Module `full_adder (a, b, cin, sum, cout)` using `assign` statements |
| `rtl/mult_array.v` | Module `mult_array` with 12 `full_adder` instances |
| `tb/tb_mult.v` | Exhaustive self-checking testbench, 256 vectors, writes `mult.vcd` |
| `synth/synth.tcl` | Yosys synthesis script |
| `synth/mult_array_netlist.v` | Gate-level netlist produced by Yosys |
| `synth/mult_array_stat.rpt` | Cell count and area report |
| `sta/sta.tcl` | OpenSTA constraints and reporting script |
| `sta/mult_array_timing.rpt` | Critical path report |
| `pnr/config.json` | LibreLane configuration |

---

## 3. Tool Flow and Prerequisites

| Stage | Tool | Part |
| --- | --- | --- |
| RTL and gate-level simulation | Icarus Verilog | A, B |
| Waveform viewing | GTKWave | A |
| Logic synthesis | Yosys | B |
| Static timing analysis | OpenSTA | C |
| RTL to GDSII | LibreLane (OpenROAD, Magic, KLayout, Netgen) | D |

**Requirements**

- Icarus Verilog (`iverilog`, `vvp`) and GTKWave
- Yosys
- OpenSTA (`sta`)
- LibreLane (which bundles or drives OpenROAD, Magic, KLayout and Netgen)
- SkyWater SKY130 PDK installed, with the `PDK_ROOT` environment variable pointing to it (for example via `volare` / `ciel`)

The typical-corner liberty file used for synthesis and STA is `sky130_fd_sc_hd__tt_025C_1v80.lib`.

---

## 4. Part A: RTL Design and Verification

### Testbench

`tb/tb_mult.v` generates a 10 ns clock, holds `rst_n` low for 2 cycles, then applies **all 256 combinations** of `a` (0 to 15) and `b` (0 to 15). For each vector it waits 2 clock edges, compares `p` with `a * b`, and prints a single summary line. Inputs change on the **falling** clock edge to avoid a race with the sampling edge.

```bash
iverilog -g2012 -o sim_rtl tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v
vvp sim_rtl          # prints the summary line
gtkwave mult.vcd     # view the waveform
```

| Test | Result line |
| --- | --- |
| Correct design | `PASS: 256 vectors checked, 0 errors` |
| Error test (sum changed to `a ^ b`) | `FAIL: 256 vectors checked, 95 errors` |

The error test confirms the testbench really detects faults. The first mismatch printed was `a=15, b=15, expected=225, got=181`. The original line (`a ^ b ^ cin`) was restored afterwards and the testbench passed again.

### Hand-worked example: 6 × 7

| Quantity | Binary | Decimal |
| --- | --- | --- |
| A | `0110` | 6 |
| B | `0111` | 7 |

| Partial product | Rule | Value (shifted) |
| --- | --- | --- |
| pp0 | A AND b0 (b0 = 1) | `0 1 1 0` |
| pp1 | A AND b1 (b1 = 1), shifted 1 | `0 1 1 0 0` |
| pp2 | A AND b2 (b2 = 1), shifted 2 | `0 1 1 0 0 0` |
| pp3 | A AND b3 (b3 = 0), shifted 3 | `0 0 0 0 0 0 0` |
| Sum | pp0 + pp1 + pp2 + pp3 | `0 0 1 0 1 0 1 0` |

**P = `00101010` = 42 = `0x2A`**

### Waveform timeline for 6 × 7

| Time | Event |
| --- | --- |
| 0 to 20 ns | `rst_n` low, all registers cleared |
| 30 ns | `a = 6`, `b = 7` applied (falling clock edge) |
| 35 ns | Clock edge 1: `a_reg` and `b_reg` capture 6 and 7 |
| 45 ns | Clock edge 2: `p` captures 42 |

Latency is therefore **2 clock cycles**.

---

## 5. Part B: Logic Synthesis (Yosys)

`synth/synth.tcl` runs the following steps, with `lib` set to `sky130_fd_sc_hd__tt_025C_1v80.lib`:

| Step | Command | Purpose |
| --- | --- | --- |
| 1 | `read_verilog rtl/full_adder.v rtl/mult_array.v` | Read the design |
| 2 | `synth -top mult_array -flatten` | Generic synthesis, flatten the full adders |
| 3 | `dfflibmap -liberty $lib` | Map flip-flops to SKY130 cells |
| 4 | `abc -liberty $lib` | Map combinational logic to SKY130 gates |
| 5 | `opt_clean -purge` | Remove unused wires |
| 6 | `tee -o synth/mult_array_stat.rpt stat -liberty $lib` | Cell and area report |
| 7 | `write_verilog -noattr synth/mult_array_netlist.v` | Write the gate-level netlist |

```bash
yosys -c synth/synth.tcl
```

### Results

| Metric | Value |
| --- | --- |
| Total number of cells | 68 |
| Number of flip-flops | 16 |
| Total cell area | 785.754 µm² |
| Flip-flop area | 400.384 µm² (16 × 25.024) |
| Flip-flop share of total area | 50.96 % |
| Most-used cell types | `dfrtp_1` (16), `nand2_1` (8), `and2_0` (6, tied with `xnor2_1` at 6) |
| Gate-level simulation | `PASS: 256 vectors checked, 0 errors` |

<details>
<summary>Full cell list (from <code>mult_array_stat.rpt</code>)</summary>

| Cell type | Count | Area (µm²) |
| --- | --- | --- |
| `sky130_fd_sc_hd__dfrtp_1` | 16 | 400.384 |
| `sky130_fd_sc_hd__nand2_1` | 8 | 30.029 |
| `sky130_fd_sc_hd__and2_0` | 6 | 37.536 |
| `sky130_fd_sc_hd__xnor2_1` | 6 | 52.550 |
| `sky130_fd_sc_hd__maj3_1` | 5 | 50.048 |
| `sky130_fd_sc_hd__nor2_1` | 4 | 15.014 |
| `sky130_fd_sc_hd__a21oi_1` | 3 | 15.014 |
| `sky130_fd_sc_hd__a22oi_1` | 3 | 22.522 |
| `sky130_fd_sc_hd__and4_1` | 2 | 17.517 |
| `sky130_fd_sc_hd__clkinv_1` | 2 | 7.507 |
| `sky130_fd_sc_hd__lpflow_isobufsrc_1` | 2 | 12.512 |
| `sky130_fd_sc_hd__mux2i_1` | 2 | 20.019 |
| `sky130_fd_sc_hd__o21ai_0` | 2 | 10.010 |
| `sky130_fd_sc_hd__xnor3_1` | 2 | 45.043 |
| `sky130_fd_sc_hd__a2111oi_0` | 1 | 8.758 |
| `sky130_fd_sc_hd__nand3_1` | 1 | 5.005 |
| `sky130_fd_sc_hd__nand4_1` | 1 | 6.256 |
| `sky130_fd_sc_hd__or3_1` | 1 | 6.256 |
| `sky130_fd_sc_hd__xor3_1` | 1 | 23.773 |
| **Total** | **68** | **785.754** |

</details>

### Gate-level simulation

The synthesized netlist is simulated with the **same testbench** to prove synthesis did not change behaviour:

```bash
CELLS=$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/verilog
iverilog -g2012 -DFUNCTIONAL -DUNIT_DELAY=#1 -o gls \
    tb/tb_mult.v $CELLS/primitives.v $CELLS/sky130_fd_sc_hd.v \
    synth/mult_array_netlist.v
vvp gls
```

Result: `PASS: 256 vectors checked, 0 errors`.

---

## 6. Part C: Static Timing Analysis (OpenSTA)

Analysis uses the **typical corner only** (`tt_025C_1v80`) on `synth/mult_array_netlist.v`.

| Step | Command | Purpose |
| --- | --- | --- |
| 1 | `read_liberty $lib` | Read the cell timing library |
| 2 | `read_verilog synth/mult_array_netlist.v`, `link_design mult_array` | Read and link the netlist |
| 3 | `create_clock -name clk -period T [get_ports clk]` | Define the clock |
| 4 | `set_input_delay 1.0 -clock clk [delete_from_list [all_inputs] [get_ports clk]]` | Input arrival time |
| 5 | `set_output_delay 1.0 -clock clk [all_outputs]` | Output required time |
| 6 | `report_worst_slack -max` | Worst setup slack |
| 7 | `report_checks -path_delay max -digits 3 > sta/mult_array_timing.rpt` | Critical path report |

```bash
sta -no_splash sta/sta.tcl
```

### Finding Tmin and Fmax

| Quantity | Formula | Value |
| --- | --- | --- |
| Worst slack at T = 10 ns (WNS) | from `report_checks` | 7.027 ns |
| Tmin | T − WNS = 10 − 7.027 | 2.973 ns (rounded to 2.97 ns) |
| Fmax | 1000 / Tmin | **336.7 MHz** |

### Results

| Metric | Value |
| --- | --- |
| Worst slack at T = 10 ns | 7.027 ns |
| Tmin | 2.97 ns |
| Fmax | 336.7 MHz |
| Slack at T = Tmin | −0.003 ns (rounding of 2.973 down to 2.97) |
| Critical path | Input register flip-flop (CLK→Q) to output register `p` flip-flop (D pin) |
| Cells on critical path | 10 (2 flip-flops + 8 combinational) |
| Latency (2 × Tmin) | 5.94 ns |
| Throughput | 336.7 million results per second |

### Critical path, cell by cell

| No. | Cell | Delay (ns) | Arrival (ns) |
| --- | --- | --- | --- |
| 1 | `sky130_fd_sc_hd__dfrtp_1` (CLK→Q) | 0.410 | 0.410 |
| 2 | `sky130_fd_sc_hd__and4_1` | 0.223 | 0.634 |
| 3 | `sky130_fd_sc_hd__o21ai_0` | 0.195 | 0.828 |
| 4 | `sky130_fd_sc_hd__nand3_1` | 0.140 | 0.969 |
| 5 | `sky130_fd_sc_hd__maj3_1` | 0.380 | 1.349 |
| 6 | `sky130_fd_sc_hd__xnor3_1` | 0.393 | 1.741 |
| 7 | `sky130_fd_sc_hd__maj3_1` | 0.369 | 2.110 |
| 8 | `sky130_fd_sc_hd__maj3_1` | 0.383 | 2.493 |
| 9 | `sky130_fd_sc_hd__maj3_1` | 0.349 | 2.842 |
| 10 | `sky130_fd_sc_hd__dfrtp_1` (D pin, capture) | – | 2.842 (data arrival) |

| Timing check at T = 10 ns | Value (ns) |
| --- | --- |
| Data arrival time | 2.842 |
| Library setup time | 0.131 |
| Data required time | 9.869 |
| Slack | 7.027 (MET) |

---

## 7. Part D: Physical Design, RTL to GDSII (LibreLane)

### Configuration (`pnr/config.json`)

| Key | Value |
| --- | --- |
| `DESIGN_NAME` | `"mult_array"` |
| `VERILOG_FILES` | `["dir::../rtl/full_adder.v", "dir::../rtl/mult_array.v"]` |
| `CLOCK_PORT` | `"clk"` |
| `CLOCK_PERIOD` | `7.5` (final passing value) |
| `FP_SIZING` | `"absolute"` |
| `DIE_AREA` | `[0, 0, 150, 150]` |
| Additional keys | `DESIGN_IS_CORE: true`, `RUN_CTS: true`, `RUN_IRDROP_REPORT: false`, `SYNTH_STRATEGY: "AREA 0"` |

```bash
cd pnr
librelane config.json
```

The starting clock period was 1.2 × Tmin = 1.2 × 2.97 ≈ 3.56 ns, rounded up to the next 0.5 ns, i.e. **4.0 ns**.

### Run log: finding a passing clock period

| Run | `CLOCK_PERIOD` (ns) | Result |
| --- | --- | --- |
| 1 | 4.0 | Failed: setup violations in the slow corners |
| 2 | 4.5 | Failed: setup violations |
| 3 | 5.0 | Failed: setup violations |
| 4 | 5.5 | Failed: setup violations |
| 5 | 6.0 | Failed: setup violations |
| 6 | 6.5 | Failed: setup violation |
| 7 | 7.0 | Failed: setup violation |
| 8 | **7.5** | **Passed:** DRC 0, LVS 0, antenna pass, setup slack +0.303 ns |

### Final metrics

| Metric | Value |
| --- | --- |
| `CLOCK_PERIOD` used | 7.5 ns |
| Number of runs needed | 8 |
| Die area | 22,500 µm² (150 µm × 150 µm) |
| Core area | 17,759.5 µm² |
| Setup slack | +0.303 ns |
| Hold slack | +0.130 ns |
| Post-route Fmax | 139.0 MHz |
| Global-route wirelength estimate | 3,836 µm |
| Routed wirelength | 2,423 µm |
| DRC errors | 0 (Magic: 0, KLayout: 0) |
| LVS errors | 0 |
| Antenna check | Passed |

### Cell count after place and route

| Cell class | Count |
| --- | --- |
| Sequential cells (flip-flops) | 16 |
| Multi-input combinational cells | 49 |
| Inverters | 2 |
| Timing repair buffers | 20 |
| Clock buffers | 3 |
| Tap cells | 245 |
| Fill cells | 1564 |
| **Total instances** | **1899** |

Compared with the 68 cells from synthesis: 90 logic/register cells remain after P&R (including 23 buffers added by the flow), and 1809 physical-only cells (tap + fill) are added. The flow runs its own synthesis step, so the logic count differs from Part B by one cell (51 vs 52). Tap cells cover about 306.5 µm².

### Layout

Layout screenshots (GDSII views from KLayout / Magic) are included in the project report in [`report/`](report/).

---

## 8. Results Summary

| Stage | Key result |
| --- | --- |
| RTL simulation | 256/256 vectors pass |
| Synthesis | 68 cells, 785.754 µm², 16 flip-flops (50.96 % of area) |
| Gate-level simulation | 256/256 vectors pass |
| STA (typical corner) | Tmin = 2.97 ns, Fmax = 336.7 MHz, 10-cell critical path |
| Physical design | 7.5 ns clock, setup +0.303 ns, hold +0.130 ns |
| Post-route Fmax | 139.0 MHz |
| Sign-off | DRC 0, LVS 0, antenna pass |

---

## 9. Analysis and Discussion

### Why 52 logic cells and not 28?

A naive count gives 16 AND + 12 full adders = 28 cells. Synthesis produced 68 − 16 = **52** logic cells because a full adder is not a single library cell: its sum maps to `xnor2` / `xnor3` / `xor3`, and its carry maps to `maj3` or an AND/OR network. ABC also merges AND gates and adders into complex cells (`a22oi`, `and4`, `a2111oi`), and adds inverters and buffers. Row 0 has no adders, and the first adder of each row has carry-in = 0, which simplifies its logic.

### Critical path versus the 2N full-adder estimate

The theoretical longest path of an N-bit array multiplier is about 2N full-adder delays (about 8 for N = 4). The synthesized critical path has only **5** full-adder-type cells (4 `maj3` and 1 `xnor3`), because ABC merges partial-product ANDs into complex gates and reduces the carry-in = 0 adders to simpler logic. Total path delay is 2.842 ns: 0.410 ns clock-to-Q plus about 2.43 ns of logic.

### Why flip-flops take about half the area

The design is tiny. A `dfrtp_1` (flip-flop with asynchronous reset) is 25.024 µm², about 6× a `nand2_1` (3.754 µm²), so 16 registers around 52 small logic cells take 50.96 % of the area.

### Why post-route Fmax (139.0 MHz) is far below Part C (336.7 MHz)

| Part C | Post-route |
| --- | --- |
| Typical corner (1.8 V, 25 °C) | Slow corners (for example `ss_100C_1v60`) |
| Ideal clock | Real clock tree |
| Ideal wires | Real wire resistance and capacitance |
| Gate delay only | Gate delay + wire delay + added buffers |

Post-route Fmax = 1000 / (7.5 − 0.303) = 139.0 MHz, about **2.4× lower** than Part C. This is why the 4.0 to 7.0 ns attempts failed even though Part C predicted 2.97 ns.

The flow also adds cells that were not in the synthesized netlist:

| Added cell type | Count | Why it is needed |
| --- | --- | --- |
| Timing repair buffers | 20 | Fix slew, fanout and hold problems; they add some delay |
| Clock buffers | 3 | Clock tree so the clock reaches all 16 flip-flops at nearly the same time |
| Tap cells | 245 | Tie wells to power/ground to prevent latch-up; no signal connections |
| Fill cells | 1564 | Keep continuous wells and meet density rules; no signal connections |

Tap and fill cells do not affect timing. The slowdown comes from the slow corners, wire delay and the added buffers.

### DRC and LVS

- **DRC** checks that the layout obeys the foundry's geometric manufacturing rules (minimum width, spacing, enclosure, density).
- **LVS** extracts the circuit from the layout and verifies it matches the synthesized netlist (same devices, same connections).

Both are needed: a layout can be DRC-clean but wired differently from the intended circuit, or match the netlist but violate rules so it cannot be fabricated reliably. This design passes both (DRC 0 in Magic and KLayout, LVS 0, antenna passed).

### Scaling to an 8-bit multiplier

For an N-bit array multiplier: N² AND gates, N(N − 1) full adders, longest path about 2N full-adder delays.

| Quantity | N = 4 | N = 8 | Change |
| --- | --- | --- | --- |
| AND gates (N²) | 16 | 64 | 4× |
| Full adders N(N − 1) | 12 | 56 | about 4.7× |
| Longest path (2N FA delays) | 8 | 16 | 2× |

Area grows roughly with the square of the width, while delay grows roughly linearly. Estimated 8-bit Tmin: logic delay 2 × 2.432 ns ≈ 4.86 ns, plus clock-to-Q (0.410 ns) and setup (0.131 ns), giving about **5.4 ns**, so Fmax falls from 336.7 MHz to about **185 MHz**. This is an estimate based on the 2N rule, not a synthesized result.

---

## 10. Quick Start: Reproducing Everything

```bash
# 0. Clone
git clone https://github.com/phalgun18/mult4_rtl_to_gdsii.git
cd mult4_rtl_to_gdsii

# 1. RTL simulation (Part A)
iverilog -g2012 -o sim_rtl tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v
vvp sim_rtl                      # expect: PASS: 256 vectors checked, 0 errors
gtkwave mult.vcd                 # optional waveform

# 2. Synthesis (Part B)
yosys -c synth/synth.tcl

# 3. Gate-level simulation (Part B)
CELLS=$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/verilog
iverilog -g2012 -DFUNCTIONAL -DUNIT_DELAY=#1 -o gls \
    tb/tb_mult.v $CELLS/primitives.v $CELLS/sky130_fd_sc_hd.v \
    synth/mult_array_netlist.v
vvp gls                          # expect: PASS: 256 vectors checked, 0 errors

# 4. Static timing analysis (Part C)
sta -no_splash sta/sta.tcl

# 5. RTL to GDSII (Part D)
cd pnr
librelane config.json
```

Run the commands from the repository root unless noted. Make sure `PDK_ROOT` is set and that the paths to the liberty file in `synth/synth.tcl` and `sta/sta.tcl` match your PDK installation.

---

## 11. Acknowledgements

Built with [Icarus Verilog](https://github.com/steveicarus/iverilog), [GTKWave](https://gtkwave.sourceforge.net/), [Yosys](https://github.com/YosysHQ/yosys), [OpenSTA](https://github.com/The-OpenROAD-Project/OpenSTA), [LibreLane](https://github.com/librelane/librelane), [OpenROAD](https://github.com/The-OpenROAD-Project/OpenROAD), [Magic](http://opencircuitdesign.com/magic/), [KLayout](https://www.klayout.de/) and [Netgen](http://opencircuitdesign.com/netgen/), on the [SkyWater SKY130 PDK](https://github.com/google/skywater-pdk).
