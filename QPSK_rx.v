// ============================================================================
// Module: qpsk_rx
// Description: A QPSK Hard-Decision Demapper and Symbol-to-Byte assembler.
// It takes incoming signed I and Q symbol values, extracts 2 bits per symbol
// based on their signs (quadrant mapping), and accumulates 4 consecutive 
// symbols to output a complete 8-bit data byte.
// ============================================================================
module qpsk_rx  (   
input clk,                  // System Clock                     
input reset,                // Synchronous active-high reset 
input signed [7:0] sym_i,   // Incoming In-Phase (I) symbol (soft value)   
input signed [7:0] sym_q,   // Incoming Quadrature (Q) symbol (soft value) 
input iq_valid,             // Enable flag indicating valid I/Q inputs this cycle 
output reg [7:0] data,      // Assembled 8-bit data output (1 byte = 4 QPSK symbols) 
output reg data_valid       // High for one clock cycle when a full byte is ready 
);   

// ----------------------------------------------------------------------------
// Internal State Registers
// ----------------------------------------------------------------------------
reg [1:0] counter;          // Counts from 0 to 3 to track the 4 incoming symbols
reg [5:0] temp_reg;         // Shift register to temporarily hold the first 6 bits (3 symbols)

// ----------------------------------------------------------------------------
// Main Sequential Block: Demapping and Byte Assembly
// ----------------------------------------------------------------------------
always @(posedge clk) begin
    // Synchronous Reset
    if (reset) begin
        data <= 8'b0;
        data_valid <= 1'b0;
        temp_reg <= 6'b0;
        counter <= 2'b00;
    end else begin
        // Default assignment: data is invalid unless we just finished assembling a byte
        data_valid <= 1'b0;
        
        // Only process data when the input symbols are valid
        if (iq_valid) begin
            
            // State machine based on the symbol counter
            case (counter)
            // 1st Symbol: Extract 2 bits (sign of Q, sign of I) into bits [1:0]
            2'b00: temp_reg[1:0] <= {(sym_q >= 0),(sym_i >= 0)};
            
            // 2nd Symbol: Extract 2 bits into bits [3:2]
            2'b01: temp_reg[3:2] <= {(sym_q >= 0),(sym_i >= 0)};
            
            // 3rd Symbol: Extract 2 bits into bits [5:4]
            2'b10: temp_reg[5:4] <= {(sym_q >= 0),(sym_i >= 0)};
            
            // 4th Symbol: Assembly and Output
            2'b11: begin
                // Concatenate the new 2 bits (MSB) with the stored 6 bits (LSB)
                // to form the complete 8-bit byte.
                data <= {(sym_q >= 0),(sym_i >= 0), temp_reg[5:0]};
                
                // Raise the valid flag to inform the next module that a byte is ready
                data_valid <= 1'b1;
            end
            endcase
            
            // Increment the counter to process the next symbol.
            // Wraps around from 3 (2'b11) back to 0 (2'b00) automatically.
            counter <= counter + 1'b1;
        end
    end
end 

endmodule
