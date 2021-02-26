#-------------------------------------------------------------------------------
#author: M Nabeel Al-Mufti
#date : 2021/1/3
#description : Program For Detecting Black Markers In A BMP file 
#-------------------------------------------------------------------------------



#---------------------------Initializing Data Section---------------------------
#only 24-bits 320x240 pixels BMP files are supported 
.eqv BMP_FILE_SIZE 240000 
.eqv BYTES_PER_ROW 960 #320x3 

	.data

		.align 4
res:		.space 2
image:		.space BMP_FILE_SIZE
pFoundX: 	.asciiz " P is at coordiante: x = "
pFoundY: 	.asciiz ", y = "
newLine: 	.asciiz "\n"
invalidMarker: 	.asciiz "No (more) valid marker has been found"
wrongFile:	.asciiz "File is invalid"
notBMP:		.asciiz "File is not BMP"
wrongSize:	.asciiz "The witdh and/or height of the BMP is not 320x240" 
not24bits:	.asciiz "The BMP file is not in the 24 bits-per-pixel format"
width:		.word 320
height:		.word 240
fname:		.asciiz "intensive_tests.bmp"
#fname:		.asciiz "wrongsize_test.bmp"
#fname:		.asciiz "not24bits_test.bmp"
#fname:		.asciiz "notBMP_test.png"
#fname:		.asciiz "INVALID FILE _ test"

#---------------------------------------------------------------------------------

#----------------------------Main Program Execution-------------------------------

	.text
main: 
	jal	read_bmp
	li	$a0, 0		#initial x coordiante
	li	$a1, 0		#initial y coordiante
		
	mainLoop: 
	li	$s0, 0 			#used as a secondary counter
	li	$s1, 0			#used to prevent a0 from unwanted alternations
	li	$s2, 0 			#save y coordiante after finding a valid marker to find more marker
	li	$s3, -1			#first counter to compare upwards
	li	$s4, -1 		#second counter to compare horiztional
	li	$s5, 0  		#potetional P x coordiante
	li	$s6, 0			#potetional P y coordiante
	li	$s7, 0  		#thickness counter
	
	move 	$s1, $a0
	findBlackPixel:			#finding a black pixel
	move	$a0, $s1
	jal	get_pixel
	beq	$v0, $t9, exitFBP	#since $t9 is 0x00000000, and so is the hex code for black.
	addi	$s1,$s1, 1		#x = x + 1
	beq	$s1,319, moveUpwards	#if the last pixel in a row is not black, move one row upwards
	j findBlackPixel
	
	exitFBP:	
	move $a0, $s1			#save our x coordiante
	move $s5, $s1			#potetional P x coordiante
	move $s2, $a1  			#save y coordiante to find more markers
	
	subu $a1,$a1,1			#if there's a black pixel beneath our found black pixel then it's a part of a larger marker or invalid, move on. 
	jal get_pixel
	beq $v0,$t9,nextPixel		#since $t9 is 0x00000000, and so is the hex code for black.
	move $a1,$s2			#if there's no black pixel beneath our found black pixel, bring y one pixel back up			
	
	upBlackPixel:			#Travesing upside the found black pixel 
	move $a0, $s1			#save our x coordiante
	jal get_pixel
	bne $v0,$t9, exitUBP		#if its not equal to a black pixel, then exit 
	addi $a1,$a1,1			#if its equal to a black pixel, move one row upwards
	addi $s3,$s3, 1			#the number of times we went upwards, will be used later to check if width and height are equal
	j upBlackPixel
	
	exitUBP:
	move 	$a0, $s1		#save our x coordiante from unwanted alternations
	subiu 	$a1,$a1,1		#go back to the last upward black pixel
	move  	$s6, $a1, 		#potetional P y coordiante

		
	subu $a0,$a0,1			#if there's a black pixel to the left of of a black pixel then it's a part of a larger marker or invalid, move on. 
	move $a1,$s2			
	move $s1, $a0
	whileleftblack:
	move $a0,$s1
	jal get_pixel
	beq $v0,$t9,nextPixel
	beq $s0,$s3,exitWhileLeftBlack
	addi $a1,$a1,1
	addi $s0,$s0,1
	j whileleftblack
	
	exitWhileLeftBlack:		 #move back x and y to point s
	move $a0,$s5
	move $a1,$s6
	move $s1,$a0
	
	rightBlackPixel:		#Traversing to the right of our potetional p
	move	$a0, $s1		#save our x coordiante from unwanted alternations
	jal get_pixel
	bne  $v0,$t9, exitRBP		#keep moving to the right until a non black pixel is met
	addi	$s1, $s1, 1		#x = x + 1
	addi	$s4, $s4, 1		#the number of times we went right side, will be used later to check if width and height are equal
	j rightBlackPixel			
	exitRBP:
	move $a0, $s1			#save our x coordiante
	
	addi $a0, $s5,1			#check above our potetional P if there are black pixels 
	addi $a1, $s6,1
	move $s1,$a0
	li   $s0,1			
	checkAbove:
	move $a0,$s1
	jal get_pixel
	beq $v0,$t9,nextPixel		#if there's a black pixel above our marker, then it's invalid, move on.
	beq $s0,$s4,exitCheckAbove	#if there isnt a black pixel above our marker, then it's safe to keep checking.
	addi $s0,$s0,1
	addi $s1,$s1,1
	j checkAbove
	exitCheckAbove:
	move $t5, $s4			 #we'll use $t5 for thickness check 
	
	bne $s3,$s4,nextPixel		 #if height is not equal length then marker is invalid 
	beqz $s4,nextPixel		 #if there's only one black pixel by itself, it shouldn't be counted as a valid marker
	beq $s3,$s4,validator		 #if height and width are equal, move on to next validation 

	validator:
	addi $s7,$s7,1			#add one to thickness counter 
	beq  $s7,$t5,checkSquare	#thickness checks, move on to last validation
	addu $a0,$s5,$s7		#move x to next thickness pixel, to see if it exists 
	move $s1,$a0
	move $a1,$s2			#move y back to point initial black pixel 
	jal get_pixel
	bne $v0, $t9,FPAchecker1a	#if there's no extra black pixel to the right of initial black pixel, continue checking
	beq $v0, $t9,FPAchecker2	#if there's extra pixel to the right of initial black pixel, continue checking
	
	FPAchecker1a:			#check vertically if there's any black pixel giving unequal thickness 	
	addi $a1,$a1,1			#move y one point above initial black pixel 
	subi $s3,$s3, 1 		#decremant one from upwards counter
	li $s0,0			#counter for sub marker
	FPA1WV:
	move $a0,$s1	
	jal get_pixel
	beq $s0,$s3,FPAchecker1b	#no unequal vertical thickness, move on to next validation
	beq $v0,$t9,nextPixel		#unequal thickness, invalid marker
	addi $a1,$a1,1			
	addi $s0,$s0,1
	j FPA1WV
	
	FPAchecker1b:			#chechking horizontally
	li   $s0,0			#reset counter for sub marker 
	subi $s4,$s4,1			#decrement 1 from horizontal counter
	addu $a1,$s4,$s2		#move y upwards
	FPA1WH:
	move	$a0, $s1		#save $a0 from unwanted alterations
	jal     get_pixel
	beq     $v0,$t9,nextPixel	#if we find a black pixel along the horizontal line, then the marker has unequal thickness and is invalid
	beq	$s0,$s4,validMarker	#if we reach the end of the line, with no black pixels, then the marker is valid
	addi	$s1,$s1,1		#x = x + 1
	addi	$s0,$s0,1		#increment counter for sub marker 	
	j FPA1WH		
	
	FPAchecker2:			#check if there's a black pixel beneath
	move $a0,$s1
	subi $a1,$a1,1			#go one step beneath 
	jal get_pixel
	move $a0,$s1
	beq  $v0,$t9,nextPixel 		#if it's black, then move to the next pixel, marker invalid
	bne  $v0,$t9,FPAchecker3a 	#if it's not black, keep checking for validation
	
	FPAchecker3a:  			 #checking vertically
	subi $s3,$s3,1			 #decremant one from upwards counter
	addi $a1,$a1,1 			 #move back to the black pixel found in step 1 validator
	li   $s0,0			 #counter for sub marker
	FPA3WV:
	move $a0,$s1
	jal get_pixel
	beq $s0,$s3,FPAchecker3b	#if its equal to the counter then there's equal vertical thickness, continue to next validation
	bne $v0,$t9,nextPixel	 	#if its not equal to a black pixel,then there's unequal vertical thickness. then marker invalid.
	addi $a1,$a1,1			#move one row upwards
	addi $s0,$s0,1			#increment counter for sub marker 
	j FPA3WV
	
	FPAchecker3b:		        #chechking horizontally
	li   $s0,0			#reset submarker 
	subi $s4,$s4,1			#decrement 1 from horizontal counter
	addu $a1,$s4,$s2		#move y upwards ... sus line
	FPA3WH:
	move	$a0, $s1		#save a0 from unwanted alterations
	jal     get_pixel
	beq	$s0,$s4,validator	#check if marker is thicker 
	bne     $v0,$t9, nextPixel	#keep moving to the right until a non black pixel is met, and if one found then marker invalid. 
	addi	$s1, $s1, 1		#x = x + 1
	addi	$s0, $s0, 1		#increment counter for sub marker 	
	j FPA3WH	
		
	checkSquare:
	move $a0,$s1
	subiu $a1,$a1,1
	jal get_pixel
	beq $v0,$t9,nextPixel
	bne $v0,$t9,validMarker
	
	b exit
exit:
	li $v0, 10
	syscall
#----------------------------End of The Main Program-------------------------------




#---------------------------------Error Messages-------------------------------------

invalidFileErr:
	li $v0, 4
	la $a0, wrongFile
	syscall
	b exit

notBMPErr:
	li $v0, 4
	la $a0, notBMP
	syscall
	b exit
wrongSizeErr:
	li $v0, 4
	la $a0, wrongSize
	syscall
	b exit
not24bitsErr:
	li $v0, 4
	la $a0, not24bits
	syscall
	b exit
	
#---------------------------------End Error Messages----------------------------------

#-------------------------------------Functions---------------------------------------

moveUpwards:
addi $a1,$a1,1  			#increase y coordiante by 1 
li   $s1,0				#reset x coordiante to 0
j findBlackPixel

read_bmp:
	sub $sp, $sp, 4			#push $ra to the stack
	sw  $ra, ($sp)
	sub $sp, $sp, 4			#push $s1
	sw  $s1, ($sp)
#open file
	li $v0, 13
	la $a0, fname			#file name
	li $a1, 0			#flags: 0-read file
	li $a2, 0			#mode: ignored
	syscall
	move $s1, $v0			#save the file descriptor
	bltz $v0, invalidFileErr	# if $v0 is less than zero, there is a file error. Wrong descriptor or inaccessable file 
	

#read file
	li $v0, 14
	move $a0, $s1			#move the file descriptor to $a0
	la $a1, image
	li  $a2, 230400
	syscall
	
	#check if BMP	
	li $t0, 0x4D42					#BMP file format code	
	lhu $t1, image					#check first 2 bytes, this is where the BMP file format code is saved.
	bne $t0,$t1, notBMPErr				#if the first 2 bytes are not 4D42, invalid file.
	
	# check if size = 320x240
	lw	$t0, width				# load width
	lw 	$t1, image + 18				# read two bytes from offset of 18, this is where the width information is saved in the file header
	bne	$t0, $t1, wrongSizeErr			# if not equal, display wrong size error
	lw	$t0, height				# load height
	lw	$t1, image + 22				# read two bytes from offset of 22, this is where the height information is saved in the file header
	bne	$t0, $t1, wrongSizeErr			# if not equal, display wrong size error
	
	# check if bmp is 24bits aka each color channel is 8 bits 
	li	$t0, 24					# we are dealing with 24-bit bitmap only
	lb	$t1, image + 28				# Read one byte from offset of 28, this is where the number of bits per pixel in the bmp is saved		
	bne	$t0, $t1, not24bitsErr			# if not equal, then the BMP file is not 24 bits per pixel

	
#close file 
	li $v0, 16 
	move $a0, $s1
	syscall
	
	lw $s1, ($sp)		#restore (pop) $s1
	add $sp, $sp, 4
	lw $ra, ($sp)
	add $sp, $sp, 4
	jr $ra 
	
# ============================================================================

get_pixel:
#description: returns color of specified pixel
#arguments:
#	$a0 - x coordinate
#	$a1 - y coordinate - (0,0) - bottom left corner
#return value: $v0 - 0RGB - pixel color

	sub $sp, $sp, 4 	#push $ra to the stack
	sw $ra, ($sp)
	
	la $t1, image + 10	#addres of file offset to pixel array
	lw $t2, ($t1)		#file offset to pixel array in $t2
	la $t1, image		#address of bitmap
	add $t2, $t1, $t2	#address of pixel array in $t2
	
	#pixel address calculation
	mul $t1, $a1, BYTES_PER_ROW #t1= y*BYTES_PER_ROW
	move $t3, $a0
	sll $a0,$a0, 1		#not sure but If the bits represent an unsigned integer, then a left shift is equivalent to multiplying the integer by two.
	add $t3, $t3, $a0	#$t3 = 3*x
	add $t1, $t1, $t3	#$t1 = 3x + y*BYTES_PER_ROW
	add $t2, $t2, $t1	#pixel address is now saved in $t2
	
	#get color
	lbu $v0, ($t2)		#load B
	lbu $t1,1,($t2)		#load G
	sll $t1,$t1,8
	or $v0, $v0, $t1
	lbu $t1,2($t2)		#load R
	sll $t1,$t1,16
	or $v0, $v0, $t1
	
	lw $ra, ($sp)		#restore (pop) #ra
	add $sp, $sp, 4
	jr $ra
	
# ============================================================================	

validMarker:
	#addi $s7, $s7, 1		#add one to the marker counter
	#li $v0, 1
	#move $a0, $s7
	#syscall
	li $v0, 4
	la $a0, pFoundX
	syscall
	li $v0, 1
	move $a0,$s5
	syscall
	li $v0, 4
	la $a0, pFoundY
	syscall
	li $v0, 1
	move $a0,$s6
	syscall
	li $v0, 4
	la $a0, newLine
	syscall
	
	nextPixel:
	addi $a0, $s5 ,1		#save x to continue finding more markers
	move $a1, $s2			#save y to continue finding more markers
	addu $t8, $a0,$a1		#checking for last pixel
	bge   $t8,558,exit 		#if we're at the last pixel, exit 
	j mainLoop

#-------------------------------------End Of Functions---------------------------------------
