`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/04/2025 10:52:56 AM
// Design Name: 
// Module Name: ImmedGen
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


module ImmedGen(
    input logic [31:7] instruc,
    output logic [31:0] utype, itype, stype, jtype, btype
    );
    always_comb begin
        utype = {instruc[31:12], 12'b0};
        itype = {{20{instruc[31]}}, instruc[30:20]};
        stype = {{20{instruc[31]}}, instruc[30:25], instruc[11:7]};
        btype = {{19{instruc[31]}}, instruc[7], instruc[30:25], instruc[11:8], 1'b0};
        jtype = {{11{instruc[31]}}, instruc[19:12], instruc[20], instruc[30:21], 1'b0};
    end
endmodule
