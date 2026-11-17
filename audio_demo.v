/*
This is a simple demo to read from a .mif memory file converted from .wav audio.

A single RAM consists of 2^16 = 65536 words, each word at most 32 bit wide.

Typical .wav files have 16-bit right channel and left channel data.

Python file wav_to_mif.py is provided to convert .wav file to .mif files.
Before conversion, convert .wav into either 48kHz or 24kHz using any converter.
Options (comment/uncomment blocks of this file):
	1. use 16-bit words, interleaving L, R, L, R (not recommended)
		a. 2^15 samples, default 48kHz, ~0.68 seconds
		b. 2^15 samples, down sample 24kHz, ~1.37 seconds
	2. use 32-bit words, L on upper 16 bits, R on lower 16 bits
		a. 2^16 samples, default 48kHz, ~1.37 seconds
		b. 2^16 samples, down sample 24kHz, ~2.7 seconds
	3. use 32-bit words, only storing L, 2 samples per word (compressed)
		a. 2^17 samples, default 48kHz, ~2.7 seconds
		b. 2^17 samples, down sample 24kHz, ~5.5 seconds (this file)

Generating .mifs for the options:
	1. python .\wav_to_mif.py .\intel-sound-logo_resampled.wav intel-sound-logo.mif 
	2. python .\wav_to_mif.py .\intel-sound-logo_resampled.wav intel-sound-logo.mif --pack32
	3. python .\wav_to_mif.py .\intel-sound-logo_downsampled.wav intel-sound-logo.mif --pack32 --double-left
*/


module audio_demo (
	// Inputs
	CLOCK_50,
	KEY,

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
	//LEDR
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
//output LEDR;

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

localparam [15:0] DON_MAX   = 16'd39835;
localparam [15:0] KATSU_MAX = 16'd19536;

reg playback_don, playback_ka;
reg [15:0] addr_don, addr_ka;

always @(posedge CLOCK_50) begin
    if (reset) begin
        playback_don <= 1'b0;
        addr_don     <= 16'b0;
    end else if (don_trigger) begin
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
    end else if (ka_trigger) begin
        playback_ka <= 1'b1;
        addr_ka     <= 16'b0;
    end else if (audio_out_allowed && playback_ka) begin
        if (addr_ka == KATSU_MAX)
            playback_ka <= 1'b0;
        else
            addr_ka <= addr_ka + 1'b1;
    end
end

assign reset = ~KEY[0];

/****32bit, L Only, Down Sampled****/

/*always @(posedge CLOCK_50) begin
	if (reset) begin
		enable <= 1'b0;
		is_lower <= 1'b0;
		delay <= 1'b0;
	end else if (audio_out_allowed && playback) begin
		if (delay && is_lower) begin
			enable <= 1'b1;
			delay <= 1'b0;
		end else if (delay) begin
			enable <= 1'b0;
		end else if (is_lower) begin
			delay <= ~delay;
			enable <= 1'b0;
		end else begin
			enable <= 1'b0;
		end
		is_lower <= ~is_lower;
	end
end

assign left_channel_audio_out	= (is_lower) ? {q_data[15:0], 16'b0} : {q_data[31:16], 16'b0};
assign right_channel_audio_out	= (is_lower) ? {q_data[15:0], 16'b0} : {q_data[31:16], 16'b0};
*/

/****32bit, L Only, Default rate****/
/*
always @(posedge CLOCK_50) begin
	if (reset) begin
		enable <= 1'b0;
		is_lower <= 1'b0;
	end else if (audio_out_allowed && playback) begin
		if (is_lower) begin
			enable <= 1'b1;
		end else begin
			enable <= 1'b0;
		end
		is_lower <= ~is_lower;
	end
end

assign left_channel_audio_out	= (is_lower) ? {q_data[15:0], 16'b0} : {q_data[31:16], 16'b0};
assign right_channel_audio_out	= (is_lower) ? {q_data[15:0], 16'b0} : {q_data[31:16], 16'b0};
*/

/****32bit, L R, Down sampled****/
/*
always @(posedge CLOCK_50) begin
	if (reset) begin
		enable <= 1'b0;
		delay <= 1'b0;
	end else if (audio_out_allowed && playback) begin
		if (delay) begin
			enable <= 1'b1;
		end else begin
			enable <= 1'b0;
		end
		delay <= ~delay;
	end
end

assign left_channel_audio_out	= {q_data[31:16], 16'b0};
assign right_channel_audio_out = {q_data[15:0], 16'b0};
*/

/****32bit, L R, Default rate****/
/*
always @(posedge CLOCK_50) begin
	if (reset) begin
		enable <= 1'b0;
	end else if (audio_out_allowed && playback) begin
		enable <= 1'b1;
	end
end
*/

// top 16 or bottom 16 
//if no playback then no sound
wire signed [15:0] don_L = playback_don ? q_don[31:16] : 16'sd0; 
wire signed [15:0] don_R = playback_don ? q_don[15:0]  : 16'sd0;

wire signed [15:0] ka_L  = playback_ka  ? q_ka[31:16]  : 16'sd0;
wire signed [15:0] ka_R  = playback_ka  ? q_ka[15:0]   : 16'sd0;

// put both sounds together if theyre hit at the same time 
// binary addition (2 maxed out 16 bits would leave 17 bits)
wire signed [16:0] mix_L = don_L + ka_L;
wire signed [16:0] mix_R = don_R + ka_R;

assign left_channel_audio_out  = {mix_L[16:1], 16'b0};
assign right_channel_audio_out = {mix_R[16:1], 16'b0};


// always @(posedge CLOCK_50) begin
//     if (reset)
//         write_audio_out <= 1'b0;
//     else
//         write_audio_out <= audio_out_allowed && (playback_don || playback_ka);
// end

assign write_audio_out = audio_out_allowed;


/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/




//maybe remake this with ROM as well
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

//debug
//assign LEDR[0] = playback_don;
//assign LEDR[1] = playback_ka;
//assign LEDR[2] = audio_out_allowed;
//assign LEDR[9:3] = addr_don[14:8];
endmodule

