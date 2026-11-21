module spi_master (
    input  wire       clk,       
    input  wire       rst_n,      
    input  wire [7:0] tx_data,    
    input  wire       start,      
    output reg        ready,      
    output reg  [7:0] rx_data,    
    output reg        done,       
    output reg        sclk,       
    output reg        mosi,       
    input  wire       miso,       
    output reg        cs_n        
);

    localparam IDLE     = 2'b00;
    localparam TRANSFER = 2'b01;
    localparam DONE     = 2'b10;

    reg [1:0] current_state, next_state;

    reg [2:0] bit_count;      
    reg [7:0] shift_reg_tx;   
    reg [7:0] shift_reg_rx;   
    reg [3:0] clk_div_count;  

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    always @(*) begin
        case (current_state)
            IDLE: begin
                if (start)
                    next_state = TRANSFER;
                else
                    next_state = IDLE;
            end
            
            TRANSFER: begin
                if (bit_count == 3'd7 && clk_div_count == 4'd7) 
                    next_state = DONE;
                else
                    next_state = TRANSFER;
            end
            
            DONE: begin
                next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sclk           <= 1'b0;
            cs_n           <= 1'b1;
            mosi           <= 1'b0;
            ready          <= 1'b1;
            done           <= 1'b0;
            bit_count      <= 3'd0;
            clk_div_count  <= 4'd0;
            shift_reg_tx   <= 8'd0;
            shift_reg_rx   <= 8'd0;
            rx_data        <= 8'd0;
        end else begin
            case (current_state)
                IDLE: begin
                    ready         <= 1'b1;
                    done          <= 1'b0;
                    cs_n          <= 1'b1;
                    sclk          <= 1'b0;
                    mosi          <= 1'b0;
                    bit_count     <= 3'd0;
                    clk_div_count <= 4'd0;
                    
                    if (start) begin
                      shift_reg_tx <= {tx_data[6:0], 1'b0};
                      mosi<= tx_data[7];
                        ready        <= 1'b0;
                        cs_n         <= 1'b0;
                    end
                end

                TRANSFER: begin
                    ready <= 1'b0;
                    cs_n  <= 1'b0;

                    if (clk_div_count == 4'd7) begin
                        clk_div_count <= 4'd0;
                        sclk          <= ~sclk;

                        if (sclk == 1'b0) begin
                            shift_reg_rx <= {shift_reg_rx[6:0], miso};
                        end                        
                        if (sclk == 1'b1) begin                            
                            if (bit_count == 3'd7) begin
                                bit_count <= 3'd0;
                            end else begin
                                bit_count <= bit_count + 1'b1;
                              mosi<= shift_reg_tx[7];
                              shift_reg_tx<= {shift_reg_tx[6:0], 1'b0};
                            end
                        end
                    end else begin
                        clk_div_count <= clk_div_count + 1'b1;
                    end
                end

                DONE: begin
                    done    <= 1'b1;
                    ready   <= 1'b0;
                    cs_n    <= 1'b1;
                    sclk    <= 1'b0;
                    rx_data <= shift_reg_rx;
                end
            endcase
        end
    end

endmodule
