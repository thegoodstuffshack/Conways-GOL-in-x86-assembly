neighbour_checks:
;	remove edge cases from main loop
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
	
	inc si
	call get_bit_state
	
	inc di
	call get_bit_state
	
	inc di
	call get_bit_state
	
	dec si
	call get_bit_state
	
	dec si
	call get_bit_state
	
	dec di
	call get_bit_state
	
	dec di
	call get_bit_state
	
	inc di
	inc si
	
.change_state:	; bl is neighbour count
	mov bh, bl
	call get_bit_state	; al -> bit state
	mov bl, bh
	or al, al
	jz .dead

.alive:
	or bl, 1
	cmp bl, 3
	je .end

.toggle:
	xor ax, ax
	mov es, ax
	call toggle_pixel_state
	mov ax, video_memory_address
	mov es, ax
	jmp .end
	
.dead:
	cmp bl, 3
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
	
	inc di
	call get_bit_state
	
	dec si
	call get_bit_state
	
	dec si
	call get_bit_state
	
	dec di
	call get_bit_state
	
	inc si
	jmp .change_state
	
.right_edge_only:	; i.e. without x+1, x+1 y-1, x+1 y+1
	dec si
	call get_bit_state
	
	dec di
	call get_bit_state

	inc si
	call get_bit_state
	
	inc si
	call get_bit_state
	
	inc di
	call get_bit_state
	
	dec si
	jmp .change_state

.top_edge_only:
	or di, di
	jz .top_left_corner

	inc di
	call get_bit_state

	inc si
	call get_bit_state

	dec di
	call get_bit_state
		
	dec di
	call get_bit_state
	
	dec si
	call get_bit_state
		
	inc di
	jmp .change_state

.bottom_edge_only:
	dec di
	call get_bit_state

	dec si
	call get_bit_state
	
	inc di
	call get_bit_state
	
	inc di
	call get_bit_state
	
	inc si
	call get_bit_state
	
	dec di
	jmp .change_state

.top_left_corner:
	inc di
	call get_bit_state
	
	dec si
	call get_bit_state
	
	dec di 
	call get_bit_state
	
	inc si
	jmp .change_state

.top_right_corner:
	dec di
	call get_bit_state
	
	dec si
	call get_bit_state
	
	inc di
	call get_bit_state
	
	inc si
	jmp .change_state
	
.bottom_left_corner:
	inc di
	call get_bit_state
	
	dec si
	call get_bit_state
	
	dec di
	call get_bit_state
	
	inc si
	jmp .change_state

.bottom_right_corner:
	dec di
	call get_bit_state
	
	dec si
	call get_bit_state
	
	inc di
	call get_bit_state
	
	inc si
	jmp .change_state