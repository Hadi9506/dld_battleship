module ship_placement_controller(
    input wire clk, reset,
    input wire up, down, left, right,
    input wire place,                   // Button to place a ship segment
    input wire done_placing,            // Signal to finish placement mode
    input wire is_p1,                   // Flag to indicate Player 1 (1) or Player 2 (0)
    output reg [35:0] placement_cursor_p1, // Cursor for Player 1 placement grid
    output reg [35:0] placement_cursor_p2, // Cursor for Player 2 placement grid
    output reg [35:0] placed_ships_p1,     // Ships placed by Player 1
    output reg [35:0] placed_ships_p2,     // Ships placed by Player 2
    output reg p1_placement_complete,      // Flag for Player 1 placement complete
    output reg p2_placement_complete       // Flag for Player 2 placement complete
);

    reg [2:0] x_pos_p1, y_pos_p1; // Player 1 cursor position
    reg [2:0] x_pos_p2, y_pos_p2; // Player 2 cursor position

    // Initialize the placement grids
    initial begin
        x_pos_p1 = 3'b000;
        y_pos_p1 = 3'b000;
        x_pos_p2 = 3'b000;
        y_pos_p2 = 3'b000;
        placement_cursor_p1 = 36'b1; // Start at position (0,0)
        placement_cursor_p2 = 36'b1;
        placed_ships_p1 = 36'b0;
        placed_ships_p2 = 36'b0;
        p1_placement_complete = 1'b0;
        p2_placement_complete = 1'b0;
    end

    // Update cursor positions and handle ship placement
    always @(posedge clk) begin
        if (reset) begin
            x_pos_p1 <= 3'b000;
            y_pos_p1 <= 3'b000;
            x_pos_p2 <= 3'b000;
            y_pos_p2 <= 3'b000;
            placement_cursor_p1 <= 36'b1;
            placement_cursor_p2 <= 36'b1;
            placed_ships_p1 <= 36'b0;
            placed_ships_p2 <= 36'b0;
            p1_placement_complete <= 1'b0;
            p2_placement_complete <= 1'b0;
        end else begin
            // Player 1 placement
            if (is_p1) begin
                if (up && y_pos_p1 > 0) y_pos_p1 <= y_pos_p1 - 1;
                if (down && y_pos_p1 < 5) y_pos_p1 <= y_pos_p1 + 1;
                if (left && x_pos_p1 > 0) x_pos_p1 <= x_pos_p1 - 1;
                if (right && x_pos_p1 < 5) x_pos_p1 <= x_pos_p1 + 1;

                placement_cursor_p1 <= 36'b0;
                placement_cursor_p1[(y_pos_p1 * 6) + x_pos_p1] <= 1'b1;

                if (place) begin
                    placed_ships_p1[(y_pos_p1 * 6) + x_pos_p1] <= 1'b1;
                end

                if (done_placing) begin
                    p1_placement_complete <= 1'b1;
                end
            end
            // Player 2 placement
            else begin
                if (up && y_pos_p2 > 0) y_pos_p2 <= y_pos_p2 - 1;
                if (down && y_pos_p2 < 5) y_pos_p2 <= y_pos_p2 + 1;
                if (left && x_pos_p2 > 0) x_pos_p2 <= x_pos_p2 - 1;
                if (right && x_pos_p2 < 5) x_pos_p2 <= x_pos_p2 + 1;

                placement_cursor_p2 <= 36'b0;
                placement_cursor_p2[(y_pos_p2 * 6) + x_pos_p2] <= 1'b1;

                if (place) begin
                    placed_ships_p2[(y_pos_p2 * 6) + x_pos_p2] <= 1'b1;
                end

                if (done_placing) begin
                    p2_placement_complete <= 1'b1;
                end
            end
        end
    end
endmodule