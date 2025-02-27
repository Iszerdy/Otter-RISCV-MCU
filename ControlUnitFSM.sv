`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/22/2025 01:08:55 PM
// Design Name: 
// Module Name: ControlUnitFSM
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


module ControlUnitFSM(
    input rst,
    input logic intr, clk, 
    input logic [6:0] opcode,  //ir[6:0]
    input logic [2:0] func3,  //ir[14:12]
    output logic PCWrite, regWrite, memWE2, memRDEN1, memRDEN2, reset, csr_we, int_taken 
);
    assign intr = 0; //Not being used yet, assign 0 so it is connected
    
    typedef enum logic [2:0] {INIT = 0, FETCH = 1, EXEC = 2, WRITEBACK = 3} state_t;
    state_t state, next_state;
    
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
     	 
    always_ff @(posedge clk) begin // If RST is asserted, loop back to INIT
        if (rst) 
            state <= INIT;
        else 
            state <= next_state;
    end

    always_comb begin //FSM
        reset = 'b0;
        memRDEN1 = 'b0;
        memRDEN2 = 'b0;
        PCWrite = 'b0;
        regWrite = 'b0;
        memWE2 = 'b0;
        int_taken = 1'b0;
        next_state = INIT;
        case (state)
            INIT:
             begin
                reset = 'b1;
                PCWrite = 'b0;
                regWrite = 'b0;
                memWE2 = 'b0;
                memRDEN1 = 'b0;
                memRDEN2 = 'b0;
                next_state = FETCH;
                end
            FETCH: 
            begin
                PCWrite = 'b0;
                regWrite = 'b0;
                memWE2 = 'b0;
                memRDEN1 = 'b1;
                memRDEN2 = 'b0;
                 next_state = EXEC;
            end
            EXEC: 
            begin
                case (opcode)
                  LUI: begin
                    regWrite = 'b1;
                    PCWrite = 'b1;
                    next_state = FETCH;
                  end
                  AUIPC: begin
                    regWrite = 'b1;
                    PCWrite = 'b1;
                    next_state = FETCH;
                  end
                  JAL: begin
                    PCWrite = 'b1;
                    regWrite = 'b1;
                    next_state = FETCH;
                  end
                  JALR: begin
                    regWrite = 'b1;
                    PCWrite = 'b1;
                    next_state = FETCH;
                 end
                  LOAD: begin
                    memRDEN2 = 'b1;
                    next_state = WRITEBACK;
                  end
                  OP_IMM: begin
                    regWrite = 'b1;
                    PCWrite = 'b1;
                    next_state = FETCH;
                  end
                  BRANCH: begin
                    PCWrite = 'b1;
                    next_state = FETCH;
                  end
                  STORE: begin
                    memWE2 = 'b1;
                    PCWrite = 'b1;
                    next_state = FETCH;
                  end
                  RTYPE: begin
                    PCWrite = 'b1;
                    regWrite = 'b1;
                    next_state = FETCH;
                  end
                  SYS: begin
                    case (func3)
                        3'b000: begin
                            PCWrite = 'b1;
                        end
                        3'b001: begin
                            regWrite = 'b1;
                            csr_we = 'b1;
                        end 
                    endcase   
                  end
                endcase  
                end
            WRITEBACK: begin
                PCWrite = 'b1;
                regWrite = 'b1;
                memRDEN2 = 'b0;
                next_state = FETCH;
                end
            default: 
                next_state = INIT;
        endcase
    end
   always_comb begin
        $display("Present State:(0 = INIT, 1= FETCH, 2 = EXEC, 3 = WRITEBACK)", state);
   end
endmodule