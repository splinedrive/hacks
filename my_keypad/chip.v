/*
Copyright (C) 2021  Hirosh Dabui <hirosh@dabui.de>

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
*/

// used waveshare 4x4 keypad matrix, learned from ref code
`include "uarttx.v"
module chip(
  clk, leds, lcol, spkp, spkm, row, col, uart_tx,
  ct, pt, seg, dot
);
input clk;
output reg [7:0] leds;
output reg [3:0] lcol;
output spkp;
output spkm;

assign spkp = 0;
assign spkm = 0;

input [3:0] row;
output [3:0] col;
output uart_tx;

output [3:0] ct;
output pt, dot;
output [6:0] seg;

/*
SB_IO #(
  .PIN_TYPE(6'b0000_01),
  .PULLUP(1'b1)
) cols[3:0] (
  .PACKAGE_PIN(col),
  .D_IN_0(col_din)
);

SB_IO #(
  .PIN_TYPE(6'b0000_01),
  .PULLUP(1'b1)
) rows[3:0] (
  .PACKAGE_PIN(row),
  .D_OUT_0(row_dout)
);
*/
wire resetn;

reg [5:0] reset_cnt = 6'b0;


localparam CLK_FREQ = $itor(12_000_000);
localparam CLK_PERIOD = 1/CLK_FREQ;
localparam BAUDRATE = 115200;
localparam CLK_PERIOD_NS = $rtoi(CLK_PERIOD*1.0e9);
localparam SAMPLE_RATE = 1_000;
localparam SAMPLE_RATE_CYCLES = $rtoi(CLK_FREQ/SAMPLE_RATE);

wire tx_ready;
reg tx_trigger;
reg [7:0] tx_data;


uarttx  #(.CLK_FREQ(CLK_FREQ), .BAUDRATE(BAUDRATE)) uarttx_u
(.clk(clk), .uart_tx(uart_tx), .tx_ready(tx_ready),
  .tx_trigger(tx_trigger), .tx_data(tx_data), .resetn(resetn));


assign resetn = &reset_cnt;
always @(posedge clk) reset_cnt <= reset_cnt + !resetn;

initial begin
  $display("SAMPLE_RATE_CYCLES:", SAMPLE_RATE_CYCLES);
end


assign pt = 1'b1;
assign dot = 1'b1;
reg [3:0] ct = 4'b0001;

wire [6:0] digit2seg_encode;

always @(*) begin
  case (current_key) 
    4'h0: digit2seg_encode = 7'h3f;
    4'h1: digit2seg_encode = 7'h06;
    4'h2: digit2seg_encode = 7'h5b;
    4'h3: digit2seg_encode = 7'h4f;
    4'h4: digit2seg_encode = 7'h66;
    4'h5: digit2seg_encode = 7'h6d;
    4'h6: digit2seg_encode = 7'h7d;
    4'h7: digit2seg_encode = 7'h07;
    4'h8: digit2seg_encode = 7'h7f;
    4'h9: digit2seg_encode = 7'h6f;
    4'ha: digit2seg_encode = 7'h77;
    4'hb: digit2seg_encode = 7'h7c;
    4'hc: digit2seg_encode = 7'h39;
    4'hd: digit2seg_encode = 7'h5e;
    4'he: digit2seg_encode = 7'h79;
    4'hf: digit2seg_encode = 7'h71;

    default:
      digit2seg_encode = 7'h3f;

  endcase
end

assign seg = ~digit2seg_encode;

reg [3:0] current_key;
always @(posedge clk) begin
  if (tick) begin
    ct[3]  <= ct[0];
    ct[0] <= ct[3];
    current_key <= ct[3] ? tx_data[7:4] : tx_data[3:0];
  end
end

reg state = 0;
always @(posedge clk) begin
  if (!resetn) begin
    state <= 0;
  end else begin

    case (state)

      0: begin
        if (!tx_ready && key_flag) begin

          tx_trigger <= 1;
          state <= 1;
        end else
          tx_trigger <= 0;
        state <= 0;
      end

      1: begin
        tx_trigger <= 0;
        state <= 0;
      end

      default: state <= 0;

    endcase

  end

end

always @(posedge clk) begin
  case (row)
    4'b1110: begin
      //      leds[7:0] <= ({~col[3:0], row[3:0]});
      leds[7:0] <= ~tx_data;
      lcol[5:0] <= row;
    end
    4'b1101: begin
      //      leds[7:0] <= ({~col[3:0], row[3:0]});
      leds[7:0] <= ~tx_data;
      lcol[5:0] <= row;
    end
    4'b1011: begin
      //      leds[7:0] <= ({~col[3:0], row[3:0]});
      leds[7:0] <= ~tx_data;
      lcol[5:0] <= row;
    end
    4'b0111: begin
      //      leds[7:0] <= ({~col[3:0], row[3:0]});
      leds[7:0] <= ~tx_data;
      lcol[5:0] <= row;
    end

    default:
      leds[7:0] <= {8{1'b1}};
  endcase
end

reg [$clog2(SAMPLE_RATE_CYCLES)-1:0] sample_clk;

wire tick = (sample_clk == SAMPLE_RATE_CYCLES);

always @(posedge clk) begin
  if (!resetn)
    sample_clk <= 0;
  else 
    sample_clk <= tick ? 0 : sample_clk + 1;
end

reg [3:0] row_reg;
reg [3:0] col_reg;
reg [3:0] col;
reg key_flag;
always @(posedge clk) begin
  if (!resetn) begin
    key_flag <= 0;
    col <= 4'b0000;
  end else begin

    if (tick) begin
      case (col)

        4'b0000: begin

          key_flag <= 0;
          if (row[3:0] != 4'b1111) begin
            col <= 4'b1110;
          end else begin
            col <= 4'b0000;
          end
        end

        4'b1110: begin
          if (row[3:0] != 4'b1111) begin
            key_flag <= 1;
            row_reg <= row;
            col_reg <= col;
            col <= 4'b0000;
            tx_data <= ~{col, row};
          end else col <= 4'b1101;
        end

        4'b1101: begin
        if (row[3:0] != 4'b1111) begin
          key_flag <= 1;
          row_reg <= row;
          col_reg <= col;
          tx_data <= ~{col, row};
          col <= 4'b0000;
        end else  col <= 4'b1011;
        end

        4'b1011: begin
        if (row[3:0] != 4'b1111) begin
          key_flag <= 1;
          row_reg <= row;
          col_reg <= col;
          col <= 4'b0000;
          tx_data <= ~{col, row};
        end else  col <= 4'b0111;
        end

        4'b0111: begin
        if (row[3:0] != 4'b1111) begin
          key_flag <= 1;
          row_reg <= row;
          col_reg <= col;
          col <= 4'b0000;
          tx_data <= ~{col, row};
        end else col <= 4'b0000;
      end

      default: begin
        key_flag <= 0;
        col <= 4'b0000;
      end
    endcase

    end /* if tick*/
  end /* reset */

  end /* always */

endmodule

