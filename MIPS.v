// main module
`timescale 1ns/1ps
module MIPS();

  // inputs for loading program instructions and data
  reg [31:0] input_program [255:0];
  reg [31:0] input_data [1023:0];
  reg instruction_load, data_load;
  reg [31:0] instruction_store;
  reg [7:0] data_store;
  
    // clock for driving the circuits logic
  reg clk = 0;
  reg [8:0] clkCount = 0;
  
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
  wire [4:0] rf_rs, rf_rt, rf_rd;
  wire [5:0] control_op_code;
  wire [31:0] id_PC, id_immediate;
  assign id_PC = IF_ID[31:0];
  assign id_immediate = { {16{IF_ID[47]}}, IF_ID[47:32] };
  assign rf_rs = IF_ID[57:53];
  assign rf_rt = IF_ID[52:48];
  assign rf_rd = IF_ID[47:43];
  assign control_op_code = IF_ID[63:58];
  
  // Instruction Decode / Execution
  reg [148:0] ID_EX;
  wire ex_RegWrite, ex_MemtoReg, ex_Branch, ex_MemRead, ex_MemWrite;
  wire [1:0] ex_ALUOp;
  wire [4:0] ex_rt, ex_rd, ex_dest_reg;
  wire [5:0] ex_funct;
  wire [31:0] ex_immediate, ex_PC, ex_branch_address, ex_read_data_1, ex_read_data_2, ex_half, ex_half_unsigned, alu_a, alu_b;
  assign ex_RegWrite = ID_EX[0];
  assign ex_MemtoReg = ID_EX[1];
  assign ex_Branch = ID_EX[2];
  assign ex_MemRead = ID_EX[3];
  assign ex_MemWrite = ID_EX[4];
  assign ex_RegDst = ID_EX[5];
  assign ex_ALUOp = ID_EX[7:6];
  assign ex_ALUSrc = ID_EX[8];
  assign ex_PC = ID_EX[40:9];
  assign ex_read_data_1 = ID_EX[72:41];
  assign ex_read_data_2 = ID_EX[104:73];
  assign ex_immediate = ID_EX[136:105];
  assign ex_funct = ex_immediate[5:0];
  assign ex_rt = ID_EX[141:137];
  assign ex_rd = ID_EX[146:142];
  assign ex_branch_address = ex_PC + 2 << ex_immediate;
  assign ex_half = ID_EX[147];
  assign ex_half_unsigned = ID_EX[148];
  assign alu_a = ex_read_data_1;
  assign alu_b = ex_ALUSrc ? ex_immediate : ex_read_data_2;
  assign ex_dest_reg = ex_RegDst ? ex_rd : ex_rt;
  
  // Execution / Memory
  reg [108:0] EX_MEM;
  wire mem_RegWrite, mem_MemtoReg, mem_Branch, mem_MemRead, mem_MemWrite, mem_Zero, PCSrc;
  wire [4:0] mem_dest_reg;
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
  assign mem_dest_reg = EX_MEM[106:102];
  assign mem_half = EX_MEM[107];
  assign mem_half_unsigned = EX_MEM[108];
  assign PCSrc = mem_Branch & mem_Zero;
  
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
  assign rf_write_data = wb_MemtoReg ? wb_mem_data : wb_alu_out;
  
  // Submodules
  
  // Instruction Memory
  wire [31:0] fetched_instruction;
  
  instruction_memory instruction_memory(fetched_instruction, PC, instruction_store, instruction_load, ready, clk);
  
  // Register File
  wire [31:0] rf_read_data_1, rf_read_data_2;
  
  register_file register_file(rf_read_data_1, rf_read_data_2, rf_rs, rf_rt, rf_reg_write, rf_write_data, wb_RegWrite, clk);
  
  // Control Unit
  wire [8:0] id_control;
  wire [1:0] id_ALUOp;
  wire id_RegDst, id_ALUSrc, id_MemtoReg, id_RegWrite, id_MemRead, id_MemWrite, id_Branch, id_half, id_half_unsigned;
  assign id_RegDst = id_control[8];
  assign id_ALUSrc = id_control[7];
  assign id_MemtoReg = id_control[6];
  assign id_RegWrite = id_control[5];
  assign id_MemRead = id_control[4];
  assign id_MemWrite = id_control[3];
  assign id_Branch = id_control[2];
  assign id_ALUOp = id_control[1:0];
  
  control_unit control_unit(id_control, id_half, id_half_unsigned, control_op_code);  
  
  // ALU Control
  wire [2:0] alu_select;
  
  alu_control alu_control(alu_select, ex_ALUOp, ex_funct);
  
  // ALU
  wire [31:0] alu_out;
  wire alu_zero;
  
  alu alu(alu_out, alu_zero, alu_a, alu_b, alu_select);
  
  // Data Memory
  wire [31:0] data_mem_read_data, mem_result;
  assign mem_result = mem_half ? (mem_half_unsigned ? { {16{1'b0}}, data_mem_read_data[31:16] } : { {16{data_mem_read_data[31]}}, data_mem_read_data }) : data_mem_read_data;
  
  data_memory data_memory(data_mem_read_data, mem_alu_out, mem_read_data_2, data_store, mem_MemWrite, mem_MemRead, data_load, ready, clk);
  
  // program initialization
  reg [7:0] instruction_index; // the index of the instuction that is in input_program
  reg [8:0] instruction_input_size;
  reg [10:0] data_index; // the index of the data that is in input_program
  reg [11:0] data_input_size;
  
  initial begin
    instruction_load = 1;
    data_load = 0;
    instruction_index = 0;
    instruction_input_size = 1;
    data_index = 0;
    data_input_size = 0;
    input_program[0] = 32'h20100032; // addi $s0, $0, 50
    
    // mips initialization
    IF_ID = 0;
    ID_EX = 0;
    EX_MEM = 0;
    MEM_WB = 0;
  end
  
  // pipelining
  always @ (posedge clk)
  begin 
    if (instruction_load) begin
      instruction_store <= input_program[instruction_index];
      instruction_index <= instruction_index + 1;
      if (instruction_index == instruction_input_size) begin
        instruction_load <= 0;
        if (~data_load)
          clkCount <= clkCount + 1;
      end
    end
    
    if (data_load) begin
      data_store <= input_program[data_index];
      data_index <= data_index + 1;
      if (data_index == data_input_size) begin
        data_load <= 0;
        if (~instruction_load)
          clkCount <= clkCount + 1;
      end
    end
    
    if (ready) begin
      // Instruction Fetch Stage
      PC <= PCSrc ? mem_branch_address : PC + 4;
      clkCount <= clkCount + 1;
      IF_ID[31:0] <= PC + 4; // incremented PC value
      IF_ID[63:32] <= fetched_instruction; // fetched instruction
      
      // Instruction Decode Stage
      ID_EX[0] <= id_RegWrite;
      ID_EX[1] <= id_MemtoReg;
      ID_EX[2] <= id_Branch;
      ID_EX[3] <= id_MemRead;
      ID_EX[4] <= id_MemWrite;
      ID_EX[5] <= id_RegDst;
      ID_EX[7:6] <= id_ALUOp;
      ID_EX[8] <= id_ALUSrc;
      ID_EX[40:9] <= id_PC;
      ID_EX[72:41] <= rf_read_data_1;
      ID_EX[104:73] <= rf_read_data_2;
      ID_EX[136:105] <= id_immediate;
      ID_EX[141:137] <= rf_rt;
      ID_EX[146:142] <= rf_rd;
      ID_EX[147] <= id_half;
      ID_EX[148] <= id_half_unsigned;
      
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
      EX_MEM[106:102] <= ex_dest_reg;
      EX_MEM[107] <= ex_half;
      EX_MEM[108] <= ex_half_unsigned;
      
      // Memory Stage
      MEM_WB[0] <= mem_RegWrite;
      MEM_WB[1] <= mem_MemtoReg;
      MEM_WB[33:2] <= mem_result;
      MEM_WB[65:34] <= mem_alu_out;
      MEM_WB[70:66] <= mem_dest_reg;
      
    end
  end
  
  initial begin
    $monitor(
      "=============================================================",
      
      "\nClock Cycle %d:", clkCount,
      "\n",
      
      "\nInstruction Fetch Stage",
      "\nThis is PCSrc (binary): %b", PCSrc,
      "\nThis is PC (decimal): %d", PC,
      "\nThis is fetched_instruction (hexadecimal): %h", fetched_instruction,
      "\n",
      
      "\nInstruction Decode Stage",
      "\nThis is control_op_code (hexadecimal): %h", control_op_code,
      "\nThis is id_RegWrite (binary): %b", id_RegWrite,
      "\nThis is id_MemtoReg (binary): %b", id_MemtoReg,
      "\nThis is id_Branch (binary): %b", id_Branch,
      "\nThis is id_MemRead (binary): %b", id_MemRead,
      "\nThis is id_MemWrite (binary): %b", id_MemWrite,
      "\nThis is id_RegDst (binary): %b", id_RegDst,
      "\nThis is id_ALUOp (binary): %b", id_ALUOp,
      "\nThis is id_ALUSrc (binary): %b", id_ALUSrc,
      "\nThis is id_PC (decimal): %d", id_PC,
      "\nThis is rf_read_data_1 (decimal): %d", rf_read_data_1,
      "\nThis is rf_read_data_2 (decimal): %d", rf_read_data_2,
      "\nThis is id_immediate (decimal): %d", id_immediate,
      "\nThis is rf_rs (decimal): %d", rf_rs,
      "\nThis is rf_rt (decimal): %d", rf_rt,
      "\nThis is rf_rd (decimal): %d", rf_rd,
      "\nThis is id_half (binary): %b", id_half,
      "\nThis is id_half_unsigned (binary): %b", id_half_unsigned,
      "\n",
      
      "\nExecution Stage",
      "\nThis is ex_PC (decimal): %d", ex_PC,
      "\nThis is ex_RegWrite (binary): %b", ex_RegWrite,
      "\nThis is ex_MemtoReg (binary): %b", ex_MemtoReg,
      "\nThis is ex_Branch (binary): %b", ex_Branch,
      "\nThis is ex_MemRead (binary): %b", ex_MemRead,
      "\nThis is ex_MemWrite (binary): %b", ex_MemWrite,
      "\nThis is ex_RegDst (binary): %b", ex_RegDst,
      "\nThis is ex_ALUOp (binary): %b", ex_ALUOp,
      "\nThis is ex_ALUSrc (binary): %b", ex_ALUSrc,
      "\nThis is ex_rt (decimal): %d", ex_rt,
      "\nThis is ex_rd (decimal): %d", ex_rd,
      "\nThis is ex_dest_reg (decimal): %d", ex_dest_reg,
      "\nThis is ex_immediate (decimal): %d", ex_immediate,
      "\nThis is ex_funct (binary): %b", ex_funct,
      "\nThis is ex_branch_address (decimal): %d", ex_branch_address,
      "\nThis is ex_read_data_1 (decimal): %d", ex_read_data_1,
      "\nThis is ex_read_data_2 (decimal): %d", ex_read_data_2,
      "\nThis is alu_a (decimal): %d", alu_a,
      "\nThis is alu_b (decimal): %d", alu_b,
      "\nThis is ex_branch_address (decimal): %d", ex_branch_address,
      "\nThis is alu_zero (binary): %b", alu_zero,
      "\nThis is alu_out (decimal): %d", alu_out,
      "\nThis is ex_read_data_2 (decimal): %d", ex_read_data_2,
      "\nThis is ex_half (binary): %b", ex_half,
      "\nThis is ex_half_unsigned (binary): %b", ex_half_unsigned,
      "\n",
      
      "\nMemory Stage",
      "\nThis is mem_RegWrite (binary): %b", mem_RegWrite,
      "\nThis is mem_MemtoReg (binary): %b", mem_MemtoReg,
      "\nThis is mem_Branch (binary): %b", mem_Branch,
      "\nThis is mem_MemRead (binary): %b", mem_MemRead,
      "\nThis is mem_MemWrite (binary): %b", mem_MemWrite,
      "\nThis is mem_branch_address (decimal): %d", mem_branch_address,
      "\nThis is data_mem_read_data (decimal): %d", data_mem_read_data,
      "\nThis is mem_result (decimal): %d", mem_result,
      "\nThis is mem_Zero (binary): %b", mem_Zero,
      "\nThis is mem_alu_out (decimal): %d", mem_alu_out,
      "\nThis is mem_dest_reg (decimal): %d", mem_dest_reg,
      "\nThis is mem_read_data_2 (decimal): %d", mem_read_data_2,
      "\nThis is mem_half (binary): %b", mem_half,
      "\nThis is mem_half_unsigned (binary): %b", mem_half_unsigned,
      "\n",
      
      "\nWrite Back Stage",
      "\nThis is mem_RegWrite (binary): %b", mem_RegWrite,
      "\nThis is rf_reg_write (binary): %b", rf_reg_write,
      "\nThis is wb_MemtoReg (binary): %b", wb_MemtoReg,
      "\nThis is wb_alu_out (decimal): %d", wb_alu_out,
      "\nThis is wb_mem_data (decimal): %d", wb_mem_data,
      "\nThis is rf_write_data (decimal): %d", rf_write_data,
      
      "\n=============================================================\n"
      );
    #120 $finish; // 6 clock cycles, 1 for loading the program and 5 for execution
  end
  
endmodule