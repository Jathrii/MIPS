module instruction_memory(instruction, address, store, load, ready, clk);
  
  output [31:0] instruction;
  input[31:0] address, store;
  input clk, ready, load;
  reg [7:0] memory [1023:0];
  reg [9:0] counter = -4;
  
  assign instruction = ready ? {memory[address],memory[address + 1],memory[address + 2],memory[address + 3]} : 'bx;
  
  always @(posedge clk)
    begin
      if(load)
        begin
          memory[counter] <= store[31:24];
          memory[counter+1] <= store[23:16];
          memory[counter+2] <= store[15:8];
          memory[counter+3] <= store[7:0];
          counter <= counter + 4;
        end
    end

endmodule