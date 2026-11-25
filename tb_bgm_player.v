/* to run on model sim
vlog bgm_player.v tb_bgm_player.v
vsim work.tb_bgm_player
add wave /tb_bgm_player/CLOCK_50 /tb_bgm_player/reset /tb_bgm_player/enable
add wave -radix unsigned /tb_bgm_player/uut/note_idx /tb_bgm_player/uut/tick_cnt /tb_bgm_player/uut/half_period
add wave /tb_bgm_player/uut/articulate_gap
add wave -radix decimal -format analog -height 80 /tb_bgm_player/bgm_audio_out
run -all
*/

`timescale 1ns / 1ps

module tb_bgm_player;

    reg               CLOCK_50;
    reg               reset;
    reg               enable;
    wire signed [15:0] bgm_audio_out;

    // Instantiate UUT with shortened tick duration for fast simulation
    bgm_player #(
        .CLKS_PER_TICK(23'd100)
    ) uut (
        .CLOCK_50      (CLOCK_50),
        .reset         (reset),
        .enable        (enable),
        .bgm_audio_out (bgm_audio_out)
    );

    // 50 MHz system clock (20 ns period)
    initial CLOCK_50 = 1'b0;
    always #10 CLOCK_50 = ~CLOCK_50;

    initial begin
        // 1. Assert reset and keep BGM disabled
        reset  = 1'b1;
        enable = 1'b0;
        #200;

        // 2. Release reset while still disabled -> output must remain 0
        reset = 1'b0;
        #2000;

        // 3. Enable BGM playback -> steps through initial REST, G4, C5, etc.
        enable = 1'b1;
        #150000; // Run long enough to observe multiple notes and articulation gaps

        // 4. Mute via enable = 0 mid-song -> output must immediately drop to 0
        enable = 1'b0;
        #5000;

        // 5. Re-enable playback
        enable = 1'b1;
        #40000;

        $stop;
    end

endmodule