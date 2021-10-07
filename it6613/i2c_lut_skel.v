/*
 *  i2_lut_skel.v
 *
 *  copyright (c) 2021 hirosh dabui <hirosh@dabui.de>
 *
 *  permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  the software is provided "as is" and the author disclaims all warranties
 *  with regard to this software including all implied warranties of
 *  merchantability and fitness. in no event shall the author be liable for
 *  any special, direct, indirect, or consequential damages or any damages
 *  whatsoever resulting from loss of use, data or profits, whether in an
 *  action of contract, negligence or other tortious action, arising out of
 *  or in connection with the use or performance of this software.
 *
 */

/* this skeleton show you howto use the look up table for i2c */

`default_nettype none
`timescale 1ns/1ps

module top(
           input  wire clk100,
           output wire [11:0] hdmi_r,
           output wire [11:0] hdmi_g,
           output wire [11:0] hdmi_b,

           output wire hdmi_pclk,

           output wire hdmi_hsync,
           output wire hdmi_vsync,

           output wire hdmi_de,
           output wire hdmi_scl,
           inout wire hdmi_sda,
       );


wire hsync;
wire vsync;
wire blank;

wire r3, r2, r1, r0;
wire g3, g2, g1, g0;
wire b3, b2, b1, b0;

assign hdmi_r = {r3, r2, r1, r0, 8'h0};
assign hdmi_g = {g3, g2, g1, g0, 8'h0};
//assign hdmi_b = {6'h0, b3, b2, b1, b0, 2'h0}; // <- this works for me on ecp5ix
assign hdmi_b = {b3, b2, b1, b0, 8'h0};

assign hdmi_hsync = hsync;
assign hdmi_vsync = vsync;
assign hdmi_de = ~blank;
assign hdmi_pclk = clk;

assign hdmi_scl = scl;
assign hdmi_sda = sda_output ? sda : 1'bz;
(* keep *)
wire hdmi_sda_in = hdmi_sda;



reg [9: 0] cycle_cnt;

wire tick = cycle_cnt == (1000/2 -1);

reg [$clog2(2048) -1:0] i2c_row;
always @(posedge clk100) begin
  if (!resetn) begin
    cycle_cnt <= 0;
    i2c_row <= 0;
  end else begin
    cycle_cnt <= tick ? 0 : cycle_cnt + 1; 
    if (tick) begin
      if (!&i2c_row) i2c_row <= i2c_row + 1;
    end
end
end


reg scl;
reg sda;
reg sda_output;

always @* begin
  case (i2c_row)
    `include "hdmi_setup.v"
    default:
      {scl, sda, sda_output} = {1'b1, 1'b1, 1'b1};
  endcase
end

endmodule

