module control_unit(out, instruction, clk);

  // OUTPUT = regDst ALUsrc memtoReg regWrite memRead memWrite branch ALUop[1:0] 
  input clk;
  input [5:0] instruction;

  output [8:0] out;

  always @(instruction)
  begin
    case(instruction)
      6'b000000 : out <= 9'b10010001x; // R-type
    	6'b001000 : out <= 9'b010100000; // addi
    	6'b100011 : out <= 9'b011110000; // lw
    	6'b101011 : out <= 9'bx1x001000; // sw
    	6'b000100 : out <= 9'bx0x000101; // beq
    endcase
  end

endmodule