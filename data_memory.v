module data_memory(read_data, address, write_data, store, MemWrite, MemRead,load,ready, clk);
  
  output reg [31:0] read_data;
  input [31:0]address, write_data;
  input [7 : 0] store;
  input MemWrite, MemRead, load, ready, clk;
  reg [7:0]memory [1023:0];
  reg [9:0] counter;
  
  always @ (posedge clk)
    begin
      if(load)
        begin
          memory[counter] <= store;
          counter <= counter+1;
        end
      else
        begin
          if(~ready)
            begin
              $display("hello there");
            end
          else
            begin
              if(MemWrite)
                begin
                  memory[address] <= write_data;
                end
               else
                 begin
                   if(MemRead)
                     begin
                       read_data <= memory[address];
                     end
                 end   
            end
        end
    end
  
  endmodule
  