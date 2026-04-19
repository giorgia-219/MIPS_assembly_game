#########################################################################
# MIPS Arcade Game
# Developed by: Giorgia Manocchio
# Year: 2025
# Description: A retro arcade game using MMIO and manual polling.
#########################################################################


.data
	# store location as x/y coordinates
	player_x: .word 0
	player_y: .word 0
	reward_x: .word 0
	reward_y: .word 0
	
	score: 	.word 0
		
	game_over_string: .asciiz "GAME OVER"
	score_string: .asciiz "Score: "
	
	
	# addresses to print on display
	transmitter_control_register: .word 0xffff0008 	# Transmitter Control Register (to check for the ready bit)
	transmitter_data_register:    .word 0xffff000C  # Transmitter Data Register (where to print ASCII characters)
	
	# addresses to receive keyboard input
	receiver_control_register: .word 0xffff0000	# Receiver Control Register (to check for the ready bit)
	receiver_data_register: .word 0xffff0004	# Receiver Data Register (where keyboard input is stored)
.text
.globl main

main:
#------ PART 1: generate and store random locations for player and reward
	
	# generate random player location
	jal	random_location	# generate two random numbers between 1 and 5 returned in v0 and v1
	sw	$v0, player_x	# save return value as x coordinate
	sw	$v1, player_y	# save return value as y coordinate
	
generate_reward:	

	# generate random reward location
	jal	random_location		# generate two random numbers between 1 and 5 returned in v0 and v1
	# check reward != player position
	lw 	$t0, player_x          	# load player row
    	bne	$v0, $t0, store_reward	# if player row != reward row, store the reward location
    	lw 	$t1, player_y         	# load player column
    	beq 	$v1, $t1, generate_reward # if the locations overlap, generate a new reward location
    	
store_reward:
    	sw 	$v0, reward_x         # store reward row
   	sw 	$v1, reward_y         # store reward column
	

# ------ PART 2: print score on display
print_environment:
    	lw	$s0, transmitter_data_register	# load address where to print on
	
	jal	print_complete_score	# print "Score: " + current three-digits score 
	
# ----- PART 3: print environment
	# loop through every row and column printing either: walls (#) on the edges, player (P), reward (R), or space ( )
print_grid:
    	li 	$t1, 0           # initialize row counter ($t1)

print_row:	#loop through every row
    	li 	$t2, 0           # initialize column counter ($t2)

print_column:	#loop through every position
# print wall in first and last row or column
    	beq 	$t1, 0, print_wall      # first row
    	beq 	$t1, 6, print_wall      # last row
    	beq 	$t2, 0, print_wall      # first column
    	beq 	$t2, 6, print_wall      # last column

    # check if the player is in current position
    	lw 	$t3, player_y         	# load player row
    	lw 	$t4, player_x          	# load player column
    	bne	$t1, $t3, check_reward	# if current row != player row, check the reward's position
    	beq 	$t2, $t4, print_player  # elif current column == player column, print player

check_reward: # check if current position is reward
    	lw 	$t3, reward_y          	# load reward row
    	lw 	$t4, reward_x          	# load reward column
    	bne	$t1, $t3, print_space	# if current row != reward row, print a white space
    	beq 	$t2, $t4, print_reward  # elif current column == reward column, print player

print_space:
	jal 	check_print_ready 	# check ready bit to print
    	addi	$t5, $zero, 32         	# load ASCII value of space char
    	sw	$t5, 0($s0)		# print on display
    	j 	next_column		# jump to next column

print_wall:
    	jal 	check_print_ready 	# check ready bit to print
    	addi	$t5, $zero, 35		# load ASCII value of hash
    	sw	$t5, 0($s0)		# print on display
    	j 	next_column     	# jump to next column

print_player:
    	jal 	check_print_ready	# check ready bit to print
    	addi	$t5, $zero, 80		# load ASCII value of P char
    	sw	$t5, 0($s0)		# print on display
    	j 	next_column     	# jump to next column

print_reward:
	jal 	check_print_ready	# check ready bit to print
    	addi	$t5, $zero, 82  	# load ASCII value of R char
    	sw	$t5, 0($s0)		# print on display
    	j 	next_column             # jump to next column

next_column:
    	addi	$t2, $t2, 1            	# increment column counter
    	blt	$t2, 7, print_column  	# if column < grid size, print another column
    	
    	# else print new line to start a new row
    	jal 	check_print_ready	# check ready bit to print
	addi	$t5, $zero, 10      	# load ASCII value of new line char
   	sw	$t5, 0($s0)		# print on display
	
    	addi 	$t1, $t1, 1            	# increment row counter
    	blt 	$t1, 7, print_row     	# if rows < grid_size, print another row

#------------------- PART 4: receive and process keyboard input

    wait_input: # KEYBOARD INPUT POLLING: wait for ready bit in receiver control register
    	#### start of code from [3] #####
	lw	$t0, receiver_control_register	# import receiver control register address
	lw 	$t1, 0($t0)      		# load rcr value
    	andi 	$t1, $t1, 1      		# isolate the ready bit (LSB)
    	#### end of code from [3] #####
    	beqz 	$t1, wait_input  		# keep looping until ready bit
    
    	# save keyboard input
    	lw	$t1, receiver_data_register	# load address where input is stored [2]
    	lw	$t0, 0($t1)			# $t0 = keyboard input
	
	# check if input is a/s/d/w by comparing with their ASCII values, else keep polling (ignoring any other keys)
    	beq	$t0, 100, move_right	# d
    	beq	$t0, 97, move_left	# a
    	beq	$t0, 115, move_down	# s
    	beq	$t0, 119, move_up	# w
	j	wait_input	
   
   #check if player is within boundaries and update position
   move_right:
   	lw	$t0, player_x		# get x location
   	addi	$t0, $t0, 1		# move right (+1)
   	beq 	$t0, 6, game_over	# player hit the wall --> game over
   	sw	$t0, player_x		# update x location
   	j	move_player		# update screen
   move_left:
   	lw	$t0, player_x		# get x location
   	addi	$t0, $t0, -1		# move left (-1)
   	beq	$t0, 0, game_over	# player hit the wall --> game over
   	sw	$t0, player_x		# update x location
	j	move_player		# update screen
   move_down:
   	lw	$t0, player_y		# get y location
   	addi	$t0, $t0, 1		# move down (+1)
   	beq	$t0, 6, game_over	# player hit the wall --> game over
   	sw	$t0, player_y		# update y location
   	j	move_player		# update screen
   move_up:
      	lw	$t0, player_y		# get y location
   	addi	$t0, $t0, -1		# move up (-1)
   	beq	$t0, 0, game_over	# player hit the wall --> game over
   	sw	$t0, player_y		# update y location
   	j	move_player		# update screen
   	
move_player:	#check if the reward was caught, else skip to printing updated location
	lw	$t0, player_x		# get player x
	lw	$t1, reward_x		# get reward x
	bne	$t0, $t1, refresh_screen # if player and reward aren't on same row, skip to refresh screen

	lw	$t0, player_y		# get player y
	lw	$t1, reward_y		# get reward y
	beq	$t0, $t1, caught_reward	# if player == reward, update score, generate new reward and refresh screen
	
refresh_screen:
	jal 	clear_screen		# print ASCII 12 to clear screen [2]
	j	print_environment 	# print grid again

    
#----------- FUNCTIONS only accessible with jal (except game_over that doesn't need a return address)

check_print_ready:	# check ready bit on Transmitter Control Register to print on display
	lw 	$t8, transmitter_control_register  # load TCR address to check ready bit
    	lw 	$t9, 0($t8)      # load TCR value
    	andi 	$t9, $t9, 1      # isolate the ready bit (LSB)	[3]
    	beqz 	$t9, check_print_ready  # if ready bit == 0, keep looping
    	jr	$ra		 # ready to print: return to program
	
random_location:	# use syscall 42 to get a random x and y value (1-5) for the player and the reward.
	addi 	$a1, $zero, 5	# set upper bound
	addi 	$v0, $zero, 42	# generate random int in range 
	syscall
	addi	$v1, $a0, 1	# save random int as return value and increment by 1 to avoid walls
	syscall
	addi	$v0, $a0, 1	# save second random int to second return register and increment by 1 to avoid walls
	jr 	$ra		# exit function
	
print_complete_score:
	# save return address on stack
	addi	$sp, $sp, -4	# get space on stack for ra 
	sw	$ra, 0($sp)	# push ra on stack
	
	# print "Score: " string
	la	$t4, score_string	# load string address
	li	$t1, 0			# initialise counter
print_score_string:			# loop through each character
	jal	check_print_ready	# check ready bit for printing on display
	add 	$t3, $t4, $t1		# char address = start address + counter
	lb  	$t2, 0($t3)		# get $t1-th char
	sw	$t2, 0($s0)		# print char on display
	addi	$t1, $t1, 1		# increment counter
	blt 	$t1, 7, print_score_string	# repeat 7 times
	
print_score:	# convert score (0-999) to ASCII value digit by digit 
# after div, get the remainder from the hi register and the int quotient from the lo register [1]
	lw	$t0, score	# get current score
	# hundreds
	div	$t0, $t0, 100	# divide score by 100
	mflo 	$t0       	# $t0 = hundreds digit (LO register)
	addi	$t0, $t0, 48	# add 48 = offset value to ASCII code
	jal	check_print_ready # check ready bit to print
	sw	$t0, 0($s0)	# print on display
	# tens
	mfhi	$t0		# keep remainder on score register
	div	$t0, $t0, 10	# divide score by 10
	mflo 	$t0       	# $t0 = tens digit (LO register)
	addi	$t0, $t0, 48	# add 48 = offset value to ASCII code
	jal	check_print_ready # check ready bit to print
	sw	$t0, 0($s0)	# print on display
	# units
	mfhi	$t0		# $t0 = units digit (HI register)
	addi	$t0, $t0, 48	# add 48 = offset value to ASCII code
	jal	check_print_ready # check ready bit to print
	sw	$t0, 0($s0)	# print on display
	
	# print a new line
	jal	check_print_ready # ready bit
	li	$t2, 10		# 10 = new line ASCII value
	sw	$t2, 0($s0)	# print on display
	
	# return to program
	lw	$ra, 0($sp)	# recover return address from stack
	addi	$sp, $sp, 4	# restore stack pointer
	jr 	$ra		# return 	

caught_reward:
	lw	$t0, score	# get score
 	addi	$t0, $t0, 5	# score += 5
 	sw	$t0, score	# save score
    	bge   	$t0, 100, game_over # if score >= 100 --> game over
	jal	clear_screen	# refresh screen
	j	generate_reward	# generate new reward and print new grid
	
clear_screen:
	# save return address
	addi	$sp, $sp, -4	# increment stack pointer
	sw	$ra, 0($sp)	# push la on stack
	
	# print ASCII 12 to clear screen
	jal 	check_print_ready # ready bit
	li	$t1, 12		# ASCII 12 [2]
	sw	$t1, 0($s0)	# print on display
	
	# return
	lw	$ra, 0($sp)	# pop return address from stack
	addi	$sp, $sp, 4	# set stack pointer
	jr	$ra		# return

game_over:
	jal 	clear_screen
   	la	$t4, game_over_string	# load address of "GAME OVER" string
	li	$t1, 0			# counter to iterate through string	
game_over_print:
	jal	check_print_ready	# check ready bit to print
	add 	$t3, $t4, $t1		# iterate address
	lb  	$t2, 0($t3)		# get first character of string
	sw	$t2, 0($s0)		# print character
	addi	$t1, $t1, 1		# increment counter
	blt	$t1, 9,	game_over_print	# loop until end of string

exit:
	# print new line
	jal	check_print_ready # ready bit
	li	$t2, 10		# t2 = new line ASCII value
	sw	$t2, 0($s0)	# print on display
	
	jal	print_complete_score	# print final score

	li	$v0, 10		# exit syscall
	syscall
