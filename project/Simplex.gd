#Copyright (c) 2015 OvermindDL1
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.
#
#OvermindDL1 would love to receive updates, fixes, and more to this code,
#though it is not required:  https://github.com/OvermindDL1/Godot-Helpers

## Testing only
#extends SceneTree

#const F2 = 0.5 * (sqrt(3.0) - 1.0)
#const G2 = (3.0 - sqrt(3.0)) / 6.0
#const G2o = G2*2.0 - 1.0
#const F3 = (1.0 / 3.0)
#const G3 = (1.0 / 6.0)
#const F2 = 0.3660254037844385965883020617184229195117950439453125
#const G2 = 0.2113248654051871344705659794271923601627349853515625
#const G2o = -0.577350269189625731058868041145615279674530029296875
#const F3 = 0.333333333333333314829616256247390992939472198486328125
#const G3 = 0.1666666666666666574148081281236954964697360992431640625
const F2 = 0.36602540378443860
const G2 = 0.21132486540518714
const G2o = -0.577350269189626
const F3 = 0.33333333333333333
const G3 = 0.16666666666666666

const GRAD3 = [
	1,1,0,  -1,1,0,  1,-1,0, -1,-1,0, 
	1,0,1,  -1,0,1,  1,0,-1, -1,0,-1, 
	0,1,1,  0,-1,1,  0,1,-1, 0,-1,-1,
	1,0,-1, -1,0,-1, 0,-1,1, 0,1,1,
	]

const GRAD4 = [
	0,1,1,1,  0,1,1,-1,  0,1,-1,1,  0,1,-1,-1,
	0,-1,1,1, 0,-1,1,-1, 0,-1,-1,1, 0,-1,-1,-1,
	1,0,1,1,  1,0,1,-1,  1,0,-1,1,  1,0,-1,-1,
	-1,0,1,1, -1,0,1,-1, -1,0,-1,1, -1,0,-1,-1,
	1,1,0,1,  1,1,0,-1,  1,-1,0,1,  1,-1,0,-1,
	-1,1,0,1, -1,1,0,-1, -1,-1,0,1, -1,-1,0,-1,
	1,1,1,0,  1,1,-1,0,  1,-1,1,0,  1,-1,-1,0,
	-1,1,1,0, -1,1,-1,0, -1,-1,1,0, -1,-1,-1,0,
	]

const PERM = [
	151, 160, 137, 91, 90, 15, 131, 13, 201, 95, 96, 53, 194, 233, 7, 225, 140,
	36, 103, 30, 69, 142, 8, 99, 37, 240, 21, 10, 23, 190, 6, 148, 247, 120,
	234, 75, 0, 26, 197, 62, 94, 252, 219, 203, 117, 35, 11, 32, 57, 177, 33,
	88, 237, 149, 56, 87, 174, 20, 125, 136, 171, 168, 68, 175, 74, 165, 71,
	134, 139, 48, 27, 166, 77, 146, 158, 231, 83, 111, 229, 122, 60, 211, 133,
	230, 220, 105, 92, 41, 55, 46, 245, 40, 244, 102, 143, 54, 65, 25, 63, 161,
	1, 216, 80, 73, 209, 76, 132, 187, 208, 89, 18, 169, 200, 196, 135, 130,
	116, 188, 159, 86, 164, 100, 109, 198, 173, 186, 3, 64, 52, 217, 226, 250,
	124, 123, 5, 202, 38, 147, 118, 126, 255, 82, 85, 212, 207, 206, 59, 227,
	47, 16, 58, 17, 182, 189, 28, 42, 223, 183, 170, 213, 119, 248, 152, 2, 44,
	154, 163, 70, 221, 153, 101, 155, 167, 43, 172, 9, 129, 22, 39, 253, 19, 98,
	108, 110, 79, 113, 224, 232, 178, 185, 112, 104, 218, 246, 97, 228, 251, 34,
	242, 193, 238, 210, 144, 12, 191, 179, 162, 241, 81, 51, 145, 235, 249, 14,
	239, 107, 49, 192, 214, 31, 181, 199, 106, 157, 184, 84, 204, 176, 115, 121,
	50, 45, 127, 4, 150, 254, 138, 236, 205, 93, 222, 114, 67, 29, 24, 72, 243,
	141, 128, 195, 78, 66, 215, 61, 156, 180, 151, 160, 137, 91, 90, 15, 131,
	13, 201, 95, 96, 53, 194, 233, 7, 225, 140, 36, 103, 30, 69, 142, 8, 99, 37,
	240, 21, 10, 23, 190, 6, 148, 247, 120, 234, 75, 0, 26, 197, 62, 94, 252,
	219, 203, 117, 35, 11, 32, 57, 177, 33, 88, 237, 149, 56, 87, 174, 20, 125,
	136, 171, 168, 68, 175, 74, 165, 71, 134, 139, 48, 27, 166, 77, 146, 158,
	231, 83, 111, 229, 122, 60, 211, 133, 230, 220, 105, 92, 41, 55, 46, 245,
	40, 244, 102, 143, 54, 65, 25, 63, 161, 1, 216, 80, 73, 209, 76, 132, 187,
	208, 89, 18, 169, 200, 196, 135, 130, 116, 188, 159, 86, 164, 100, 109, 198,
	173, 186, 3, 64, 52, 217, 226, 250, 124, 123, 5, 202, 38, 147, 118, 126,
	255, 82, 85, 212, 207, 206, 59, 227, 47, 16, 58, 17, 182, 189, 28, 42, 223,
	183, 170, 213, 119, 248, 152, 2, 44, 154, 163, 70, 221, 153, 101, 155, 167,
	43, 172, 9, 129, 22, 39, 253, 19, 98, 108, 110, 79, 113, 224, 232, 178, 185,
	112, 104, 218, 246, 97, 228, 251, 34, 242, 193, 238, 210, 144, 12, 191, 179,
	162, 241, 81, 51, 145, 235, 249, 14, 239, 107, 49, 192, 214, 31, 181, 199,
	106, 157, 184, 84, 204, 176, 115, 121, 50, 45, 127, 4, 150, 254, 138, 236,
	05, 93, 222, 114, 67, 29, 24, 72, 243, 141, 128, 195, 78, 66, 215, 61, 156,
	180,
	]

static func simplex2(c0, c1):
	var s = (c0+c1) * 0.36602540378443860
	var a0 = floor(c0+s)
	var a1 = floor(c1+s)
	var t = (a0+a1) * 0.21132486540518714
	
	var n0 = 0.0
	var n1 = 0.0
	var n2 = 0.0
	
	var p00 = c0-(a0-t)
	var p01 = 0.0
	var p02 = 0.0
	var p10 = c1-(a1-t)
	var p11 = 0.0
	var p12 = 0.0
	
	# Current gdscript casts false to 0 and true to 1
	var b0 = int(p00 > p10)
	var b1 = int(p00 <= p10)
	
	p01 = p00 - b0 + 0.21132486540518714
	p11 = p10 - b1 + 0.21132486540518714
	p02 = p00 + -0.577350269189626
	p12 = p10 + -0.577350269189626
	
	var A0 = int(a0)&255
	var A1 = int(a1)&255
	var g0 = (PERM[A0 + PERM[A1]] % 12) * 3
	var g1 = (PERM[A0 + b0 + PERM[A1 + b1]] % 12) * 3
	var g2 = (PERM[A0 + 1 + PERM[A1 + 1]] % 12) * 3
	
	var f0 = 0.5 - p00*p00 - p10*p10
	var f1 = 0.5 - p01*p01 - p11*p11
	var f2 = 0.5 - p02*p02 - p12*p12
	
	if f0 > 0:
		#n0 = f0*f0*f0*f0 * (GRAD3[g0]*p00 + GRAD3[g0]*p10)
		n0 = f0*f0*f0*f0 * (GRAD3[g0]*p00 + GRAD3[g0 + 1]*p10)
	if f1 > 0:
		#n1 = f1*f1*f1*f1 * (GRAD3[g1 + 1]*p01 + GRAD3[g1 + 1]*p11)
		n1 = f1*f1*f1*f1 * (GRAD3[g1]*p01 + GRAD3[g1 + 1]*p11)
	if f2 > 0:
		#n2 = f2*f2*f2*f2 * (GRAD3[g2 + 2]*p02 + GRAD3[g2 + 2]*p12)
		n2 = f2*f2*f2*f2 * (GRAD3[g2]*p02 + GRAD3[g2 + 1]*p12)
	
	return (n0 + n1 + n2) * 70.0


static func simplex3(c0, c1, c2):
	var s = (c0+c1+c2) * 0.33333333333333333
	var a0 = floor(c0+s)
	var a1 = floor(c1+s)
	var a2 = floor(c2+s)
	var t = (a0+a1+a2) * 0.16666666666666666
	
	var n00 = 0
	var n01 = 0
	var n02 = 0
	var n10 = 0
	var n11 = 0
	var n12 = 0
	
	var p00 = c0-(a0-t)
	var p01 = c1-(a1-t)
	var p02 = c2-(a2-t)
	
	if p00 >= p01:
		if p01 >= p02:
			n00 = 1
			n10 = 1
			n11 = 1
		elif p00 >= p02:
			n00 = 1
			n10 = 1
			n12 = 1
		else:
			n02 = 1
			n10 = 1
			n12 = 1
	else:
		if p01 < p02:
			n02 = 1
			n11 = 1
			n12 = 1
		elif p00 < p02:
			n01 = 1
			n11 = 1
			n12 = 1
		else:
			n01 = 1
			n10 = 1
			n11 = 1
	
	var p10 = p00 - 1.0 + 0.5
	var p20 = p00 - n10 + 0.33333333333333333
	var p30 = p00 - n00 + 0.16666666666666666
	var p11 = p01 - 1.0 + 0.5
	var p21 = p01 - n11 + 0.33333333333333333
	var p31 = p01 - n01 + 0.16666666666666666
	var p12 = p02 - 1.0 + 0.5
	var p22 = p02 - n12 + 0.33333333333333333
	var p32 = p02 - n02 + 0.16666666666666666
	
	var A0 = int(a0)&255
	var A1 = int(a1)&255
	var A2 = int(a2)&255
	var g0 = (PERM[A0 + PERM[A2]] % 12) * 3
	var g1 = (PERM[A0 + n00 + PERM[A1 + n01 + PERM[n02 + A2]]] % 12) * 3
	var g2 = (PERM[A0 + n10 + PERM[A1 + n11 + PERM[n12 + A2]]] % 12) * 3
	var g3 = (PERM[A0 + 1 + PERM[A1 + 1 + PERM[A2 + 1]]] % 12) * 3
	
	var f0 = 0.6 - p00*p00 - p01*p01 - p02*p02
	var f1 = 0.6 - p10*p10 - p11*p11 - p12*p12
	var f2 = 0.6 - p20*p20 - p21*p21 - p22*p22
	var f3 = 0.6 - p30*p30 - p31*p31 - p32*p32
	
	var n0 = 0.0
	var n1 = 0.0
	var n2 = 0.0
	var n3 = 0.0
	if f0 > 0:
		n0 = f0*f0*f0*f0 * (p00*GRAD3[g0] + p01*GRAD3[g0+1] + p02*GRAD3[g0+2])
	if f1 > 0:
		n1 = f1*f1*f1*f1 * (p10*GRAD3[g1] + p11*GRAD3[g1+1] + p12*GRAD3[g1+2])
	if f2 > 0:
		n2 = f2*f2*f2*f2 * (p20*GRAD3[g2] + p21*GRAD3[g2+1] + p22*GRAD3[g2+2])
	if f3 > 0:
		n3 = f3*f3*f3*f3 * (p30*GRAD3[g3] + p31*GRAD3[g3+1] + p32*GRAD3[g3+2])
	
	return (n0 + n1 + n2 + n3) * 32.0


## Testing only
#func _init():
#	var c = 1000000
#	print("Preloading data into active memory")
#	for a in range(c/100):
#		simplex2(c, c)
#	
#	print("Testing simplex2...")
#	var t = OS.get_unix_time()
#	for a in range(c):
#		simplex2(c, c)
#	print ("Testing of simplex2 with "+str(c)+" iterations took "+str(OS.get_unix_time()-t)+" seconds.")
#	
#	print("Testing simplex3...")
#	t = OS.get_unix_time()
#	for a in range(c):
#		simplex3(c, c, c)
#	print ("Testing of simplex3 with "+str(c)+" iterations took "+str(OS.get_unix_time()-t)+" seconds.")
#	quit()
