

module fifo_tb() ;

localparam SUM_OF_STUDENTS_ID = 212291215 + 209020825 ;  // Please Update to your actual ID numbers

localparam FIFO_DEPTH = 16 + SUM_OF_STUDENTS_ID % 16 ;   // Some Value between 16 and 32
localparam FIFO_WIDTH = 8 + SUM_OF_STUDENTS_ID % 8 ;     // Some Value between 8 and 16 bits

localparam HALF_PERIOD = 5 ;      // Half of cycle time period in time units
localparam NUM_CYCLES = 1000 ;    // number of cycles in test
localparam SIM_TIME = NUM_CYCLES*2*HALF_PERIOD ;  // stop simulation after parametrized SIM_TIME


localparam TB_MEM_DEPTH = NUM_CYCLES ;             // To accommodate worst case of access per cycle
localparam MEM_PTR_WIDTH = $clog2(TB_MEM_DEPTH);   // the number of pointer bits needed 


reg  [FIFO_WIDTH-1:0]  src_mem [TB_MEM_DEPTH-1:0] ; // Testbench source memory
reg  [FIFO_WIDTH-1:0]  dst_mem [TB_MEM_DEPTH-1:0] ; // Testbench destination memory


reg  clk;                            // Clock
reg  reset;                          // Reset
wire read_en;                        // Read enable
wire write_en;                       // Write enable                  
wire empty;                          // FIFO empty indication
wire full;                           // FIFO full indication

wire [FIFO_WIDTH-1:0] data_in;       // FIFO Output Data   
wire [FIFO_WIDTH-1:0] data_out;      // FIFO Output Data 

reg [MEM_PTR_WIDTH-1:0] src_ptr;     // source memory pointer
reg [MEM_PTR_WIDTH-1:0] dst_ptr;     // destination memory pointer

reg rand_write_en  ;  
reg rand_read_en  ;
reg capture_read ;


// Instantiate the FIFO
fifo #(.FIFO_DEPTH(FIFO_DEPTH),.FIFO_WIDTH(FIFO_WIDTH)) i_fifo (
  .clk       (clk),                            
  .reset     (reset),                       
  .read_en   (read_en),                      
  .write_en  (write_en),                     
  .data_in   (data_in),                               
  .empty     (empty),                        
  .full      (full),                         
  .data_out  (data_out));

  integer i ; // local loop index and random value
  
  initial begin   // Testbench Wakeup setup
  
     $display("\n\n HELLO FIFO EXERCISE, SUM_OF_STUDENTS_ID =%d\n\n",SUM_OF_STUDENTS_ID); 
     
     // initialize the source memory with random data     
     for (i=0;i<TB_MEM_DEPTH;i=i+1) src_mem[i] = $random%(2**FIFO_WIDTH) ;
          
     clk = 1;                                   // Initialize clk
     reset = 1;                                 // Assert Reset
     src_ptr = 0 ;                              // Test Pointers initialization
     dst_ptr = 0 ;
     capture_read = 0 ;
     #40 reset = 0;                             // De-assert Reset after 10 time units	  
  	 #SIM_TIME begin                           // stop simulation and check results after parametrized SIM_TIME
      // Check that destination memory is same as source memory
       for (i=0;i<dst_ptr;i=i+1) 
         if (src_mem[i]==dst_mem[i])
           $display("src_mem[%4d] = dst_mem[%4d] = %8d ; PASS",i,i,src_mem[i]) ;
         else begin 
           $display("src_mem[%4d] = %8d , dst_mem[%4d] = %8d ; FAIL",i,src_mem[i],i,dst_mem[i]) ; 
           $finish ;           
         end
       $finish ;
     end      
     
  end
  
  always #HALF_PERIOD clk = !clk ;  // Toggle the clk forever every Half period
 
  // Handle Write
 
  // randomly write on average every 10th cycle   
  always @(posedge clk) 
    if (reset) rand_write_en <= 0 ; 
    else rand_write_en <= ($random%10==0) ;
  
  assign write_en = rand_write_en & !full ;
  assign data_in = src_mem[src_ptr] ; 
  
  always @(posedge clk) 
    if (write_en) src_ptr <= src_ptr + 1 ;
  
   
  // Handle Read
   
  // randomly issue read from fifo on average every 10th cycle 
  always @(posedge clk) 
    if (reset) rand_read_en <= 0 ; else rand_read_en <= ($random%10==0) ;
    
  assign read_en = rand_read_en & !empty ;


  // data from fifo will come one cycle after read_en is asserted     
  always @(posedge clk) capture_read <= read_en ; 
      
            
  // Testbench Capture Read from FIFO handling
  always @(posedge clk)
     if (capture_read) begin       
       dst_mem[dst_ptr] = data_out ; // capture read
       dst_ptr <= dst_ptr + 1 ;        
     end      

  
 
endmodule


