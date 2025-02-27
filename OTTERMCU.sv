`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/28/2025 06:52:39 PM
// Design Name: 
// Module Name: RegisterFile
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module OTTERMCU(
    input logic RST, INTR, CLK,
    input logic [31:0] IOBUS_IN,
    output logic IOBUS_WR,
    output logic [31:0] IOBUS_OUT,
    output logic [31:0] IOBUS_ADDR
);
    //Memory
    logic [31:0] instruc;
    logic [31:0] mem_data;
    
    //Program Counter
    logic [31:0] next_addr;
    logic [31:0] pc;
    
    //FSM
    logic PCWrite;
    logic regWrite;
    logic memRDEN1;
    logic memRDEN2;
    logic memWE2;
    logic reset;
    
    // Immediate generator output
    logic [31:0] utype;
    logic [31:0] itype;
    logic [31:0] stype;
    logic [31:0] jtype;
    logic [31:0] btype;
    
    //Decoder
    logic [2:0] PCSource;
    logic [3:0] alu_fun;
    logic [1:0] alu_srcA;
    logic [2:0] alu_srcB;
    logic [1:0] rf_wr_sel;
    
    // Branch address generator output
    logic [31:0] jalr;
    logic [31:0] branch;
    logic [31:0] jal;
    logic [31:0] mepc;
    logic [31:0] mtvec;
    
    //REG_FILE
    logic [31:0] rs1;
    logic [31:0] rs2;
    logic [31:0] csr_rd;
    
    assign csr_rd = 32'b0; //not implemented yet, but need value for regFile MUX
    //CSR
    logic int_taken;
    
    //ALU
    logic [31:0] alu_result;
    logic [31:0] srcA;
    logic [31:0] srcB;
    logic [31:0] wd_load;
    
    BranchCondGen BRANCH_COND_GEN(
        .rs1(rs1),
        .rs2(rs2),
        .br_eq(br_eq),
        .br_lt(br_lt),
        .br_ltu(br_ltu)
        );
            

    ControlUnitFSM CU_FSM(
        .rst(RST),
        .intr(INTR),
        .clk(CLK),
        .opcode(instruc[6:0]),     // ir[6:0]
        .func3(instruc[14:12]),
        .PCWrite(PCWrite),
        .regWrite(regWrite),
        .memWE2(memWE2),
        .memRDEN1(memRDEN1),
        .memRDEN2(memRDEN2),
        .reset(reset),
        .csr_we(csr_we),
        .int_taken(int_taken)
    );
        
    TopLevelPC PC (
        .clk(CLK), 
        .pc_rst(RST),
        .pc_we(PCWrite),
        .pc_sel(PCSource),
        .jalr(jalr),
        .branch(branch),
        .jal(jal),
        .mtvec(mtvec),
        .mepc(mepc),
        .pc_count(pc),
        .next_addr(next_addr)
    );
    
    
    Memory OTTER_MEMORY(        
        .MEM_CLK(CLK),
        .MEM_RDEN1(memRDEN1),
        .MEM_RDEN2(memRDEN2),
        .MEM_WE2(memWE2),
        .MEM_ADDR1(pc[15:2]),
        .MEM_ADDR2(alu_result),
        .MEM_DIN2(rs2),
        .MEM_SIZE(instruc[13:12]),
        .MEM_SIGN(instruc[14]),
        .IO_IN(IOBUS_IN),
        .IO_WR(IOBUS_WR),
        .MEM_DOUT1(instruc),
        .MEM_DOUT2(mem_data)
        );

    
    ControlUnitDecoder CU_DCDR(
        .br_eq(br_eq),
        .br_lt(br_lt),
        .br_ltu(br_ltu),
        .opcode(instruc[6:0]),
        .func7(instruc[30]),
        .func3(instruc[14:12]),
        .int_taken(int_taken),
        .alu_fun(alu_fun),
        .alu_srcA(alu_srcA),
        .alu_srcB(alu_srcB),
        .PCSource(PCSource),
        .rf_wr_sel(rf_wr_sel)
    );
    
    ImmedGen IMM_GEN(               // Immediate generator
        .instruc(instruc[31:7]),
        .utype(utype),
        .itype(itype),
        .stype(stype),
        .jtype(jtype),
        .btype(btype)
        );
        
    BranchAddrGen BRANCH_ADDR_GEN(  // Branch Address Generator 
        .PC(pc),
        .jtype_imm(jtype), 
        .btype_imm(btype),
        .itype_imm(itype),
        .rs1(rs1), 
        .jal(jal),
        .branch(branch),
        .jalr(jalr)
        );
        
    always_comb begin  //Register File MUX
        case (rf_wr_sel)
           4'b0: wd_load = next_addr;
           4'b1: wd_load = csr_rd;
           4'b10: wd_load = mem_data;
           4'b11: wd_load = alu_result;
           default: wd_load = 4'b0;
        endcase
    end   
     
    RegisterFile REG_FILE(   //Register File
        .clk(CLK),
        .en(regWrite),
        .adr1(instruc[19:15]),
        .adr2(instruc[24:20]),
        .w_data(wd_load),
        .w_adr(instruc[11:7]),
        .rs1(rs1),
        .rs2(rs2)
        );
        
    always_comb begin  // ALU scrA MUX
        case (alu_srcA)
           2'b0: srcA = rs1;
           2'b1: srcA = utype;
           2'b10: srcA = !rs1;
           default: srcA = 'b0;
        endcase
    end
    
    always_comb begin  // ALU scrB MUX
        case (alu_srcB)
           4'b0: srcB = rs2;
           4'b1: srcB = itype;
           4'b0010: srcB = stype;
           4'b0011: srcB = pc;
           default: srcB = 4'b0;
        endcase
    end
             
    ALU ALU(
        .srcA(srcA),
        .srcB(srcB),
        .alu_fun(alu_fun),
        .alu_result(alu_result)
        );

    always @(posedge CLK) begin // Outputs results for clarity
    if (regWrite) begin
        $display("PC: ", pc);
        $display("ALU Result:", alu_result);
    end
    end

    // IO Mapping
   assign IOBUS_ADDR = alu_result;  
   assign IOBUS_OUT = rs2;
endmodule
