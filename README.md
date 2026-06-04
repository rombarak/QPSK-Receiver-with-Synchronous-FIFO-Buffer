# QPSK Receiver Data-Path and Synchronous Buffer Integration

## System Purpose & Operation
This project implements a critical segment of a digital communication receiver data-path. In modern digital receivers, high-frequency analog radio signals are captured and converted into digital samples by an Analog-to-Digital Converter (ADC). 

The purpose of this RTL design is to take those raw, digitized baseband samples, decode them back into meaningful binary data, and safely buffer them. Specifically, it translates a continuous stream of Quadrature Phase Shift Keying (QPSK) symbols into standard 8-bit ASCII characters. Because the incoming RF symbol rate may not perfectly match the downstream processing speed of the system (such as a MAC layer controller), a Synchronous FIFO is integrated to provide elastic buffering, preventing data loss during transmission bursts.

---

## Understanding QPSK and the Demapping Process

Quadrature Phase Shift Keying (QPSK) is a modulation scheme that transmits data by altering the phase of a carrier wave. In the digital domain, these phase shifts are represented on a Cartesian plane using two orthogonal components:
* **I (In-Phase):** Represents the X-axis coordinate.
* **Q (Quadrature):** Represents the Y-axis coordinate.

Because QPSK utilizes four distinct phase states (the four quadrants of the Cartesian plane), each transmitted symbol encodes exactly **2 bits** of information.

### How This Module Implements Demapping:
Instead of dealing with complex analog phases, this RTL design operates on post-ADC digital data. 
1. **Coordinate Input:** The module receives the I and Q coordinates as 8-bit signed integers (ranging from -128 to +127). The ideal signal points are physically centered at `I = +/-64` and `Q = +/-64`.
2. **Hard-Decision Slicing:** The demapper (`QPSK_rx.v`) looks strictly at the Most Significant Bit (MSB) of the I and Q inputs, which acts as the sign bit. By evaluating whether the coordinates are positive or negative, it instantly determines which of the four quadrants the symbol falls into.
3. **Symbol to Binary Conversion:** Based on the quadrant, it assigns a 2-bit value (e.g., `00`, `01`, `10`, `11`). 
4. **Deserialization:** To form standard bytes, the module shifts four consecutive 2-bit symbols into an internal register (from LSB to MSB) until a complete 8-bit ASCII character is assembled.

---

## Part 1: Synchronous FIFO (Elastic Buffer)
The foundation of the system is a parameterized Synchronous FIFO (`FIFO.v`), designed to safely bridge data transfers between the receiver front-end and downstream logic.

### Micro-Architecture Highlights:
* **Parameterized Design:** Configurable utilizing `FIFO_DEPTH` (default: 16) and `FIFO_WIDTH` (default: 8) parameters.
* **Efficient Pointer Management:** Utilizes the Verilog `$clog2()` built-in function to dynamically allocate memory pointer widths.
* **State Detection Logic:** To distinguish between `Full` and `Empty` conditions without a dedicated entry counter (avoiding a critical path bottleneck), the read and write pointers are extended by one extra MSB. The FIFO is empty when both pointers match exactly, and full when the lower bits match but their MSBs differ.

---

## Part 2: QPSK Demapper (Receiver Front-End)
The baseband demapping logic (`QPSK_rx.v`) decodes the Cartesian inputs.

### Micro-Architecture Highlights:
* **Combinational Quadrant Mapping:** Executes parallel checks on the sign bits of `sym_i` and `sym_q` to instantly map the Cartesian pair to its 2-bit representation.
* **Synchronous Byte Assembly:** Utilizes a state counter (0 to 3) to manage the shifting of the four 2-bit chunks into a holding register, assembling a complete 8-bit character before pulsing the `data_valid` flag.

---

## Part 3: Top-Level Integration (System Wrapper)
The main wrapper (`QPSK_with_FIFO.v`) unifies the Demapper and the FIFO.

### Integration Mechanics:
* **Direct Handshaking:** The 1-cycle `data_valid` output pulse from the QPSK module acts as the explicit `write_en` signal for the FIFO. Data is pushed into the memory array only when fully assembled.
* **Data Flow Decoupling:** Placing the FIFO immediately after the demapper safely decouples the unpredictable RF symbol arrival rate from the system's internal processing pace.

---

## Verification Environment
A comprehensive testbench (`QPSK_with_FIFO_tb.v`) was developed to validate functional correctness and system limits.

* **Pseudo-Random Stimulus:** Injects pre-recorded valid I/Q symbols utilizing a randomized valid-flag assertion, mimicking real-world, non-continuous RF behavior.
* **Automated Data Checking:** Demapped data is continuously monitored and decoded back into ASCII characters. The testbench verifies the payload against expected memory arrays (`QPSK_rx_tb_msgs.vh`) and dynamically prints the decoded message.
* **Backpressure & Overflow Testing:** The verification suite implements separate parameters for `IN_RATE` (data push frequency) and `OUT_RATE` (data pop frequency). This enables aggressive stress-testing of the FIFO's capacity and validates the `full_error` circuitry under heavy traffic scenarios.

---

## Simulation Setup
To run the simulation, ensure all source files and the message header file are located in the same working directory. The RTL is fully synthesizable and compatible with standard Verilog simulators (e.g., Cadence Xcelium/IRUN, ModelSim, Vivado).

Example execution using Cadence XRUN:
`xrun -sv QPSK_with_FIFO_tb.v QPSK_with_FIFO.v QPSK_rx.v FIFO.v`
