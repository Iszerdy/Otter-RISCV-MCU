`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/22/2025 01:07:58 PM
// Design Name: 
// Module Name: ControlUnitDecoder
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


module ControlUnitDecoder(
    input logic br_eq, br_lt, br_ltu,
    input logic [6:0] opcode, // ir[6:0]
    input logic func7,  //ir[30]
    input logic [2:0] func3, //ir[14:12]
    input logic int_taken,
    output logic [3:0] alu_fun,
    output logic [1:0] alu_srcA,
    output logic [2:0] alu_srcB,
    output logic [2:0] PCSource,
    output logic [1:0] rf_wr_sel
);


    typedef enum logic [6:0] {
        LUI    = 7'b0110111,
        AUIPC  = 7'b0010111,
        JAL    = 7'b1101111,        
        JALR   = 7'b1100111,
        LOAD   = 7'b0000011,
        OP_IMM = 7'b0010011,
        BRANCH = 7'b1100011,
        STORE  = 7'b0100011,
        RTYPE = 7'b0110011,
        SYS    = 7'b1110011
    } opcode_t;
	opcode_t OPCODE;    //- symbolic names for instruction opcodes
   
	assign OPCODE = opcode_t'(opcode);
	typedef enum logic [2:0] {
	   BEQ = 3'b000,
	   BNE = 3'b001,
	   BLT = 3'b100,
	   BGE = 3'b101,
	   BLTU = 3'b110,
	   BGEU = 3'b111
	} func3_t;    
    func3_t FUNC3; //- define variable of new opcode type
    assign FUNC3 = func3_t'(func3); 
    
    always_comb begin
        PCSource = 3'b000;
        alu_srcA = 2'b00;
        alu_fun = 4'b0000;
        alu_srcB = 3'b000;
        rf_wr_sel = 2'b00;
        if (int_taken == 'b1) begin
            PCSource = 3'b100;
        end else begin
            case (OPCODE)
                LUI: begin
                    alu_fun = 4'b1001;
                    alu_srcA = 2'b01;
                    alu_srcB = 3'b000; 
                    rf_wr_sel = 2'b11;
                end
                AUIPC: begin  
                    alu_srcA = 2'b01;
                    alu_srcB = 3'b011;
                    rf_wr_sel = 2'b11;
               end
               JALR: begin
                    alu_srcA = 2'b01;
                    alu_srcB = 3'b001;
                    PCSource = 3'b001;
               end
               LOAD: begin
                    alu_fun = 4'b0000;
                    alu_srcA = 2'b00;
                    alu_srcB = 3'b001;
                    rf_wr_sel = 2'b10;
               end
               STORE: begin
                    alu_fun = 4'b0000;
                    alu_srcA = 2'b00;
                    alu_srcB = 3'b010;
                    rf_wr_sel = 2'b10;  
               end
               OP_IMM: begin
                    alu_srcA = 2'b00; 
                    alu_srcB = 3'b001;
                    rf_wr_sel = 2'b11;
               end
               RTYPE: begin
                    alu_srcA = 2'b00; 
                    alu_srcB = 3'b000;
                    rf_wr_sel = 2'b11;
               end
               BRANCH: begin
                    case(FUNC3)
                        BEQ: begin
                            if(br_eq) begin
                                PCSource = 3'b010;
                                rf_wr_sel = 2'b10;
                            end
                        end
                        BNE: begin
                            if (!br_eq) begin
                                PCSource = 3'b010;
                            end
                        end
                        BLT: begin
                            if(br_lt) begin
                                PCSource = 3'b010;
                            end
                        end
                        BGE: begin
                            if(!br_lt) begin
                                PCSource = 3'b010;
                            end
                        end
                        BLTU: begin
                            if(br_ltu) begin
                                PCSource = 3'b010;
                            end
                        end
                        BGEU: begin
                            if(!br_ltu) begin
                                PCSource = 3'b010;
                            end
                        end
                        default: begin
                            PCSource = 3'b000;
                        end
                    endcase
               end
               SYS: begin
                    case (func3)
                        3'b000: begin
                            PCSource = 3'b101;
                        end
                        3'b001: begin
                            rf_wr_sel = 2'b01;
                        end
                    endcase
               end
               default: begin  
                    PCSource = 3'b000;
                    alu_srcA = 2'b00; 
                    alu_srcB = 3'b000;
                    rf_wr_sel = 2'b00;
                    alu_fun = 4'b0000;
               end
            endcase
            if(OPCODE == OP_IMM || OPCODE == RTYPE) begin
                case(FUNC3)
                    3'b000: begin // ADDI, ADD, SUB
                        alu_fun = 4'b0000;
                        if(OPCODE == RTYPE && func7 == 'b1) begin
                            alu_fun = 4'b1000;
                        end
                    end
                    3'b001: begin //SLLI, SLL
                        alu_fun = 4'b0001;
                    end
                    3'b010: begin//SLTI, SLT
		       	        alu_fun = 4'b0010;
		          	end
                    3'b011: begin //SLTIU, SLTU
                        alu_fun = 4'b0011;
                    end
                    3'b100: begin //XORI, XOR
                        alu_fun = 4'b0100;
                    end
                    3'b101: begin //SRLI, SRL, SRAI, SRA
                        if(func7) begin //SRAI, SRA
                            alu_fun = 4'b1101;
                        end else begin//SRLI, SRL
                            alu_fun = 4'b0101;
                        end
                    end
                    3'b110: begin //ORI, OR
                        alu_fun = 4'b0110;
                    end
                    3'b111: begin //ANDI, AND
                        alu_fun = 4'b0000;
                    end
                    default: begin
                        PCSource = 3'b000;
                        alu_fun = 4'b0000;
                        alu_srcA = 2'b00;
                        alu_srcB = 3'b000;
                        rf_wr_sel = 2'b00;
                    end
                endcase
            end
        end
    end
endmodule
