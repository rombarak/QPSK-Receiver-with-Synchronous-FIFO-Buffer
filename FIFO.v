module fifo #(parameter FIFO_DEPTH=16 , FIFO_WIDTH=8) (
 input clk, // Clock
 input reset, // Reset

 // Write Port

 input write_en, // Write enable
 input [FIFO_WIDTH-1:0] data_in, // FIFO Input Data
 output empty, // FIFO empty indication

 // Read Port

 input read_en, // Read enable
 output full, // FIFO full indication
 output reg [FIFO_WIDTH-1:0] data_out // FIFO Output Data
); 
parameter PTR_WIDTH = $clog2(FIFO_DEPTH);
reg [FIFO_WIDTH-1:0] mem_array [0:FIFO_DEPTH-1];
reg [PTR_WIDTH:0] rd_ptr ;
reg [PTR_WIDTH:0] wr_ptr ;
integer i;
always @(posedge clk) begin
    if (reset) begin
        rd_ptr <= 0;
        wr_ptr <= 0;
        data_out <= 0; 
         for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
            mem_array[i] <= 0;
         end

    end
    else begin 

        if (write_en && !full) begin
            mem_array[wr_ptr[PTR_WIDTH-1:0]] <= data_in;

            if (wr_ptr[PTR_WIDTH-1:0] == FIFO_DEPTH - 1)
                wr_ptr <= {~wr_ptr[PTR_WIDTH], {PTR_WIDTH{1'b0}}};
            else
                wr_ptr <= wr_ptr + 1;
        end

        if (read_en && !empty) begin
            data_out <= mem_array[rd_ptr[PTR_WIDTH-1:0]];

            if (rd_ptr[PTR_WIDTH-1:0] == FIFO_DEPTH - 1)
                rd_ptr <= {~rd_ptr[PTR_WIDTH], {PTR_WIDTH{1'b0}}};
            else
                rd_ptr <= rd_ptr + 1;
        end
    end
end
assign empty = (rd_ptr==wr_ptr);
assign full = (wr_ptr[PTR_WIDTH] != rd_ptr [PTR_WIDTH]) && (wr_ptr[PTR_WIDTH-1:0] == rd_ptr [PTR_WIDTH-1:0]);

endmodule
