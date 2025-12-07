`timescale 1ns/1ps

module RV32I_FPGA_Top (
    input  logic        CLOCK_50,   // clock 50MHz từ board
    input  logic [17:0] SW,         // switch
    input  logic [3:0]  KEY,        // nút nhấn
    output logic [17:0] LEDR        // LED
);
    // ----------------------------
    // Reset: giả sử KEY[0] là reset_n (nhấn = 0, thả = 1)
    // ----------------------------
    logic rst_n;
    assign rst_n = KEY[0];   // nếu bạn muốn nhấn để reset thì có thể invert: KEY[0]

    // ----------------------------
    // Clock divider: từ 50MHz -> clock chậm cho CPU
    // ----------------------------
    logic cpu_clk;
    Clock_Divider #(
        .DIV(500_000)     // chỉnh tùy bạn muốn chậm/nhanh
    ) u_clk_div (
        .clk_in (CLOCK_50),
        .rst_n  (rst_n),
        .clk_out(cpu_clk)
    );

    // ----------------------------
    // Kết nối SW/LED 8 bit thấp cho CPU
    // ----------------------------
    logic [7:0] sw_cpu;
    logic [7:0] led_cpu;

    assign sw_cpu      = SW[7:0];          // dùng 8 SW thấp
    assign LEDR[7:0]   = led_cpu;          // 8 LED thấp hiển thị counter
    assign LEDR[17:8]  = 10'b0;            // các LED còn lại tắt

    // ----------------------------
    // Instance core pipeline
    // RV32I_Pipline đã có port sw/led và Data_Memory đã map I/O
    // ----------------------------
    RV32I_Pipline #(
        .DEPTH_WORDS(2048)
    ) u_core (
        .clk  (cpu_clk),   // dùng clock đã chia
        .rst_n(rst_n),
        .sw   (sw_cpu),
        .led  (led_cpu)
    );

endmodule
