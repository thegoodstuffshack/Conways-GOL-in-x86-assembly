neighbour_checks:
;	remove edge cases from main loop
	or di, di												;
	jz .left_edge											;
	
	cmp di, frame_width - 1
	je .right_edge
	
	or si, si
	jz .top_edge_only
	
	cmp si, frame_height - 1
	je .bottom_edge_only

;	center cases only : x-1, x-1 y+1, x-1 y-1, y+1, y-1, x+1, x+1 y+1, x+1 y-1
.center_cases:
	dec di
	call get_bit_state
	add [neighbour_count], al
	
	inc si
	call get_bit_state
	add [neighbour_count], al
	
	inc di
	call get_bit_state
	add [neighbour_count], al
	
	inc di
	call get_bit_state
	add [neighbour_count], al
	
	dec si
	call get_bit_state
	add [neighbour_count], al
	
	dec si
	call get_bit_state
	add [neighbour_count], al
	
	dec di
	call get_bit_state
	add [neighbour_count], al
	
	dec di
	call get_bit_state
	add [neighbour_count], al
	
	inc di
	inc si
	
.change_state:
	call get_bit_state	; al -> bit state
	mov ah, [neighbour_count]
	
	or al, al
	jz .dead

.alive:
	or ah, al
	cmp ah, 3
	je .end

.toggle:
	push es
	mov es, bx	; es -> 0
	mov bx, grid_address
	call toggle_pixel_state
	pop es
	xor bx, bx
	jmp .end
	
.dead:
	cmp ah, 3
	je .toggle

.end:
	inc di	
	jmp game_loop

;	further determine edge cases
.left_edge:
	or si, si
	jz .top_left_corner
	cmp si, frame_height - 1
	je .bottom_left_corner
	jmp .left_edge_only

.right_edge:
	or si, si
	jz .top_right_corner
	cmp si, frame_height - 1
	je .bottom_right_corner
	jmp .right_edge_only

;	corners and edges only
.left_edge_only:	; i.e. without x-1, x-1 y-1, x-1 y+1
	inc si
	call get_bit_state
	add [neighbour_count], al
	
	inc di
	call get_bit_state
	add [neighbour_count], al
	
	dec si
	call get_bit_state
	add [neighbour_count], al
	
	dec si
	call get_bit_state
	add [neighbour_count], al
	
	dec di
	call get_bit_state
	add [neighbour_count], al
	
	inc si
	jmp .change_state
	
.right_edge_only:	; i.e. without x+1, x+1 y-1, x+1 y+1
	dec si
	call get_bit_state
	add [neighbour_count], al
	
	dec di
	call get_bit_state
	add [neighbour_count], al

	inc si
	call get_bit_state
	add [neighbour_count], al
	
	inc si
	call get_bit_state
	add [neighbour_count], al
	
	inc di
	call get_bit_state
	add [neighbour_count], al
	
	dec si
	jmp .change_state

.top_edge_only:
	inc di
	call get_bit_state
	add [neighbour_count], al

	inc si
	call get_bit_state
	add [neighbour_count], al

	dec di
	call get_bit_state
	add [neighbour_count], al	
	
	dec di
	call get_bit_state
	add [neighbour_count], al	

	dec si
	call get_bit_state
	add [neighbour_count], al	
	
	inc di
	jmp .change_state

.bottom_edge_only:
	dec di
	call get_bit_state
	add [neighbour_count], al	
	
	dec si
	call get_bit_state
	add [neighbour_count], al
	
	inc di
	call get_bit_state
	add [neighbour_count], al
	
	inc di
	call get_bit_state
	add [neighbour_count], al
	
	inc si
	call get_bit_state
	add [neighbour_count], al
	
	dec di
	jmp .change_state

.top_left_corner:
	inc di
	call get_bit_state
	add [neighbour_count], al
	
	dec si
	call get_bit_state
	add [neighbour_count], al
	
	dec di 
	call get_bit_state
	add [neighbour_count], al
	
	inc si
	jmp .change_state

.top_right_corner:
	dec di
	call get_bit_state
	add [neighbour_count], al
	
	dec si
	call get_bit_state
	add [neighbour_count], al
	
	inc di
	call get_bit_state
	add [neighbour_count], al
	
	inc si
	jmp .change_state
	
.bottom_left_corner:
	inc di
	call get_bit_state
	add [neighbour_count], al
	
	dec si
	call get_bit_state
	add [neighbour_count], al
	
	dec di
	call get_bit_state
	add [neighbour_count], al
	
	inc si
	jmp .change_state

.bottom_right_corner:
	dec di
	call get_bit_state
	add [neighbour_count], al
	
	dec si
	call get_bit_state
	add [neighbour_count], al
	
	inc di
	call get_bit_state
	add [neighbour_count], al
	
	inc si
	jmp .change_state