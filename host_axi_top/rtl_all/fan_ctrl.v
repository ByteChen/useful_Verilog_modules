module fan_ctrl (
	input clk,
	input reset_n,
	output fan_ctl_o
	);

  parameter FAN_OFF = 4000;
  parameter FAN_TOTAL = 10000;
  
  reg [11:0] pwm_reg;
  reg fan_ctl_o;

  always @ (posedge clk or negedge reset_n)	begin
  	if (~reset_n) begin	
  		pwm_reg <= 12'd0;
  		fan_ctl_o <= 1'b1;
  	end
  	else begin
  	 pwm_reg <= pwm_reg + 1'b1;
   	 if (pwm_reg == FAN_TOTAL)	begin
        fan_ctl_o <= 1'b1;
        pwm_reg <= 12'd0;
      end
     else if (pwm_reg == FAN_OFF)
        fan_ctl_o <= 1'b0;
    end
  end
  
endmodule