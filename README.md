# ICTC APB 8-bit Timer Verification

A SystemVerilog verification project for an 8-bit APB timer peripheral, built with an object-oriented layered testbench. This project was developed as part of the "8-bit timer verification using SystemVerilog" lab.

---

## 1. Overview

The Device Under Test (DUT) is an 8-bit timer with an **APB (Advanced Peripheral Bus)** interface. It supports:

- Register read/write access over APB.
- 8-bit up-counting and down-counting.
- Programmable clock division of `ker_clk` by 1, 2, 4, or 8.
- Interrupt generation on **overflow** and **underflow** events.
- **Write-1-to-Clear (W1C)** status flags.

The verification environment is implemented in SystemVerilog using a layered OOP testbench with `stimulus`, `driver`, `monitor`, `scoreboard`, `environment`, and reusable `base_test` classes.

---

## 2. Project Structure

```
ICTC-APB-8bit-Timer-Verification/
├── rtl/                    # RTL design of the DUT
│   ├── timer_top.v         # Top-level module
│   ├── timer_register.v    # APB register block (TCR, TSR, TDR, TIE)
│   ├── timer_clock_divisor.v  # Clock divider
│   ├── timer_counter.v     # 8-bit counter
│   └── timer_interupt.v    # Interrupt logic
├── tb/                     # SystemVerilog testbench
│   ├── testbench.sv        # Top-level testbench
│   ├── dut_interface.sv    # APB interface
│   ├── timer_pkg.sv        # Package containing testbench classes
│   ├── packet.sv           # Transaction packet definition
│   ├── obs_packet.sv       # Observed packet definition
│   ├── stimulus.sv         # Stimulus generator
│   ├── driver.sv           # APB bus driver
│   ├── monitor.sv          # Bus monitor
│   ├── scoreboard.sv       # Reference model and checker
│   └── environment.sv      # Testbench component integration
├── testcase/               # 32 directed/random test cases + factory/package
├── sim/                    # Simulation scripts
│   ├── Makefile
│   ├── compile.f
│   ├── regress.cfg
│   ├── regress.pl
│   ├── rtl.f
│   └── tb.f
├── Vplan_8bit_timer.xlsx   # Verification Plan
└── README.md
```

---

## 3. DUT Architecture

### 3.1. Block Diagram

```
                    +------------------+
   pclk, presetn    |                  |
   pwrite, psel     |   timer_register |----> reg_TDR, clkdiv, count_down,
   penable, paddr   |                  |      timer_en, underflow_en,
   pwdata <-------> |                  |      overflow_en, load
   prdata <-------- |                  |<---- s_udf, s_ovf
                    +------------------+
                             |
                             v
                    +------------------+
   ker_clk -------->| timer_clock_     |----> clk_out
   clkdiv --------->|   divisor        |
                    +------------------+
                             |
                             v
                    +------------------+
   clk_in --------->|  timer_counter   |----> s_ovf, s_udf
   load, count_down |                  |
   timer_en, reg_TDR|                  |
                    +------------------+
                             |
                             v
                    +------------------+
   udf, ovf ------->| timer_interrupt  |----> interrupt
   underflow_en     |                  |
   overflow_en      +------------------+
```

### 3.2. APB Register Map

| Address | Name | Description | Access |
|---------|------|-------------|--------|
| `0x00` | **TCR** | Timer Control Register `[4:0]`: `clkdiv[4:3]`, `load[2]`, `count_down[1]`, `timer_en[0]` | RW |
| `0x01` | **TSR** | Timer Status Register `[1:0]`: `udf[1]`, `ovf[0]` | W1C |
| `0x02` | **TDR** | Timer Data Register (reload value for the counter) | RW |
| `0x03` | **TIE** | Timer Interrupt Enable `[1:0]`: `underflow_en[1]`, `overflow_en[0]` | RW |
| `0x04 - 0xFF` | Reserved | Writes ignored, reads return 0 | - |

### 3.3. RTL Module Descriptions

- **`timer_register.v`**: Handles APB transactions and stores the TCR, TDR, and TIE registers. Updates the TSR flags from the counter and supports W1C access to TSR.
- **`timer_clock_divisor.v`**: Divides `ker_clk` based on `clkdiv`:
  - `00`: bypass `ker_clk`
  - `01`: divide by 2
  - `10`: divide by 4
  - `11`: divide by 8
- **`timer_counter.v`**: 8-bit counter with up/down counting, reload from TDR when `load=1`, and overflow/underflow flag generation.
- **`timer_interrupt.v`**: Generates `interrupt = (underflow_en & udf) | (overflow_en & ovf)`.

---

## 4. Verification Environment

The testbench follows a **layered verification architecture** using SystemVerilog OOP:

```
+------------------+
|   test cases     |  default_value, rw_register, w1c_register, reserved_region
+------------------+
         |
         v
+------------------+
|   environment    |  stimulus + driver + monitor + scoreboard
+------------------+
         |
         v
+------------------+
|    dut_if        |  APB interface
+------------------+
         |
         v
+------------------+
|      DUT         |  timer_top
+------------------+
```

### 4.1. Testbench Components

| Component | File | Description |
|-----------|------|-------------|
| `packet` | `packet.sv` | APB transaction definition (addr, data, read/write) |
| `obs_packet` | `obs_packet.sv` | Observed bus signal packet |
| `stimulus` | `stimulus.sv` | Queue of packets sent to the driver |
| `driver` | `driver.sv` | Implements APB protocol (SETUP → ENABLE → IDLE) |
| `monitor` | `monitor.sv` | Samples bus signals every `pclk` cycle |
| `scoreboard` | `scoreboard.sv` | Reference model and read-data checker |
| `environment` | `environment.sv` | Instantiates and runs all components in parallel |
| `base_test` | `base_test.sv` | Base class providing `write()`, `read()`, and `run_test()` APIs |
| `test_factory` | `test_factory.sv` | Creates test cases by name from `+TESTNAME=` plusarg |

### 4.2. Scoreboard / Reference Model

The scoreboard maintains reference registers (`ref_tcr`, `ref_tsr`, `ref_tdr`, `ref_tie`) and:

- Updates the reference model on every **WRITE** transaction.
- Predicts the expected read value on every **READ** transaction.
- Reports total comparisons, mismatches, and a final **PASS/FAIL** status.

---

## 5. Test Cases

The regression contains all 31 test cases in `Vplan_8bit_timer.xlsx`, plus the
additional `load_hold_test` that verifies the counter remains at TDR while
`TCR.load` stays asserted.

| Group | Count | Coverage |
|-------|------:|----------|
| Register / APB | 8 | Defaults, RW, reserved space, W1C, reset, protocol, CDC access, random access |
| Clock divisor | 5 | No divide, /2, /4, /8, runtime reconfiguration |
| Counter | 11 | Up/down, load, load hold, enable/disable, rollover, direction change, random stress |
| Interrupt | 8 | Overflow/underflow, polling, W1C clear, late enable, dual source, race, divided clocks |

---

## 6. Running Simulation

### 6.1. Requirements

- **QuestaSim** installed on Windows (e.g., `C:\questasim64_10.2c\win64`).
- **WSL** or a Unix-like environment to run the `Makefile`.
- Override the QuestaSim path if needed:
  ```bash
  make all QUESTA_PATH=/mnt/c/questasim64_10.2c/win64
  ```

### 6.2. Make Targets

```bash
cd sim/

# Compile and run the default test (w1c_register_test)
make all

# Compile only
make build

# Run the compiled testbench
make run

# Run a specific test
make run TESTNAME=rw_register_test

# Compile once and run the complete 32-test regression
make regress

# Open waveform viewer
make wave

# Open coverage GUI (requires COV=ON)
make cov_gui

# Clean generated files
make clean

# Show help
make help
```

### 6.3. Makefile Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `TESTNAME` | `w1c_register_test` | Test case to run |
| `TB_NAME` | `testbench` | Top-level testbench module |
| `SEED` | `1` | Simulation seed (`random` for auto-generated seed) |
| `COV` | `OFF` | Enable coverage collection (`ON`/`OFF`) |
| `RADIX` | `hexadecimal` | Waveform display radix |

---

## 7. Verification Status

The complete regression was run with QuestaSim 10.2c after integrating the
Vplan test suite: **32 passed, 0 failed, 0 unknown**. The generated summary is
written to `sim/regress.rpt`; detailed logs and waveforms are under `sim/log/`.

The scoreboard prints a final report similar to:

```
========== [scoreboard] FINAL REPORT ===========
  compares   = <n>
  writes     = <n>
  reads      = <n>
  mismatches = 0
  STATUS     = PASS
================================================
```

---

## 8. References

- `07.-Project-1.-8-bit-timer-verification-using-Systemverilog.pdf`: Lab assignment document.
- `Vplan_8bit_timer.xlsx`: Detailed verification plan.
