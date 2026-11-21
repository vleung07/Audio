/*
To run on modelsim
vlog audio_demo.v Don.v Katsu.v tb_audio.v
vsim -L altera_mf_ver work.tb_audio
add wave -radix unsigned /tb_audio/dut/addr_don
add wave -radix unsigned /tb_audio/dut/addr_ka
add wave -radix unsigned /tb_audio/dut/don_rom/address
add wave /tb_audio/dut/don_rom/clock
add wave -radix hex /tb_audio/dut/q_don
add wave -radix hex /tb_audio/dut/q_ka
add wave -format Analog-Automatic -radix decimal /tb_audio/dut/mix_L
run -all
*/
`timescale 1ns / 1ps

module tb_audio;

    // Inputs to audio_demo
    reg CLOCK_50;
    reg [3:0] KEY;
    reg [9:0] SW;

    // Instantiate your top-level module
    audio_demo dut (
        .CLOCK_50 (CLOCK_50),
        .KEY      (KEY),
        .SW       (SW)
    );

    // 1. Generate 50 MHz clock (20 ns period)
    initial CLOCK_50 = 1'b0;
    always #10 CLOCK_50 = ~CLOCK_50;

    // 2. Simulate the audio chip asking for a new sample every 10 clock cycles
    initial begin
        force dut.audio_out_allowed = 1'b0;
        forever begin
            repeat (9) @(posedge CLOCK_50);
            force dut.audio_out_allowed = 1'b1;
            @(posedge CLOCK_50);
            force dut.audio_out_allowed = 1'b0;
        end
    end

    // 3. Test sequence: Reset -> Solo Don -> Solo Katsu -> Both Together
    initial begin
        // Default state: all keys unpressed (active-low = 1)
        KEY = 4'b1111;
        SW  = 10'b0;

        // Assert reset (KEY[0] = 0) for 5 clock cycles
        KEY[0] = 1'b0;
        repeat (5) @(posedge CLOCK_50);
        KEY[0] = 1'b1;
        repeat (10) @(posedge CLOCK_50);

        // 1. Solo Don: Press KEY[1]
        KEY[1] = 1'b0;
        repeat (5) @(posedge CLOCK_50);
        KEY[1] = 1'b1;
        repeat (150) @(posedge CLOCK_50);

        // 2. Solo Katsu: Reset briefly so Don stops, then press KEY[2]
        KEY[0] = 1'b0;
        repeat (5) @(posedge CLOCK_50);
        KEY[0] = 1'b1;
        repeat (10) @(posedge CLOCK_50);

        KEY[2] = 1'b0;
        repeat (5) @(posedge CLOCK_50);
        KEY[2] = 1'b1;
        repeat (150) @(posedge CLOCK_50);

        // 3. Both Together: Press KEY[1] (Don) while Katsu is still playing
        KEY[1] = 1'b0;
        repeat (5) @(posedge CLOCK_50);
        KEY[1] = 1'b1;

        // Let both sounds play and mix for 20 more samples, then stop
        repeat (200) @(posedge CLOCK_50);
        $stop;
    end

endmodule

module Audio_Controller (
    input CLOCK_50, reset, clear_audio_in_memory, read_audio_in,
    input clear_audio_out_memory, write_audio_out,
    input [31:0] left_channel_audio_out, right_channel_audio_out,
    input AUD_ADCDAT,
    inout AUD_BCLK, AUD_ADCLRCK, AUD_DACLRCK,
    output audio_in_available, audio_out_allowed, AUD_XCK, AUD_DACDAT,
    output [31:0] left_channel_audio_in, right_channel_audio_in
);
endmodule

module avconf #(
    parameter USE_MIC_INPUT = 0
) (
    input CLOCK_50, reset,
    output FPGA_I2C_SCLK,
    inout FPGA_I2C_SDAT
);
endmodule
