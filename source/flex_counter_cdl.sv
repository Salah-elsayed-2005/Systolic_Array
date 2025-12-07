`timescale 1ns / 10ps

module flex_counter_cdl #(parameter SIZE = 4) (
    input logic clk,n_rst,
    input logic clear,count_enable,
    input logic [SIZE-1:0]rollover_val,
    output logic [SIZE-1:0]count_out,
    output logic rollover_flag
);
    logic [SIZE-1:0] next_count;
    logic flag;
    always_ff @(posedge clk , negedge n_rst ) begin 
        if(!n_rst)begin
            count_out <=0;
            rollover_flag<=0;
        end
        else begin
            count_out <= next_count;
            rollover_flag<=flag;
        end
    end

    always_comb begin 
        next_count=count_out;
        flag=0;
       
        if(clear)begin
            next_count=0;
            flag=0;
            
        end
        else if(count_enable) begin
            if(count_out<rollover_val)begin
                next_count++;
                flag=0;
                if(count_out==rollover_val-1)begin
                    flag=1;
                end
            end
            else begin
                next_count=0;
                flag=0;
            end
        end
        else if (count_out==rollover_val)begin
            flag=1;
        end
    end
endmodule

