`timescale 1ns / 1ps

module debouncer (
    input wire clk,      
    input wire reset,     
    input wire raw_signal, 
    output wire debounced_signal 
);

    // Parameter for debounce stability
    parameter STABLE_COUNT = 5; // Number of cycles to confirm stable signal
    // At 100 Hz refresh_clk, 5 cycles = 50 ms

    reg [1:0] debounce_state; // State variable to track debounce process
    reg [2:0] counter;        // Counter to ensure signal stability

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            debounce_state <= 2'b00;
            counter <= 3'b000;
        end else begin
            case (debounce_state)
                2'b00: begin // Idle, waiting for rising edge
                    if (raw_signal) begin
                        if (counter < STABLE_COUNT) begin
                            counter <= counter + 1;
                        end else begin
                            debounce_state <= 2'b01;
                            counter <= 3'b000;
                        end
                    end else begin
                        counter <= 3'b000;
                    end
                end
                2'b01: begin // Rising edge detected, confirm stability
                    if (raw_signal) begin
                        if (counter < STABLE_COUNT) begin
                            counter <= counter + 1;
                        end else begin
                            debounce_state <= 2'b10;
                            counter <= 3'b000;
                        end
                    end else begin
                        debounce_state <= 2'b00;
                        counter <= 3'b000;
                    end
                end
                2'b10: begin // Active, waiting for falling edge
                    if (!raw_signal) begin
                        if (counter < STABLE_COUNT) begin
                            counter <= counter + 1;
                        end else begin
                            debounce_state <= 2'b00;
                            counter <= 3'b000;
                        end
                    end else begin
                        counter <= 3'b000;
                    end
                end
                default: begin
                    debounce_state <= 2'b00;
                    counter <= 3'b000;
                end
            endcase
        end
    end

    assign debounced_signal = (debounce_state == 2'b10);

endmodule