module bgm_player (
    CLOCK_50,
    reset,
    enable,
    bgm_audio_out
);

    input                CLOCK_50, reset, enable;
    output signed [15:0] bgm_audio_out; 

    // 1 tick = 1/6th of a quarter note at 120 BPM (50 MHz / 12 = 4,166,667 clocks)
    parameter [22:0] CLKS_PER_TICK = 23'd4166667;
    parameter [6:0]  TOTAL_NOTES   = 7'd81; 

    // all the notes
    parameter [4:0] REST = 5'd0,
                    F4   = 5'd1,  G4   = 5'd2,  A4   = 5'd3,  AS4  = 5'd4,
                    B4   = 5'd5,  C5   = 5'd6,  D5   = 5'd7,  E5   = 5'd8,
                    F5   = 5'd9,  G5   = 5'd10, A5   = 5'd11, B5   = 5'd12,
                    C6   = 5'd13, D6   = 5'd14, E6   = 5'd15;

    reg [6:0]  note_idx;
    reg [22:0] clk_cnt;
    reg [4:0]  tick_cnt;

    reg [4:0]  curr_pitch;
    reg [4:0]  curr_dur; // Duration in ticks 

    
    always @(*) begin
        case (note_idx)
            // Bar 1
            7'd0:  {curr_pitch, curr_dur} = {REST, 5'd4};
            7'd1:  {curr_pitch, curr_dur} = {G4,   5'd2};
            7'd2:  {curr_pitch, curr_dur} = {C5,   5'd2};
            7'd3:  {curr_pitch, curr_dur} = {G4,   5'd2};
            7'd4:  {curr_pitch, curr_dur} = {C5,   5'd2};
            7'd5:  {curr_pitch, curr_dur} = {D5,   5'd2};
            7'd6:  {curr_pitch, curr_dur} = {G4,   5'd2};
            7'd7:  {curr_pitch, curr_dur} = {D5,   5'd2};
            7'd8:  {curr_pitch, curr_dur} = {E5,   5'd2};
            7'd9:  {curr_pitch, curr_dur} = {G4,   5'd2};
            7'd10: {curr_pitch, curr_dur} = {E5,   5'd2};
            // Bar 2
            7'd11: {curr_pitch, curr_dur} = {F5,   5'd4};
            7'd12: {curr_pitch, curr_dur} = {E5,   5'd2};
            7'd13: {curr_pitch, curr_dur} = {D5,   5'd4};
            7'd14: {curr_pitch, curr_dur} = {C5,   5'd2};
            7'd15: {curr_pitch, curr_dur} = {G4,   5'd2};
            7'd16: {curr_pitch, curr_dur} = {C5,   5'd2};
            7'd17: {curr_pitch, curr_dur} = {B4,   5'd2};
            7'd18: {curr_pitch, curr_dur} = {A4,   5'd4};
            7'd19: {curr_pitch, curr_dur} = {G4,   5'd2};
            // Bar 3
            7'd20: {curr_pitch, curr_dur} = {REST, 5'd4};
            7'd21: {curr_pitch, curr_dur} = {G4,   5'd2};
            7'd22: {curr_pitch, curr_dur} = {C5,   5'd2};
            7'd23: {curr_pitch, curr_dur} = {G4,   5'd2};
            7'd24: {curr_pitch, curr_dur} = {C5,   5'd2};
            7'd25: {curr_pitch, curr_dur} = {E5,   5'd2};
            7'd26: {curr_pitch, curr_dur} = {G4,   5'd2};
            7'd27: {curr_pitch, curr_dur} = {E5,   5'd2};
            7'd28: {curr_pitch, curr_dur} = {F5,   5'd2};
            7'd29: {curr_pitch, curr_dur} = {G4,   5'd2};
            7'd30: {curr_pitch, curr_dur} = {F5,   5'd2};
            // Bar 4
            7'd31: {curr_pitch, curr_dur} = {G5,   5'd4};
            7'd32: {curr_pitch, curr_dur} = {F5,   5'd2};
            7'd33: {curr_pitch, curr_dur} = {D5,   5'd2};
            7'd34: {curr_pitch, curr_dur} = {E5,   5'd2};
            7'd35: {curr_pitch, curr_dur} = {C5,   5'd2};
            7'd36: {curr_pitch, curr_dur} = {D5,   5'd2};
            7'd37: {curr_pitch, curr_dur} = {B4,   5'd2};
            7'd38: {curr_pitch, curr_dur} = {C5,   5'd2};
            7'd39: {curr_pitch, curr_dur} = {D5,   5'd3};
            7'd40: {curr_pitch, curr_dur} = {REST, 5'd3};
            // Bar 5
            7'd41: {curr_pitch, curr_dur} = {F4,   5'd3};
            7'd42: {curr_pitch, curr_dur} = {G4,   5'd3};
            7'd43: {curr_pitch, curr_dur} = {A4,   5'd3};
            7'd44: {curr_pitch, curr_dur} = {AS4,  5'd3};
            7'd45: {curr_pitch, curr_dur} = {B4,   5'd3};
            7'd46: {curr_pitch, curr_dur} = {C5,   5'd3};
            7'd47: {curr_pitch, curr_dur} = {D5,   5'd3};
            7'd48: {curr_pitch, curr_dur} = {E5,   5'd3};
            // Bar 6
            7'd49: {curr_pitch, curr_dur} = {F5,   5'd3};
            7'd50: {curr_pitch, curr_dur} = {REST, 5'd3};
            7'd51: {curr_pitch, curr_dur} = {B5,   5'd2};
            7'd52: {curr_pitch, curr_dur} = {B5,   5'd2};
            7'd53: {curr_pitch, curr_dur} = {B5,   5'd2};
            7'd54: {curr_pitch, curr_dur} = {B5,   5'd6};
            7'd55: {curr_pitch, curr_dur} = {REST, 5'd6};
            // Bar 7
            7'd56: {curr_pitch, curr_dur} = {C6,   5'd6};
            7'd57: {curr_pitch, curr_dur} = {B5,   5'd2};
            7'd58: {curr_pitch, curr_dur} = {A5,   5'd2};
            7'd59: {curr_pitch, curr_dur} = {G5,   5'd2};
            7'd60: {curr_pitch, curr_dur} = {F5,   5'd6};
            7'd61: {curr_pitch, curr_dur} = {C6,   5'd6};
            // Bar 8
            7'd62: {curr_pitch, curr_dur} = {B5,   5'd6};
            7'd63: {curr_pitch, curr_dur} = {A5,   5'd2};
            7'd64: {curr_pitch, curr_dur} = {G5,   5'd2};
            7'd65: {curr_pitch, curr_dur} = {F5,   5'd2};
            7'd66: {curr_pitch, curr_dur} = {E5,   5'd6};
            7'd67: {curr_pitch, curr_dur} = {B5,   5'd6};
            // Bar 9
            7'd68: {curr_pitch, curr_dur} = {A5,   5'd6};
            7'd69: {curr_pitch, curr_dur} = {G5,   5'd2};
            7'd70: {curr_pitch, curr_dur} = {F5,   5'd2};
            7'd71: {curr_pitch, curr_dur} = {E5,   5'd2};
            7'd72: {curr_pitch, curr_dur} = {D5,   5'd3};
            7'd73: {curr_pitch, curr_dur} = {C5,   5'd3};
            7'd74: {curr_pitch, curr_dur} = {B4,   5'd3};
            7'd75: {curr_pitch, curr_dur} = {C5,   5'd3};
            // Bar 10
            7'd76: {curr_pitch, curr_dur} = {D5,   5'd6};
            7'd77: {curr_pitch, curr_dur} = {D5,   5'd2};
            7'd78: {curr_pitch, curr_dur} = {F5,   5'd2};
            7'd79: {curr_pitch, curr_dur} = {B5,   5'd2};
            7'd80: {curr_pitch, curr_dur} = {E6,   5'd6};
            7'd81: {curr_pitch, curr_dur} = {REST, 5'd6};

            default: {curr_pitch, curr_dur} = {REST, 5'd6};
        endcase
    end

    //1/2freq for when to flip for the right tone
    reg [17:0] half_period;
    always @(*) begin
        case (curr_pitch)
            F4:      half_period = 18'd71586;
            G4:      half_period = 18'd63776;
            A4:      half_period = 18'd56818;
            AS4:     half_period = 18'd53629;
            B4:      half_period = 18'd50619;
            C5:      half_period = 18'd47778;
            D5:      half_period = 18'd42566;
            E5:      half_period = 18'd37922;
            F5:      half_period = 18'd35793;
            G5:      half_period = 18'd31888;
            A5:      half_period = 18'd28409;
            B5:      half_period = 18'd25310;
            C6:      half_period = 18'd23889;
            D6:      half_period = 18'd21283;
            E6:      half_period = 18'd18961;
            default: half_period = 18'd0;
        endcase
    end

    // play the song
    always @(posedge CLOCK_50) begin
        if (reset || !enable) begin
            clk_cnt  <= 23'd0;
            tick_cnt <= 5'd0;
            note_idx <= 7'd0;
        end else begin
            if (clk_cnt == CLKS_PER_TICK - 1) begin
                clk_cnt <= 23'd0;
                if (tick_cnt + 5'd1 >= curr_dur) begin
                    tick_cnt <= 5'd0;
                    if (note_idx <= TOTAL_NOTES) begin
                        note_idx <= note_idx + 7'd1;
                    end
                end else begin
                    tick_cnt <= tick_cnt + 5'd1;
                end
            end else begin
                clk_cnt <= clk_cnt + 23'd1;
            end
        end
    end

    
    reg [17:0] tone_cnt;
    reg        tone_sq;
    wire       articulate_gap;

    assign articulate_gap = (tick_cnt == curr_dur - 5'd1) && (clk_cnt > (CLKS_PER_TICK >> 1));

    always @(posedge CLOCK_50) begin
        if (reset || !enable || half_period == 18'd0 || articulate_gap) begin
            tone_cnt <= 18'd0;
            tone_sq  <= 1'b0;
        end else if (tone_cnt >= half_period - 18'd1) begin // flip pos to neg
            tone_cnt <= 18'd0;
            tone_sq  <= ~tone_sq;
        end else begin
            tone_cnt <= tone_cnt + 18'd1;
        end
    end

    // cap volume at 2048 to not max out the volume
    assign bgm_audio_out = (half_period == 18'd0 || articulate_gap) ? 16'sd0 :
                           (tone_sq ? 16'sd2048 : -16'sd2048);// + or - 
                           //square wave

endmodule