`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

// Create Date: 10/20/2024 11:35:12 AM
// Author: Enrique Albertos (javagoza)
// Design Name: Driver for the hx711 24-Bit Analog-to-Digital Converter (ADC) for Weigh Scales
// Module Name: hx711driver_test
// Project Name: FruitVision Scale
// Target Devices: Zynq 7020
// Tool Versions: Vivado 2022.1, 2022.2
// Description: Driver 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module hx711driver (
    input clk,
    input reset,
    input logic [15:0] dvsr, // 0,5 * (# clk in SCK period)
    input logic start,
    output logic [23:0] dout,
    output logic hx711_done_tick,
    output logic ready,
    output logic sclk,
    input logic hx711_in
);

// FSM state type
typedef enum {idle, cpha_delay, p0, p1, g0, g1} state_type;

// p0, p1 hx711 signal clock half periods data in
// g0, g1 hx711 signal clock half periods gain selection
// cpha_delay to sample on the second edge

// State register
state_type state_reg;
state_type state_next;

// Clock signal generation
logic p_clk;

// Clock divider counter
logic [15:0] c_reg;
logic [15:0] c_next;

// HX711 clock signal
logic hx711_clk_reg;
logic hx711_clk_next;

// Ready signal
logic ready_i;

// Done tick signal
logic hx711_done_tick_i;

// Bit counter
logic [5:0] n_reg;
logic [5:0] n_next;

// Data input register
logic [23:0] si_reg;
logic [23:0] si_next;


// body fsm for receiving 24 bits  register
always_ff @(posedge clk, posedge reset)
    if (reset) begin
        state_reg <= idle;
        si_reg <= 0;
        n_reg <= 0;
        c_reg <= 0;
        hx711_clk_reg <= 0;
    end
    else begin
        state_reg <= state_next;
        si_reg <= si_next;
        n_reg <= n_next;
        c_reg <= c_next;
        hx711_clk_reg <= hx711_clk_next;
    end
    
// FSM next state logic
always_comb
begin
    state_next = state_reg; // Default state: the same
    ready_i = 0;
    hx711_done_tick_i = 0;
    si_next = si_reg;
    n_next = n_reg;
    c_next = c_reg;
    case (state_reg)
        idle: begin
                ready_i = 1; // Indicate that the data is ready
                if (start & !hx711_in) begin // Start signal and HX711 input is low
                    n_next = 0; // Reset bit counter
                    c_next =0;  // Reset clock divider counter
                    state_next = cpha_delay; // Transition to delay state
                end
            end
        cpha_delay: begin
                if (c_reg==dvsr) begin // Delay period reached
                    state_next = p0; // Transition to first clock phase
                    c_next = 0;  // Reset clock divider counter
                end
                else
                    c_next = c_reg + 1; // Increment clock divider counter
            end
        p0: begin
                if (c_reg==dvsr) begin // First clock phase completed
                    state_next = p1;  // Transition to second clock phase
                    si_next = {si_reg[22:0], hx711_in}; // Shift in new bit
                    c_next = 0; // Reset clock divider counter
                end
                else
                    c_next = c_reg + 1;  // Increment clock divider counter
            end
        p1: begin
                if (c_reg==dvsr) begin // Second clock phase completed
                    if (n_reg==23) begin // All 24 bits read
                        state_next = g0; // Transition to gain selection phase
                        c_next = 0; // Reset clock divider counter
                    end
                    else begin
                        state_next = p0;  // Transition to next bit
                        n_next = n_reg + 1;  // Increment bit counter
                        c_next = 0;  // Reset clock divider counter
                    end
                end
                else
                    c_next = c_reg + 1; // Increment clock divider counter
            end
        g0: begin
                if (c_reg==dvsr) begin // First gain selection phase completed
                    state_next = g1; // Transition to second gain selection phase
                    c_next = 0; // Reset clock divider counter
                end
                else
                    c_next = c_reg + 1;  // Increment clock divider counter
            end
        g1: begin
                if (c_reg==dvsr) begin // Second gain selection phase completed
                    hx711_done_tick_i = 1;  // Indicate data acquisition is complete
                    state_next = idle;  // Transition to idle state
                end
                else
                    c_next = c_reg + 1; // Increment clock divider counter
            end
     endcase
end

// Assign output signals
assign ready = ready_i;
assign hx711_done_tick = hx711_done_tick_i;

// Clock signal generation
assign p_clk = (state_next==p0) || (state_next == g0);
assign hx711_clk_next = p_clk;

// Output assignment
assign dout = si_reg;
assign sclk = hx711_clk_reg;


endmodule