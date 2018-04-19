module control_unit(out, half, half_unsigned, instruction);

  input [5:0] instruction;

  // OUTPUT = regDst ALUsrc memtoReg regWrite memRead memWrite branch ALUop[1:0] 

  output reg half, half_unsigned; // signals for lh and lhu
  output reg [8:0] out;

  parameter [8:0] regDst = 9'b100000000;
  parameter [8:0] ALUsrc = 9'b010000000;
  parameter [8:0] memtoReg = 9'b001000000;
  parameter [8:0] regWrite = 9'b000100000;
  parameter [8:0] memRead = 9'b000010000;
  parameter [8:0] memWrite = 9'b000001000;
  parameter [8:0] branch = 9'b000000100;
  parameter [8:0] R_typeALU = 9'b0000001x;
  parameter [8:0] branchALU = 9'b00000001;


  always @(instruction)
  begin
    case(instruction)
      6'b000000 : out <= regDst | regWrite | R_typeALU ; // R-type
    	6'b001000 : out <= ALUsrc | regWrite;                      // addi
    	6'b100011 : out <= ALUsrc | memtoReg | regWrite | memRead; // lw
    	6'b101011 : out <= 9'bx0x000000 | ALUsrc | memWrite ; // sw
    	6'b000100 : out <= 9'bx0x000000 | branch | branchALU; // beq
      6'b100001 : out <= 9'bx0x000000 | ALUsrc | memWrite ; // lh
      6'b100101 : out <= 9'bx0x000000 | ALUsrc | memWrite ; // lhu
    endcase
    
    if (instruction == 6'b100001) begin // lh
      half <= 1;
      half_unsigned <= 0;
    end
    else if (instruction == 6'b100101) begin // lhu
      half <= 1;
      half_unsigned <= 1;
    end
    else begin
      half <= 0;
      half_unsigned <= 0;
    end
  end

endmodule
