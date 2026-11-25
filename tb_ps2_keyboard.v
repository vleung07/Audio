/* to run in modelsim
vlib work
vlog ps2_keyboard.v tb_ps2_keyboard.v
vsim work.tb_ps2_keyboard
add wave -radix hex /tb_ps2_keyboard/*
add wave -radix hex /tb_ps2_keyboard/uut/is_held /tb_ps2_keyboard/uut/held_code
run -all
*/

`timescale 1ns / 1ps

module tb_ps2_keyboard;

    reg        CLOCK_50;
    reg        reset;
    reg        PS2_CLK;
    reg        PS2_DAT;
    wire [7:0] scancode;
    wire       key_pressed;

    // Instantiate Unit Under Test (UUT)
    ps2_keyboard uut (
        .CLOCK_50    (CLOCK_50),
        .reset       (reset),
        .PS2_CLK     (PS2_CLK),
        .PS2_DAT     (PS2_DAT),
        .scancode    (scancode),
        .key_pressed (key_pressed)
    );

    // 50 MHz system clock (20 ns period)
    initial CLOCK_50 = 1'b0;
    always #10 CLOCK_50 = ~CLOCK_50;

    // Task to transmit one 11-bit PS/2 frame (LSB first, sampled on negedge PS2_CLK)
    task send_ps2_byte;
        input [7:0] data;
        integer i;
        reg parity;
        begin
            // Odd parity bit required by PS/2 protocol
            parity = ~(^data);

            // 1. Start bit (0)
            PS2_DAT = 1'b0;
            #500 PS2_CLK = 1'b0;
            #500 PS2_CLK = 1'b1;

            // 2. 8 Data bits (LSB first: bit 0 to bit 7)
            for (i = 0; i < 8; i = i + 1) begin
                PS2_DAT = data[i];
                #500 PS2_CLK = 1'b0;
                #500 PS2_CLK = 1'b1;
            end

            // 3. Parity bit
            PS2_DAT = parity;
            #500 PS2_CLK = 1'b0;
            #500 PS2_CLK = 1'b1;

            // 4. Stop bit (1)
            PS2_DAT = 1'b1;
            #500 PS2_CLK = 1'b0;
            #500 PS2_CLK = 1'b1;

            // Idle gap between bytes
            #2000;
        end
    endtask

    initial begin
        // Initialize inputs (PS/2 lines idle high, reset is active-low)
        reset   = 1'b0;
        PS2_CLK = 1'b1;
        PS2_DAT = 1'b1;
        #100;

        // Release reset
        reset = 1'b1;
        #200;

        // Test 1: Press 'G' (scancode 8'h34) -> key_pressed should pulse for 1 cycle
        send_ps2_byte(8'h34);

        // Test 2: Hold 'G' (keyboard auto-repeats 8'h34) -> key_pressed must stay 0
        send_ps2_byte(8'h34);
        send_ps2_byte(8'h34);

        // Test 3: Release 'G' (break prefix 8'hF0 followed by 8'h34) -> key_pressed must stay 0
        send_ps2_byte(8'hF0);
        send_ps2_byte(8'h34);

        // Test 4: Press 'G' again after release -> key_pressed should pulse again
        send_ps2_byte(8'h34);

        // Test 5: Press 'F' (scancode 8'h2B) -> key_pressed pulses with 8'h2B
        send_ps2_byte(8'h2B);

        #2000;
        $stop;
    end

endmodule