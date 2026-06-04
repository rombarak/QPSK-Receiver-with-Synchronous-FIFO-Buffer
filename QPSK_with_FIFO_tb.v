
module qpsk_with_fifo_tb ();    // simple counter test-bench 

  localparam SUM_OF_STUDENTS_ID = 209020825 + 212291215 ;  // Please Update to your actual ID numbers
  localparam MSG_IDX = (SUM_OF_STUDENTS_ID+5) % 10;            // Don't touch calculating personalized message index (between 0 and 9)
  
  localparam OUT_RATE = 2 ;
  localparam IN_RATE = 3;  
  
  
  reg clk ;                     // Testbench clk
  reg reset ;                     // Testbench reset
   
  reg signed [7:0] sym_i;      // DUT Symbol input I value (scaled to 0-255)  
  reg signed [7:0] sym_q;      // DUT Symbol inpit Q value (scaled to 0-255)
  reg iq_valid;         // DUT I,Q symbol inputs are valid
                        
  wire [7:0] data_out;      // DUT demapped data out 'charterer' (out of 4 symbols)
  wire data_out_valid;       // DUT fata out valid

localparam MAX_MSG_LENGTH = 40 ; 
localparam NUM_MSGS = 10 ;   
     
reg [(MAX_MSG_LENGTH*4*8)-1:0] qpsk_msg_i [NUM_MSGS-1:0] ;
reg [(MAX_MSG_LENGTH*4*8)-1:0] qpsk_msg_q [NUM_MSGS-1:0] ;

reg rand_read_en  ;
reg capture_read ;

wire full_error ;

initial begin  
`include "qspk_rx_tb_msgs.vh"
end
    
qpsk_with_fifo i_qpsk_with_fifo (   

     // Symbols Interface   
     .clk        (clk           ),     
     .reset      (reset         ),
     .sym_i      (sym_i         ),
     .sym_q      (sym_q         ),
     .iq_valid   (iq_valid      ),

     // data Interface
     .read_en    (read_en),                      
     .empty      (empty),                        
     .full       (full_error),                         
     .data_out   (data_out      )
    
);

    
  initial begin   // Testbench Wakeup setup
  
        $display("\n\nTESTING QPSK_RX, SUM_OF_STUDENTS_ID =%d\n",SUM_OF_STUDENTS_ID) ; 
        clk = 1;                  // Initialize clk
        reset = 1;                  // Assert Reset
        #20 reset = 0;              // De-assert Reset after 10 iq_idxime units	  
        
        $write("\n\nQPSK RECIVED TEXT MESSAGE: \n\n");
  end
  
  always #5 clk = !clk ;  // Toggle the clk forever every 5 time units
  
  integer iq_idx = 0 ;
  integer sym_idx = 0 ;
  
  always @(posedge clk)
   if(($random%IN_RATE)&&!reset) begin // transfer a symbol on average one per 3 cycles
     sym_i <= qpsk_msg_i[MSG_IDX][(sym_idx*8)+7 -: 8] ;
     sym_q <= qpsk_msg_q[MSG_IDX][(sym_idx*8)+7 -: 8] ;      
     iq_valid <= 1 ;
     sym_idx = sym_idx+1 ;     
   end else  iq_valid <= 0 ;    


 // Handle Read
   
  // randomly issue read from fifo on average once every 2 cycles 
  always @(posedge clk) 
    if (reset) rand_read_en <= 0 ; else rand_read_en <= ($random%OUT_RATE==0) ; 
    
  assign read_en = rand_read_en & !empty ;

  // data from fifo will come one cycle after read_en is asserted     
  always @(posedge clk) capture_read <= read_en ; 
   

  always @(posedge clk)   
   if (capture_read) begin
    if ((data_out<128) && (data_out>0))
      $write("%c",data_out) ; // display character  
    else begin
      if ((data_out==8'd0)||(data_out==8'hff)) begin
       $display("\n\n\n");
      $finish;
      end
      $write("\nERROR: NON-TEXT CHARCHTER ASCII CODE hex %-2X, QUITTING\n\n", data_out);
      $finish  ;    
    end
   end
  
  always @(posedge clk) 
   if (full_error) begin
      $display("\n\nERROR: FIFO Full Error Reduce FIFO read rate in the Testbench, or Increase Fifo Size\n\n");
      $finish ;
   end else if  (sym_idx==MAX_MSG_LENGTH*4*8) 
       $finish ;
   
endmodule 
