# AXI4 Class-Based SystemVerilog Verification

A class-based SystemVerilog verification project for an AXI4-based memory system using directed testing, constrained-random verification, self-checking scoreboarding, SystemVerilog Assertions (SVA), and coverage-driven verification.

The project was developed incrementally: the verification environment first exposed several RTL and memory-related issues, which were then investigated, corrected, and re-verified until a clean functional baseline was achieved.

> **Note:** The source files in this repository represent the final corrected implementation after RTL debugging and verification closure.  
> The `docs/` directory contains reports documenting both the earlier verification/debugging stage and the final post-fix regression.

---

## Verification Architecture

The class-based verification environment follows the flow:

```text
Generator / Sequences
        ↓
      Driver
        ↓
    AXI4 DUT
        ↓
     Monitor
        ↓
Reference Model
        ↓
   Scoreboard
```

Functional coverage and SystemVerilog Assertions operate in parallel with the main self-checking flow.

The environment uses transaction-level SystemVerilog classes and mailboxes to separate stimulus generation, driving, monitoring, checking, and coverage collection.

---

## Verification Features

- Directed AXI read and write testing
- Constrained-random transaction generation
- Single and burst transactions
- Valid and invalid address scenarios
- 4-KB boundary-crossing verification
- Independent reference model
- Self-checking scoreboard
- SystemVerilog Assertions (SVA)
- Functional coverage and cross coverage
- Code, FSM, condition, expression, and toggle coverage
- Directed coverage-closure scenarios
- Backpressure and reset-oriented verification scenarios

---

## RTL Issues Identified and Corrected

The verification process exposed several implementation issues that were investigated and corrected.

### 1. AXI 4-KB Boundary Check

The original implementation recalculated the boundary condition using incrementing burst addresses.

The corrected implementation calculates the complete burst boundary once from the original `AWADDR` or `ARADDR` using:

```text
Number of beats = AxLEN + 1
Bytes per beat  = 2^AxSIZE
```

This ensures that the complete AXI burst is checked correctly against the 4-KB boundary.

### 2. FSM State Register Width

The read and write FSM state registers were originally wider than required.

They were corrected to use 2-bit state registers for the four implemented states.

### 3. Memory Reset Polarity

The memory read-data register incorrectly handled the active-low reset.

The reset condition was corrected from:

```systemverilog
if (rst_n)
```

to:

```systemverilog
if (!rst_n)
```

### 4. Off-by-One Memory Read Address

The original memory implementation read from:

```systemverilog
memory[mem_addr + 1]
```

instead of the requested location.

It was corrected to:

```systemverilog
memory[mem_addr]
```

### 5. Synchronous Read Timing

Burst reads initially showed a one-beat delay because the memory is synchronous.

A new `R_WAIT` state was introduced:

```text
R_IDLE → R_ADDR → R_WAIT → R_DATA
```

This allows the memory output to update before the AXI read data is presented.

---

## Final Verification Results

| Metric | Final Result |
| --- | ---: |
| Functional Regression | **52 PASS / 0 FAIL** |
| Functional Coverage | **100% (44/44 bins)** |
| Assertion Coverage | **100% (16/16 assertions)** |
| FSM State Coverage | **100%** |
| FSM Transition Coverage | **100%** |
| Expression Coverage | **100%** |
| Statement Coverage | **97.84%** |
| Branch Coverage | **94.44%** |
| Condition Coverage | **90.47%** |
| DUT Toggle Coverage | **90.06%** |
| Memory Toggle Coverage | **70.90%** |
| Filtered Overall Coverage | **96.52%** |

The remaining structural coverage gaps were analyzed individually and correspond mainly to structurally unreachable FSM default paths, RTL sequencing constraints, constant-by-design signals, and non-functional implementation variables.

---

## Repository Structure

```text
AXI4-Class-Based-Verification/
│
├── rtl/
│   ├── axi4.v
│   └── axi_memory.v
│
├── tb/
│   ├── axi_assertions.sv
│   ├── axi_coverage.sv
│   ├── axi_driver.sv
│   ├── axi_environment.sv
│   ├── axi_generator.sv
│   ├── axi_interface.sv
│   ├── axi_monitor.sv
│   ├── axi_package.sv
│   ├── axi_reference_model.sv
│   ├── axi_scoreboard.sv
│   ├── axi_sequences.sv
│   ├── axi_tb_top.sv
│   ├── axi_test.sv
│   └── axi_transaction.sv
│
├── sim/
│   └── run.do
│
├── docs/
│   ├── 01_Verification_Report_Before_RTL_Fixes.docx
│   └── 02_Final_Verification_Report_After_RTL_Fixes.docx
│
└── README.md
```

---

## Project Reports

### 01 — Verification Report Before RTL Fixes

Documents the original verification environment, coverage analysis, scoreboard findings, and DUT issues identified during the verification process.

[View Report](docs/01_Verification_Report_Before_RTL_Fixes.docx)

### 02 — Final Verification Report After RTL Fixes

Documents the RTL corrections, debugging work, coverage closure, and the final clean class-based verification baseline.

[View Report](docs/02_Final_Verification_Report_After_RTL_Fixes.docx)

---

## Tools and Technologies

**SystemVerilog • SVA • AXI4 • QuestaSim • Functional Coverage • Code Coverage • Constrained-Random Verification • Class-Based Verification**

---

## Project Contribution

This project was developed as a team-based verification project.

My primary contributions included:

- Generator and driver development
- Directed AXI verification sequences
- Constrained-random stimulus generation
- Targeted coverage-closure stimulus
- RTL/debugging investigation
- Regression and coverage analysis

Integration, debugging, simulation review, coverage closure, and final verification analysis were performed collaboratively.

---

## Key Takeaway

This project demonstrates more than achieving a target coverage percentage.

The verification environment was used to expose real RTL problems, trace scoreboard mismatches back to their root causes, correct the implementation, re-run regression, and achieve a stable verification baseline with complete functional, assertion, FSM, and expression coverage.

The completed class-based environment was then used as the verified baseline for the next stage of the project: migration to UVM.
