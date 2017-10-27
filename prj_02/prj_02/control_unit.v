// Name: control_unit.v
// Module: CONTROL_UNIT
// Output: RF_DATA_W  : Data to be written at register file address RF_ADDR_W
//         RF_ADDR_W  : Register file address of the memory location to be written
//         RF_ADDR_R1 : Register file address of the memory location to be read for RF_DATA_R1
//         RF_ADDR_R2 : Registere file address of the memory location to be read for RF_DATA_R2
//         RF_READ    : Register file Read signal
//         RF_WRITE   : Register file Write signal
//         ALU_OP1    : ALU operand 1
//         ALU_OP2    : ALU operand 2
//         ALU_OPRN   : ALU operation code
//         MEM_ADDR   : Memory address to be read in
//         MEM_READ   : Memory read signal
//         MEM_WRITE  : Memory write signal
//
// Input:  RF_DATA_R1 : Data at ADDR_R1 address
//         RF_DATA_R2 : Data at ADDR_R1 address
//         ALU_RESULT    : ALU output data
//         CLK        : Clock signal
//         RST        : Reset signal
//
// INOUT: MEM_DATA    : Data to be read in from or write to the memory
//
// Notes: - Control unit synchronize operations of a processor
//
// Revision History:
//
// Version	Date		Who		email			note
//------------------------------------------------------------------------------------------
//  1.0     Sep 10, 2014	Kaushik Patra	kpatra@sjsu.edu		Initial creation
//  1.1     Oct 19, 2014        Kaushik Patra   kpatra@sjsu.edu         Added ZERO status output
//------------------------------------------------------------------------------------------
`include "prj_definition.v"
module CONTROL_UNIT(MEM_DATA, RF_DATA_W, RF_ADDR_W, RF_ADDR_R1, RF_ADDR_R2, RF_READ, RF_WRITE,
                    ALU_OP1, ALU_OP2, ALU_OPRN, MEM_ADDR, MEM_READ, MEM_WRITE,
                    RF_DATA_R1, RF_DATA_R2, ALU_RESULT, ZERO, CLK, RST);

// Output signals
// Outputs for register file
output [`DATA_INDEX_LIMIT:0] RF_DATA_W;
output [`REG_ADDR_INDEX_LIMIT:0] RF_ADDR_W, RF_ADDR_R1, RF_ADDR_R2; //[`ADDRESS_INDEX_LIMIT:0], wrong bit-length?
output RF_READ, RF_WRITE;
// Outputs for ALU
output [`DATA_INDEX_LIMIT:0]  ALU_OP1, ALU_OP2;
output  [`ALU_OPRN_INDEX_LIMIT:0] ALU_OPRN;
// Outputs for memory
output [`ADDRESS_INDEX_LIMIT:0]  MEM_ADDR;
output MEM_READ, MEM_WRITE;

// Input signals
input [`DATA_INDEX_LIMIT:0] RF_DATA_R1, RF_DATA_R2, ALU_RESULT;
input ZERO, CLK, RST;

// Inout signal
inout [`DATA_INDEX_LIMIT:0] MEM_DATA;

// State nets
wire [2:0] proc_state;

PROC_SM state_machine(.STATE(proc_state),.CLK(CLK),.RST(RST)); //instantiate State_Machine

//========Registers=============
//Output Registers
//Outputs for register file
reg [`DATA_INDEX_LIMIT:0] RF_DATA_W_reg;
reg [`REG_ADDR_INDEX_LIMIT:0] RF_ADDR_W_reg, RF_ADDR_R1_reg, RF_ADDR_R2_reg;
reg RF_READ_reg, RF_WRITE_reg;
//Outputs for ALU
reg [`DATA_INDEX_LIMIT:0]  ALU_OP1_reg, ALU_OP2_reg;
reg  [`ALU_OPRN_INDEX_LIMIT:0] ALU_OPRN_reg;
//Outputs for memory
reg [`ADDRESS_INDEX_LIMIT:0]  MEM_ADDR_reg;
reg MEM_READ_reg, MEM_WRITE_reg;
//Register for writing out data. Assign to Inout MEM_DATA when WRITE
reg [`DATA_INDEX_LIMIT:0] MEM_DATA_reg;
//========Outputs assignments======
//Outputs for register file
assign RF_DATA_W = RF_DATA_W_reg;
assign RF_ADDR_W = RF_ADDR_W_reg; assign RF_ADDR_R1 = RF_ADDR_R1_reg; assign RF_ADDR_R2 = RF_ADDR_R2_reg;
assign RF_READ = RF_READ_reg; assign RF_WRITE = RF_WRITE_reg;
//Outputs for ALU
assign ALU_OP1 = ALU_OP1_reg; assign ALU_OP2 = ALU_OP2_reg;
assign ALU_OPRN = ALU_OPRN_reg;
//Outputs for memory
assign MEM_ADDR = MEM_ADDR_reg;
assign MEM_READ = MEM_READ_reg; assign MEM_WRITE = MEM_WRITE_reg;
//Register for writing out data. Assign to Inout MEM_DATA when WRITE
assign MEM_DATA = ((MEM_READ===1'b0)&&(MEM_WRITE===1'b1))?MEM_DATA_reg:{`DATA_WIDTH{1'bz} };
//==================================
//Internal Register
reg [`ADDRESS_INDEX_LIMIT:0] PC_REG;
reg [`DATA_INDEX_LIMIT:0] INST_REG;
reg [`ADDRESS_INDEX_LIMIT:0] SP_REG;
reg [5:0] opcode;
reg [4:0] rs;
reg [4:0] rt;
reg [4:0] rd;
reg [4:0] shamt;
reg [5:0] funct;
reg [15:0] immediate;
reg [25:0] address;
reg [`DATA_INDEX_LIMIT:0] SIGN_EXT;
reg [`DATA_INDEX_LIMIT:0] ZERO_EXT;
reg [`DATA_INDEX_LIMIT:0] LUI;
reg [`DATA_INDEX_LIMIT:0] JMP_ADDR;


always @ (proc_state)
begin
  //Addr<=PC; R<=1; W<=0; RegRW<=00||11
  if (proc_state === `PROC_FETCH)
  begin
    MEM_ADDR_reg = PC_REG;
    MEM_READ_reg = 1'b1; MEM_WRITE_reg = 1'b0;
    RF_READ_reg = 1'b0; RF_WRITE_reg = 1'b0;
  end
  //Decoding INST_REG
  else if (proc_state === `PROC_DECODE)
  begin
    INST_REG = MEM_DATA;
    //Parse Instruction
    //R-Type
    {opcode, rs, rt, rd, shamt, funct} = INST_REG;
    //I-Type
    {opcode, rs, rt, immediate} = INST_REG;
    //J-Type
    {opcode, address} = INST_REG;
    //Sign extension
    SIGN_EXT = {{16{immediate[15]}},immediate};
    //Zero extension
    ZERO_EXT = {16'h0000, immediate};
    //LUI: {16-bit , 16x0}
    LUI = {immediate, 16'h0000};
    //Jump address: {6x0, 26-bit}
    JMP_ADDR = {6'b000000, address};
  end
end
endmodule

//------------------------------------------------------------------------------------------
// Module: CONTROL_UNIT
// Output: STATE      : State of the processor
//
// Input:  CLK        : Clock signal
//         RST        : Reset signal
//
// INOUT: MEM_DATA    : Data to be read in from or write to the memory
//
// Notes: - Processor continuously cycle witnin fetch, decode, execute,
//          memory, write back state. State values are in the prj_definition.v
//
// Revision History:
//
// Version	Date		Who		email			note
//------------------------------------------------------------------------------------------
//  1.0     Sep 10, 2014	Kaushik Patra	kpatra@sjsu.edu		Initial creation
//------------------------------------------------------------------------------------------
module PROC_SM(STATE,CLK,RST);
// list of inputs
input CLK, RST;
// list of outputs
output [2:0] STATE;

//state and next_state register
reg [2:0] state_reg;
reg [2:0] next_state;

assign STATE = state_reg;

//initial
initial
begin
  state_reg = 3'bxxx;
  next_state = `PROC_FETCH;
end

//reset on negedge RST
always @ (negedge RST)
begin
  state_reg = 3'bxxx;
  next_state = `PROC_FETCH;
end

//posedge CLK signal
always @ (posedge CLK)
begin
  state_reg = next_state;
end

//update next_state
always @ (state_reg)
begin
  case(state_reg)
    `PROC_FETCH : next_state = `PROC_DECODE;
    `PROC_DECODE : next_state = `PROC_EXE;
    `PROC_EXE : next_state = `PROC_MEM;
    `PROC_MEM : next_state = `PROC_WB;
    `PROC_WB : next_state = `PROC_FETCH;
  endcase
end

//===========================================================================
//print_instruction task
//usage: print_instruction(INST_REG);
//===========================================================================
task print_instruction;
input [`DATA_INDEX_LIMIT:0] inst;

reg [5:0] op_task;
reg [4:0] rs_task;
reg [4:0] rt_task;
reg [4:0] rd_task;
reg [4:0] shamt_task;
reg [5:0] funct_task;
reg [15:0] imm_task;
reg [25:0] addr_task;

begin
  // parse the instruction
  // R-type
  {op_task, rs_task, rt_task, rd_task, shamt_task, funct_task} = inst;
  // I-type
  {op_task, rs_task, rt_task, imm_task } = inst;
  // J-type
  {op_task, addr_task} = inst;
  $write("@ %6dns -> [0X%08h] ", $time, inst);
  case(op_task)
    // R-Type
    6'h00 : begin
      case(funct_task)
        6'h20: $write("add  r[%02d], r[%02d], r[%02d];", rs_task, rt_task, rd_task);
        6'h22: $write("sub  r[%02d], r[%02d], r[%02d];", rs_task, rt_task, rd_task);
        6'h2c: $write("mul  r[%02d], r[%02d], r[%02d];", rs_task, rt_task, rd_task);
        6'h24: $write("and  r[%02d], r[%02d], r[%02d];", rs_task, rt_task, rd_task);
        6'h25: $write("or   r[%02d], r[%02d], r[%02d];", rs_task, rt_task, rd_task);
        6'h27: $write("nor  r[%02d], r[%02d], r[%02d];", rs_task, rt_task, rd_task);
        6'h2a: $write("slt  r[%02d], r[%02d], r[%02d];", rs_task, rt_task, rd_task);
        6'h01: $write("sll  r[%02d], %2d, r[%02d];", rs_task, shamt_task, rd_task);
        6'h02: $write("srl  r[%02d], 0X%02h, r[%02d];", rs_task, shamt_task, rd_task);
        6'h08: $write("jr   r[%02d];", rs_task);
        default: $write("");
      endcase
    end
    6'h08 : $write("addi  r[%02d], r[%02d], 0X%04h;", rs_task, rt_task, imm_task);
    6'h1d : $write("muli  r[%02d], r[%02d], 0X%04h;", rs_task, rt_task, imm_task);
    6'h0c : $write("andi  r[%02d], r[%02d], 0X%04h;", rs_task, rt_task, imm_task);
    6'h0d : $write("ori   r[%02d], r[%02d], 0X%04h;", rs_task, rt_task, imm_task);
    6'h0f : $write("lui   r[%02d], 0X%04h;", rt_task, imm_task);
    6'h0a : $write("slti  r[%02d], r[%02d], 0X%04h;", rs_task, rt_task, imm_task);
    6'h04 : $write("beq r[%02d], r[%02d], 0X%04h;", rs_task, rt_task, imm_task);
    6'h05 : $write("bne r[%02d], r[%02d], 0X%04h;", rs_task, rt_task, imm_task);
    6'h23 : $write("lw r[%02d], r[%02d], 0X%04h;", rs_task, rt_task, imm_task);
    6'h2b : $write("sw r[%02d], r[%02d], 0X%04h;", rs_task, rt_task, imm_task);
    6'h02 : $write("jmp 0X%07h;", addr_task);
    6'h03 : $write("jal 0X%07h;", addr_task);
    6'h1b : $write("push;");
    6'h1c : $write("pop;");
    default: $write("");
  endcase
  $write("\n");
end
endtask

endmodule
