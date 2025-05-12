`timescale 1ns / 1ps

module ship_placement_controller(
    input wire clk, reset,
    input wire up, down, left, right,
    input wire place_or_rotate,         // Button to place ship or toggle orientation
    input wire is_p1,                   // Flag to indicate Player 1 (1) or Player 2 (0)
    output reg [35:0] placement_cursor_p1, // Cursor for Player 1 placement grid
    output reg [35:0] placement_cursor_p2, // Cursor for Player 2 placement grid
    output reg [35:0] placed_ships_p1,     // Ships placed by Player 1
    output reg [35:0] placed_ships_p2,     // Ships placed by Player 2
    output reg p1_placement_complete,      // Flag for Player 1 placement complete
    output reg p2_placement_complete       // Flag for Player 2 placement complete
);

    // Ship placement states
    localparam SHIP_4 = 2'b00; // Placing 4-block ship
    localparam SHIP_3 = 2'b01; // Placing 3-block ship
    localparam SHIP_2 = 2'b10; // Placing 2-block ship
    localparam DONE   = 2'b11; // All ships placed

    reg [2:0] x_pos_p1, y_pos_p1; // Player 1 cursor position
    reg [2:0] x_pos_p2, y_pos_p2; // Player 2 cursor position
    reg orientation_p1;           // Player 1 ship orientation (0: horizontal, 1: vertical)
    reg orientation_p2;           // Player 2 ship orientation
    reg [1:0] ship_state_p1;      // Current ship being placed by Player 1
    reg [1:0] ship_state_p2;      // Current ship being placed by Player 2
    reg place_pulse_p1, place_pulse_p2; // Edge detection for place_or_rotate
    reg last_place_or_rotate_p1, last_place_or_rotate_p2;
    reg [35:0] new_ship_p1;       // Temporary storage for new ship placement (Player 1)
    reg [35:0] new_ship_p2;       // Temporary storage for new ship placement (Player 2)

    // Initialize the placement grids
    initial begin
        x_pos_p1 = 3'b000;
        y_pos_p1 = 3'b000;
        x_pos_p2 = 3'b000;
        y_pos_p2 = 3'b000;
        placement_cursor_p1 = 36'b0;
        placement_cursor_p2 = 36'b0;
        placed_ships_p1 = 36'b0;
        placed_ships_p2 = 36'b0;
        p1_placement_complete = 1'b0;
        p2_placement_complete = 1'b0;
        orientation_p1 = 1'b0;
        orientation_p2 = 1'b0;
        ship_state_p1 = SHIP_4;
        ship_state_p2 = SHIP_4;
        place_pulse_p1 = 1'b0;
        place_pulse_p2 = 1'b0;
        last_place_or_rotate_p1 = 1'b0;
        last_place_or_rotate_p2 = 1'b0;
        new_ship_p1 = 36'b0;
        new_ship_p2 = 36'b0;
    end

    // Edge detection for place_or_rotate signal
    always @(posedge clk) begin
        if (reset) begin
            last_place_or_rotate_p1 <= 1'b0;
            last_place_or_rotate_p2 <= 1'b0;
            place_pulse_p1 <= 1'b0;
            place_pulse_p2 <= 1'b0;
        end else begin
            last_place_or_rotate_p1 <= place_or_rotate;
            last_place_or_rotate_p2 <= place_or_rotate;
            place_pulse_p1 <= (is_p1 && place_or_rotate && !last_place_or_rotate_p1);
            place_pulse_p2 <= (!is_p1 && place_or_rotate && !last_place_or_rotate_p2);
        end
    end

    // Update cursor positions and handle ship placement
    always @(posedge clk) begin
        if (reset) begin
            x_pos_p1 <= 3'b000;
            y_pos_p1 <= 3'b000;
            x_pos_p2 <= 3'b000;
            y_pos_p2 <= 3'b000;
            placement_cursor_p1 <= 36'b0;
            placement_cursor_p2 <= 36'b0;
            placed_ships_p1 <= 36'b0;
            placed_ships_p2 <= 36'b0;
            p1_placement_complete <= 1'b0;
            p2_placement_complete <= 1'b0;
            orientation_p1 <= 1'b0;
            orientation_p2 <= 1'b0;
            ship_state_p1 <= SHIP_4;
            ship_state_p2 <= SHIP_4;
            new_ship_p1 <= 36'b0;
            new_ship_p2 <= 36'b0;
        end else begin
            // Player 1 placement
            if (is_p1 && !p1_placement_complete) begin
                // Cursor movement
                if (up && y_pos_p1 > 0) y_pos_p1 <= y_pos_p1 - 1;
                if (down && y_pos_p1 < 5) y_pos_p1 <= y_pos_p1 + 1;
                if (left && x_pos_p1 > 0) x_pos_p1 <= x_pos_p1 - 1;
                if (right && x_pos_p1 < 5) x_pos_p1 <= x_pos_p1 + 1;

                // Update cursor based on ship size and orientation
                placement_cursor_p1 <= 36'b0;
                case (ship_state_p1)
                    SHIP_4: begin
                        if (orientation_p1) begin // Vertical
                            if (y_pos_p1 <= 2) begin
                                placement_cursor_p1[(y_pos_p1 * 6) + x_pos_p1] <= 1'b1;
                                placement_cursor_p1[((y_pos_p1 + 1) * 6) + x_pos_p1] <= 1'b1;
                                placement_cursor_p1[((y_pos_p1 + 2) * 6) + x_pos_p1] <= 1'b1;
                                placement_cursor_p1[((y_pos_p1 + 3) * 6) + x_pos_p1] <= 1'b1;
                            end
                        end else begin // Horizontal
                            if (x_pos_p1 <= 2) begin
                                placement_cursor_p1[(y_pos_p1 * 6) + x_pos_p1] <= 1'b1;
                                placement_cursor_p1[(y_pos_p1 * 6) + x_pos_p1 + 1] <= 1'b1;
                                placement_cursor_p1[(y_pos_p1 * 6) + x_pos_p1 + 2] <= 1'b1;
                                placement_cursor_p1[(y_pos_p1 * 6) + x_pos_p1 + 3] <= 1'b1;
                            end
                        end
                    end
                    SHIP_3: begin
                        if (orientation_p1) begin // Vertical
                            if (y_pos_p1 <= 3) begin
                                placement_cursor_p1[(y_pos_p1 * 6) + x_pos_p1] <= 1'b1;
                                placement_cursor_p1[((y_pos_p1 + 1) * 6) + x_pos_p1] <= 1'b1;
                                placement_cursor_p1[((y_pos_p1 + 2) * 6) + x_pos_p1] <= 1'b1;
                            end
                        end else begin // Horizontal
                            if (x_pos_p1 <= 3) begin
                                placement_cursor_p1[(y_pos_p1 * 6) + x_pos_p1] <= 1'b1;
                                placement_cursor_p1[(y_pos_p1 * 6) + x_pos_p1 + 1] <= 1'b1;
                                placement_cursor_p1[(y_pos_p1 * 6) + x_pos_p1 + 2] <= 1'b1;
                            end
                        end
                    end
                    SHIP_2: begin
                        if (orientation_p1) begin // Vertical
                            if (y_pos_p1 <= 4) begin
                                placement_cursor_p1[(y_pos_p1 * 6) + x_pos_p1] <= 1'b1;
                                placement_cursor_p1[((y_pos_p1 + 1) * 6) + x_pos_p1] <= 1'b1;
                            end
                        end else begin // Horizontal
                            if (x_pos_p1 <= 4) begin
                                placement_cursor_p1[(y_pos_p1 * 6) + x_pos_p1] <= 1'b1;
                                placement_cursor_p1[(y_pos_p1 * 6) + x_pos_p1 + 1] <= 1'b1;
                            end
                        end
                    end
                endcase

                // Handle place or rotate
                if (place_pulse_p1) begin
                    if (orientation_p1 == 1'b0 && (x_pos_p1 > 5 || (ship_state_p1 == SHIP_4 && x_pos_p1 > 2) || (ship_state_p1 == SHIP_3 && x_pos_p1 > 3) || (ship_state_p1 == SHIP_2 && x_pos_p1 > 4)) ||
                        orientation_p1 == 1'b1 && (y_pos_p1 > 5 || (ship_state_p1 == SHIP_4 && y_pos_p1 > 2) || (ship_state_p1 == SHIP_3 && y_pos_p1 > 3) || (ship_state_p1 == SHIP_2 && y_pos_p1 > 4))) begin
                        // Invalid placement, toggle orientation instead
                        orientation_p1 <= !orientation_p1;
                    end else begin
                        // Check for overlap
                        new_ship_p1 = 36'b0;
                        case (ship_state_p1)
                            SHIP_4: begin
                                if (orientation_p1) begin
                                    new_ship_p1[(y_pos_p1 * 6) + x_pos_p1] = 1'b1;
                                    new_ship_p1[((y_pos_p1 + 1) * 6) + x_pos_p1] = 1'b1;
                                    new_ship_p1[((y_pos_p1 + 2) * 6) + x_pos_p1] = 1'b1;
                                    new_ship_p1[((y_pos_p1 + 3) * 6) + x_pos_p1] = 1'b1;
                                end else begin
                                    new_ship_p1[(y_pos_p1 * 6) + x_pos_p1] = 1'b1;
                                    new_ship_p1[(y_pos_p1 * 6) + x_pos_p1 + 1] = 1'b1;
                                    new_ship_p1[(y_pos_p1 * 6) + x_pos_p1 + 2] = 1'b1;
                                    new_ship_p1[(y_pos_p1 * 6) + x_pos_p1 + 3] = 1'b1;
                                end
                            end
                            SHIP_3: begin
                                if (orientation_p1) begin
                                    new_ship_p1[(y_pos_p1 * 6) + x_pos_p1] = 1'b1;
                                    new_ship_p1[((y_pos_p1 + 1) * 6) + x_pos_p1] = 1'b1;
                                    new_ship_p1[((y_pos_p1 + 2) * 6) + x_pos_p1] = 1'b1;
                                end else begin
                                    new_ship_p1[(y_pos_p1 * 6) + x_pos_p1] = 1'b1;
                                    new_ship_p1[(y_pos_p1 * 6) + x_pos_p1 + 1] = 1'b1;
                                    new_ship_p1[(y_pos_p1 * 6) + x_pos_p1 + 2] = 1'b1;
                                end
                            end
                            SHIP_2: begin
                                if (orientation_p1) begin
                                    new_ship_p1[(y_pos_p1 * 6) + x_pos_p1] = 1'b1;
                                    new_ship_p1[((y_pos_p1 + 1) * 6) + x_pos_p1] = 1'b1;
                                end else begin
                                    new_ship_p1[(y_pos_p1 * 6) + x_pos_p1] = 1'b1;
                                    new_ship_p1[(y_pos_p1 * 6) + x_pos_p1 + 1] = 1'b1;
                                end
                            end
                        endcase
                        if ((new_ship_p1 & placed_ships_p1) == 36'b0) begin
                            // Valid placement, place ship and advance to next ship
                            placed_ships_p1 <= placed_ships_p1 | new_ship_p1;
                            case (ship_state_p1)
                                SHIP_4: ship_state_p1 <= SHIP_3;
                                SHIP_3: ship_state_p1 <= SHIP_2;
                                SHIP_2: begin
                                    ship_state_p1 <= DONE;
                                    p1_placement_complete <= 1'b1;
                                end
                            endcase
                        end else begin
                            // Overlap detected, toggle orientation
                            orientation_p1 <= !orientation_p1;
                        end
                    end
                end
            end
            // Player 2 placement
            else if (!is_p1 && !p2_placement_complete) begin
                // Cursor movement
                if (up && y_pos_p2 > 0) y_pos_p2 <= y_pos_p2 - 1;
                if (down && y_pos_p2 < 5) y_pos_p2 <= y_pos_p2 + 1;
                if (left && x_pos_p2 > 0) x_pos_p2 <= x_pos_p2 - 1;
                if (right && x_pos_p2 < 5) x_pos_p2 <= x_pos_p2 + 1;

                // Update cursor based on ship size and orientation
                placement_cursor_p2 <= 36'b0;
                case (ship_state_p2)
                    SHIP_4: begin
                        if (orientation_p2) begin // Vertical
                            if (y_pos_p2 <= 2) begin
                                placement_cursor_p2[(y_pos_p2 * 6) + x_pos_p2] <= 1'b1;
                                placement_cursor_p2[((y_pos_p2 + 1) * 6) + x_pos_p2] <= 1'b1;
                                placement_cursor_p2[((y_pos_p2 + 2) * 6) + x_pos_p2] <= 1'b1;
                                placement_cursor_p2[((y_pos_p2 + 3) * 6) + x_pos_p2] <= 1'b1;
                            end
                        end else begin // Horizontal
                            if (x_pos_p2 <= 2) begin
                                placement_cursor_p2[(y_pos_p2 * 6) + x_pos_p2] <= 1'b1;
                                placement_cursor_p2[(y_pos_p2 * 6) + x_pos_p2 + 1] <= 1'b1;
                                placement_cursor_p2[(y_pos_p2 * 6) + x_pos_p2 + 2] <= 1'b1;
                                placement_cursor_p2[(y_pos_p2 * 6) + x_pos_p2 + 3] <= 1'b1;
                            end
                        end
                    end
                    SHIP_3: begin
                        if (orientation_p2) begin // Vertical
                            if (y_pos_p2 <= 3) begin
                                placement_cursor_p2[(y_pos_p2 * 6) + x_pos_p2] <= 1'b1;
                                placement_cursor_p2[((y_pos_p2 + 1) * 6) + x_pos_p2] <= 1'b1;
                                placement_cursor_p2[((y_pos_p2 + 2) * 6) + x_pos_p2] <= 1'b1;
                            end
                        end else begin // Horizontal
                            if (x_pos_p2 <= 3) begin
                                placement_cursor_p2[(y_pos_p2 * 6) + x_pos_p2] <= 1'b1;
                                placement_cursor_p2[(y_pos_p2 * 6) + x_pos_p2 + 1] <= 1'b1;
                                placement_cursor_p2[(y_pos_p2 * 6) + x_pos_p2 + 2] <= 1'b1;
                            end
                        end
                    end
                    SHIP_2: begin
                        if (orientation_p2) begin // Vertical
                            if (y_pos_p2 <= 4) begin
                                placement_cursor_p2[(y_pos_p2 * 6) + x_pos_p2] <= 1'b1;
                                placement_cursor_p2[((y_pos_p2 + 1) * 6) + x_pos_p2] <= 1'b1;
                            end
                        end else begin // Horizontal
                            if (x_pos_p2 <= 4) begin
                                placement_cursor_p2[(y_pos_p2 * 6) + x_pos_p2] <= 1'b1;
                                placement_cursor_p2[(y_pos_p2 * 6) + x_pos_p2 + 1] <= 1'b1;
                            end
                        end
                    end
                endcase

                // Handle place or rotate
                if (place_pulse_p2) begin
                    if (orientation_p2 == 1'b0 && (x_pos_p2 > 5 || (ship_state_p2 == SHIP_4 && x_pos_p2 > 2) || (ship_state_p2 == SHIP_3 && x_pos_p2 > 3) || (ship_state_p2 == SHIP_2 && x_pos_p2 > 4)) ||
                        orientation_p2 == 1'b1 && (y_pos_p2 > 5 || (ship_state_p2 == SHIP_4 && y_pos_p2 > 2) || (ship_state_p2 == SHIP_3 && y_pos_p2 > 3) || (ship_state_p2 == SHIP_2 && y_pos_p2 > 4))) begin
                        // Invalid placement, toggle orientation instead
                        orientation_p2 <= !orientation_p2;
                    end else begin
                        // Check for overlap
                        new_ship_p2 = 36'b0;
                        case (ship_state_p2)
                            SHIP_4: begin
                                if (orientation_p2) begin
                                    new_ship_p2[(y_pos_p2 * 6) + x_pos_p2] = 1'b1;
                                    new_ship_p2[((y_pos_p2 + 1) * 6) + x_pos_p2] = 1'b1;
                                    new_ship_p2[((y_pos_p2 + 2) * 6) + x_pos_p2] = 1'b1;
                                    new_ship_p2[((y_pos_p2 + 3) * 6) + x_pos_p2] = 1'b1;
                                end else begin
                                    new_ship_p2[(y_pos_p2 * 6) + x_pos_p2] = 1'b1;
                                    new_ship_p2[(y_pos_p2 * 6) + x_pos_p2 + 1] = 1'b1;
                                    new_ship_p2[(y_pos_p2 * 6) + x_pos_p2 + 2] = 1'b1;
                                    new_ship_p2[(y_pos_p2 * 6) + x_pos_p2 + 3] = 1'b1;
                                end
                            end
                            SHIP_3: begin
                                if (orientation_p2) begin
                                    new_ship_p2[(y_pos_p2 * 6) + x_pos_p2] = 1'b1;
                                    new_ship_p2[((y_pos_p2 + 1) * 6) + x_pos_p2] = 1'b1;
                                    new_ship_p2[((y_pos_p2 + 2) * 6) + x_pos_p2] = 1'b1;
                                end else begin
                                    new_ship_p2[(y_pos_p2 * 6) + x_pos_p2] = 1'b1;
                                    new_ship_p2[(y_pos_p2 * 6) + x_pos_p2 + 1] = 1'b1;
                                    new_ship_p2[(y_pos_p2 * 6) + x_pos_p2 + 2] = 1'b1;
                                end
                            end
                            SHIP_2: begin
                                if (orientation_p2) begin
                                    new_ship_p2[(y_pos_p2 * 6) + x_pos_p2] = 1'b1;
                                    new_ship_p2[((y_pos_p2 + 1) * 6) + x_pos_p2] = 1'b1;
                                end else begin
                                    new_ship_p2[(y_pos_p2 * 6) + x_pos_p2] = 1'b1;
                                    new_ship_p2[(y_pos_p2 * 6) + x_pos_p2 + 1] = 1'b1;
                                end
                            end
                        endcase
                        if ((new_ship_p2 & placed_ships_p2) == 36'b0) begin
                            // Valid placement, place ship and advance to next ship
                            placed_ships_p2 <= placed_ships_p2 | new_ship_p2;
                            case (ship_state_p2)
                                SHIP_4: ship_state_p2 <= SHIP_3;
                                SHIP_3: ship_state_p2 <= SHIP_2;
                                SHIP_2: begin
                                    ship_state_p2 <= DONE;
                                    p2_placement_complete <= 1'b1;
                                end
                            endcase
                        end else begin
                            // Overlap detected, toggle orientation
                            orientation_p2 <= !orientation_p2;
                        end
                    end
                end
            end
        end
    end

endmodule