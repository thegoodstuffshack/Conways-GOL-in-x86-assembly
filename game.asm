[bits 16]
[org 0x7c00]
jmp start

; nasm -f bin game.asm -o test.bin
; qemu-system-x86_64 test.bin

;========================================================================
;========================================================================

BOOT_DRIVE					db 0
video_memory_address		equ 0xA000
neighbour_checks_address 	equ 0x7e00
grid_address				equ 0x8200
frame_width					equ 320
frame_height				equ 200

neighbour_count				db 0
current_coord_state			db 0

;========================================================================
;========================================================================

start:
	xor ax, ax
	mov es, ax
	mov ds, ax
	mov ss, ax
	mov sp, 0x7c00
	mov [BOOT_DRIVE], dl

	call load_sector
	call setup_graphics_mode
	
	;	load grid state from grid.asm
	call refresh_screen_from_grid
	
	; ; wait for user input
	; mov ah, 0
	; int 0x16
	
;========================================================================
game_setup:

;	load grid state from grid.asm
	call refresh_screen_from_grid
	
	xor di, di
	xor si, si
	
; exit on user input
	mov ah, 1
	int 0x16
	jnz _end
	
;	use states in video memory to determine new states, place in grid
;	need to individually check state for each tile - 64K

;;	GAME CHANGE - code wrap-around borders
;;	ISSUE - adjusting frame size works however grid is incompatible with different values for width

;; OPTIMISATION - shorten functions called more often than others
;				- i.e. lengthen less used functions, e.g. keep es set
;				- es -> video_memory_address, bx -> 0
;; OPTIMISATION - conditional checking of neighbours to prevent same byte grab
;; OPTIMISATION - only check cells in each iteration that either changed or had neighbours that changed
;; OPTIMISATION - 
;; OPTIMISATION - edit .change_state to -> alive if: current_coord_state | neighbour_count == 3
;; OPTIMISATION - use register for storing neighbour count
;; OPTIMISATION - saving memory with functions increases compute time -> integrate functions
;;				- not reusing code will make it faster, bake EVERYTHING

game_loop:
	cmp di, frame_width
	jne .same_row
	inc si
	cmp si, frame_height
	je game_setup
	
	xor di, di
.same_row:
	call get_bit_state ; 0000 000x
	mov [current_coord_state], al
	mov byte [neighbour_count], 0
	; jmp _end
	jmp neighbour_checks
;========================================================================
;========================================================================
_end:
	mov al, 3
	call change_graphics_mode
	cli
	hlt

setup_graphics_mode:
;	change bios video mode to graphics 320x200 colour
	mov al, 0x0d
	call change_graphics_mode
	
;	set background colour - 16 bit
;	black, blue, green, cyan, red, magenta, orange, l grey, d grey, l blue, l green, l cyan, l red, pink, yellow, white
	mov ah, 0x0b
	mov bh, 0
	mov bl, 0 ; black
	int 0x10
ret

refresh_screen_from_grid:
	push video_memory_address
	pop es
	xor di, di
	mov ds, di
	mov si, grid_address
	mov cx, frame_height * frame_width / 32
	rep movsd	; mov ds:si to es:di , inc di, inc si, repeat cx times
ret

get_bit_state:
	push video_memory_address
	pop es
	xor bx, bx
	push di
	call extract_byte
	pop di
	and al, ch ; 0101 1110 --> 0000 00x0
	or al, al
	mov al, 0
	jz .zero
	inc al
.zero:
ret

;========================================================================
;========================================================================
; es as es
; bx as bx
; di as x coord
; si as y coord
; returns al as byte at address
; returns ch as bit pos in byte
extract_byte:
	push di
	and di, 0b0000000000000111
	mov cx, di
	pop di
	shr di, 3
	
	mov ch, 0b10000000
	shr ch, cl
	
	mov ax, frame_width / 8
	mul si
	add di, ax ; calculate offset
	
	mov al, [es:bx+di]
	
	ret

; es as es
; bx as bx
; di as input for x coord
; si as input for y coord
toggle_pixel_state:
	push di
	call extract_byte
	xor al, ch
	add di, bx

	stosb	; mov al into address es:di
	
	xor ax, ax
	mov es, ax
	pop di
	ret

; cx as input
delay:
	mov ah, 0x86
	xor dx, dx
	int 0x15
	ret

; al as input
print_char:
	mov ah, 0x0e
	int 0x10
	ret

; al as input
change_graphics_mode:
	mov ah, 0
	int 0x10
	ret

load_sector:
	mov ah, 0x02	; read data to memory
	mov al, 18		; no. of sectors
	mov ch, 0		; cylinder_count 
	mov cl, 2		; sector in head
	mov dh, 0		; head_count
	mov dl, [BOOT_DRIVE]
	xor bx, bx
	mov es, bx
	mov bx, neighbour_checks_address
	int 0x13
	; jc disk_error
ret
	
; disk_error:
	; mov al, '1'
	; call print_char
	; jmp $
	
times 510-($-$$) db 0
dw 0xAA55

neighbour_checks_start:
%include "neighbour_checks.asm"
times 512*2-($-neighbour_checks_start) db 0

grid_start:
%include "grid.asm"
times 512*16-($-grid_start) db 0