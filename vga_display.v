`timescale 1ns / 1ps

module vga_display
(
    input wire clk, reset,
    output wire Hsync, Vsync,
    input wire [35:0] coloring_array_p1, // Player 1's attack grid state
    input wire [35:0] coloring_array_p2, // Player 2's attack grid state
    input wire [35:0] hitmiss_array_p1,  // Player 1's ship positions
    input wire [35:0] hitmiss_array_p2,  // Player 2's ship positions
    input wire [35:0] cursor_p1,         // Player 1's attack cursor
    input wire [35:0] cursor_p2,         // Player 2's attack cursor
    input wire [35:0] placement_cursor_p1, // Player 1's placement cursor
    input wire [35:0] placement_cursor_p2, // Player 2's placement cursor
    input wire [35:0] placed_ships_p1,   // Player 1's placed ships
    input wire [35:0] placed_ships_p2,   // Player 2's placed ships
    input wire [2:0] game_state,         // Game state to control grid visibility
    input wire [3:0] start_timer,        // Timer value for start screen
    output reg [3:0] vgaRed,
    output reg [3:0] vgaGreen,
    output reg [3:0] vgaBlue
);

    // VGA timing parameters
    localparam H_DISPLAY       = 640;
    localparam H_L_BORDER      =  48;
    localparam H_R_BORDER      =  16;
    localparam H_RETRACE       =  96;
    localparam H_MAX           = H_DISPLAY + H_L_BORDER + H_R_BORDER + H_RETRACE - 1;
    localparam START_H_RETRACE = H_DISPLAY + H_R_BORDER;
    localparam END_H_RETRACE   = H_DISPLAY + H_R_BORDER + H_RETRACE - 1;

    localparam V_DISPLAY       = 480;
    localparam V_T_BORDER      =  10;
    localparam V_B_BORDER      =  33;
    localparam V_RETRACE       =   2;
    localparam V_MAX           = V_DISPLAY + V_T_BORDER + V_B_BORDER + V_RETRACE - 1;
    localparam START_V_RETRACE = V_DISPLAY + V_B_BORDER;
    localparam END_V_RETRACE   = V_DISPLAY + V_B_BORDER + V_RETRACE - 1;

    // Game states
    localparam STATE_START      = 3'b000;
    localparam STATE_P1_PLACING = 3'b001;
    localparam STATE_P2_PLACING = 3'b010;
    localparam STATE_P1_ATTACK  = 3'b011;
    localparam STATE_P2_ATTACK  = 3'b100;
    localparam STATE_P1_WINS    = 3'b101;
    localparam STATE_P2_WINS    = 3'b110;

    // Grid parameters
    localparam cell_size = 30;
    localparam grid_size = 6;

    // Grid positions
    localparam grid1_start_x = 50;  // Player 1 placement grid (top-left)
    localparam grid1_start_y = 50;
    localparam grid2_start_x = 300; // Player 2 placement grid (top-right)
    localparam grid2_start_y = 50;
    localparam grid3_start_x = 50;  // Player 1 attack grid (bottom-left)
    localparam grid3_start_y = 300;
    localparam grid4_start_x = 300; // Player 2 attack grid (bottom-right)
    localparam grid4_start_y = 300;

    // Ship bit array sizes
    localparam SHIP_4_WIDTH = 120;  // 4 cells wide
    localparam SHIP_3_WIDTH = 90;   // 3 cells wide
    localparam SHIP_2_WIDTH = 60;   // 2 cells wide
    localparam SHIP_HEIGHT = 30;    // Height for all ships
    localparam SHIP_4_SIZE = SHIP_4_WIDTH * SHIP_HEIGHT; // 3600 bits
    localparam SHIP_3_SIZE = SHIP_3_WIDTH * SHIP_HEIGHT; // 2700 bits
    localparam SHIP_2_SIZE = SHIP_2_WIDTH * SHIP_HEIGHT; // 1800 bits
    localparam FIRE_SIZE = 30 * 30; // 900 bits for fire image

    // Ship bit arrays (1 = ship pixel, 0 = background)
    reg [0:SHIP_4_SIZE-1] ship_4_bits;
    reg [0:SHIP_3_SIZE-1] ship_3_bits;
    reg [0:SHIP_2_SIZE-1] ship_2_bits;
    reg [0:FIRE_SIZE-1] fire_bits;
    integer row,col,i;
    // Initialize bit arrays with provided bits
    initial begin
        ship_4_bits = 3600'b111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100001111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000011111111111111111111111100001111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000001111111111111111111111100001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000011111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110000000000000000000000000111111111111111111111111111111111111111111111111111111111111111100000000000000000011111111111110000000000000000000000000111111111111111111111111111111111111111111111111111111111111111100000000000000000001111111111110000000011111111111111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000011110000000000000000011111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000011111111111111111111111111111111111111111111111111111111111111111111111000000000000000000000000000000000000000000000000001111111111111111111111111111111111111111111111111111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000011111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111000000000000000000000001111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111111111111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111;
        ship_3_bits = 2700'b111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111000111111111111111111111111111111111111111111111111111111111000000000000111111111111111111000111111111111111111111111111111111111111111111111111111111000000000000111111111111111111000111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000001111111111111111111111111111111111111111111111111111111111111111111111111000000000000000000111111111111111111111111111111111111111111111111000000000000001111111111000000000000000000111111111111111111111111111111111111111111111111000000000000000111111111000000111111111111111111111111111111111111111111111111111111000000000000000000000000000000000000111000000000000111111111111111111111111111111111111111000000000000000000000000000000000000111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111100000000000000000000000000000000000000000000000000000000000000000000000000000000011111111100000000000000000000000000000000000000000000000000000000000000000000000000000001111111111111000000000000000000000000000000000000000000000000000000000000000000000000000111111111111111111111111111111111111111111111111111111111111111111111111000000000000000001111111111111111000000000000000000000000000000000000000000000000000000000000000000000000111111111111111111000000000000000000000000000000000000000000000000000000000000000000000001111111111111111111100000000000000000000000000000000000000000000000000000000000000000000111111111111111111111110000000000000000000000000000000000000000000000000000000000000000001111111111111111111111110000000000000000000000000000000000000000000000000000000000000000111111111111111111111111111000000000000000000000000000000000000000000000000000000000000001111111111111111111111111111000000000000000000000000000000000000000000000000000000000000111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111;
        ship_2_bits = 1800'b111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100111111111111111111111111111111111111110000000011111111111100111111111111111111111111111111111111110000000011111111111100111111111111111111111111111111111111111111111111111111100000000001111111111111111111111111111111111111111111111111000000000000111111111111111111111111111111110000000001111111000000000000111111111111111111111111111111110000000000111111000011111111111111111111111111111111111100000000000000000000000011000000001111111111111111111111111100000000000000000000000011111111111111111111111111111111111000000000000000000000000011111111111111111111111111111111111000000000000000000000000000000000000011111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000001111110000000000000000000000000000000000000000000000000000001111110000000000000000000000000000000000000000000000000000111111111000000000000000000000000000000000000000000000000001111111111111111111111111111111111111111111111110000000000011111111111000000000000000000000000000000000000000000000000111111111111000000000000000000000000000000000000000000000001111111111111100000000000000000000000000000000000000000000011111111111111100000000000000000000000000000000000000000000111111111111111100000000000000000000000000000000000000000001111111111111111110000000000000000000000000000000000000000011111111111111111110000000000000000000000000000000000000000111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111;
        
        // Fire: 30x30, simple cross shape
        for (i = 0; i < FIRE_SIZE; i = i + 1) begin
            row = i / 30;
            col = i % 30;
            if (row == col || row + col == 29) // Diagonal cross
                fire_bits[i] = 1'b1;
            else
                fire_bits[i] = 1'b0;
        end
    end

    // Simplified 5x7 pixel font for text display (1, 2, A, B, E, H, I, L, N, P, R, S, T, W, Y)
    reg [0:34] font [0:14]; // 15 characters total
    initial begin
        font[0]  = 35'b0110000100001000010011111; // 1
        font[1]  = 35'b1111100001001111100011111; // 2
        font[2]  = 35'b0111010001111111000110001; // A
        font[3]  = 35'b1111010001111101000111110; // B
        font[4]  = 35'b1111110000111101000011111; // E
        font[5]  = 35'b1000110001111111000110001; // H
        font[6]  = 35'b1111100100001000010011111; // I
        font[7]  = 35'b1000010000100001000011111; // L
        font[8]  = 35'b1000111001101011001110001; // N
        font[9]  = 35'b1111010001111101000010000; // P
        font[10] = 35'b1111010001111101010010010; // R
        font[11] = 35'b0111110000011100000111110; // S
        font[12] = 35'b1111100100001000010000100; // T
        font[13] = 35'b1000110001101011101110001; // W
        font[14] = 35'b1000101010001000010000100; // Y
    end

    // Function to draw text at a given position
    function [11:0] draw_text;
        input [9:0] h_pos, v_pos; // Screen position to start drawing
        input [9:0] h_pixel, v_pixel; // Current pixel being drawn
        input [3:0] char_idx; // Character index (0-14 for 1, 2, A, B, E, H, I, L, N, P, R, S, T, W, Y)
        reg [9:0] x_offset, y_offset;
        reg [4:0] font_x, font_y;
        begin
            x_offset = h_pixel - h_pos;
            y_offset = v_pixel - v_pos;
            font_x = x_offset % 5;
            font_y = y_offset % 7;
            if (x_offset < 5 && y_offset < 7) begin
                if (font[char_idx][font_y * 5 + font_x])
                    draw_text = 12'hFFF; // White text
                else
                    draw_text = 12'h000; // Transparent (black)
            end else
                draw_text = 12'h000;
        end
    endfunction

    // Declare all variables at the top
    integer curr_cell;
    integer ship_length;
    integer start_x;
    integer start_y;
    integer ship_start_cell;
    reg is_horizontal;
    integer x_offset;
    integer y_offset;
    integer bit_index;
    integer offset;
    integer ship_width;

    reg [11:0] pixel_color;
    reg [9:0] scaled_h, scaled_v;

    // mod-4 counter to generate 25 MHz pixel tick
    reg [1:0] pixel_reg;
    wire [1:0] pixel_next;
    wire pixel_tick;

    always @(posedge clk, posedge reset)
    if(reset)
        pixel_reg <= 0;
    else
        pixel_reg <= pixel_next;

    assign pixel_next = pixel_reg + 1;
    assign pixel_tick = (pixel_reg == 0);

    // registers to keep track of current pixel location
    reg [9:0] h_count_reg, h_count_next, v_count_reg, v_count_next;

    // register to keep track of vsync and hsync signal states
    reg vsync_reg, hsync_reg;
    wire vsync_next, hsync_next;
     
    always @(posedge clk, posedge reset)
    if(reset)
       begin
            v_count_reg <= 0;
            h_count_reg <= 0;
            vsync_reg   <= 0;
            hsync_reg   <= 0;
       end
    else
       begin
            v_count_reg <= v_count_next;
            h_count_reg <= h_count_next;
            vsync_reg   <= vsync_next;
            hsync_reg   <= hsync_next;
       end

    always @*
    begin
        h_count_next = pixel_tick ?
                      h_count_reg == H_MAX ? 0 : h_count_reg + 1
              : h_count_reg;

        v_count_next = pixel_tick && h_count_reg == H_MAX ?
                      (v_count_reg == V_MAX ? 0 : v_count_reg + 1)
              : v_count_reg;
    end

    assign hsync_next = h_count_reg >= START_H_RETRACE && h_count_reg <= END_H_RETRACE;
    assign vsync_next = v_count_reg >= START_V_RETRACE && v_count_reg <= END_V_RETRACE;

    assign video_on = (h_count_reg < H_DISPLAY) && (v_count_reg < V_DISPLAY);
    
    always @(*)
    begin
        vgaRed = 4'b0000;
        vgaGreen = 4'b0000;
        vgaBlue = 4'b0000;
        pixel_color = 12'h000;
        
        if (v_count_reg >= 0 && v_count_reg < V_DISPLAY)
        begin
            // Start Screen: Black background with "BATTLESHIP" and timer
            if (game_state == STATE_START)
            begin
                // Default to black background
                vgaRed = 4'b0000;
                vgaGreen = 4'b0000;
                vgaBlue = 4'b0000;
                
                // Draw "BATTLESHIP" at (295, 200)
                
                begin
                    // B
                    if (h_count_reg >= 295 && h_count_reg < 300)
                        pixel_color = draw_text(295, 200, h_count_reg, v_count_reg, 3);
                    // A
                    else if (h_count_reg >= 300 && h_count_reg < 305)
                        pixel_color = draw_text(300, 200, h_count_reg, v_count_reg, 2);
                    // T
                    else if (h_count_reg >= 305 && h_count_reg < 310)
                        pixel_color = draw_text(305, 200, h_count_reg, v_count_reg, 12);
                    // T
                    else if (h_count_reg >= 310 && h_count_reg < 315)
                        pixel_color = draw_text(310, 200, h_count_reg, v_count_reg, 12);
                    // L
                    else if (h_count_reg >= 315 && h_count_reg < 320)
                        pixel_color = draw_text(315, 200, h_count_reg, v_count_reg, 7);
                    // E
                    else if (h_count_reg >= 320 && h_count_reg < 325)
                        pixel_color = draw_text(320, 200, h_count_reg, v_count_reg, 4);
                    // S
                    else if (h_count_reg >= 325 && h_count_reg < 330)
                        pixel_color = draw_text(325, 200, h_count_reg, v_count_reg, 11);
                    // H
                    else if (h_count_reg >= 330 && h_count_reg < 335)
                        pixel_color = draw_text(330, 200, h_count_reg, v_count_reg, 5);
                    // I
                    else if (h_count_reg >= 335 && h_count_reg < 340)
                        pixel_color = draw_text(335, 200, h_count_reg, v_count_reg, 6);
                    // P
                    else if (h_count_reg >= 340 && h_count_reg < 345)
                        pixel_color = draw_text(340, 200, h_count_reg, v_count_reg, 9);
                end
                // Draw timer at (315, 220)
                
                
                    pixel_color = draw_text(315, 220, h_count_reg, v_count_reg, start_timer);
                
                if (pixel_color != 12'h000) begin
                    vgaRed = pixel_color[11:8];
                    vgaGreen = pixel_color[7:4];
                    vgaBlue = pixel_color[3:0];
                end
            end
            // End Screen with Winner Text
            else if (game_state == STATE_P1_WINS || game_state == STATE_P2_WINS)
            begin
                vgaRed = 4'b1111; // Red screen
                vgaGreen = 4'b0000;
                vgaBlue = 4'b0000;
                // Overlay "Player 1 Wins" or "Player 2 Wins" at (200, 200)
                if (h_count_reg >= 200 && h_count_reg < 300 && v_count_reg >= 200 && v_count_reg < 207)
                begin
                    // P
                    if (h_count_reg >= 200 && h_count_reg < 205)
                        pixel_color = draw_text(200, 200, h_count_reg, v_count_reg, 9);
                    // L
                    else if (h_count_reg >= 205 && h_count_reg < 210)
                        pixel_color = draw_text(205, 200, h_count_reg, v_count_reg, 7);
                    // A
                    else if (h_count_reg >= 210 && h_count_reg < 215)
                        pixel_color = draw_text(210, 200, h_count_reg, v_count_reg, 2);
                    // Y
                    else if (h_count_reg >= 215 && h_count_reg < 220)
                        pixel_color = draw_text(215, 200, h_count_reg, v_count_reg, 14);
                    // E
                    else if (h_count_reg >= 220 && h_count_reg < 225)
                        pixel_color = draw_text(220, 200, h_count_reg, v_count_reg, 4);
                    // R
                    else if (h_count_reg >= 225 && h_count_reg < 230)
                        pixel_color = draw_text(225, 200, h_count_reg, v_count_reg, 10);
                    // Space
                    else if (h_count_reg >= 230 && h_count_reg < 235)
                        pixel_color = 12'h000;
                    // 1 or 2
                    else if (h_count_reg >= 235 && h_count_reg < 240)
                        pixel_color = draw_text(235, 200, h_count_reg, v_count_reg, game_state == STATE_P1_WINS ? 0 : 1);
                    // Space
                    else if (h_count_reg >= 240 && h_count_reg < 245)
                        pixel_color = 12'h000;
                    // W
                    else if (h_count_reg >= 245 && h_count_reg < 250)
                        pixel_color = draw_text(245, 200, h_count_reg, v_count_reg, 13);
                    // I
                    else if (h_count_reg >= 250 && h_count_reg < 255)
                        pixel_color = draw_text(250, 200, h_count_reg, v_count_reg, 6);
                    // N
                    else if (h_count_reg >= 255 && h_count_reg < 260)
                        pixel_color = draw_text(255, 200, h_count_reg, v_count_reg, 8);
                    // S
                    else if (h_count_reg >= 260 && h_count_reg < 265)
                        pixel_color = draw_text(260, 200, h_count_reg, v_count_reg, 11);
                end
                
                if (pixel_color != 12'h000) begin
                    vgaRed = pixel_color[11:8];
                    vgaGreen = pixel_color[7:4];
                    vgaBlue = pixel_color[3:0];
                end
            end
            // Grid 1 - Player 1 Placement Grid
            else if (game_state == STATE_P1_PLACING &&
                     h_count_reg >= grid1_start_x && h_count_reg < grid1_start_x + (grid_size * cell_size) &&
                     v_count_reg >= grid1_start_y && v_count_reg < grid1_start_y + (grid_size * cell_size))
            begin
                curr_cell = ((v_count_reg - grid1_start_y) / cell_size) * grid_size + 
                            ((h_count_reg - grid1_start_x) / cell_size);
                
                if ((h_count_reg - grid1_start_x) % cell_size == 0 || 
                    (v_count_reg - grid1_start_y) % cell_size == 0)
                    {vgaRed, vgaGreen, vgaBlue} = 12'h777; // Grid lines
                else if (placement_cursor_p1[curr_cell] == 1)
                    {vgaRed, vgaGreen, vgaBlue} = 12'hFF0; // Yellow cursor
                else if (placed_ships_p1[curr_cell] == 1)
                begin
                    ship_length = 1;
                    start_x = (curr_cell % grid_size);
                    start_y = (curr_cell / grid_size);
                    ship_start_cell = curr_cell;
                    is_horizontal = 0;

                    // Check horizontal (left or right)
                    if (start_x > 0 && placed_ships_p1[curr_cell - 1] == 1) begin
                        offset = 0;
                        for (offset = 1; offset < 3 && start_x > 0 && placed_ships_p1[curr_cell - offset] == 1; offset = offset + 1)
                            start_x = start_x - 1;
                        ship_start_cell = curr_cell - (offset - 1);
                        start_x = (ship_start_cell % grid_size);
                        start_y = (ship_start_cell / grid_size);
                        ship_length = 1;
                        for (offset = 1; offset < 3 && start_x + ship_length < grid_size && placed_ships_p1[ship_start_cell + ship_length] == 1; offset = offset + 1)
                            ship_length = ship_length + 1;
                        is_horizontal = 1;
                    end
                    else if (start_y > 0 && placed_ships_p1[curr_cell - grid_size] == 1) begin
                        offset = 0;
                        for (offset = 1; offset < 3 && start_y > 0 && placed_ships_p1[curr_cell - (offset * grid_size)] == 1; offset = offset + 1)
                            start_y = start_y - 1;
                        ship_start_cell = curr_cell - ((offset - 1) * grid_size);
                        start_x = (ship_start_cell % grid_size);
                        start_y = (ship_start_cell / grid_size);
                        ship_length = 1;
                        for (offset = 1; offset < 3 && start_y + ship_length < grid_size && placed_ships_p1[ship_start_cell + (ship_length * grid_size)] == 1; offset = offset + 1)
                            ship_length = ship_length + 1;
                        is_horizontal = 0;
                    end
                    else begin
                        if (start_x + 1 < grid_size && placed_ships_p1[curr_cell + 1] == 1) begin
                            is_horizontal = 1;
                            for (offset = 1; offset < 3 && start_x + ship_length < grid_size && placed_ships_p1[curr_cell + ship_length] == 1; offset = offset + 1)
                                ship_length = ship_length + 1;
                        end
                        else if (start_y + 1 < grid_size && placed_ships_p1[curr_cell + grid_size] == 1) begin
                            is_horizontal = 0;
                            for (offset = 1; offset < 3 && start_y + ship_length < grid_size && placed_ships_p1[curr_cell + (ship_length * grid_size)] == 1; offset = offset + 1)
                                ship_length = ship_length + 1;
                        end
                    end

                    // Determine ship width based on length
                    ship_width = ship_length == 4 ? SHIP_4_WIDTH :
                                 ship_length == 3 ? SHIP_3_WIDTH :
                                 SHIP_2_WIDTH;

                    if (is_horizontal &&
                        h_count_reg >= grid1_start_x + (start_x * cell_size) &&
                        h_count_reg < grid1_start_x + (start_x * cell_size) + (ship_length * cell_size) &&
                        v_count_reg >= grid1_start_y + (start_y * cell_size) &&
                        v_count_reg < grid1_start_y + (start_y * cell_size) + cell_size)
                    begin
                        x_offset = h_count_reg - (grid1_start_x + (start_x * cell_size));
                        y_offset = v_count_reg - (grid1_start_y + (start_y * cell_size));
                        bit_index = y_offset * ship_width + x_offset;
                        if (ship_length == 4 && bit_index < SHIP_4_SIZE && ship_4_bits[bit_index])
                            pixel_color = 12'hFFF; // White ship
                        else if (ship_length == 3 && bit_index < SHIP_3_SIZE && ship_3_bits[bit_index])
                            pixel_color = 12'hFFF;
                        else if (ship_length == 2 && bit_index < SHIP_2_SIZE && ship_2_bits[bit_index])
                            pixel_color = 12'hFFF;
                        else
                            pixel_color = 12'h000;
                    end
                    else if (!is_horizontal &&
                             h_count_reg >= grid1_start_x + (start_x * cell_size) &&
                             h_count_reg < grid1_start_x + (start_x * cell_size) + cell_size &&
                             v_count_reg >= grid1_start_y + (start_y * cell_size) &&
                             v_count_reg < grid1_start_y + (start_y * cell_size) + (ship_length * cell_size))
                    begin
                        x_offset = h_count_reg - (grid1_start_x + (start_x * cell_size));
                        y_offset = v_count_reg - (grid1_start_y + (start_y * cell_size));
                        // Rotate the bitmap: swap x and y, and adjust for vertical orientation
                        bit_index = x_offset * ship_width + (ship_width - 1 - (y_offset % ship_width));
                        if (ship_length == 4 && bit_index < SHIP_4_SIZE && ship_4_bits[bit_index])
                            pixel_color = 12'hFFF;
                        else if (ship_length == 3 && bit_index < SHIP_3_SIZE && ship_3_bits[bit_index])
                            pixel_color = 12'hFFF;
                        else if (ship_length == 2 && bit_index < SHIP_2_SIZE && ship_2_bits[bit_index])
                            pixel_color = 12'hFFF;
                        else
                            pixel_color = 12'h000;
                    end

                    if (pixel_color != 12'h000) begin
                        vgaRed = pixel_color[11:8];
                        vgaGreen = pixel_color[7:4];
                        vgaBlue = pixel_color[3:0];
                    end
                end
                else
                    {vgaRed, vgaGreen, vgaBlue} = 12'h555; // Default cell color
            end
            // Grid 2 - Player 2 Placement Grid
            else if (game_state == STATE_P2_PLACING &&
                     h_count_reg >= grid2_start_x && h_count_reg < grid2_start_x + (grid_size * cell_size) &&
                     v_count_reg >= grid2_start_y && v_count_reg < grid2_start_y + (grid_size * cell_size))
            begin
                curr_cell = ((v_count_reg - grid2_start_y) / cell_size) * grid_size + 
                            ((h_count_reg - grid2_start_x) / cell_size);
                
                if ((h_count_reg - grid2_start_x) % cell_size == 0 || 
                    (v_count_reg - grid2_start_y) % cell_size == 0)
                    {vgaRed, vgaGreen, vgaBlue} = 12'h777; // Grid lines
                else if (placement_cursor_p2[curr_cell] == 1)
                    {vgaRed, vgaGreen, vgaBlue} = 12'hFF0; // Yellow cursor
                else if (placed_ships_p2[curr_cell] == 1)
                begin
                    ship_length = 1;
                    start_x = (curr_cell % grid_size);
                    start_y = (curr_cell / grid_size);
                    ship_start_cell = curr_cell;
                    is_horizontal = 0;

                    // Check horizontal (left or right)
                    if (start_x > 0 && placed_ships_p2[curr_cell - 1] == 1) begin
                        offset = 0;
                        for (offset = 1; offset < 3 && start_x > 0 && placed_ships_p2[curr_cell - offset] == 1; offset = offset + 1)
                            start_x = start_x - 1;
                        ship_start_cell = curr_cell - (offset - 1);
                        start_x = (ship_start_cell % grid_size);
                        start_y = (ship_start_cell / grid_size);
                        ship_length = 1;
                        for (offset = 1; offset < 3 && start_x + ship_length < grid_size && placed_ships_p2[ship_start_cell + ship_length] == 1; offset = offset + 1)
                            ship_length = ship_length + 1;
                        is_horizontal = 1;
                    end
                    else if (start_y > 0 && placed_ships_p2[curr_cell - grid_size] == 1) begin
                        offset = 0;
                        for (offset = 1; offset < 3 && start_y > 0 && placed_ships_p2[curr_cell - (offset * grid_size)] == 1; offset = offset + 1)
                            start_y = start_y - 1;
                        ship_start_cell = curr_cell - ((offset - 1) * grid_size);
                        start_x = (ship_start_cell % grid_size);
                        start_y = (ship_start_cell / grid_size);
                        ship_length = 1;
                        for (offset = 1; offset < 3 && start_y + ship_length < grid_size && placed_ships_p2[ship_start_cell + (ship_length * grid_size)] == 1; offset = offset + 1)
                            ship_length = ship_length + 1;
                        is_horizontal = 0;
                    end
                    else begin
                        if (start_x + 1 < grid_size && placed_ships_p2[curr_cell + 1] == 1) begin
                            is_horizontal = 1;
                            for (offset = 1; offset < 3 && start_x + ship_length < grid_size && placed_ships_p2[curr_cell + ship_length] == 1; offset = offset + 1)
                                ship_length = ship_length + 1;
                        end
                        else if (start_y + 1 < grid_size && placed_ships_p2[curr_cell + grid_size] == 1) begin
                            is_horizontal = 0;
                            for (offset = 1; offset < 3 && start_y + ship_length < grid_size && placed_ships_p2[curr_cell + (ship_length * grid_size)] == 1; offset = offset + 1)
                                ship_length = ship_length + 1;
                        end
                    end

                    // Determine ship width based on length
                    ship_width = ship_length == 4 ? SHIP_4_WIDTH :
                                 ship_length == 3 ? SHIP_3_WIDTH :
                                 SHIP_2_WIDTH;

                    if (is_horizontal &&
                        h_count_reg >= grid2_start_x + (start_x * cell_size) &&
                        h_count_reg < grid2_start_x + (start_x * cell_size) + (ship_length * cell_size) &&
                        v_count_reg >= grid2_start_y + (start_y * cell_size) &&
                        v_count_reg < grid2_start_y + (start_y * cell_size) + cell_size)
                    begin
                        x_offset = h_count_reg - (grid2_start_x + (start_x * cell_size));
                        y_offset = v_count_reg - (grid2_start_y + (start_y * cell_size));
                        bit_index = y_offset * ship_width + x_offset;
                        if (ship_length == 4 && bit_index < SHIP_4_SIZE && ship_4_bits[bit_index])
                            pixel_color = 12'hFFF;
                        else if (ship_length == 3 && bit_index < SHIP_3_SIZE && ship_3_bits[bit_index])
                            pixel_color = 12'hFFF;
                        else if (ship_length == 2 && bit_index < SHIP_2_SIZE && ship_2_bits[bit_index])
                            pixel_color = 12'hFFF;
                        else
                            pixel_color = 12'h000;
                    end
                    else if (!is_horizontal &&
                             h_count_reg >= grid2_start_x + (start_x * cell_size) &&
                             h_count_reg < grid2_start_x + (start_x * cell_size) + cell_size &&
                             v_count_reg >= grid2_start_y + (start_y * cell_size) &&
                             v_count_reg < grid2_start_y + (start_y * cell_size) + (ship_length * cell_size))
                    begin
                        x_offset = h_count_reg - (grid2_start_x + (start_x * cell_size));
                        y_offset = v_count_reg - (grid2_start_y + (start_y * cell_size));
                        // Rotate the bitmap: swap x and y, and adjust for vertical orientation
                        bit_index = x_offset * ship_width + (ship_width - 1 - (y_offset % ship_width));
                        if (ship_length == 4 && bit_index < SHIP_4_SIZE && ship_4_bits[bit_index])
                            pixel_color = 12'hFFF;
                        else if (ship_length == 3 && bit_index < SHIP_3_SIZE && ship_3_bits[bit_index])
                            pixel_color = 12'hFFF;
                        else if (ship_length == 2 && bit_index < SHIP_2_SIZE && ship_2_bits[bit_index])
                            pixel_color = 12'hFFF;
                        else
                            pixel_color = 12'h000;
                    end

                    if (pixel_color != 12'h000) begin
                        vgaRed = pixel_color[11:8];
                        vgaGreen = pixel_color[7:4];
                        vgaBlue = pixel_color[3:0];
                    end
                end
                else
                    {vgaRed, vgaGreen, vgaBlue} = 12'h555; // Default cell color
            end
            // Grid 3 - Player 1 Attack Grid
            else if ((game_state == STATE_P1_ATTACK || game_state == STATE_P2_ATTACK) &&
                     h_count_reg >= grid3_start_x && h_count_reg < grid3_start_x + (grid_size * cell_size) &&
                     v_count_reg >= grid3_start_y && v_count_reg < grid3_start_y + (grid_size * cell_size))
            begin
                curr_cell = ((v_count_reg - grid3_start_y) / cell_size) * grid_size + 
                            ((h_count_reg - grid3_start_x) / cell_size);
                
                if ((h_count_reg - grid3_start_x) % cell_size == 0 || 
                    (v_count_reg - grid3_start_y) % cell_size == 0)
                    {vgaRed, vgaGreen, vgaBlue} = 12'h777; // Grid lines
                else if (game_state == STATE_P1_ATTACK && cursor_p1[curr_cell] == 1)
                    {vgaRed, vgaGreen, vgaBlue} = 12'hFF0; // Yellow cursor
                else if (coloring_array_p1[curr_cell] == 1)
                begin
                    if (hitmiss_array_p2[curr_cell] == 1) begin // Hit
                        bit_index = ((v_count_reg - grid3_start_y) % cell_size) * 30 + ((h_count_reg - grid3_start_x) % cell_size);
                        if (bit_index < FIRE_SIZE && fire_bits[bit_index])
                            pixel_color = 12'hF00; // Red cross for hit
                        else
                            pixel_color = 12'h000;
                    end else begin // Miss
                        pixel_color = 12'hFFF; // White cell for miss
                    end
                    if (pixel_color != 12'h000) begin
                        vgaRed = pixel_color[11:8];
                        vgaGreen = pixel_color[7:4];
                        vgaBlue = pixel_color[3:0];
                    end
                end
                else
                    {vgaRed, vgaGreen, vgaBlue} = 12'h555; // Default cell color
            end
            // Grid 4 - Player 2 Attack Grid
            else if ((game_state == STATE_P1_ATTACK || game_state == STATE_P2_ATTACK) &&
                     h_count_reg >= grid4_start_x && h_count_reg < grid4_start_x + (grid_size * cell_size) &&
                     v_count_reg >= grid4_start_y && v_count_reg < grid4_start_y + (grid_size * cell_size))
            begin
                curr_cell = ((v_count_reg - grid4_start_y) / cell_size) * grid_size + 
                            ((h_count_reg - grid4_start_x) / cell_size);
                
                if ((h_count_reg - grid4_start_x) % cell_size == 0 || 
                    (v_count_reg - grid4_start_y) % cell_size == 0)
                    {vgaRed, vgaGreen, vgaBlue} = 12'h777; // Grid lines
                else if (game_state == STATE_P2_ATTACK && cursor_p2[curr_cell] == 1)
                    {vgaRed, vgaGreen, vgaBlue} = 12'hFF0; // Yellow cursor
                else if (coloring_array_p2[curr_cell] == 1)
                begin
                    if (hitmiss_array_p1[curr_cell] == 1) begin // Hit
                        bit_index = ((v_count_reg - grid4_start_y) % cell_size) * 30 + ((h_count_reg - grid4_start_x) % cell_size);
                        if (bit_index < FIRE_SIZE && fire_bits[bit_index])
                            pixel_color = 12'hF00; // Red cross for hit
                        else
                            pixel_color = 12'h000;
                    end else begin // Miss
                        pixel_color = 12'hFFF; // White cell for miss
                    end
                    if (pixel_color != 12'h000) begin
                        vgaRed = pixel_color[11:8];
                        vgaGreen = pixel_color[7:4];
                        vgaBlue = pixel_color[3:0];
                    end
                end
                else
                    {vgaRed, vgaGreen, vgaBlue} = 12'h555; // Default cell color
            end
            // Title text area above grids
            else if (h_count_reg >= grid1_start_x && h_count_reg < grid4_start_x + (grid_size * cell_size) &&
                     v_count_reg >= 20 && v_count_reg < 40)
            begin
                if (game_state == STATE_P1_PLACING && h_count_reg >= grid1_start_x + 30 && h_count_reg < grid1_start_x + 150)
                    {vgaRed, vgaGreen, vgaBlue} = 12'hFFF; // "Player 1 Fleet"
                else if (game_state == STATE_P2_PLACING && h_count_reg >= grid2_start_x + 30 && h_count_reg < grid2_start_x + 150)
                    {vgaRed, vgaGreen, vgaBlue} = 12'hFFF; // "Player 2 Fleet"
                else if ((game_state == STATE_P1_ATTACK || game_state == STATE_P2_ATTACK) && h_count_reg >= grid3_start_x + 30 && h_count_reg < grid3_start_x + 150)
                    {vgaRed, vgaGreen, vgaBlue} = 12'hFFF; // "Player 2 Fleet"
                else if ((game_state == STATE_P1_ATTACK || game_state == STATE_P2_ATTACK) && h_count_reg >= grid4_start_x + 30 && h_count_reg < grid4_start_x + 150)
                    {vgaRed, vgaGreen, vgaBlue} = 12'hFFF; // "Player 1 Fleet"
                else
                    {vgaRed, vgaGreen, vgaBlue} = 12'h000; // Black background
            end
            else
                {vgaRed, vgaGreen, vgaBlue} = 12'h00F; // Debug: Blue outside display area
        end
        else
            {vgaRed, vgaGreen, vgaBlue} = 12'h00F; // Debug: Blue outside display area
    end
    
    assign Hsync = hsync_reg;
    assign Vsync = vsync_reg;
endmodule