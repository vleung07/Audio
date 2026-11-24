
module audio_demo (
	// Inputs
	CLOCK_50,
	KEY,
    PS2_CLK,
	PS2_DAT,

	AUD_ADCDAT,

	// Bidirectionals
	AUD_BCLK,
	AUD_ADCLRCK,
	AUD_DACLRCK,

	FPGA_I2C_SDAT,

	// Outputs
	AUD_XCK,
	AUD_DACDAT,

	FPGA_I2C_SCLK,
	SW
	
);

/*****************************************************************************
 *                           Parameter Declarations                          *
 *****************************************************************************/


/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/
// Inputs
input				CLOCK_50;
input		[3:0]	KEY;
input		[3:0]	SW;
input PS2_CLK, PS2_DAT;

input				AUD_ADCDAT;

// Bidirectionals
inout				AUD_BCLK;
inout				AUD_ADCLRCK;
inout				AUD_DACLRCK;

inout				FPGA_I2C_SDAT;

// Outputs
output				AUD_XCK;
output				AUD_DACDAT;

output				FPGA_I2C_SCLK;

/*****************************************************************************
 *                 Internal Wires and Registers Declarations                 *
 *****************************************************************************/
// Internal Wires
wire				audio_in_available;
reg		[31:0]	left_channel_audio_in;
reg		[31:0]	right_channel_audio_in;
wire				read_audio_in;

wire				audio_out_allowed;
wire		[31:0]	left_channel_audio_out;
wire		[31:0]	right_channel_audio_out;
wire				write_audio_out;

wire [31:0] q_ka;
wire [31:0] q_don;

//not enough memory
/*wire [7:0]  q_bgm;

reg  [17:0] addr_bgm;
reg  [2:0]  bgm_div; // Divides 48 kHz by 6 -> 8 kHz
reg         bgm_done;*/

//wire     [31:0] q_data;

// Internal Registers

wire reset;
reg playback;
//reg [15:0] addr_cnt;
reg is_lower;
reg delay; // down sampling to 24k

reg enable;

// State Machine Registers

/*****************************************************************************
 *                         Finite State Machine(s)                           *
 *****************************************************************************/


/*****************************************************************************
 *                             Sequential Logic                              *
 *****************************************************************************/

//play note on hit
reg key1_prev, key2_prev;
wire don_trigger = key1_prev && ~KEY[1];
wire ka_trigger  = key2_prev && ~KEY[2];

always @(posedge CLOCK_50) begin
    if (reset) begin
        key1_prev <= 1'b1;
        key2_prev <= 1'b1;
    end else begin
        key1_prev <= KEY[1];
        key2_prev <= KEY[2];
    end
end

wire [7:0] keyVal;
wire key_pressed;

ps2_keyboard u_keyb(
    .CLOCK_50    (CLOCK_50),
    .reset       (KEY[0]), 
    .PS2_CLK     (PS2_CLK),
    .PS2_DAT     (PS2_DAT),
    .scancode    (keyVal),
    .key_pressed (key_pressed)
);

wire don_key_trigger = key_pressed && (keyVal == 8'h34 || keyVal == 8'h33);//g or h
wire ka_key_trigger  = key_pressed && (keyVal == 8'h2B || keyVal == 8'h3B);//f or j

localparam [15:0] DON_MAX   = 16'd39835;
localparam [15:0] KATSU_MAX = 16'd19536;

reg playback_don, playback_ka;
reg [15:0] addr_don, addr_ka;

always @(posedge CLOCK_50) begin
    if (reset) begin
        playback_don <= 1'b0;
        addr_don     <= 16'b0;
    end else if (don_trigger || don_key_trigger) begin
        playback_don <= 1'b1;
        addr_don     <= 16'b0;
    end else if (audio_out_allowed && playback_don) begin
        if (addr_don == DON_MAX)
            playback_don <= 1'b0;
        else
            addr_don <= addr_don + 1'b1;
    end
end

always @(posedge CLOCK_50) begin
    if (reset) begin
        playback_ka <= 1'b0;
        addr_ka     <= 16'b0;
    end else if (ka_trigger || ka_key_trigger) begin
        playback_ka <= 1'b1;
        addr_ka     <= 16'b0;
    end else if (audio_out_allowed && playback_ka) begin
        if (addr_ka == KATSU_MAX)
            playback_ka <= 1'b0;
        else
            addr_ka <= addr_ka + 1'b1;
    end
end
//not enough memory
/*
always @(posedge CLOCK_50) begin
    if (reset || !bgm_en) begin
        addr_bgm <= 18'd0;
        bgm_div  <= 3'd0;
        bgm_done <= 1'b0;
    end else if (audio_out_allowed && !bgm_done) begin
        if (bgm_div == 3'd5) begin
            bgm_div <= 3'd0;
            if (addr_bgm == BGM_MAX)
                bgm_done <= 1'b1; // Stop at the end of the track
            else
                addr_bgm <= addr_bgm + 18'd1;
        end else begin
            bgm_div <= bgm_div + 3'd1;
        end
    end
end
*/

assign reset = ~KEY[0];

// top 16 or bottom 16 
//if no playback then no sound
wire signed [15:0] don_L = playback_don ? q_don[31:16] : 16'sd0; 
wire signed [15:0] don_R = playback_don ? q_don[15:0]  : 16'sd0;

wire signed [15:0] ka_L  = playback_ka  ? q_ka[31:16]  : 16'sd0;
wire signed [15:0] ka_R  = playback_ka  ? q_ka[15:0]   : 16'sd0;

wire signed [15:0] bgm_out;

bgm_player u_bgm (
    .CLOCK_50      (CLOCK_50),
    .reset         (~KEY[0]), // Active-high reset (matches active-low KEY[0])
    .enable        (SW[0]),   // Flip SW[0] up to play BGM
    .bgm_audio_out (bgm_out)
);

// put both sounds together if theyre hit at the same time 
// binary addition (2 maxed out 16 bits would leave 17 bits)

//not enough memory...
/*wire signed [15:0] bgm_sample = (bgm_en && !bgm_done) ? {q_bgm, 8'd0} : 16'sd0;
wire signed [17:0] mix_L = don_L + ka_L + bgm_sample;
wire signed [17:0] mix_R = don_R + ka_R + bgm_sample;

assign left_channel_audio_out  = {mix_L[17:2], 16'b0};
assign right_channel_audio_out = {mix_R[17:2], 16'b0};*/

wire signed [17:0] mix_L = don_L + ka_L + bgm_out;
wire signed [17:0] mix_R = don_R + ka_R + bgm_out;

assign left_channel_audio_out  = {mix_L[17:2], 16'b0};
assign right_channel_audio_out = {mix_R[17:2], 16'b0};

assign write_audio_out = audio_out_allowed;


/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/


//not enough memory
/*
localparam [17:0] BGM_MAX = 18'd158165; 

BGM bgm_rom (
    .address ( addr_bgm ),
    .clock   ( CLOCK_50 ),
    .q       ( q_bgm )
);

wire bgm_en = SW[0];
*/

Don	don_rom (
.address ( addr_don[15:0] ),
.clock ( CLOCK_50 ),
.q ( q_don )
);

Katsu katsu_rom (
    .address ( addr_ka[14:0] ),
    .clock   ( CLOCK_50 ),
    .q       ( q_ka )
);

 
Audio_Controller Audio_Controller (
	// Inputs
	.CLOCK_50						(CLOCK_50),
	.reset						(~KEY[0]),

	.clear_audio_in_memory		(),
	.read_audio_in				(read_audio_in),
	
	.clear_audio_out_memory		(),
	.left_channel_audio_out		(left_channel_audio_out),
	.right_channel_audio_out	(right_channel_audio_out),
	.write_audio_out			(write_audio_out),

	.AUD_ADCDAT					(AUD_ADCDAT),

	// Bidirectionals
	.AUD_BCLK					(AUD_BCLK),
	.AUD_ADCLRCK				(AUD_ADCLRCK),
	.AUD_DACLRCK				(AUD_DACLRCK),


	// Outputs
	.audio_in_available			(audio_in_available),
	.left_channel_audio_in		(),
	.right_channel_audio_in		(),

	.audio_out_allowed			(audio_out_allowed),

	.AUD_XCK					(AUD_XCK),
	.AUD_DACDAT					(AUD_DACDAT)

);

avconf #(.USE_MIC_INPUT(1)) avc (
	.FPGA_I2C_SCLK					(FPGA_I2C_SCLK),
	.FPGA_I2C_SDAT					(FPGA_I2C_SDAT),
	.CLOCK_50					(CLOCK_50),
	.reset						(~KEY[0])
);

endmodule

