module qpsk_rx_tb ();    // Basic Testbench for the QPSK receiver

  // ----------------------------------------------------------------------------
  // Parameter and personal ID definitions
  // ----------------------------------------------------------------------------
  localparam SUM_OF_STUDENTS_ID = 987654321 + 987654321 ;  // Please update to your actual ID numbers
  localparam MSG_IDX = SUM_OF_STUDENTS_ID % 10;            // Do not touch - calculates the personal message index (between 0 and 9)
  
  // ----------------------------------------------------------------------------
  // Control signals definition (wires and registers of the testbench)
  // ----------------------------------------------------------------------------
  reg clk ;                     // Testbench clock
  reg reset ;                   // Testbench reset signal
   
  reg signed [7:0] sym_i;       // I input value of the tested module (represents a signed number)
  reg signed [7:0] sym_q;       // Q input value of the tested module (represents a signed number)
  reg iq_valid;                 // Flag indicating that the I,Q coordinates are valid in the current clock cycle
                        
  wire [7:0] data;              // Data output from the module - a byte-sized character (composed of 4 symbols)
  wire data_valid;              // Output flag from the module indicating the data byte is ready and valid

  // ----------------------------------------------------------------------------
  // Definition of memory arrays to hold the test vectors (recorded messages)
  // ----------------------------------------------------------------------------
  localparam MAX_MSG_LENGTH = 40 ; // Maximum message length (40 characters)
  localparam NUM_MSGS = 10 ;       // Number of available messages in the repository
       
  // 2D arrays to hold the bit sequence of the I and Q signals for all 10 messages
  reg [(MAX_MSG_LENGTH*4*8)-1:0] qpsk_msg_i [NUM_MSGS-1:0] ;
  reg [(MAX_MSG_LENGTH*4*8)-1:0] qpsk_msg_q [NUM_MSGS-1:0] ;

  // Loading data from an external file into the arrays during initialization
  initial begin  
    `include "qspk_rx_tb_msgs.vh"
  end
      
  // ----------------------------------------------------------------------------
  // Connecting the tested module (DUT Instantiation)
  // ----------------------------------------------------------------------------
  qpsk_rx i_qpsk_rx(   
       .clk        (clk           ),     
       .reset      (reset         ),
       .sym_i      (sym_i         ),
       .sym_q      (sym_q         ),
       .iq_valid   (iq_valid      ),
       .data       (data          ),
       .data_valid (data_valid    )     
  );

  // ----------------------------------------------------------------------------
  // System initialization and clock generation block
  // ----------------------------------------------------------------------------
  initial begin   
        $display("\n\nTESTING QPSK_RX, SUM_OF_STUDENTS_ID =%d\n",SUM_OF_STUDENTS_ID) ; 
        clk = 1;                    // Initialize clock to high state
        reset = 1;                  // Activate reset (active state)
        #20 reset = 0;              // Deactivate reset after 20 time units (exactly 2 full clock cycles)   
        
        $write("\n\nQPSK RECIVED TEXT MESSAGE: \n\n");
  end
  
  always #5 clk = !clk ;  // Toggle clock state every 5 time units (creates a frequency with a period of 10)
  
  integer iq_idx = 0 ;
  integer sym_idx = 0 ;   // Counter to track the number of transmitted symbols
  
  // ----------------------------------------------------------------------------
  // Data injection mechanism (Stimulus Generation)
  // ----------------------------------------------------------------------------
  always @(posedge clk)
   // Using a random function to transmit a symbol only in some clock cycles (simulates non-continuous timing)
   if(($random%3)&&!reset) begin 
     // Extracting 8 specific bits from the long data sequence in the array, according to the current index
     sym_i <= qpsk_msg_i[MSG_IDX][(sym_idx*8)+7 -: 8] ;
     sym_q <= qpsk_msg_q[MSG_IDX][(sym_idx*8)+7 -: 8] ;      
     iq_valid <= 1 ;         // Signaling the module that the data is valid this clock cycle
     sym_idx = sym_idx+1 ;   // Incrementing the counter to the next symbol
   end else  
     iq_valid <= 0 ;         // Resetting the flag in cycles where no new data is transmitted

  // ----------------------------------------------------------------------------
  // Output verification mechanism (Monitor & Checker)
  // ----------------------------------------------------------------------------
  always @(posedge clk)   
   if (data_valid) begin // Waiting for the flag from the module indicating the data byte is ready
    if ((data<128) && (data>0))
      $write("%c",data) ; // If it's a valid ASCII character, print it as text to the screen  
    else begin
      // If a value of 0 or 0xFF is received, it marks the end of the message and the simulation should finish successfully
      if ((data==8'd0)||(data==8'hff)) begin
       $display("\n\n\n");
      $finish;
      end
      // If an invalid character is received, print an error message and stop the simulation
      $write($time,"\nERROR: NON-TEXT CHARCHTER ASCII CODE hex %-2X, QUITTING\n\n", data);
      $finish  ;    
    end
   end
  
  // ----------------------------------------------------------------------------
  // Safety and stop mechanism (Timeout)
  // ----------------------------------------------------------------------------
  always @(posedge clk)  
   // If all possible symbols have been sent (reaching maximum message length), finish the simulation
   if   (sym_idx==MAX_MSG_LENGTH*4*8) 
       $finish ;
   
endmodule
