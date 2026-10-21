/*
 * Tiny Tapeout AI Accelerator Chip Top Module
 * Target: SkyWater 130nm ASIC Process
 */

`default_nettype none

module tt_um_ai_accelerator (
    input  wire [7:0] ui_in,    // Dedicated inputs: Data Aktivasi A (INT8)
    output wire [7:0] uo_out,   // Dedicated outputs: Hasil komputasi / ReLU (INT8)
    input  wire [7:0] uio_in,   // IOs: Input Bobot W (INT8)
    output wire [7:0] uio_out,  // IOs: Bidirectional Output (tidak dipakai)
    output wire [7:0] uio_oe,   // IOs: Output Enable (set ke 0 untuk input)
    input  wire       ena,      // Will go high when the design is enabled
    input  wire       clk,      // Clock sinyal
    input  wire       rst_n     // Reset active low
);

    // Semua pin uio diset sebagai input
    assign uio_oe  = 8'b00000000;
    assign uio_out = 8'b00000000;

    // Register input
    reg signed [7:0] a_reg;
    reg signed [7:0] w_reg;
    reg signed [15:0] accum;

    // Perkalian paralel INT8 x INT8 = INT16
    wire signed [15:0] product = a_reg * w_reg;

    always @(posedge clk) begin
        if (!rst_n) begin
            a_reg <= 8'd0;
            w_reg <= 8'd0;
            accum <= 16'd0;
        end else if (ena) begin
            a_reg <= ui_in;
            w_reg <= uio_in;
            // Akumulasi MAC Unit: Accum = Accum + (A * W)
            accum <= accum + product;
        end
    end

    // ReLU Activation Function:
    // Jika akumulasi negatif (< 0), hasil dipotong ke 0.
    // Jika positif, kita ambil 8-bit yang ter-skala.
    wire is_negative = accum[15];
    wire [7:0] relu_out = is_negative ? 8'd0 : accum[7:0];

    // Output ke pin luar chip
    assign uo_out = relu_out;

endmodule
