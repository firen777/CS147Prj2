// Name: proj_2_tb.v
// Module: DA_VINCI_TB
// 
//
// Monitors:  DATA : Data to be written at address ADDR
//            ADDR : Address of the memory location to be accessed
//            READ : Read signal
//            WRITE: Write signal
//
// Input:   DATA : Data read out in the read operation
//          CLK  : Clock signal
//          RST  : Reset signal
//
// Notes: - Testbench for MEMORY_64MB memory system
//
// Revision History:
//
// Version	Date		Who		email			note
//------------------------------------------------------------------------------------------
//  1.0     Sep 10, 2014	Kaushik Patra	kpatra@sjsu.edu		Initial creation
//------------------------------------------------------------------------------------------
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//To be edited
`include "prj_definition.v"
module REGISTER_FILE_TB;

// R/W data registers
reg [`DATA_INDEX_LIMIT:0] DATA_REG_R1;
reg [`DATA_INDEX_LIMIT:0] DATA_REG_R2;
reg [`DATA_INDEX_LIMIT:0] DATA_REG_W;

// R/W Addresses
reg [`ADDRESS_INDEX_LIMIT:0] ADDR_R1;
reg [`ADDRESS_INDEX_LIMIT:0] ADDR_R2;
reg [`ADDRESS_INDEX_LIMIT:0] ADDR_W;
// Read, Write, Reset signal
reg READ, WRITE, RST;

integer i; // index for memory operation
integer no_of_test, no_of_pass;
integer load_data_1;
integer load_data_2;

// wire lists
wire  CLK;
wire [`DATA_INDEX_LIMIT:0] DATA_R1;
wire [`DATA_INDEX_LIMIT:0] DATA_R2;

assign DATA_R1 = ((READ===1'b0)&&(WRITE===1'b1))?DATA_REG_R1:{`DATA_WIDTH{1'bz} };
assign DATA_R2 = ((READ===1'b0)&&(WRITE===1'b1))?DATA_REG_R2:{`DATA_WIDTH{1'bz} };

// Clock generator instance
CLK_GENERATOR clk_gen_inst(.CLK(CLK));

// registor instance
//module REGISTER_FILE_32x32(DATA_R1, DATA_R2, ADDR_R1, ADDR_R2, 
//                            DATA_W, ADDR_W, READ, WRITE, CLK, RST);
REGISTER_FILE_32x32 reg_inst(.DATA_R1(DATA_R1), .DATA_R2(DATA_R2), .ADDR_R1(ADDR_R1), .ADDR_R2(ADDR_R2), 
                             .DATA_W(DATA_REG_W), .ADDR_W(ADDR_W), .READ(READ), .WRITE(WRITE), .CLK(CLK), .RST(RST));

initial
begin
RST=1'b1;
READ=1'b0;
WRITE=1'b0;
DATA_REG_W = {`DATA_WIDTH{1'b0} };
no_of_test = 0;
no_of_pass = 0;
load_data_1 = 'h00414020;
load_data_2 = 'h0270302a;

// Start the operation
#10    RST=1'b0;
#10    RST=1'b1;
// Write cycle
for(i=1;i<10; i = i + 1)
begin
#10     DATA_REG_W=i; READ=1'b0; WRITE=1'b1; ADDR_W = i;
end

// Test Hi-Z:
#10   READ=1'b0; WRITE=1'b0;
#5    no_of_test = no_of_test + 1;
      if (DATA_R1 !== {`DATA_WIDTH{1'bz}} || DATA_R2 !== {`DATA_WIDTH{1'bz}})
        $write("[TEST] Read %1b, Write %1b, expecting 32'hzzzzzzzz, got %8h, %8h [FAILED]\n", READ, WRITE, DATA_R1, DATA_R2);
      else 
	no_of_pass  = no_of_pass + 1;

// test of write and read R1 data:
for(i=0;i<10; i = i + 1)
begin
#5      READ=1'b1; WRITE=1'b0; ADDR_R1 = i;
#5      no_of_test = no_of_test + 1;
        if (DATA_R1 !== i)
	    $write("[TEST] Read %1b, Write %1b, expecting %8h, got %8h [FAILED]\n", READ, WRITE, i, DATA_R1);
        else 
	    no_of_pass  = no_of_pass + 1;

end

// test of write and read R2 data:
for(i=0;i<10; i = i + 1)
begin
#5      READ=1'b1; WRITE=1'b0; ADDR_R2 = i;
#5      no_of_test = no_of_test + 1;
        if (DATA_R2 !== i)
	    $write("[TEST] Read %1b, Write %1b, expecting %8h, got %8h [FAILED]\n", READ, WRITE, i, DATA_R2);
        else 
	    no_of_pass  = no_of_pass + 1;

end

// Another test for Write/Read data
//Write at 31:
#10      ADDR_W = 31; DATA_REG_W = load_data_1; READ=1'b0; WRITE=1'b1;
//Write at 27:
#10      ADDR_W = 27; DATA_REG_W = load_data_2; READ=1'b0; WRITE=1'b1;
//Read R1, Read R2:
#10      ADDR_R1 = 31; ADDR_R2 = 27; READ=1'b1; WRITE=1'b0;
#10      no_of_test = no_of_test + 1;
        if (DATA_R1 !== load_data_1 || DATA_R2 !== load_data_2)
        begin
            if (DATA_R1 !== load_data_1)
                $write("[TEST] R1: Read %1b, Write %1b, Addr %d, expecting %8h, got %8h [FAILED]\n", 
                                                                READ, WRITE, ADDR_R1, load_data_1, DATA_R1);
            if (DATA_R2 !== load_data_2)
                $write("[TEST] R2: Read %1b, Write %1b, Addr %d, expecting %8h, got %8h [FAILED]\n", 
                                                                READ, WRITE, ADDR_R2, load_data_2, DATA_R2);
        end
        else
            no_of_pass  = no_of_pass + 1;


#10    READ=1'b0; WRITE=1'b0; // No op

#10 $write("\n");
    $write("\tTotal number of tests %d\n", no_of_test);
    $write("\tTotal number of pass  %d\n", no_of_pass);
    $write("\n");
//    $writememh("mem_dump_01.dat", mem_inst.sram_32x64m, 'h0000000, 'h000000f);
//    $writememh("mem_dump_02.dat", mem_inst.sram_32x64m, 'h0001000, 'h000100f);
    $stop;

end
endmodule
