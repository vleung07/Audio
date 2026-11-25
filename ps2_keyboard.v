//PS2 KEYBOARD IS ACTIVE LOW 
//when pressed it outputs 33 bits but we only need the first 11 if we just detect on hit
//bc the board does make, release, make 
//also the bits get sent 1 bit at a time on the negedge of the ps2 clock


module ps2_keyboard (CLOCK_50, reset, PS2_CLK, PS2_DAT, scancode, key_pressed);
    input  CLOCK_50, reset, PS2_CLK, PS2_DAT;
    output reg [7:0] scancode;    
    output reg key_pressed;

    //reset to high bc active low
    reg [1:0] clk_sync, dat_sync;
    always @(posedge CLOCK_50) begin
        if (!reset) begin
            clk_sync <= 2'b11;
            dat_sync <= 2'b11;
        end else begin
            clk_sync <= {clk_sync[0], PS2_CLK};
            dat_sync <= {dat_sync[0], PS2_DAT};
        end
    end

    wire negedge_ps2_clk = (clk_sync[1] == 1'b1) && (clk_sync[0] == 1'b0);
    wire ps2_data_bit = dat_sync[1];

    // take first 11
    reg [10:0] shift_reg;
    reg [3:0] bit_cnt;
    reg ignore_next; 
    // Flag to ignore the byte right after 8'hF0 (key release)
	 
	 reg [7:0] held_code;
	 reg is_held;

    always @(posedge CLOCK_50) begin
        if (!reset) begin
            shift_reg   <= 11'd0;
            bit_cnt <= 4'd0;
            scancode <= 8'd0;
            key_pressed <= 1'b0;
            ignore_next <= 1'b0;
				held_code <= 8'd0;
				is_held <= 1'b0;
        end else begin
            key_pressed <= 1'b0; // Default: pulse is only 1 clock cycle

            if (negedge_ps2_clk) begin
                //right shifting
                shift_reg <= {ps2_data_bit, shift_reg[10:1]};

                //first 11 bits received
                if (bit_cnt == 4'd10) begin
                    bit_cnt <= 4'd0;

                    if (shift_reg[9:2] == 8'hF0) begin
                        //release code so we want to ignore the one after to avoid double input
                        ignore_next <= 1'b1;
                    end else if (ignore_next) begin
                        ignore_next <= 1'b0;
								
								if (shift_reg[9:2] == held_code) begin
									is_held <= 1'b0;
									held_code <= 8'd0;
								end
                    end else begin
								if (!is_held || (shift_reg[9:2] != held_code)) begin
									scancode    <= shift_reg[9:2];
									key_pressed <= 1'b1;
									held_code <= shift_reg[9:2];
									is_held <= 1'b1;
									end
                    end
                end else begin
                    // keep going until 11 bits
                    bit_cnt <= bit_cnt + 4'd1;
                end
            end
        end
    end
endmodule