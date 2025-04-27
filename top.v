module top(
    input wire clk, reset, raw_up, raw_down, raw_left, raw_right, raw_attack, raw_done,
    output wire Hsync, Vsync,
    output wire [3:0] vgaRed,
    output wire [3:0] vgaGreen,
    output wire [3:0] vgaBlue,
    output reg [3:0] an,
    output wire [6:0] seg
);
   
    // State machine for game phases
    localparam STATE_P1_PLACING = 3'b000;  // Player 1 placing ships
    localparam STATE_P2_PLACING = 3'b001;  // Player 2 placing ships
    localparam STATE_P1_ATTACK  = 3'b010;  // Player 1 attacking
    localparam STATE_P2_ATTACK  = 3'b011;  // Player 2 attacking
    localparam STATE_P1_WINS    = 3'b100;  // Player 1 wins
    localparam STATE_P2_WINS    = 3'b101;  // Player 2 wins

    reg [2:0] game_state, next_game_state;
    reg [2:0] dig_display;  // For seven-segment display

    wire [35:0] attack_cursor_p1, attack_cursor_p2, coloring_array_p1, coloring_array_p2;
    wire [35:0] placement_cursor_p1, placement_cursor_p2, placed_ships_p1, placed_ships_p2;
    wire attack, done;
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
    debouncer d5(.clk(refresh_clk), .reset(reset), .raw_signal(raw_attack), .debounced_signal(attack));
    debouncer d6(.clk(refresh_clk), .reset(reset), .raw_signal(raw_done), .debounced_signal(done));

    // Ship placement controller for both players
    ship_placement_controller placement_ctrl(
        .clk(one_hz_clk),
        .reset(reset),
        .up(game_state == STATE_P1_PLACING ? up : (game_state == STATE_P2_PLACING ? up : 1'b0)),
        .down(game_state == STATE_P1_PLACING ? down : (game_state == STATE_P2_PLACING ? down : 1'b0)),
        .left(game_state == STATE_P1_PLACING ? left : (game_state == STATE_P2_PLACING ? left : 1'b0)),
        .right(game_state == STATE_P1_PLACING ? right : (game_state == STATE_P2_PLACING ? right : 1'b0)),
        .place(game_state == STATE_P1_PLACING || game_state == STATE_P2_PLACING ? attack : 1'b0), // Using raw_attack as place button
        .done_placing(done),
        .is_p1(game_state == STATE_P1_PLACING),
        .placement_cursor_p1(placement_cursor_p1),
        .placement_cursor_p2(placement_cursor_p2),
        .placed_ships_p1(placed_ships_p1),
        .placed_ships_p2(placed_ships_p2),
        //eliminating the need for a separate place signal.
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
        .attack(game_state == STATE_P1_ATTACK ? attack : 1'b0),
        .cursor(attack_cursor_p1),
        .ships(placed_ships_p2), // Player 1 attacks Player 2's ships
        .grid_state(coloring_array_p1));

    grid_attack ga2(.clk(one_hz_clk),
        .reset(reset),
        .attack(game_state == STATE_P2_ATTACK ? attack : 1'b0),
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
        .vgaRed(vgaRed),
        .vgaGreen(vgaGreen),
        .vgaBlue(vgaBlue));

    // State machine logic
    always @(posedge refresh_clk or posedge reset) begin
        if (reset)
            game_state <= STATE_P1_PLACING;
        else
            game_state <= next_game_state;
    end

    always @(*) begin
        next_game_state = game_state;
        dig_display = game_state; // Map game state to seven-segment display

        case (game_state)
            STATE_P1_PLACING: begin
                if (done && p1_placement_complete)
                    next_game_state = STATE_P2_PLACING;
            end
            STATE_P2_PLACING: begin
                if (done && p2_placement_complete)
                    next_game_state = STATE_P1_ATTACK;
            end
            STATE_P1_ATTACK: begin
                // Check if Player 1 has destroyed Player 2's fleet
                if ((placed_ships_p2 & coloring_array_p1) == placed_ships_p2)
                    next_game_state = STATE_P1_WINS;
                else if (attack)
                    next_game_state = STATE_P2_ATTACK;
            end
            STATE_P2_ATTACK: begin
                // Check if Player 2 has destroyed Player 1's fleet
                if ((placed_ships_p1 & coloring_array_p2) == placed_ships_p1)
                    next_game_state = STATE_P2_WINS;
                else if (attack)
                    next_game_state = STATE_P1_ATTACK;
            end
            STATE_P1_WINS, STATE_P2_WINS: begin
                // Stay in win state until reset
                next_game_state = game_state;
            end
            default: next_game_state = STATE_P1_PLACING;
        endcase
    end

    // Seven segment display
    always @(posedge refresh_clk) begin
        an <= 4'b1110; // Enable one digit
    end

    seven_seg sev(.digit(dig_display), .seg(seg));
endmodule