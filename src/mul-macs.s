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
	sh1add	\dest, \src, \src
	slli	\dest, \dest, 1
.else
	slli	\scratch0, \src, 2
	slli	\dest, \src, 1
	add	\dest, \dest, \scratch0

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
	sh2add	\dest, \src, \src
	slli	\dest, \dest, 1
.else
	slli	\scratch0, \src, 3
	slli	\dest, \src, 1
	add	\dest, \dest, \scratch0
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
