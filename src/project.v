/*
 * Copyright (c) 2025 AravindakshanGA
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_example (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

/*
  64-bit GCD Finder

  Dedicated Inputs will be used to get data in 8 bit chunks
  Dedicated Outputs will be used to send data in 8 bit chunks

  IO Pins will be used as CONTROL PINS. 
    IO[3:0] --> Get Control Signal Inputs
      IO 0 -- start signal
    IO[7:4] --> Used to signal Control Signals (OUTPUT)
*/

  localparam [2:0] ST_IDLE_RESET 		= 3'd0;				localparam [2:0] ST_INPUT_A		 	= 3'd1;			
  localparam [2:0] ST_INPUT_B			 	= 3'd2;				localparam [2:0] ST_COMPUTE			= 3'd3;
  localparam [2:0] ST_OUTPUT        	= 3'd4;

  reg [2:0] CURR_STATE = 3'd0;
  reg [2:0] NEXT_STATE = 3'd0;

  reg [2:0] IO_COUNTER = 3'd0;

  // DATAPATH Registers
  reg [63:0] INPUT_A = 64'd0;
  reg [63:0] INPUT_B = 64'd0;
//  reg [63:0] OUTPUT = 64'd0;

  reg [7:0] REG_UO;
  reg COMPUTE_FINISHED;

  wire [63:0] SUB_OUT;
  wire B_ZERO;

  always @(posedge clk) begin
    if(rst_n == 1'b0) begin
      CURR_STATE <= ST_IDLE_RESET;
    end
    else begin
      CURR_STATE <= NEXT_STATE;
    end
  end

  always @(*) begin
      NEXT_STATE = CURR_STATE;
      case(CURR_STATE)
        ST_IDLE_RESET : if(uio_in[0] == 1'b1) NEXT_STATE = ST_INPUT_A;
        ST_INPUT_A : if(IO_COUNTER == 3'd7) NEXT_STATE = ST_INPUT_B;
        ST_INPUT_B : if(IO_COUNTER == 3'd7) NEXT_STATE = ST_COMPUTE;
        ST_COMPUTE : if(B_ZERO == 1'b0) NEXT_STATE = ST_OUTPUT;
        ST_OUTPUT : if(IO_COUNTER == 3'd7) NEXT_STATE = ST_IDLE_RESET;
        default: ;
      endcase
  end

  assign SUB_OUT = INPUT_A - INPUT_B;
  assign B_ZERO = (INPUT_B == 0);

  always @(posedge clk) begin
    if(rst_n == 1'b0) begin
		REG_UO <= 8'd0;
    COMPUTE_FINISHED <= 1'b0;
    end
    else begin
      case(CURR_STATE)
        ST_IDLE_RESET: begin
          INPUT_A <= 64'd0;
          INPUT_B <= 64'd0;
          COMPUTE_FINISHED <= 1'b0;
        end
        // Inputs taken in LSB first manner
        ST_INPUT_A: begin 
			case(IO_COUNTER)
				3'd0: INPUT_A [7:0] <= ui_in;
				3'd1: INPUT_A [15:8]  <= ui_in;
				3'd2: INPUT_A [23:16] <= ui_in;
				3'd3: INPUT_A [31:24] <= ui_in;
				3'd4: INPUT_A [39:32] <= ui_in;
				3'd5: INPUT_A [47:40] <= ui_in;
				3'd6: INPUT_A [55:48] <= ui_in;
				3'd7: INPUT_A [63:56] <= ui_in;
				default: ;
			 endcase
//          INPUT_A [IO_COUNTER + 7 : IO_COUNTER] <= ui_in;
          IO_COUNTER <= IO_COUNTER + 3'd1;
        end
        ST_INPUT_B: begin 
			 case(IO_COUNTER)
				3'd0: INPUT_B [7:0] <= ui_in;
				3'd1: INPUT_B [15:8]  <= ui_in;
				3'd2: INPUT_B [23:16] <= ui_in;
				3'd3: INPUT_B [31:24] <= ui_in;
				3'd4: INPUT_B [39:32] <= ui_in;
				3'd5: INPUT_B [47:40] <= ui_in;
				3'd6: INPUT_B [55:48] <= ui_in;
				3'd7: INPUT_B [63:56] <= ui_in;
				default: ;
			 endcase
//          INPUT_A [IO_COUNTER + 7 : IO_COUNTER] <= ui_in;
          IO_COUNTER <= IO_COUNTER + 3'd1;
        end
        ST_COMPUTE : begin
          if(B_ZERO != 0) begin
            if(INPUT_A < INPUT_B)
              INPUT_A <= INPUT_B;
            else
              INPUT_A <= SUB_OUT;
            INPUT_B <= INPUT_A;
          end
          else begin
            COMPUTE_FINISHED <= 1'b1;
          end
        end
        ST_OUTPUT: begin
			COMPUTE_FINISHED <= 1'b0;
			 case(IO_COUNTER)
				3'd0: REG_UO <= INPUT_A [7:0]  ;
				3'd1: REG_UO <= INPUT_A [15:8] ;
				3'd2: REG_UO <= INPUT_A [23:16];
				3'd3: REG_UO <= INPUT_A [31:24];
				3'd4: REG_UO <= INPUT_A [39:32];
				3'd5: REG_UO <= INPUT_A [47:40];
				3'd6: REG_UO <= INPUT_A [55:48];
				3'd7: REG_UO <= INPUT_A [63:56];
				default: ;
			 endcase
//          REG_UO <= INPUT_A [IO_COUNTER + 7 : IO_COUNTER];
          IO_COUNTER <= IO_COUNTER + 3'd1;
        end
        default: ;
      endcase
    end
  end

  // All output pins must be assigned. If not used, assign to 0.
  assign uo_out  = REG_UO;  // Example: ou_out is the sum of ui_in and uio_in
  assign uio_out = {3'd0, COMPUTE_FINISHED, 4'd0};
  assign uio_oe  = 8'h0F;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, clk, rst_n, 1'b0};

endmodule
