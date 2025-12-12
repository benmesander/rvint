# Macros to perform optimal shift-and-add based multiplication by constants
#
# macros are designed so dest and src can be same register, or
# dest and scratch can be same register

.macro mul3 dest src scratch0
.if HAS_ZBA
	sh1add	\dest, \src, \src
.else	
	slli	\scratch0, \src, 1
	add	\dest, \scratch0, \src
.endif
.endm

.macro mul5 dest src scratch0
.if HAS_ZBA	
	sh2add	\dest, \src, \src
.else
	slli	\scratch0, \src, 2
	add	\dest, \scratch0, \src
.endif
.endm	

.macro mul6 dest src scratch0
.if HAS_ZBA
	sh1add	\dest, \src, \src	# dest = 3*src
	slli	\dest, \dest, 1		# dest = 6*src
.else
	# Fixed for dest == scratch case
	slli	\dest, \src, 1		# dest = 2*src
	add	\dest, \dest, \src	# dest = 3*src
	slli	\dest, \dest, 1		# dest = 6*src
.endif
.endm
.macro mul9 dest src scratch0
.if HAS_ZBA	
	sh3add	\dest, \src, \src
.else
	slli	\scratch0, \src, 3
	add	\dest, \scratch0, \src
.endif
.endm

.macro mul10 dest src scratch0
.if HAS_ZBA
	sh2add	\dest, \src, \src	# dest = 5*src
	slli	\dest, \dest, 1		# dest = 10*src
.else
	slli	\dest, \src, 2		# dest = 4*src
	add	\dest, \dest, \src	# dest = 5*src
	slli	\dest, \dest, 1		# dest = 10*src
.endif
.endm

.macro mul11 dest src scratch0
.if HAS_ZBA
	sh3add	\dest, \src, \src
	sh1add	\dest, \src, \dest
.else
	slli	\scratch0, \src, 2
	add	\scratch0, \scratch0, \src
	slli	\scratch0, \scratch0, 1
	add	\dest, \scratch0, \src
.endif
.endm
	
.macro mul12 dest src scratch0
.if HAS_ZBA
	sh1add	\dest, \src, \src
	slli	\dest, \dest, 2
.else
	slli	\scratch0, \src, 1
	add	\scratch0, \scratch0, \src
	slli	\dest, \scratch0, 2
.endif
.endm

.macro mul13 dest src scratch0
.if HAS_ZBA
	sh3add	\dest, \src, \src
	sh2add	\dest, \src, \dest
.else
	slli	\scratch0, \src, 1
	add	\scratch0, \scratch0, \src
	slli	\scratch0, \scratch0, 2
	add	\dest, \scratch0, \src
.endif
.endm

.macro mul100 dest src scratch0
.if HAS_ZBA
	sh1add	\scratch0, \src, \src
	sh3add	\dest, \scratch0, \src
	slli	\dest, \dest, 2
.else
	slli	\scratch0, \src, 1
	add	\scratch0, \scratch0, \src
	slli	\scratch0, \scratch0, 3
	add	\dest, \scratch0, \src
	slli	\dest, \dest, 2
.endif
.endm

.macro mul1000 dest src scratch0
.if HAS_ZBA
	sh2add	\scratch0, \src, \src		# *5
	sh2add	\scratch0, \scratch0, \scratch0	# *25
	sh2add	\dest, \scratch0, \scratch0	# *125
	slli	\dest, \dest, 3			# *1000
.else
	slli	\scratch0, \src, 1		# *2
	add	\scratch0, \scratch0, \src	# *3
	slli	\scratch0, \scratch0, 3		# *24
	slli	\dest, \src, 10			# *1024
	sub	\dest, \dest, \scratch0		# *1024 - *24 = *1000
.endif
.endm
