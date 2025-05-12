`timescale 1ns / 1ps

module top(
    input wire clk, reset, raw_up, raw_down, raw_left, raw_right, raw_attack,
    output wire Hsync, Vsync,
    output wire [3:0] vgaRed,
    output wire [3:0] vgaGreen,
    output wire [3:0] vgaBlue
);
   
    // State machine for game phases
    localparam STATE_START      = 3'b000;  // Start screen
    localparam STATE_P1_PLACING = 3'b001;  // Player 1 placing ships
    localparam STATE_P2_PLACING = 3'b010;  // Player 2 placing ships
    localparam STATE_P1_ATTACK  = 3'b011;  // Player 1 attacking
    localparam STATE_P2_ATTACK  = 3'b100;  // Player 2 attacking
    localparam STATE_P1_WINS    = 3'b101;  // Player 1 wins
    localparam STATE_P2_WINS    = 3'b110;  // Player 2 wins

    reg [2:0] game_state, next_game_state;
    reg [3:0] start_timer; // 10-second timer for start screen

    wire [35:0] attack_cursor_p1, attack_cursor_p2, coloring_array_p1, coloring_array_p2;
    wire [35:0] placement_cursor_p1, placement_cursor_p2, placed_ships_p1, placed_ships_p2;
    wire place_or_rotate;
    wire one_hz_clk, refresh_clk, up, down, left, right;
    wire p1_placement_complete, p2_placement_complete;
    
    // Clock dividers
    clock_dividers c(.clk(clk),
                    .one_hz_clk(one_hz_clk),
                    .refresh_clk(refresh_clk));
                   
    // Button debouncers
    debouncer d1(.clk(refresh_clk), .reset(reset), .raw_signal(raw_up), .debounced_signal(up));
    debouncer d2(.clk(refresh_clk), .reset(reset), .raw_signal(raw_down), .debounced_signal(down));
    debouncer d3(.clk(refresh_clk), .reset(reset), .raw_signal(raw_left), .debounced_signal(left));
    debouncer d4(.clk(refresh_clk), .reset(reset), .raw_signal(raw_right), .debounced_signal(right));
    debouncer d5(.clk(refresh_clk), .reset(reset), .raw_signal(raw_attack), .debounced_signal(place_or_rotate));

    // Ship placement controller for both players
    ship_placement_controller placement_ctrl(
        .clk(one_hz_clk),
        .reset(reset),
        .up(game_state == STATE_P1_PLACING ? up : (game_state == STATE_P2_PLACING ? up : 1'b0)),
        .down(game_state == STATE_P1_PLACING ? down : (game_state == STATE_P2_PLACING ? down : 1'b0)),
        .left(game_state == STATE_P1_PLACING ? left : (game_state == STATE_P2_PLACING ? left : 1'b0)),
        .right(game_state == STATE_P1_PLACING ? right : (game_state == STATE_P2_PLACING ? right : 1'b0)),
        .place_or_rotate(game_state == STATE_P1_PLACING || game_state == STATE_P2_PLACING ? place_or_rotate : 1'b0),
        .is_p1(game_state == STATE_P1_PLACING),
        .placement_cursor_p1(placement_cursor_p1),
        .placement_cursor_p2(placement_cursor_p2),
        .placed_ships_p1(placed_ships_p1),
        .placed_ships_p2(placed_ships_p2),
        .p1_placement_complete(p1_placement_complete),
        .p2_placement_complete(p2_placement_complete)
    );

    // Attack grid controllers for both players
    grid_controller g1(.clk(one_hz_clk),
        .reset(reset),
        .up(game_state == STATE_P1_ATTACK ? up : 1'b0),
        .down(game_state == STATE_P1_ATTACK ? down : 1'b0),
        .left(game_state == STATE_P1_ATTACK ? left : 1'b0),
        .right(game_state == STATE_P1_ATTACK ? right : 1'b0),
        .grid(attack_cursor_p1));

    grid_controller g2(.clk(one_hz_clk),
        .reset(reset),
        .up(game_state == STATE_P2_ATTACK ? up : 1'b0),
        .down(game_state == STATE_P2_ATTACK ? down : 1'b0),
        .left(game_state == STATE_P2_ATTACK ? left : 1'b0),
        .right(game_state == STATE_P2_ATTACK ? right : 1'b0),
        .grid(attack_cursor_p2));

    // Attack logic for both players
    grid_attack ga1(.clk(one_hz_clk),
        .reset(reset),
        .attack(game_state == STATE_P1_ATTACK ? place_or_rotate : 1'b0),
        .cursor(attack_cursor_p1),
        .ships(placed_ships_p2), // Player 1 attacks Player 2's ships
        .grid_state(coloring_array_p1));

    grid_attack ga2(.clk(one_hz_clk),
        .reset(reset),
        .attack(game_state == STATE_P2_ATTACK ? place_or_rotate : 1'b0),
        .cursor(attack_cursor_p2),
        .ships(placed_ships_p1), // Player 2 attacks Player 1's ships
        .grid_state(coloring_array_p2));

    // VGA display controller
    vga_display v(.clk(clk),
        .reset(reset),
        .Hsync(Hsync),
        .Vsync(Vsync),
        .coloring_array_p1(coloring_array_p1),
        .coloring_array_p2(coloring_array_p2),
        .hitmiss_array_p1(placed_ships_p1),
        .hitmiss_array_p2(placed_ships_p2),
        .cursor_p1(attack_cursor_p1),
        .cursor_p2(attack_cursor_p2),
        .placement_cursor_p1(placement_cursor_p1),
        .placement_cursor_p2(placement_cursor_p2),
        .placed_ships_p1(placed_ships_p1),
        .placed_ships_p2(placed_ships_p2),
        .game_state(game_state),
        .start_timer(start_timer),
        .vgaRed(vgaRed),
        .vgaGreen(vgaGreen),
        .vgaBlue(vgaBlue));

    // Start screen timer
    always @(posedge one_hz_clk or posedge reset) begin
        if (reset) begin
            start_timer <= 4'd10; // Start at 10 seconds
            game_state <= STATE_START;
        end else begin
            game_state <= next_game_state;
            if (game_state == STATE_START) begin
                if (start_timer > 0)
                    start_timer <= start_timer - 1;
            end
        end
    end

    // State machine logic
    always @(*) begin
        next_game_state = game_state;

        case (game_state)
            STATE_START: begin
                if (start_timer == 0)
                    next_game_state = STATE_P1_PLACING;
            end
            STATE_P1_PLACING: begin
                if (p1_placement_complete)
                    next_game_state = STATE_P2_PLACING;
            end
            STATE_P2_PLACING: begin
                if (p2_placement_complete)
                    next_game_state = STATE_P1_ATTACK;
            end
            STATE_P1_ATTACK: begin
                // Check if Player 1 has destroyed Player 2's fleet
                if ((placed_ships_p2 & coloring_array_p1) == placed_ships_p2)
                    next_game_state = STATE_P1_WINS;
                else if (place_or_rotate)
                    next_game_state = STATE_P2_ATTACK;
            end
            STATE_P2_ATTACK: begin
                // Check if Player 2 has destroyed Player 1's fleet
                if ((placed_ships_p1 & coloring_array_p2) == placed_ships_p1)
                    next_game_state = STATE_P2_WINS;
                else if (place_or_rotate)
                    next_game_state = STATE_P1_ATTACK;
            end
            STATE_P1_WINS: begin
                next_game_state = game_state;
            end
            STATE_P2_WINS: begin
                next_game_state = game_state;
            end
            default: next_game_state = STATE_START;
        endcase
    end

endmodule