// for reference when adding more sounds

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