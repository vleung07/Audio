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
    // (Fast-forwarded 100x so simulation finishes in milliseconds instead of minutes)
    initial begin
        force dut.audio_out_allowed = 1'b0;
        forever begin
            repeat (9) @(posedge CLOCK_50);
            force dut.audio_out_allowed = 1'b1;
            @(posedge CLOCK_50);
            force dut.audio_out_allowed = 1'b0;
        end
    end

    // 3. Test sequence: Reset -> Hit Don -> Hit Katsu while Don plays
    initial begin
        // Default state: all keys unpressed (active-low = 1)
        KEY = 4'b1111;
        SW  = 10'b0;

        // Assert reset (KEY[0] = 0) for 5 clock cycles
        KEY[0] = 1'b0;
        repeat (5) @(posedge CLOCK_50);
        KEY[0] = 1'b1;
        repeat (10) @(posedge CLOCK_50);

        // Press KEY[1] (Don)
        KEY[1] = 1'b0;
        repeat (5) @(posedge CLOCK_50);
        KEY[1] = 1'b1;

        // Wait 50 samples while Don is playing, then press KEY[2] (Katsu)
        repeat (500) @(posedge CLOCK_50);
        KEY[2] = 1'b0;
        repeat (5) @(posedge CLOCK_50);
        KEY[2] = 1'b1;

        // Let both sounds play and mix for 500 more samples, then stop
        repeat (5000) @(posedge CLOCK_50);
        $stop;
    end

endmodule