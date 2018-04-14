module instruction_memory(instruction, address,store,load,ready,clk);
  
  output reg [31:0] instruction;
  input[31:0]address,store;
  input clk,ready,load;
  reg [7:0]memory [1023:0];
  reg [9:0] counter;
  
  always @(posedge clk)
    begin
      if(load)
        begin
          memory[counter]<=store[7:0];
          memory[counter+1]<=store[15:8];
          memory[counter+2]<=store[23:16];
          memory[counter+3]<=store[31:24];
          counter<=counter+4;
         end
      else
        begin
          if(~ready)
            begin
              $display("hello there");
            end
          else
            begin
               instruction<=memory[address];
            end
        end
    end

endmodule