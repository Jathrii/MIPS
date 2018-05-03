module data_memory(read_data, address, write_data, store, MemWrite, MemRead, load, ready, clk);
  
  output [31:0] read_data;
  input [31:0]address, write_data;
  input [7:0] store;
  input MemWrite, MemRead, load, ready, clk;
  reg [7:0]memory [1023:0];
  reg [9:0] counter = -1;
  
  assign read_data = ready ? (MemRead ? memory[address] : 'bx) : 'bx;
  
  always @ (posedge clk)
  begin
    if(load) begin
      memory[counter] <= store;
      counter <= counter+1;
    end
    else if(ready && MemWrite)
      memory[address] <= write_data;
  end
  
endmodule