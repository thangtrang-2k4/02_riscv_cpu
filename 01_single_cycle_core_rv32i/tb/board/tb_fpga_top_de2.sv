`timescale 1ns/1ps

module tb_fpga_top_de2;

  // ====== Clock & Reset ======
  logic CLOCK_50;
  logic [3:0]  KEY;
  logic [17:0] SW;
  wire  [7:0]  LEDG;
  wire  [17:0] LEDR;

  // ====== Instantiate DUT ======
  fpga_top_de2 dut (
    .CLOCK_50 (CLOCK_50),
    .KEY      (KEY),
    .SW       (SW),
    .LEDG     (LEDG),
    .LEDR     (LEDR)
  );

  // ====== Clock generation ======
  // 50 MHz → 20 ns period
  initial begin
    CLOCK_50 = 0;
    forever #10 CLOCK_50 = ~CLOCK_50;
  end

  // ====== Stimulus ======
  initial begin
    // Ghi log
    $display("=== Simulation start ===");

    // Reset active-low: giữ 0 trong 100ns
    KEY[0] = 1'b0;
    #90;
    KEY[0] = 1'b1;

    // Không dùng KEY[3:1], set về 1
    KEY[3:1] = 3'b111;

    // ====== Test mode slow clock ======
    $display("[TEST] Running with slow clock (SW[0]=0)");
    SW[0] = 1'b1; // SW[0]=0 → slow clock
    repeat (5_000_000) @(posedge CLOCK_50); // chờ vài chu kỳ để slow_clk đổi

    $display("LEDG (a0[3:0]) = %b, LEDR[0] (heartbeat) = %b", LEDG[3:0], LEDR[0]);

    // ====== Test mode full speed ======
    $display("[TEST] Switch to full speed (SW[0]=1)");
    SW[0] = 1'b1;
    repeat (100) @(posedge CLOCK_50);
    $display("LEDG (a0[3:0]) = %b, LEDR[0] (heartbeat) = %b", LEDG[3:0], LEDR[0]);

  end
  initial begin
    // ====== End ======
    $display("=== Simulation end ===");
    #1000;
    $stop;
  end

endmodule
