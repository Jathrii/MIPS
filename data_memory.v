module data_memory(read_data, address, write_data, store, MemWrite, MemRead, load, ready, clk);
  
  output [31:0] read_data;
  input [31:0]address, write_data;
  input [7:0] store;
  input MemWrite, MemRead, load, ready, clk;
  reg [7:0]memory [1023:0];
  reg [9:0] counter = -1;
  
  assign read_data = ready ? (MemRead ? {memory[address],memory[address + 1],memory[address + 2],memory[address + 3]} : 'bx) : 'bx;
  
  always @ (posedge clk)
  begin
    if(load) begin
      memory[counter] <= store;
      counter <= counter+1;
    end
    else if(ready && MemWrite) begin
      memory[address] <= write_data[31:24];
      memory[address+1] <= write_data[23:16];
      memory[address+2] <= write_data[15:8];
      memory[address+3] <= write_data[7:0];
    end
  end
  
endmodule