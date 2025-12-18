.include "config.s"
.data
.align	8
divtab:	
.equ 	offset_testnum, 0
.equ	offset_label, 	8
.equ	offset_len,	16
.equ	offset_dividend,24
.equ	offset_quotient,32
.equ	offset_ptr, 	40
.equ	offset_flags,	48
.equ	struct_len, 	56

######################################################################
# div3u tests

.dword	300		# testnum
.dword	div3u_label	# pointer to nul-terminated ascii string
.dword	6		# len of label
.dword	0		# dividend
.dword	0		# quotient
.dword	div3u		# pointer to routine
.dword	1		# flags, 0 = end of list	

.dword	301
.dword	div3u_label
.dword	6
.dword	1
.dword	0
.dword	div3u
.dword	1

.dword	302
.dword	div3u_label
.dword	6
.dword	2
.dword	0
.dword	div3u
.dword	1
	
.dword	303
.dword	div3u_label
.dword	6
.dword	3
.dword	1
.dword	div3u
.dword	1

.dword	304
.dword	div3u_label
.dword	6
.dword	0x7fffffff
.dword	0x2aaaaaaa
.dword	div3u
.dword	1

.dword	305
.dword	div3u_label
.dword	6
.dword	0x80000000
.dword	0x2aaaaaaa
.dword	div3u
.dword	1
	
.dword	306
.dword	div3u_label
.dword	6
.dword	0xffffffff
.dword	0x55555555
.dword	div3u
.dword	1

.if CPU_BITS == 64

.dword	307
.dword	div3u_label
.dword	6
.dword	0x100000000
.dword	0x55555555
.dword	div3u
.dword	1

.dword	308
.dword	div3u_label
.dword	6
.dword	0x7fffffffffffffff
.dword	0x2aaaaaaaaaaaaaaa
.dword	div3u
.dword	1

.dword	309
.dword	div3u_label
.dword	6
.dword	0x8000000000000000
.dword	0x2aaaaaaaaaaaaaaa
.dword	div3u
.dword	1

.dword	310
.dword	div3u_label
.dword	6
.dword	-1
.dword	0x5555555555555555
.dword	div3u
.dword	1

.endif	

######################################################################
# div5u tests

.dword	500
.dword	div5u_label
.dword	6
.dword	0
.dword	0
.dword	div5u
.dword	1

.dword	501
.dword	div5u_label
.dword	6
.dword	1
.dword	0
.dword	div5u
.dword	1

.dword	502
.dword	div5u_label
.dword	6
.dword	4
.dword	0
.dword	div5u
.dword	1

.dword	503
.dword	div5u_label
.dword	6
.dword	5
.dword	1
.dword	div5u
.dword	1

.dword	504
.dword	div5u_label
.dword	6
.dword	9
.dword	1
.dword	div5u
.dword	1

.dword	505
.dword	div5u_label
.dword	6
.dword	10
.dword	2
.dword	div5u
.dword	1

.dword	506
.dword	div5u_label
.dword	6
.dword	123
.dword	24
.dword	div5u
.dword	1

.dword	507
.dword	div5u_label
.dword	6
.dword	0x7fffffff
.dword	0x19999999
.dword	div5u
.dword	1

.dword	508
.dword	div5u_label
.dword	6
.dword	0x80000000
.dword	0x19999999
.dword	div5u
.dword	1

.dword	509
.dword	div5u_label
.dword	6
.dword	0xffffffff
.dword	0x33333333
.dword	div5u
.dword	1

.if CPU_BITS == 64

.dword	510
.dword	div5u_label
.dword	6
.dword	0x100000000
.dword	0x33333333
.dword	div5u
.dword	1

.dword	511
.dword	div5u_label
.dword	6
.dword	0x7fffffffffffffff
.dword	0x1999999999999999
.dword	div5u
.dword	1

.dword	512
.dword	div5u_label
.dword	6
.dword	0x8000000000000000
.dword	0x1999999999999999
.dword	div5u
.dword	1

.dword	513
.dword	div5u_label
.dword	6
.dword	-1
.dword	0x3333333333333333
.dword	div5u
.dword	1

.endif

######################################################################
# div6u tests

.dword	600
.dword	div6u_label
.dword	6
.dword	0
.dword	0
.dword	div6u
.dword	1

.dword	601
.dword	div6u_label
.dword	6
.dword	5
.dword	0
.dword	div6u
.dword	1

.dword	602
.dword	div6u_label
.dword	6
.dword	6
.dword	1
.dword	div6u
.dword	1

.dword	603
.dword	div6u_label
.dword	6
.dword	11
.dword	1
.dword	div6u
.dword	1

.dword	604
.dword	div6u_label
.dword	6
.dword	123
.dword	20
.dword	div6u
.dword	1

.dword	605
.dword	div6u_label
.dword	6
.dword	0x7fffffff
.dword	0x15555555
.dword	div6u
.dword	1

.dword	606
.dword	div6u_label
.dword	6
.dword	0x80000000
.dword	0x15555555
.dword	div6u
.dword	1

.dword	607
.dword	div6u_label
.dword	6
.dword	0xffffffff
.dword	0x2aaaaaaa
.dword	div6u
.dword	1

.if CPU_BITS == 64

.dword	608
.dword	div6u_label
.dword	6
.dword	0x100000000
.dword	0x2aaaaaaa
.dword	div6u
.dword	1

.dword	609
.dword	div6u_label
.dword	6
.dword	0x7fffffffffffffff
.dword	0x1555555555555555
.dword	div6u
.dword	1

.dword	610
.dword	div6u_label
.dword	6
.dword	0x8000000000000000
.dword	0x1555555555555555
.dword	div6u
.dword	1

.dword	611
.dword	div6u_label
.dword	6
.dword	-1
.dword	0x2aaaaaaaaaaaaaaa
.dword	div6u
.dword	1
	
.endif

######################################################################
# div7u tests

.dword	700
.dword	div7u_label
.dword	6
.dword	0
.dword	0
.dword	div7u
.dword	1

.dword	701
.dword	div7u_label
.dword	6
.dword	7
.dword	1
.dword	div7u
.dword	1

.dword	702
.dword	div7u_label
.dword	6
.dword	13
.dword	1
.dword	div7u
.dword	1

.dword	703
.dword	div7u_label
.dword	6
.dword	49
.dword	7
.dword	div7u
.dword	1

.dword	704
.dword	div7u_label
.dword	6
.dword	2147483647
.dword	306783378
.dword	div7u
.dword	1

.dword	705
.dword	div7u_label
.dword	6
.dword	2863311530
.dword	409044504
.dword	div7u
.dword	1

.dword	706
.dword	div7u_label
.dword	6
.dword	4294967289
.dword	613566755
.dword	div7u
.dword	1

.dword	707
.dword	div7u_label
.dword	6
.dword	4294967295
.dword	613566756
.dword	div7u
.dword	1

.if CPU_BITS == 64

.dword	708
.dword	div7u_label
.dword	6
.dword	4294967296
.dword	613566756
.dword	div7u
.dword	1

.dword	709
.dword	div7u_label
.dword	6
.dword	0x7FFFFFFFFFFFFFFF
.dword	1317624576693539401
.dword	div7u
.dword	1

.dword	710
.dword	div7u_label
.dword	6
.dword	0xAAAAAAAAAAAAAAAA
.dword	1756832768924719201
.dword	div7u
.dword	1

.dword	711
.dword	div7u_label
.dword	6
.dword	0x5555555555555555
.dword	878416384462359600
.dword	div7u
.dword	1

.dword	712
.dword	div7u_label
.dword	6
.dword	0xFFFFFFFFFFFFFFF8
.dword	2635249153387078801
.dword	div7u
.dword	1

.dword	713
.dword	div7u_label
.dword	6
.dword	0xFFFFFFFFFFFFFFF9
.dword	2635249153387078801
.dword	div7u
.dword	1

.dword	714
.dword	div7u_label
.dword	6
.dword	0xFFFFFFFFFFFFFFFF
.dword	2635249153387078802
.dword	div7u
.dword	1

.endif

######################################################################
# div9u tests

.dword	900
.dword	div9u_label
.dword	6
.dword	0
.dword	0
.dword	div9u
.dword	1

.dword	901
.dword	div9u_label
.dword	6
.dword	9
.dword	1
.dword	div9u
.dword	1

.dword	902
.dword	div9u_label
.dword	6
.dword	17
.dword	1
.dword	div9u
.dword	1

.dword	903
.dword	div9u_label
.dword	6
.dword	81
.dword	9
.dword	div9u
.dword	1

.dword	904
.dword	div9u_label
.dword	6
.dword	0x7FFFFFFF
.dword	238609294
.dword	div9u
.dword	1

.dword	905
.dword	div9u_label
.dword	6
.dword	0xAAAAAAAA
.dword	318145725
.dword	div9u
.dword	1

.dword	906
.dword	div9u_label
.dword	6
.dword	0xFFFFFFFB
.dword	477218587
.dword	div9u
.dword	1

.dword	907
.dword	div9u_label
.dword	6
.dword	0xFFFFFFFC
.dword	477218588
.dword	div9u
.dword	1

.dword	908
.dword	div9u_label
.dword	6
.dword	0xFFFFFFFF
.dword	477218588
.dword	div9u
.dword	1

.if CPU_BITS == 64

.dword	910
.dword	div9u_label
.dword	6
.dword	0x0000000100000000
.dword	477218588
.dword	div9u
.dword	1

.dword	911
.dword	div9u_label
.dword	6
.dword	0x7FFFFFFFFFFFFFFF
.dword	1024819115206086200
.dword	div9u
.dword	1

.dword	912
.dword	div9u_label
.dword	6
.dword	0xAAAAAAAAAAAAAAAA
.dword	1366425486941448267
.dword	div9u
.dword	1

.dword	913
.dword	div9u_label
.dword	6
.dword	0xFFFFFFFFFFFFFFF6
.dword	2049638230412172400
.dword	div9u
.dword	1

.dword	913
.dword	div9u_label
.dword	6
.dword	0xFFFFFFFFFFFFFFF8
.dword	2049638230412172400
.dword	div9u
.dword	1

.dword	914
.dword	div9u_label
.dword	6
.dword	0xFFFFFFFFFFFFFFFF
.dword	2049638230412172401
.dword	div9u
.dword	1

.endif

######################################################################
# div10u tests

.dword	1000
.dword	div10u_label
.dword	7
.dword	0
.dword	0
.dword	div10u
.dword	1

.dword	1001
.dword	div10u_label
.dword	7
.dword	9
.dword	0
.dword	div10u
.dword	1

.dword	1002
.dword	div10u_label
.dword	7
.dword	10
.dword	1
.dword	div10u
.dword	1

.dword	1003
.dword	div10u_label
.dword	7
.dword	19
.dword	1
.dword	div10u
.dword	1

.dword	1004
.dword	div10u_label
.dword	7
.dword	123
.dword	12
.dword	div10u
.dword	1

.dword	1005
.dword	div10u_label
.dword	7
.dword	0x7fffffff
.dword	214748364
.dword	div10u
.dword	1

.dword	1006
.dword	div10u_label
.dword	7
.dword	0x80000000
.dword	214748364
.dword	div10u
.dword	1

.dword	1007
.dword	div10u_label
.dword	7
.dword	0xffffffff
.dword	429496729
.dword	div10u
.dword	1

.if CPU_BITS == 64

.dword	1008
.dword	div10u_label
.dword	7
.dword	0x100000000
.dword	0x19999999
.dword	div10u
.dword	1

.dword	1009
.dword	div10u_label
.dword	7
.dword	0x7fffffffffffffff
.dword	0x0ccccccccccccccc
.dword	div10u
.dword	1

.dword	1010
.dword	div10u_label
.dword	7
.dword	-1
.dword	0x1999999999999999
.dword	div10u
.dword	1

.endif

######################################################################
# div11u tests

# Test 0: 0 / 11 = 0
.dword	1100
.dword	div11u_label
.dword	7
.dword	0
.dword	0
.dword	div11u
.dword	1

# Test 11: 11 / 11 = 1
.dword	1101
.dword	div11u_label
.dword	7
.dword	11
.dword	1
.dword	div11u
.dword	1

# Test 21: 21 / 11 = 1 (Max Remainder 10 case)
.dword	1102
.dword	div11u_label
.dword	7
.dword	21
.dword	1
.dword	div11u
.dword	1

# Test 121: 121 / 11 = 11 (Square)
.dword	1103
.dword	div11u_label
.dword	7
.dword	121
.dword	11
.dword	div11u
.dword	1

# Test Max Signed 32-bit: 0x7FFFFFFF / 11
.dword	1104
.dword	div11u_label
.dword	7
.dword	0x7fffffff
.dword	195225786
.dword	div11u
.dword	1

# Test Alternating Bits: 0xAAAAAAAA / 11
.dword	1105
.dword	div11u_label
.dword	7
.dword	0xaaaaaaaa
.dword	260301048
.dword	div11u
.dword	1

# Test UINT32_MAX - 11 (Exact boundary)
.dword	1106
.dword	div11u_label
.dword	7
.dword	0xfffffff4
.dword	390451571
.dword	div11u
.dword	1

# Test UINT32_MAX - 4 (Max Remainder 10 case)
.dword	1107
.dword	div11u_label
.dword	7
.dword	0xfffffffb
.dword	390451571
.dword	div11u
.dword	1

# Test UINT32_MAX
.dword	1108
.dword	div11u_label
.dword	7
.dword	0xffffffff
.dword	390451572
.dword	div11u
.dword	1

.if CPU_BITS == 64

# Test 2^32 / 11
.dword	1109
.dword	div11u_label
.dword	7
.dword	0x100000000
.dword	390451572
.dword	div11u
.dword	1

# Test Max Signed 64-bit
.dword	1110
.dword	div11u_label
.dword	7
.dword	0x7fffffffffffffff
.dword	838488366986797800
.dword	div11u
.dword	1

# Test Alternating Bits 64-bit
.dword	1111
.dword	div11u_label
.dword	7
.dword	0xaaaaaaaaaaaaaaaa
.dword	1117984489315730400
.dword	div11u
.dword	1

# Test UINT64_MAX - 11 (Exact boundary)
.dword	1112
.dword	div11u_label
.dword	7
.dword	0xfffffffffffffff4
.dword	1676976733973595600
.dword	div11u
.dword	1

# Test UINT64_MAX - 5 (Max Remainder 10 case)
.dword	1113
.dword	div11u_label
.dword	7
.dword	0xfffffffffffffffa
.dword	1676976733973595600
.dword	div11u
.dword	1

# Test UINT64_MAX
.dword	1114
.dword	div11u_label
.dword	7
.dword	-1			# 0xffffffffffffffff
.dword	1676976733973595601
.dword	div11u
.dword	1

.endif


######################################################################
# div12u tests

# --- div12u Tests ---

# Test 0: 0 / 12 = 0
.dword	1200
.dword	div12u_label
.dword	7
.dword	0
.dword	0
.dword	div12u
.dword	1

# Test 12: 12 / 12 = 1
.dword	1201
.dword	div12u_label
.dword	7
.dword	12
.dword	1
.dword	div12u
.dword	1

# Test 23: 23 / 12 = 1 (Max Remainder 11 case)
.dword	1202
.dword	div12u_label
.dword	7
.dword	23
.dword	1
.dword	div12u
.dword	1

# Test 144: 144 / 12 = 12 (Square)
.dword	1203
.dword	div12u_label
.dword	7
.dword	144
.dword	12
.dword	div12u
.dword	1

# Test Max Signed 32-bit: 0x7FFFFFFF / 12
.dword	1204
.dword	div12u_label
.dword	7
.dword	0x7fffffff
.dword	178956970
.dword	div12u
.dword	1

# Test Alternating Bits: 0xAAAAAAAA / 12
.dword	1205
.dword	div12u_label
.dword	7
.dword	0xaaaaaaaa
.dword	238609294
.dword	div12u
.dword	1

# Test UINT32_MAX - 12 (Exact boundary)
# UINT32_MAX % 12 == 3. So UINT32_MAX - 3 is exact.
.dword	1206
.dword	div12u_label
.dword	7
.dword	0xfffffffc
.dword	357913941
.dword	div12u
.dword	1

# Test UINT32_MAX - 4 (Max Remainder 11 case)
# UINT32_MAX is Rem 3. 3 - 4 = -1 = 11 (mod 12).
.dword	1207
.dword	div12u_label
.dword	7
.dword	0xfffffffb
.dword	357913940
.dword	div12u
.dword	1

# Test UINT32_MAX
.dword	1208
.dword	div12u_label
.dword	7
.dword	0xffffffff
.dword	357913941
.dword	div12u
.dword	1

.if CPU_BITS == 64

# Test 2^32 / 12
.dword	1209
.dword	div12u_label
.dword	7
.dword	0x100000000
.dword	357913941
.dword	div12u
.dword	1

# Test Max Signed 64-bit
.dword	1210
.dword	div12u_label
.dword	7
.dword	0x7fffffffffffffff
.dword	768614336404564650
.dword	div12u
.dword	1

# Test Alternating Bits 64-bit
.dword	1211
.dword	div12u_label
.dword	7
.dword	0xaaaaaaaaaaaaaaaa
.dword	1024819115206086200
.dword	div12u
.dword	1

# Test UINT64_MAX - 12 (Exact boundary)
# UINT64_MAX % 12 == 3. So UINT64_MAX - 3 is exact.
.dword	1212
.dword	div12u_label
.dword	7
.dword	0xfffffffffffffffc
.dword	1537228672809129301
.dword	div12u
.dword	1

# Test UINT64_MAX - 4 (Max Remainder 11 case)
# UINT64_MAX is Rem 3. 3 - 4 = -1 = 11 (mod 12).
.dword	1213
.dword	div12u_label
.dword	7
.dword	0xfffffffffffffffb
.dword	1537228672809129300
.dword	div12u
.dword	1

# Test UINT64_MAX
.dword	1214
.dword	div12u_label
.dword	7
.dword	-1			# 0xffffffffffffffff
.dword	1537228672809129301
.dword	div12u
.dword	1

.endif


######################################################################
# div13u tests

# --- div13u Tests ---

# Test 0: 0 / 13 = 0
.dword	1300
.dword	div13u_label
.dword	7
.dword	0
.dword	0
.dword	div13u
.dword	1

# Test 13: 13 / 13 = 1
.dword	1301
.dword	div13u_label
.dword	7
.dword	13
.dword	1
.dword	div13u
.dword	1

# Test 25: 25 / 13 = 1 (Max Remainder 12 case)
.dword	1302
.dword	div13u_label
.dword	7
.dword	25
.dword	1
.dword	div13u
.dword	1

# Test 169: 169 / 13 = 13 (Square)
.dword	1303
.dword	div13u_label
.dword	7
.dword	169
.dword	13
.dword	div13u
.dword	1

# Test Max Signed 32-bit: 0x7FFFFFFF / 13
.dword	1304
.dword	div13u_label
.dword	7
.dword	0x7fffffff
.dword	165191049
.dword	div13u
.dword	1

# Test Alternating Bits: 0xAAAAAAAA / 13
.dword	1305
.dword	div13u_label
.dword	7
.dword	0xaaaaaaaa
.dword	220254733
.dword	div13u
.dword	1

# Test UINT32_MAX - 13 (Exact boundary)
# UINT32_MAX % 13 == 8. So UINT32_MAX - 8 is exact.
.dword	1306
.dword	div13u_label
.dword	7
.dword	0xfffffff7	# UINT32_MAX - 8
.dword	330382099
.dword	div13u
.dword	1

# Test UINT32_MAX - 9 (Max Remainder 12 case)
# UINT32_MAX is Rem 8. 8 - 9 = -1 = 12 (mod 13).
.dword	1307
.dword	div13u_label
.dword	7
.dword	0xfffffff6
.dword	330382098
.dword	div13u
.dword	1

# Test UINT32_MAX
.dword	1308
.dword	div13u_label
.dword	7
.dword	0xffffffff
.dword	330382099
.dword	div13u
.dword	1

.if CPU_BITS == 64

# Test 2^32 / 13
.dword	1309
.dword	div13u_label
.dword	7
.dword	0x100000000
.dword	330382099
.dword	div13u
.dword	1

# Test Max Signed 64-bit
.dword	1310
.dword	div13u_label
.dword	7
.dword	0x7fffffffffffffff
.dword	709490156681136600
.dword	div13u
.dword	1

# Test Alternating Bits 64-bit
.dword	1311
.dword	div13u_label
.dword	7
.dword	0xaaaaaaaaaaaaaaaa
.dword	945986875574848800
.dword	div13u
.dword	1

# Test UINT64_MAX - 13 (Exact boundary)
# UINT64_MAX % 13 == 2. So UINT64_MAX - 2 is exact.
.dword	1312
.dword	div13u_label
.dword	7
.dword	0xfffffffffffffffd
.dword	1418980313362273201
.dword	div13u
.dword	1

# Test UINT64_MAX - 3 (Max Remainder 12 case)
# UINT64_MAX is Rem 2. 2 - 3 = -1 = 12 (mod 13).
.dword	1313
.dword	div13u_label
.dword	7
.dword	0xfffffffffffffffc
.dword	1418980313362273200
.dword	div13u
.dword	1

# Test UINT64_MAX
.dword	1314
.dword	div13u_label
.dword	7
.dword	-1			# 0xffffffffffffffff
.dword	1418980313362273201
.dword	div13u
.dword	1

.endif

######################################################################
# div100u tests

# Test 0: 0 / 100 = 0
.dword	10000
.dword	div100u_label
.dword	8
.dword	0
.dword	0
.dword	div100u
.dword	1

# Test 100: 100 / 100 = 1
.dword	10001
.dword	div100u_label
.dword	8
.dword	100
.dword	1
.dword	div100u
.dword	1

# Test 200: 200 / 100 = 2
.dword	10002
.dword	div100u_label
.dword	8
.dword	200
.dword	2
.dword	div100u
.dword	1

# Test 199: 199 / 100 = 1 (Max Remainder 99 case)
.dword	10003
.dword	div100u_label
.dword	8
.dword	199
.dword	1
.dword	div100u
.dword	1

# Test 10000: 10000 / 100 = 100 (Square)
.dword	10004
.dword	div100u_label
.dword	8
.dword	10000
.dword	100
.dword	div100u
.dword	1

# Test Max Signed 32-bit: 0x7FFFFFFF / 100
# 2147483647 / 100 = 21474836
.dword	10005
.dword	div100u_label
.dword	8
.dword	0x7fffffff
.dword	21474836
.dword	div100u
.dword	1

# Test UINT32_MAX: 0xFFFFFFFF / 100
# 4294967295 / 100 = 42949672
.dword	10006
.dword	div100u_label
.dword	8
.dword	0xffffffff
.dword	42949672
.dword	div100u
.dword	1

.if CPU_BITS == 64

# Test 2^32 / 100
# 4294967296 / 100 = 42949672
.dword	10007
.dword	div100u_label
.dword	8
.dword	0x100000000
.dword	42949672
.dword	div100u
.dword	1

# Test Max Signed 64-bit: 0x7FFFFFFFFFFFFFFF / 100
# 9223372036854775807 / 100 = 92233720368547758
.dword	10008
.dword	div100u_label
.dword	8
.dword	0x7fffffffffffffff
.dword	92233720368547758
.dword	div100u
.dword	1

# Test UINT64_MAX: -1 / 100
# 18446744073709551615 / 100 = 184467440737095516
.dword	10009
.dword	div100u_label
.dword	8
.dword	-1
.dword	184467440737095516
.dword	div100u
.dword	1

.endif

######################################################################
# div1000u tests

# Test 0: 0 / 1000 = 0
.dword	20000
.dword	div1000u_label
.dword	9
.dword	0
.dword	0
.dword	div1000u
.dword	1

# Test 1000: 1000 / 1000 = 1
.dword	20001
.dword	div1000u_label
.dword	9
.dword	1000
.dword	1
.dword	div1000u
.dword	1

# Test 2000: 2000 / 1000 = 2
.dword	20002
.dword	div1000u_label
.dword	9
.dword	2000
.dword	2
.dword	div1000u
.dword	1

# Test 1999: 1999 / 1000 = 1 (Max Remainder 999 case)
.dword	20003
.dword	div1000u_label
.dword	9
.dword	1999
.dword	1
.dword	div1000u
.dword	1

# Test 1,000,000: 1000000 / 1000 = 1000 (Square)
.dword	20004
.dword	div1000u_label
.dword	9
.dword	1000000
.dword	1000
.dword	div1000u
.dword	1

# Test Max Signed 32-bit: 0x7FFFFFFF / 1000
# 2147483647 / 1000 = 2147483
.dword	20005
.dword	div1000u_label
.dword	9
.dword	0x7fffffff
.dword	2147483
.dword	div1000u
.dword	1

# Test UINT32_MAX: 0xFFFFFFFF / 1000
# 4294967295 / 1000 = 4294967
.dword	20006
.dword	div1000u_label
.dword	9
.dword	0xffffffff
.dword	4294967
.dword	div1000u
.dword	1

.if CPU_BITS == 64

# Test 2^32 / 1000
# 4294967296 / 1000 = 4294967
.dword	20007
.dword	div1000u_label
.dword	9
.dword	0x100000000
.dword	4294967
.dword	div1000u
.dword	1

# Test Max Signed 64-bit: 0x7FFFFFFFFFFFFFFF / 1000
# 9223372036854775807 / 1000 = 9223372036854775
.dword	20008
.dword	div1000u_label
.dword	9
.dword	0x7fffffffffffffff
.dword	9223372036854775
.dword	div1000u
.dword	1

# Test UINT64_MAX: -1 / 1000
# 18446744073709551615 / 1000 = 18446744073709551
.dword	20009
.dword	div1000u_label
.dword	9
.dword	-1
.dword	18446744073709551
.dword	div1000u
.dword	1

.endif

######################################################################
# div3 tests

# Test 0: 0 / 3 = 0
.dword	3000
.dword	div3_label
.dword	5
.dword	0
.dword	0
.dword	div3
.dword	1

# Test 3: 3 / 3 = 1
.dword	3001
.dword	div3_label
.dword	5
.dword	3
.dword	1
.dword	div3
.dword	1

# Test -3: -3 / 3 = -1
.dword	3002
.dword	div3_label
.dword	5
.dword	-3
.dword	-1
.dword	div3
.dword	1

# Test 6: 6 / 3 = 2
.dword	3003
.dword	div3_label
.dword	5
.dword	6
.dword	2
.dword	div3
.dword	1

# Test -6: -6 / 3 = -2
.dword	3004
.dword	div3_label
.dword	5
.dword	-6
.dword	-2
.dword	div3
.dword	1

# Test -1: -1 / 3 = 0
.dword	3005
.dword	div3_label
.dword	5
.dword	-1
.dword	0
.dword	div3
.dword	1

# Test -2: -2 / 3 = 0
.dword	3006
.dword	div3_label
.dword	5
.dword	-2
.dword	0
.dword	div3
.dword	1

# Test Max Signed 32-bit: 0x7FFFFFFF / 3
# 2147483647 / 3 = 715827882 (0x2AAAAAAA)
.dword	3007
.dword	div3_label
.dword	5
.dword	0x7fffffff
.dword	0x2aaaaaaa
.dword	div3
.dword	1

# Test Min Signed 32-bit: -2147483648 / 3
# -2147483648 / 3 = -715827882
# Using decimal ensures correct sign extension for 64-bit .dword
.dword	3008
.dword	div3_label
.dword	5
.dword	-2147483648     # Replaces 0x80000000
.dword	-715827882      # Replaces 0xd5555556
.dword	div3
.dword	1

.if CPU_BITS == 64

# Test Max Signed 64-bit: 0x7FFFFFFFFFFFFFFF / 3
# 9223372036854775807 / 3 = 3074457345618258602
.dword	3009
.dword	div3_label
.dword	5
.dword	0x7fffffffffffffff
.dword	0x2aaaaaaaaaaaaaaa
.dword	div3
.dword	1

# Test Min Signed 64-bit: 0x8000000000000000 / 3
# Using hex here is safe because the top bit is explicitly set in 64-bit width
# -9223372036854775808 / 3 = -3074457345618258602
.dword	3010
.dword	div3_label
.dword	5
.dword	0x8000000000000000
.dword	0xd555555555555556
.dword	div3
.dword	1

.endif
######################################################################
# div5 tests

# Test 0: 0 / 5 = 0
.dword	5000
.dword	div5_label
.dword	6
.dword	0
.dword	0
.dword	div5
.dword	1

# Test 5: 5 / 5 = 1
.dword	5001
.dword	div5_label
.dword	6
.dword	5
.dword	1
.dword	div5
.dword	1

# Test -5: -5 / 5 = -1
.dword	5002
.dword	div5_label
.dword	6
.dword	-5
.dword	-1
.dword	div5
.dword	1

# Test 13: 13 / 5 = 2
.dword	5003
.dword	div5_label
.dword	6
.dword	13
.dword	2
.dword	div5
.dword	1

# Test -13: -13 / 5 = -2
.dword	5004
.dword	div5_label
.dword	6
.dword	-13
.dword	-2
.dword	div5
.dword	1

# Test Max Signed 32-bit: 2147483647 / 5
# 2147483647 / 5 = 429496729 (0x19999999)
.dword	5005
.dword	div5_label
.dword	6
.dword	2147483647
.dword	429496729
.dword	div5
.dword	1

# Test Min Signed 32-bit: -2147483648 / 5
# -2147483648 / 5 = -429496729 (0xE6666667)
.dword	5006
.dword	div5_label
.dword	6
.dword	-2147483648
.dword	-429496729
.dword	div5
.dword	1

.if CPU_BITS == 64

# Test Max Signed 64-bit
# 9223372036854775807 / 5 = 1844674407370955161
.dword	5007
.dword	div5_label
.dword	6
.dword	0x7fffffffffffffff
.dword	1844674407370955161
.dword	div5
.dword	1

# Test Min Signed 64-bit
# -9223372036854775808 / 5 = -1844674407370955161
.dword	5008
.dword	div5_label
.dword	6
.dword	0x8000000000000000
.dword	-1844674407370955161
.dword	div5
.dword	1

.endif

######################################################################
# div6 tests

# Test 0: 0 / 6 = 0
.dword	6000
.dword	div6_label
.dword	6
.dword	0
.dword	0
.dword	div6
.dword	1

# Test 6: 6 / 6 = 1
.dword	6001
.dword	div6_label
.dword	6
.dword	6
.dword	1
.dword	div6
.dword	1

# Test -6: -6 / 6 = -1
.dword	6002
.dword	div6_label
.dword	6
.dword	-6
.dword	-1
.dword	div6
.dword	1

# Test 13: 13 / 6 = 2
.dword	6003
.dword	div6_label
.dword	6
.dword	13
.dword	2
.dword	div6
.dword	1

# Test -13: -13 / 6 = -2
.dword	6004
.dword	div6_label
.dword	6
.dword	-13
.dword	-2
.dword	div6
.dword	1

# Test Max Signed 32-bit: 2147483647 / 6
# 2147483647 / 6 = 357913941
.dword	6005
.dword	div6_label
.dword	6
.dword	2147483647
.dword	357913941
.dword	div6
.dword	1

# Test Min Signed 32-bit: -2147483648 / 6
# -2147483648 / 6 = -357913941
.dword	6006
.dword	div6_label
.dword	6
.dword	-2147483648
.dword	-357913941
.dword	div6
.dword	1

.if CPU_BITS == 64

# Test Max Signed 64-bit
# 9223372036854775807 / 6 = 1537228672809129301
.dword	6007
.dword	div6_label
.dword	6
.dword	0x7fffffffffffffff
.dword	1537228672809129301
.dword	div6
.dword	1

# Test Min Signed 64-bit
# -9223372036854775808 / 6 = -1537228672809129301
.dword	6008
.dword	div6_label
.dword	6
.dword	0x8000000000000000
.dword	-1537228672809129301
.dword	div6
.dword	1

.endif

######################################################################
# div7 tests

# Test 0: 0 / 7 = 0
.dword	7000
.dword	div7_label
.dword	6
.dword	0
.dword	0
.dword	div7
.dword	1

# Test 7: 7 / 7 = 1
.dword	7001
.dword	div7_label
.dword	6
.dword	7
.dword	1
.dword	div7
.dword	1

# Test -7: -7 / 7 = -1
.dword	7002
.dword	div7_label
.dword	6
.dword	-7
.dword	-1
.dword	div7
.dword	1

# Test 15: 15 / 7 = 2
.dword	7003
.dword	div7_label
.dword	6
.dword	15
.dword	2
.dword	div7
.dword	1

# Test -15: -15 / 7 = -2
.dword	7004
.dword	div7_label
.dword	6
.dword	-15
.dword	-2
.dword	div7
.dword	1

# Test Max Signed 32-bit: 2147483647 / 7
# 2147483647 / 7 = 306783378
.dword	7005
.dword	div7_label
.dword	6
.dword	2147483647
.dword	306783378
.dword	div7
.dword	1

# Test Min Signed 32-bit: -2147483648 / 7
# -2147483648 / 7 = -306783378
.dword	7006
.dword	div7_label
.dword	6
.dword	-2147483648
.dword	-306783378
.dword	div7
.dword	1

.if CPU_BITS == 64

# Test Max Signed 64-bit
# 9223372036854775807 / 7 = 1317624576693539401
.dword	7007
.dword	div7_label
.dword	6
.dword	0x7fffffffffffffff
.dword	1317624576693539401
.dword	div7
.dword	1

# Test Min Signed 64-bit
# -9223372036854775808 / 7 = -1317624576693539401
.dword	7008
.dword	div7_label
.dword	6
.dword	0x8000000000000000
.dword	-1317624576693539401
.dword	div7
.dword	1

.endif	

######################################################################
# div9 tests

# Test 0: 0 / 9 = 0
.dword	9000
.dword	div9_label
.dword	6
.dword	0
.dword	0
.dword	div9
.dword	1

# Test 9: 9 / 9 = 1
.dword	9001
.dword	div9_label
.dword	6
.dword	9
.dword	1
.dword	div9
.dword	1

# Test -9: -9 / 9 = -1
.dword	9002
.dword	div9_label
.dword	6
.dword	-9
.dword	-1
.dword	div9
.dword	1

# Test 19: 19 / 9 = 2
.dword	9003
.dword	div9_label
.dword	6
.dword	19
.dword	2
.dword	div9
.dword	1

# Test -19: -19 / 9 = -2
.dword	9004
.dword	div9_label
.dword	6
.dword	-19
.dword	-2
.dword	div9
.dword	1

# Test Max Signed 32-bit: 2147483647 / 9
# 2147483647 / 9 = 238609294
.dword	9005
.dword	div9_label
.dword	6
.dword	2147483647
.dword	238609294
.dword	div9
.dword	1

# Test Min Signed 32-bit: -2147483648 / 9
# -2147483648 / 9 = -238609294
.dword	9006
.dword	div9_label
.dword	6
.dword	-2147483648
.dword	-238609294
.dword	div9
.dword	1

.if CPU_BITS == 64

# Test Max Signed 64-bit
# 9223372036854775807 / 9 = 1024819115206086200
.dword	9007
.dword	div9_label
.dword	6
.dword	0x7fffffffffffffff
.dword	1024819115206086200
.dword	div9
.dword	1

# Test Min Signed 64-bit
# -9223372036854775808 / 9 = -1024819115206086200
.dword	9008
.dword	div9_label
.dword	6
.dword	0x8000000000000000
.dword	-1024819115206086200
.dword	div9
.dword	1

.endif

######################################################################
# div10 tests

# Test 0: 0 / 10 = 0
.dword	10000
.dword	div10_label
.dword	7
.dword	0
.dword	0
.dword	div10
.dword	1

# Test 10: 10 / 10 = 1
.dword	10001
.dword	div10_label
.dword	7
.dword	10
.dword	1
.dword	div10
.dword	1

# Test -10: -10 / 10 = -1
.dword	10002
.dword	div10_label
.dword	7
.dword	-10
.dword	-1
.dword	div10
.dword	1

# Test 20: 20 / 10 = 2
.dword	10003
.dword	div10_label
.dword	7
.dword	20
.dword	2
.dword	div10
.dword	1

# Test -20: -20 / 10 = -2
.dword	10004
.dword	div10_label
.dword	7
.dword	-20
.dword	-2
.dword	div10
.dword	1

# Test Max Signed 32-bit: 2147483647 / 10
# 2147483647 / 10 = 214748364
.dword	10005
.dword	div10_label
.dword	7
.dword	2147483647
.dword	214748364
.dword	div10
.dword	1

# Test Min Signed 32-bit: -2147483648 / 10
# -2147483648 / 10 = -214748364
.dword	10006
.dword	div10_label
.dword	7
.dword	-2147483648
.dword	-214748364
.dword	div10
.dword	1

.if CPU_BITS == 64

# Test Max Signed 64-bit
# 9223372036854775807 / 10 = 922337203685477580
.dword	10007
.dword	div10_label
.dword	7
.dword	0x7fffffffffffffff
.dword	922337203685477580
.dword	div10
.dword	1

# Test Min Signed 64-bit
# -9223372036854775808 / 10 = -922337203685477580
.dword	10008
.dword	div10_label
.dword	7
.dword	0x8000000000000000
.dword	-922337203685477580
.dword	div10
.dword	1

.endif

######################################################################
# div11 tests

# Test 0: 0 / 11 = 0
.dword	11000
.dword	div11_label
.dword	7
.dword	0
.dword	0
.dword	div11
.dword	1

# Test 11: 11 / 11 = 1
.dword	11001
.dword	div11_label
.dword	7
.dword	11
.dword	1
.dword	div11
.dword	1

# Test -11: -11 / 11 = -1
.dword	11002
.dword	div11_label
.dword	7
.dword	-11
.dword	-1
.dword	div11
.dword	1

# Test 22: 22 / 11 = 2
.dword	11003
.dword	div11_label
.dword	7
.dword	22
.dword	2
.dword	div11
.dword	1

# Test -22: -22 / 11 = -2
.dword	11004
.dword	div11_label
.dword	7
.dword	-22
.dword	-2
.dword	div11
.dword	1

# Test Max Signed 32-bit: 2147483647 / 11
# 2147483647 / 11 = 195225786
.dword	11005
.dword	div11_label
.dword	7
.dword	2147483647
.dword	195225786
.dword	div11
.dword	1

# Test Min Signed 32-bit: -2147483648 / 11
# -2147483648 / 11 = -195225786
.dword	11006
.dword	div11_label
.dword	7
.dword	-2147483648
.dword	-195225786
.dword	div11
.dword	1

.if CPU_BITS == 64

# Test Max Signed 64-bit
# 9223372036854775807 / 11 = 838488366986797800
.dword	11007
.dword	div11_label
.dword	7
.dword	0x7fffffffffffffff
.dword	838488366986797800
.dword	div11
.dword	1

# Test Min Signed 64-bit
# -9223372036854775808 / 11 = -838488366986797800
.dword	11008
.dword	div11_label
.dword	7
.dword	0x8000000000000000
.dword	-838488366986797800
.dword	div11
.dword	1

.endif

######################################################################
# div12 tests

# Test 0: 0 / 12 = 0
.dword	12000
.dword	div12_label
.dword	7
.dword	0
.dword	0
.dword	div12
.dword	1

# Test 12: 12 / 12 = 1
.dword	12001
.dword	div12_label
.dword	7
.dword	12
.dword	1
.dword	div12
.dword	1

# Test -12: -12 / 12 = -1
.dword	12002
.dword	div12_label
.dword	7
.dword	-12
.dword	-1
.dword	div12
.dword	1

# Test 24: 24 / 12 = 2
.dword	12003
.dword	div12_label
.dword	7
.dword	24
.dword	2
.dword	div12
.dword	1

# Test -24: -24 / 12 = -2
.dword	12004
.dword	div12_label
.dword	7
.dword	-24
.dword	-2
.dword	div12
.dword	1

# Test Max Signed 32-bit: 2147483647 / 12
# 2147483647 / 12 = 178956970
.dword	12005
.dword	div12_label
.dword	7
.dword	2147483647
.dword	178956970
.dword	div12
.dword	1

# Test Min Signed 32-bit: -2147483648 / 12
# -2147483648 / 12 = -178956970
.dword	12006
.dword	div12_label
.dword	7
.dword	-2147483648
.dword	-178956970
.dword	div12
.dword	1

.if CPU_BITS == 64

# Test Max Signed 64-bit
# 9223372036854775807 / 12 = 768614336404564650
.dword	12007
.dword	div12_label
.dword	7
.dword	0x7fffffffffffffff
.dword	768614336404564650
.dword	div12
.dword	1

# Test Min Signed 64-bit
# -9223372036854775808 / 12 = -768614336404564650
.dword	12008
.dword	div12_label
.dword	7
.dword	0x8000000000000000
.dword	-768614336404564650
.dword	div12
.dword	1

.endif

######################################################################
# div13 tests

# Test 0: 0 / 13 = 0
.dword	13000
.dword	div13_label
.dword	7
.dword	0
.dword	0
.dword	div13
.dword	1

# Test 13: 13 / 13 = 1
.dword	13001
.dword	div13_label
.dword	7
.dword	13
.dword	1
.dword	div13
.dword	1

# Test -13: -13 / 13 = -1
.dword	13002
.dword	div13_label
.dword	7
.dword	-13
.dword	-1
.dword	div13
.dword	1

# Test 26: 26 / 13 = 2
.dword	13003
.dword	div13_label
.dword	7
.dword	26
.dword	2
.dword	div13
.dword	1

# Test -26: -26 / 13 = -2
.dword	13004
.dword	div13_label
.dword	7
.dword	-26
.dword	-2
.dword	div13
.dword	1

# Test Max Signed 32-bit: 2147483647 / 13
# 2147483647 / 13 = 165191049
.dword	13005
.dword	div13_label
.dword	7
.dword	2147483647
.dword	165191049
.dword	div13
.dword	1

# Test Min Signed 32-bit: -2147483648 / 13
# -2147483648 / 13 = -165191049
.dword	13006
.dword	div13_label
.dword	7
.dword	-2147483648
.dword	-165191049
.dword	div13
.dword	1

.if CPU_BITS == 64

# Test Max Signed 64-bit
# 9223372036854775807 / 13 = 709490156681136600
.dword	13007
.dword	div13_label
.dword	7
.dword	0x7fffffffffffffff
.dword	709490156681136600
.dword	div13
.dword	1

# Test Min Signed 64-bit
# -9223372036854775808 / 13 = -709490156681136600
.dword	13008
.dword	div13_label
.dword	7
.dword	0x8000000000000000
.dword	-709490156681136600
.dword	div13
.dword	1

.endif

######################################################################
# div100 tests

# Test 0: 0 / 100 = 0
.dword	100000
.dword	div100_label
.dword	8
.dword	0
.dword	0
.dword	div100
.dword	1

# Test 100: 100 / 100 = 1
.dword	100001
.dword	div100_label
.dword	8
.dword	100
.dword	1
.dword	div100
.dword	1

# Test -100: -100 / 100 = -1
.dword	100002
.dword	div100_label
.dword	8
.dword	-100
.dword	-1
.dword	div100
.dword	1

# Test 200: 200 / 100 = 2
.dword	100003
.dword	div100_label
.dword	8
.dword	200
.dword	2
.dword	div100
.dword	1

# Test -200: -200 / 100 = -2
.dword	100004
.dword	div100_label
.dword	8
.dword	-200
.dword	-2
.dword	div100
.dword	1

# Test Max Signed 32-bit: 2147483647 / 100
# 2147483647 / 100 = 21474836
.dword	100005
.dword	div100_label
.dword	8
.dword	2147483647
.dword	21474836
.dword	div100
.dword	1

# Test Min Signed 32-bit: -2147483648 / 100
# -2147483648 / 100 = -21474836
.dword	100006
.dword	div100_label
.dword	8
.dword	-2147483648
.dword	-21474836
.dword	div100
.dword	1

.if CPU_BITS == 64

# Test Max Signed 64-bit
# 9223372036854775807 / 100 = 92233720368547758
.dword	100007
.dword	div100_label
.dword	8
.dword	0x7fffffffffffffff
.dword	92233720368547758
.dword	div100
.dword	1

# Test Min Signed 64-bit
# -9223372036854775808 / 100 = -92233720368547758
.dword	100008
.dword	div100_label
.dword	8
.dword	0x8000000000000000
.dword	-92233720368547758
.dword	div100
.dword	1

.endif

######################################################################
# div1000 tests

# Test 0: 0 / 1000 = 0
.dword	1000000
.dword	div1000_label
.dword	8
.dword	0
.dword	0
.dword	div1000
.dword	1

# Test 1000: 1000 / 1000 = 1
.dword	1000001
.dword	div1000_label
.dword	8
.dword	1000
.dword	1
.dword	div1000
.dword	1

# Test -1000: -1000 / 1000 = -1
.dword	1000002
.dword	div1000_label
.dword	8
.dword	-1000
.dword	-1
.dword	div1000
.dword	1

# Test 2000: 2000 / 1000 = 2
.dword	1000003
.dword	div1000_label
.dword	8
.dword	2000
.dword	2
.dword	div1000
.dword	1

# Test -2000: -2000 / 1000 = -2
.dword	1000004
.dword	div1000_label
.dword	8
.dword	-2000
.dword	-2
.dword	div1000
.dword	1

# Test Max Signed 32-bit: 2147483647 / 1000
# 2147483647 / 1000 = 2147483
.dword	1000005
.dword	div1000_label
.dword	8
.dword	2147483647
.dword	2147483
.dword	div1000
.dword	1

# Test Min Signed 32-bit: -2147483648 / 1000
# -2147483648 / 1000 = -2147483
.dword	1000006
.dword	div1000_label
.dword	8
.dword	-2147483648
.dword	-2147483
.dword	div1000
.dword	1

.if CPU_BITS == 64

# Test Max Signed 64-bit
# 9223372036854775807 / 1000 = 9223372036854775
.dword	1000007
.dword	div1000_label
.dword	8
.dword	0x7fffffffffffffff
.dword	9223372036854775
.dword	div1000
.dword	1

# Test Min Signed 64-bit
# -9223372036854775808 / 1000 = -9223372036854775
.dword	1000008
.dword	div1000_label
.dword	8
.dword	0x8000000000000000
.dword	-9223372036854775
.dword	div1000
.dword	1

.endif
	
# loop terminator
.dword	0
.dword	0
.dword	0
.dword	0
.dword	0
.dword	0
.dword	0

.text
	
######################################################################
# uses linux ecalls for write and exit

# Test Categories:
# Basic Division (small numbers)
# Zero Dividend
# Zero Divisor
# Divisor Greater than Dividend
# Negative Dividend or Divisor
# Large Dividend and Divisor
#
# Test Case Structure:
# Each test case will:
# Load values into registers.
# Jal the function under test.

.globl _start

_start:

	# 1. Basic Division (Dividend = 10, Divisor = 3)
	# Expected Result: Quotient = 3, Remainder = 1 (since 10 ÷ 3 = 3 remainder 1)

test1:
	la	a1, test1s
	li	a2, 7
	jal	print

	li	a0, 10		# Load dividend (10) into a0
	li	a1, 3		# Load divisor (3) into a1
	jal	divremu		# Jal divremu

	# Check results
	# a0 (quotient) should be 3
	# a1 (remainder) should be 1

	addi	a0, a0, -3
	bnez	a0, test1_fail
	addi	a1, a1, -1
	bnez	a1, test1_fail

	la	a1, pass
	jal	result
	
	j	test2

test1_fail:

	la	a1, fail
	jal	result
	
test2:

	# 2. Zero Dividend (Dividend = 0, Divisor = 3)
	# Expected Result: Quotient = 0, Remainder = 0 (since 0 ÷ 3 = 0 remainder 0)

	la	a1, test2s
	li	a2, 7
	jal	print

	li	a0, 0		# Load dividend (0) into a0
	li	a1, 3		# Load divisor (3) into a1
	jal	divremu		# Jal divremu

	# Check results
	# a0 (quotient) should be 0
	# a1 (remainder) should be 0

	bnez	a0, test2_fail
	bnez	a1, test2_fail

	la	a1, pass
	jal	result

	j	test3

test2_fail:

	la	a1, fail
	jal	result

test3:

	# 3. Zero Divisor (Dividend = 10, Divisor = 0)
	# Expected Result: Division by zero returns Qoutient = 0, Remainder = 0

	la	a1, test3s
	li	a2, 7
	jal	print

	li	a0, 10		# Load dividend (10) into a0
	li	a1, 0		# Load divisor (0) into a1
	jal	divremu		# Jal divremu

	# Check results
	# a0 (quotient) should be -1
	# a1 (remainder) should be 10

	addi	a1, a1, -10
	bnez	a1, test3_fail
	addi	a0, a0, 1
	bnez	a0, test3_fail

	la	a1, pass
	jal	result

	j	test4

test3_fail:

	la	a1, fail
	jal	result

test4:

	# 4. Divisor Greater than Dividend (Dividend = 3, Divisor = 10)
	# Expected Result: Quotient = 0, Remainder = 3 (since 3 ÷ 10 = 0 remainder 3)

	la	a1, test4s
	li	a2, 7
	jal	print

	li	a0, 3		# Load dividend (3) into a0
	li	a1, 10		# Load divisor (10) into a1
	jal	divremu		# Jal divremu

	# Check results
	# a0 (quotient) should be 0
	# a1 (remainder) should be 3

	bnez	a0, test4_fail
	addi	a1, a1, -3
	bnez	a1, test4_fail

	la	a1, pass
	jal	result
	j	test5

test4_fail:
	la	a1, fail
	jal	result

test5:

	# 5. Negative Dividend (Dividend = -10, Divisor = 3)
	# Expected Result: Quotient = -3, Remainder = -1 (since -10 ÷ 3 = -3 remainder -1)

	la	a1, test5s
	li	a2, 7
	jal	print

	li	a0, -10		# Load dividend (-10) into a0
	li	a1, 3		# Load divisor (3) into a1
	jal	divrem		# Jal divrem
	
	# Check results
	# a0 (quotient) should be -3
	# a1 (remainder) should be 1
	
	addi	a0, a0, 3
	bnez	a0, test5_fail
	addi	a1, a1, 1
	bnez	a1, test5_fail
	
	la	a1, pass
	jal	result
	j	test6
	
test5_fail:
	la	a1, fail
	jal	result

test6:

	# 6. Negative Divisor (Dividend = 10, Divisor = -3)
	# Expected Result: Quotient = -3, Remainder = -1 (since 10 ÷ -3 = -3 remainder -1)

	la	a1, test6s
	li	a2, 7
	jal	print
	
	li	a0, 10		# Load dividend (10) into a0
	li	a1, -3		# Load divisor (-3) into a1
	jal	divrem		# Jal divrem

	# Check results
	# a0 (quotient) should be -3
	# a1 (remainder) should be -1
	
	addi	a0, a0, 3
	bnez	a0, test6_fail
	addi	a1, a1, 1
	bnez	a0, test6_fail

	la	a1, pass
	jal	result

	j	test7

test6_fail:
	la	a1, fail
	jal	result

test7:

	# 7. Both Dividend and Divisor Negative (Dividend = -10, Divisor = -3)
	# Expected Result: Quotient = 3, Remainder = -1 (since -10 ÷ -3 = 3 remainder -1)

	la	a1, test7s
	li	a2, 7
	jal	print

	li	a0, -10		# Load dividend (-10) into a0
	li	a1, -3		# Load divisor (-3) into a1
	jal	divrem		# Jal divrem

	# Check results
	# a0 (quotient) should be 3
	# a1 (remainder) should be -1

	addi	a0, a0, -3
	bnez	a0, test7_fail
	addi	a1, a1, 1
	bnez	a1, test7_fail

	la	a1, pass
	jal	result

	j	test8

test7_fail:
	la	a1, fail
	jal	result

test8:

	# 8. Large Dividend (Dividend = 123456, Divisor = 123)
	# Expected Result: Quotient = 1007, Remainder = 105 (since 123456 ÷ 123 = 1007 remainder 105)

	la	a1, test8s
	li	a2, 7
	jal	print

	li	a0, 123456	# Load dividend (123456) into a0
	li	a1, 123		# Load divisor (123) into a1
	jal	divremu		# Jal divremu

	# Check results
	# a0 (quotient) should be 1003
	# a1 (remainder) should be 87

	addi	a0, a0, -1003
	bnez	a0, test8_fail
	addi	a1, a1, -87
	bnez	a1, test8_fail

	la	a1, pass
	jal	result

	j	test9

test8_fail:

	la	a1, fail
	jal	result

test9:

	# 9. Edge Case: Large Dividend and Divisor (Dividend = 1024, Divisor = 2)
	# Expected Result: Quotient = 512, Remainder = 0 (since 1024 ÷ 2 = 512 remainder 0)

	la	a1, test9s
	li	a2, 7
	jal	print

	li	a0, 1024	# Load dividend (1024) into a0
	li	a1, 2		# Load divisor (2) into a1
	jal	divremu		# Jal divremu

	# Check results
	# a0 (quotient) should be 512
	# a1 (remainder) should be 0

	addi	a0, a0, -512
	bnez	a0, test9_fail
	bnez	a1, test9_fail

	la	a1, pass
	jal	result
	j	test10

test9_fail:
	la	a1, fail
	jal	result

test10:

	# 10. Maximum Dividend (Dividend = MAX_INT, Divisor = 1)
	# Expected Result: Quotient = MAX_INT, Remainder = 0 (since MAX_INT ÷ 1 = MAX_INT remainder 0)

	la	a1, test10s
	li	a2, 8
	jal	print

	li	a0, 2147483647	# Load maximum 32-bit signed integer into a0
	li	a1, 1		# Load divisor (1) into a1
	jal	divremu		# Jal divremu

	# Check results
	# a0 (quotient) should be 2147483647
	# a1 (remainder) should be 0

	li	a2, -2147483647
	add	a0, a0, a2
	bnez	a0, test10_fail
	bnez	a1, test10_fail

	la	a1, pass
	jal	result
	j	test11

test10_fail:

	la	a1, fail
	jal	result

test11:
	# Expected Result: Quotient = 4, Remainder = 21

	la	a1, test11s
	li	a2, 8
	jal	print

	li	a0, 433
	li	a1, 103

	jal	divremu

	# Check results
	# a0 (quotient) should be 4
	# a1 (remainder) should be 21
	mv	s0, a0
	mv	s1, a1
	jal	to_decu
	mv	a2, a1
	mv	a1, a0
	jal	print
	la	a1, space
	li	a2, 1
	jal	print
	mv	a0, s1
	jal	to_decu
	mv	a2, a1
	mv	a1, a0
	jal	print
	la	a1, space
	li	a2, 1
	jal	print

	mv	a0, s0
	mv	a1, s1
	addi	a0, a0, -4
	bnez	a0, test11_fail
	addi	a1, a1, -21
	bnez	a1, test11_fail

	la	a1, pass
	jal	result
	#	j	div3u_tests
	j	foo

test11_fail:

	la	a1, fail
	jal	result

.macro	load	reg addr
.if CPU_BITS == 64
	ld	\reg, \addr
.else
	lw	\reg, \addr
.endif
.endm

foo:	
	la	s0, divtab
loopy:	
	load	a0, offset_flags(s0)
	beqz	a0, _end

	load	a0, offset_testnum(s0)	# s0 = testnum
	jal	to_dec
	mv	a2, a1
	mv	a1, a0
	jal	print
	la	a1, colon	# ": "
	li	a2, 2
	jal	print

	load	a1, offset_label(s0)	# label
	load	a2, offset_len(s0)	# len of label
	jal	print

	load	s1,offset_dividend(s0)	# s1 = dividend
	mv	a0, s1
	li	a1, CPU_BYTES
	li	a2, 1
	jal	to_hex		# convert dividend to hex
	mv	a2, a1
	mv	a1, a0
	jal	print		# print dividend
	la	a1, space
	li	a2, 1
	jal	print		# print space

	load	a0, offset_quotient(s0)	# expected quotient is in 16(s0)
	mv	s2, a0		# expected quotient is in s2
	li	a1, CPU_BYTES
	li	a2, 1
	jal	to_hex
	mv	a2, a1
	mv	a1, a0
	jal	print		# print expected quotient
	la	a1, space
	li	a2, 1
	jal	print		# print space

	load	a1, offset_ptr(s0)	# routine pointer
	mv	a0, s1		# get dividend in a0
	jalr	a1		# jal routine

	bne	a0, s2, test_fail
	
	la	a1, pass
	li	a2, 5
	jal	print
	j	next
	
test_fail:
	li	a1, CPU_BYTES
	li	a2, 1
	jal	to_hex
	mv	a2, a1
	mv	a1, a0
	jal	print
	la	a1, space
	li	a2, 1
	jal	print
	la	a1, fail
	li	a2, 5
	jal	print
next:
	addi	s0, s0, struct_len
	j	loopy

_end:
	li	a0, 0		# exit code
	li	a7, 93		# sysjal exit
	ecall

print:	
	li	a0, 1
	li	a7, 64
	ecall
	ret

result:
	li	a0, 1
	li	a2, 5
	li	a7, 64
	ecall
	ret

test1s:	.asciz	"test1: "
test2s:	.asciz	"test2: "
test3s:	.asciz	"test3: "
test4s:	.asciz	"test4: "
test5s:	.asciz	"test5: "
test6s:	.asciz	"test6: "
test7s:	.asciz	"test7: "
test8s:	.asciz	"test8: "
test9s:	.asciz	"test9: "
test10s:	.asciz	"test10: "
test11s:	.asciz	"test11: "
pass:	.asciz	"pass\n"
fail:	.asciz	"fail\n"
space:	.asciz	" "
colon:	.asciz	": "

.data
div3u_label:		.asciz	"div3u "
div5u_label:		.asciz	"div5u: "
div6u_label:		.asciz	"div6u: "
div7u_label:		.asciz	"div7u: "
div9u_label:		.asciz	"div9u: "
div10u_label:		.asciz	"div10u: "
div11u_label:		.asciz	"div11u: "
div12u_label:		.asciz	"div12u: "
div13u_label:		.asciz	"div13u: "
div100u_label:		.asciz	"div100u: "
div1000u_label:		.asciz	"div1000u "
div3_label:		.asciz	"div3 "
div5_label:		.asciz	"div5: "
div6_label:		.asciz	"div6: "
div7_label:		.asciz	"div7: "
div9_label:		.asciz	"div9: "
div10_label:		.asciz	"div10: "
div11_label:		.asciz	"div11: "
div12_label:		.asciz	"div12: "
div13_label:		.asciz	"div13: "
div100_label:		.asciz	"div100: "
div1000_label:		.asciz	"div1000 "

