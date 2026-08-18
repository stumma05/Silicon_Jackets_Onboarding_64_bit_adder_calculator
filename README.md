# 64-Bit SRAM Calculator & SystemVerilog Verification Environment

## Overview
This project features a 64-bit adder/concatenation digital circuit paired with a robust, Object-Oriented SystemVerilog testbench. The primary focus of this repository is the custom verification environment built to validate the Device Under Test (DUT) through directed testing, constrained randomization, and assertion-based verification. 

## Key Features & Verification Methodology
* **Custom OOP Testbench Architecture:** Implemented a scalable testbench using SystemVerilog classes (Driver, Monitor, Scoreboard, Sequencer) communicating via mailboxes and virtual interfaces.
* **Constrained Random Verification (CRV):** Developed sequence items with randomized data and address fields, utilizing constraints to ensure read/write operations stay within valid SRAM memory bounds (512 depth).
* **Automated Golden Model Checking:** Built a Scoreboard with local memory arrays to simulate expected behavior and automatically flag read/write mismatches against the DUT in real-time.
* **SystemVerilog Assertions (SVA):** Integrated assertions at the top-level testbench to continuously monitor and verify synchronous reset behavior, buffer toggling, and address boundary limits.
* **Multi-Simulator Support:** The environment utilizes compiler directives to seamlessly support waveform dumping and interface port mapping for both Synopsys VCS and Cadence Xcelium.

## DUT Architecture (The Calculator)
The core module interfaces with SRAM cells and executes states governed by an internal Finite State Machine (`S_IDLE`, `S_READ`, `S_ADD`, `S_WRITE`, `S_END`). It performs 64-bit operations by fetching 32-bit words from SRAM A and SRAM B, calculating the result, and writing it back to memory. 

## Test Plan & Coverage
* **Directed Testing:** Initialized SRAM with specific values to verify base addition, boundary values (e.g., 0 + 0, 0 + MAX), and overflow conditions.
* **Randomized Testing:** Executed high-volume randomized read/write sequences to stress-test the FSM and memory interfaces.

## How to Run
[Insert the terminal commands required to compile and run your simulation here. For example: `make run_vcs` or `xrun -f filelist.f`]
