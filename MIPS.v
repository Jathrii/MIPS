// main module
`timescale 1ns/1ps
module MIPS(instruction_load, data_load, instruction_store, data_store, ready);

  // inputs for loading program instructions and data
  input instruction_load, data_load, ready;
  input [31:0] instruction_store;
  input [7:0] data_store;
  
    // clock for driving the circuits logic
  reg clk = 0;
  
  // generating the clock
  always #10 clk = ~clk;
  
  // flag to indicate that loading is done
  wire ready;
  assign ready = ~(instruction_load | data_load);

  // program counter
  reg [31:0] PC = 0;
  
  // pipeline registers
  
  // Instruction Fetch / Instruction Decode
  reg [63:0] IF_ID;
  wire [4:0] rf_rs, rf_rt, id_rd;
  wire [5:0] control_op_code;
  wire [31:0] id_PC, id_immediate;
  assign id_PC = IF_ID[31:0];
  assign id_immediate = { {16{IF_ID[47]}}, IF_ID[47:32] };
  assign rf_rs = IF_ID[57:53];
  assign rf_rt = IF_ID[52:48];
  assign rf_rd = IF_ID[47:43];
  assign control_op_code = IF_ID[63:58];
  
  // Instruction Decode / Execution
  reg [145:0] ID_EX;
  wire ex_RegWrite, ex_MemtoReg, ex_Branch, ex_MemRead, ex_MemWrite;
  wire [4:0] ex_rt, ex_rd, ex_dest_reg;
  wire [5:0] ex_funct;
  wire [31:0] ex_immediate, ex_PC, ex_branch_address, ex_read_data_1, ex_read_data_2, alu_a, alu_b;
  assign ex_RegWrite = ID_EX[0];
  assign ex_MemtoReg = ID_EX[1];
  assign ex_Branch = ID_EX[2];
  assign ex_MemRead = ID_EX[3];
  assign ex_MemWrite = ID_EX[4];
  assign ex_RegDst = ID_EX[5];
  assign ex_ALUOp = ID_EX[6];
  assign ex_ALUSrc = ID_EX[7];
  assign ex_PC = ID_EX[39:8];
  assign ex_immediate = ID_EX[135:104];
  assign ex_funct = ex_immediate[5:0];
  assign ex_rt = ID_EX[140:136];
  assign ex_rd = ID_EX[145:141];
  assign ex_branch_address = ex_PC + 2 << ex_immediate;
  assign ex_read_data_1 = ID_EX[71:40];
  assign ex_read_data_2 = ID_EX[103:72];
  assign alu_a = ex_read_data_1;
  assign alu_b = ex_ALUSrc ? ex_immediate : ex_read_data_2;
  assign ex_dst_reg = ex_RegDst ? ex_rd : ex_rt;
  
  // Execution / Memory
  reg [106:0] EX_MEM;
  wire mem_RegWrite, mem_MemtoReg, mem_Branch, mem_MemRead, mem_MemWrite, mem_Zero, mem_PCSrc;
  wire [4:0] mem_dst_reg;
  wire [31:0] mem_branch_address, mem_alu_out, mem_read_data_2;
  assign mem_RegWrite = EX_MEM[0];
  assign mem_MemtoReg = EX_MEM[1];
  assign mem_Branch = EX_MEM[2];
  assign mem_MemRead = EX_MEM[3];
  assign mem_MemWrite = EX_MEM[4];
  assign mem_branch_address = EX_MEM[36:5];
  assign mem_Zero = EX_MEM[37];
  assign mem_alu_out = EX_MEM[69:38];
  assign mem_read_data_2 = EX_MEM[101:70];
  assign mem_dst_reg = EX_MEM[106:102];
  assign mem_PCSrc = mem_Branch & mem_Zero;
  
  // Memory / Writeback
  reg [70:0] MEM_WB;
  wire wb_RegWrite, wb_MemtoReg;
  wire [4:0] rf_reg_write;
  wire [31:0] rf_write_data, wb_mem_data, wb_alu_out;
  assign wb_RegWrite = MEM_WB[0];
  assign wb_MemtoReg = MEM_WB[1];
  assign wb_mem_data = MEM_WB[33:2];
  assign wb_alu_out = MEM_WB[65:34];
  assign rf_reg_write = MEM_WB[70:66]; // wb_dst_reg
  assign rf_write_data = wb_MemtoReg ? wb_alu_out : wb_mem_data;
  
  // Submodules
  
  // Instruction Memory
  wire fetched_instruction;
  
  instruction_memory(fetched_instruction, PC, instructio_store, instruction_load, ready, clk);
  
  // Register File
  wire [31:0] rf_read_data_1, rf_read_data_2;
  
  register_file(rf_read_data_1, rf_read_data_2, rf_rs, rf_rt, rf_reg_write, rf_write_data, wb_RegWrite, clk);
  
  // Control Unit
  wire [8:0] id_control;
  wire [1:0] id_ALUOp;
  wire id_RegDst, id_ALUSrc, id_MemtoReg, id_RegWrite, id_MemRead, id_MemWrite, id_Branch;
  assign id_RegDst = id_control[8];
  assign id_ALUSrc = id_control[7];
  assign id_MemtoReg = id_control[6];
  assign id_RegWrite = id_control[5];
  assign id_MemRead = id_control[4];
  assign id_MemWrite = id_control[3];
  assign id_Branch = id_control[2];
  assign id_ALUOp = id_control[1:0];
  
  control_unit control_unit(id_control, control_op_code, clk);  
  
  // ALU Control
  wire [2:0] alu_select;
  alu_control alu_control(alu_select, ex_ALUOp, ex_funct);
  
  // ALU
  wire [31:0] alu_out;
  wire alu_zero;
  
  alu alu(alu_out, alu_zero, alu_a, alu_b, alu_select);
  
  // Data Memory
  wire [31:0] data_mem_read_data;
  data_memory data_memory(data_mem_read_data, mem_alu_out, mem_read_data_2, data_store, mem_MemWrite, mem_MemRead, data_load, ready, clk);
  
  // pipelining
  always @ (posedge clk)
  begin
    if (ready) begin
      // Instruction Fetch Stage
      PC <= mem_PCSrc ? mem_branch_address : PC + 4;
      IF_ID[31:0] <= PC + 4; // incremented PC value
      IF_ID[63:32] <= fetched_instruction; // fetched instruction
      
      // Instruction Decode Stage
      ID_EX[0] <= id_RegWrite;
      ID_EX[1] <= id_MemtoReg;
      ID_EX[2] <= id_Branch;
      ID_EX[3] <= id_MemRead;
      ID_EX[4] <= id_MemWrite;
      ID_EX[5] <= id_RegDst;
      ID_EX[6] <= id_ALUOp;
      ID_EX[7] <= id_ALUSrc;
      ID_EX[39:8] <= id_PC;
      ID_EX[71:40] <= rf_read_data_1;
      ID_EX[103:72] <= rf_read_data_2;
      ID_EX[135:104] <= id_immediate;
      ID_EX[140:136] <= rf_rt;
      ID_EX[145:141] <= rf_rd;
      
      // Execute Stage
      EX_MEM[0] <= ex_RegWrite;
      EX_MEM[1] <= ex_MemtoReg;
      EX_MEM[2] <= ex_Branch;
      EX_MEM[3] <= ex_MemRead;
      EX_MEM[4] <= ex_MemWrite;
      EX_MEM[36:5] <= ex_branch_address;
      EX_MEM[37] <= alu_zero;
      EX_MEM[69:38] <= alu_out;
      EX_MEM[101:70] <= ex_read_data_2;
      EX_MEM[106:102] <= ex_dst_reg;
      
      // Memory Stage
      MEM_WB[0] <= mem_RegWrite;
      MEM_WB[1] <= mem_MemtoReg;
      MEM_WB[33:2] <= data_mem_read_data;
      MEM_WB[65:34] <= mem_alu_out;
      MEM_WB[70:66] <= mem_dst_reg;
      
    end
  end
  
endmodule