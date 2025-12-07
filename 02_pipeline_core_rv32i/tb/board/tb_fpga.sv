`timescale 1ns/1ps

module tb_fpga;

    // ------------------------------
    // Testbench signals
    // ------------------------------
    logic        CLOCK_50;
    logic [17:0] SW;
    logic [3:0]  KEY;
    logic [17:0] LEDR;

    // ------------------------------
    // Clock generator: 50 MHz
    // Period = 20 ns
    // ------------------------------
    initial begin
        CLOCK_50 = 0;
        forever #10 CLOCK_50 = ~CLOCK_50;   // 20 ns period → 50 MHz
    end

    // ------------------------------
    // Reset task
    // ------------------------------
    task reset();
    begin
        KEY[0] = 0;       // active-low reset
        #200;             // giữ reset trong 200 ns
        KEY[0] = 1;       // release reset
    end
    endtask


    // ------------------------------
    // DUT: FPGA Top
    // ------------------------------
    RV32I_FPGA_Top dut (
        .CLOCK_50 (CLOCK_50),
        .SW       (SW),
        .KEY      (KEY),
        .LEDR     (LEDR)
    );

    // ------------------------------
    // Test scenario
    // ------------------------------
    initial begin
        // Init
        SW      = 18'd0;
        KEY     = 4'b1111;  // KEY[0]=1 initially (not reset)

        // Apply reset
        reset();

        // =====================================================
        // TEST 1 – SW=1 → counter phải đếm lên
        // =====================================================
        $display("\n=== TEST 1: SW = 1 → Counter UP ===");
        SW[0] = 1;
        repeat (20) begin
            @(posedge CLOCK_50);
            $display("[%0t ns] LEDR = %0d", $time, LEDR[7:0]);
        end

        // =====================================================
        // TEST 2 – SW=0 → counter phải đếm xuống
        // =====================================================
        $display("\n=== TEST 2: SW = 0 → Counter DOWN ===");
        SW[0] = 0;
        repeat (20) begin
            @(posedge CLOCK_50);
            $display("[%0t ns] LEDR = %0d", $time, LEDR[7:0]);
        end

        // =====================================================
        // TEST 3 – Toggle SW liên tục
        // =====================================================
        $display("\n=== TEST 3: Toggle SW ===");
        repeat (10) begin
            SW[0] = ~SW[0];
            @(posedge CLOCK_50);
            $display("[%0t ns] SW=%0d LEDR=%0d", $time, SW[0], LEDR[7:0]);
        end

        // Done
        $display("\nSimulation Finished.");
        #100;
        $finish;
    end

endmodule
