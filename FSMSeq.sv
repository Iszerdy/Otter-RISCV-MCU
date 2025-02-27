`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/02/2024 10:42:28 AM
// Design Name: 
// Module Name: FSMSeq
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
module FSMSeq(
    input logic EIN, RST, clk, // 100 MHz clock
    output logic [6:0] state_reg, // 7-segment cathode control
    output reg [3:0] Anode_Activate // 7-segment anode control
    );

    logic [3:0] seq;          // Current state
    logic [3:0] ns;           // Next state
    logic clk_Hz;            // 1 Hz clock signal
    logic [26:0] clk_div;     // Clock divider counter
    logic [1:0] holder; // Counter to keep "1" displayed for 2 seconds

    // Clock divider to generate a 1 Hz clock from 100 MHz input
    always_ff @(posedge clk or posedge RST) begin
        if (RST) begin
            clk_div <= 27'd0;
            clk_Hz <= 1'b0;
        end else if (clk_div == 27'd49999999) begin
            clk_div <= 27'd0;
            clk_Hz <= ~clk_Hz; // Toggle the 1 Hz clock
        end else begin
            clk_div <= clk_div + 1;
        end
    end

    // Always activate the rightmost digit
    always_comb begin
        Anode_Activate = 4'b1110; // Only rightmost display active
    end

    // FSM for sequence logic with a hold counter for "1"
    always_ff @(posedge clk_Hz or posedge RST) begin
        if (RST) begin
            seq <= 4'b0001;          // Start with "1"
            holder <= 2'd0;    // Reset the hold counter
        end else if (EIN) begin
            if (seq == 4'b0001 && holder < 2'd1) begin
                // Stay in "1" for 2 seconds (2 clock cycles of clk_1Hz)
                holder <= holder + 1;
            end else begin
                holder <= 2'd0; // Reset hold counter when transitioning
                seq <= ns;            // Transition to the next state
            end
        end
    end

    // Next state logic
    always_comb begin
        ns = seq; // Default to current state
        if (EIN) begin
            case (seq)
                4'b0001: ns = 4'b0111; // 1 -> 7
                4'b0111: ns = 4'b0000; // 7 -> 0
                4'b0000: ns = 4'b0001; // 0 -> 1
                default: ns = 4'b0001; // Default back to 1
            endcase
        end
    end
    // Output logic for the 7-segment display
    always_comb begin   
        case(seq)
            4'b0001: state_reg = 7'b1001111; // Display 1
            4'b0111: state_reg = 7'b0001111; // Display 7
            4'b0000: state_reg = 7'b0000001; // Display 0
            default: state_reg = 7'b1111111; // Default to blank/off
        endcase
    end
            
endmodule
