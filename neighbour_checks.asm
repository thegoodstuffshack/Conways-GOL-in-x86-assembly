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
	mov dx, di
	;	math for finding bit in the byte - could use lookup table
	and di, 0x0007 ; 0000 0000 0000 0111
	mov cx, di	; store remainder
	mov di, dx
	mov ch, 0b10000000	; 
	shr ch, cl			; use remainder to find bit pos in byte

	shr di, 3		; from bit to byte value div 8
;	multiply si by 40
	lea ax, [esi*4+esi] ; si * (1,2,3,4,5,8,9)
	lea ax, [eax*8]		; si * 8
	add di, ax

	mov al, [di+grid_address]	; get byte
	xor al, ch	; toggle bit
	mov [di+grid_address], al
	mov di, dx
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