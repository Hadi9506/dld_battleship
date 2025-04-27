module grid_attack(
    input clk,
    input reset,
    input attack,
    input [35:0] cursor,
    input [35:0] ships,
    output reg [35:0] grid_state
);

// Initialize the grid state
initial begin
    grid_state = 36'b0;
end

// Update the grid state on each clock edge
always @(posedge clk) begin
    if (reset) begin
        // Reset the grid state to all zeros
        grid_state <= 36'b0;
    end else if (attack) begin
        // Update the grid state for an attack
        grid_state <= grid_state | cursor;
    end
end
endmodule