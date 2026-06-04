// ============================================================================
// Module: qpsk_with_fifo
// Description: Top-level integration module (Wrapper) that connects the 
// QPSK receiver and the synchronous FIFO. 
// It takes raw I/Q symbols, demaps them into bytes, and safely buffers 
// them so a downstream system (like a MAC layer) can read them at its own pace.
// ============================================================================
module qpsk_with_fifo (
    // ------------------------------------------------------------------------
    // System Signals
    // ------------------------------------------------------------------------
    input clk,                  // System clock shared by both RX and FIFO
    input reset,                // Synchronous active-high reset
    
    // ------------------------------------------------------------------------
    // Front-End Interface (From RF/ADC)
    // ------------------------------------------------------------------------
    input signed [7:0] sym_i,   // Incoming In-Phase (I) symbol
    input signed [7:0] sym_q,   // Incoming Quadrature (Q) symbol
    input iq_valid,             // High when valid I/Q symbols are present
    
    // ------------------------------------------------------------------------
    // Back-End Interface (To downstream processor/MAC)
    // ------------------------------------------------------------------------
    input read_en,              // Downstream requests to read a byte from FIFO
    output [7:0] data_out,      // The 8-bit byte read from the FIFO
    output empty,               // FIFO empty flag (no data to read)
    output full                 // FIFO full flag (buffer is maxed out)
);

    // ------------------------------------------------------------------------
    // Internal Interconnects (Bridges between RX and FIFO)
    // ------------------------------------------------------------------------
    // This wire carries the assembled 8-bit byte from the QPSK RX to the FIFO.
    wire [7:0] internal_data;
    
    // This wire carries the 1-cycle valid pulse from the QPSK RX.
    // Crucially, it acts as the 'write_en' (push) signal for the FIFO.
    wire internal_valid;

    // ------------------------------------------------------------------------
    // Instance 1: QPSK Receiver (The Demapper)
    // ------------------------------------------------------------------------
    // Responsible for taking the 4 pairs of I/Q symbols and packing them 
    // into a single 8-bit byte.
    qpsk_rx u_rx (
        .clk(clk),
        .reset(reset),
        .sym_i(sym_i),
        .sym_q(sym_q),
        .iq_valid(iq_valid),
        .data(internal_data),       // Output: Assembled byte connects to internal wire
        .data_valid(internal_valid) // Output: Valid pulse connects to internal wire
    );

    // ------------------------------------------------------------------------
    // Instance 2: Synchronous FIFO (The Buffer)
    // ------------------------------------------------------------------------
    // Responsible for safely storing the assembled bytes until the downstream
    // system is ready to read them (Elastic buffering).
    fifo #(
        .FIFO_DEPTH(16),            // FIFO can hold up to 16 bytes
        .FIFO_WIDTH(8)              // Each entry is 8 bits wide
    ) u_fifo (
        .clk(clk),
        .reset(reset),
        
        // Write port connected directly to the QPSK RX outputs
        .write_en(internal_valid),  // Writes to FIFO only when RX says data is valid
        .data_in(internal_data),    // The actual byte to write
        
        // Read port connected to the outside world
        .read_en(read_en),
        .empty(empty),
        .full(full),
        .data_out(data_out)
    );

endmodule
