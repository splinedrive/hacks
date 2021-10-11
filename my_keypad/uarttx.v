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
module uarttx(clk, uart_tx, tx_ready, tx_trigger, tx_data, resetn);
input clk;
input tx_trigger;
output uart_tx;
output tx_ready;
input  resetn;
input [7:0] tx_data;

/*
reg [5:0] reset_cnt = 0;

wire resetn = &reset_cnt;

always @(posedge clk) begin
  reset_cnt <= reset_cnt + {{5{1'b0}}, !resetn};
end
*/

parameter CLK_FREQ = 12_000_000;
parameter BAUDRATE = 9600;
parameter CYCLES4BIT = $rtoi(CLK_FREQ/BAUDRATE);
parameter BIT_COUNTER_WIDTH = $clog2(CYCLES4BIT);
localparam HALF_CYCLES4BIT = $rtoi(CYCLES4BIT / 2);
initial begin
  $display("CYCLES4BIT per bit:\n", CYCLES4BIT);
  $display("Half CYCLES4BIT per bit:\n", HALF_CYCLES4BIT);
  $display("RX state bits:\n", TX_STATE_BITS);
  $display("Width bits cycle counter per bit:\n", BIT_COUNTER_WIDTH);
end

reg [$clog2(TX_STOP) -1:0]tx_state;
localparam TX_IDLE  = 0;
localparam TX_START = 1;
localparam TX_DATA =  2;
localparam TX_STOP  = 3;
localparam TX_STATE_BITS = $clog2(TX_STOP);

reg tx_ready;
reg tx = 1'b1;
reg [BIT_COUNTER_WIDTH - 1: 0] tx_bit_cycle_cnt = 0;
reg [2:0] tx_bit_cnt = 0;

assign uart_tx = tx;

always @(posedge clk) begin

  if (!resetn) begin
    tx_state <= TX_IDLE;
    tx_ready <= 1'b0;
    tx_bit_cycle_cnt <= 0;
    tx_bit_cnt <= 0;
    tx <= 1'b1;
  end else begin

    case (tx_state)

      TX_IDLE: begin
        tx_ready <= 0;
        if (tx_trigger == 1'b1) begin 
          tx_state <= TX_START;
          tx <= 1'b1;
          tx_bit_cycle_cnt <= 0;
        end
      end

      TX_START: begin
        tx_bit_cycle_cnt <= tx_bit_cycle_cnt + 1;
        tx <= 1'b0;

        if (tx_bit_cycle_cnt == (CYCLES4BIT - 1)) begin
          tx_bit_cnt <= 0;
          tx_bit_cycle_cnt <= 0;
          tx_state <= TX_DATA;
        end else 
          tx_state <= TX_START;
      end

    TX_DATA: begin
      tx_bit_cycle_cnt <= tx_bit_cycle_cnt + 1;
      tx <= tx_data[tx_bit_cnt];

      if (tx_bit_cycle_cnt == (CYCLES4BIT -1)) begin
        tx_bit_cycle_cnt <= 0;
        tx_bit_cnt <= tx_bit_cnt + 1;

        if (tx_bit_cnt == 7) begin
          tx_state <= TX_STOP;
        end else 
          tx_state <= TX_DATA;

      end else 
        tx_state <= TX_DATA;
    end

    TX_STOP: begin
      tx <= 1'b1;
      tx_bit_cycle_cnt <= tx_bit_cycle_cnt + 1;
      if (tx_bit_cycle_cnt == (CYCLES4BIT -1)) begin
        tx_ready <= 1;
        tx_state <= TX_IDLE;
      end else
        tx_state <= TX_STOP;
    end

    default:
      tx_state <= TX_IDLE;

  endcase

  end // if

end // always

endmodule
