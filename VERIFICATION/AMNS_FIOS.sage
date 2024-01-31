load("AMNS.sage")
import random

def polcomp2(a, width):
	return a.map_coefficients(lambda t : t if (t >= 0) else 2**width-abs(t))
	
def poldecomp2(a, width):
	return a.map_coefficients(lambda t : -(2**width-t) if ((t >> (width-1)) != 0) else t)
	
def polsignext(a, init_width, final_width):
	return polcomp2(poldecomp2(a, init_width), final_width)

def sra(x,n,m):
    if x & 2**(n-1) != 0:  # MSB is 1, i.e. x is negative
        filler = int('1'*m + '0'*(n-m),2)
        x = (x >> m) | filler  # fill in 0's with 1's
        return x
    else:
        return x >> m
        
def polsra(x, n, m):
	return x.map_coefficients(lambda t : sra(t, n, m))
	
def AMNS_FIOS(A_arr, B_arr, E, M_arr, M_prime_0):

	w = 17
	
	W = 2**17

	s = len(A_arr)
	
	res_arr = s*[PolyRing(0)]
	
	for i in range(s):
		
		res_arr[0] = (res_arr[0] + (A_arr[i]*B_arr[0] % E)).map_coefficients(lambda t : t % 2**(48))
		
		q = (((res_arr[0].map_coefficients(lambda t : t % W))*M_prime_0) % E).map_coefficients(lambda t : t % W)
		
		res_arr[0] = (res_arr[0] + (q*M_arr[0] % E)).map_coefficients(lambda t : t % 2**(48))
		
		res_arr[0] = polsra(res_arr[0], 48, w)
		
		for j in range(1, s):
		
			res_arr[j-1] = (res_arr[j-1] + (A_arr[i]*B_arr[j] % E) + (q*M_arr[j] % E) + res_arr[j]).map_coefficients(lambda t : t % 2**(48))
			
			res_arr[j] = polsra(res_arr[j-1], 48, w)
			
			res_arr[j-1] = res_arr[j-1].map_coefficients(lambda t : t % W)
			
		print(list(map(hex, list(res_arr[s-2]))))
					
	res_arr[s-1] = res_arr[s-1].map_coefficients(lambda t : t % (2**w))
	
	return res_arr

def test(p_size):

	PolyRing = PolynomialRing(ZZ, name = "x", sparse = False)

	p = random_prime(2**p_size-1, False, 2**(p_size-1))

	w = 17
	W = 2**w

	N = 5
	LAMBDA = 2

	AMNS_inst = AMNS(p, N, LAMBDA = LAMBDA)

	E = AMNS_inst.E
	gamma = AMNS_inst.GAMMA

	phi_log2 = AMNS_inst.phi_log2
	phi = 2**phi_log2

	s = (phi_log2-1)//17+1

	M = AMNS_inst.M
	M_prime = AMNS_inst.M_P

	M_prime_0 = M_prime.map_coefficients(lambda t : t % W)

	a_int = random.randrange(2**(p_size-1), p)
	b_int = random.randrange(2**(p_size-1), p)

	A = PolyRing(AMNS_inst.conv_in(a_int))
	B = PolyRing(AMNS_inst.conv_in(b_int))

	A_comp2 = polcomp2(A, s*w)
	B_comp2 = polcomp2(B, s*w)
	M_comp2 = polcomp2(M, s*w)

	A_comp2_arr = [A_comp2.map_coefficients(lambda t : (t >> (i*w)) % W) for i in range(s)]
	B_comp2_arr = [B_comp2.map_coefficients(lambda t : (t >> (i*w)) % W) for i in range(s)]

	M_comp2_arr = [M_comp2.map_coefficients(lambda t : (t >> (i*w)) % W) for i in range(s)]
	
	res_arr = AMNS_FIOS(A_comp2_arr, B_comp2_arr, E, M_comp2_arr, M_prime_0)

	res = PolyRing(0)
	for i in range(s):
		res = res + res_arr[i].map_coefficients(lambda t : t << (i*w))
		
	res = poldecomp2(res, s*w)
	
	verif = (a_int*b_int*inverse_mod(phi, p)) % p
	
	#print("p : ", hex(p), "\na : ", hex(a_int), "\nb : ", hex(b_int))
	
	#print("\ntest  : ", hex(res(gamma) % p), "\nverif : ", hex(verif), "\nmatch : ", res(gamma) % p == verif)
	
	return (p_size, p, a, b)

if __name__ == "__main__":

    PolyRing = PolynomialRing(ZZ, name = "x", sparse = False)

    p_size = 256

    #p = random_prime(2**p_size-1, False, 2**(p_size-1))

    p = 111351430153662633905068858573340700256403678493558389246694298294547995384453

    w = 17
    W = 2**w

    N = 5
    LAMBDA = 2

    AMNS_inst = AMNS(p, N, LAMBDA = LAMBDA)

    E = AMNS_inst.E
    gamma = AMNS_inst.GAMMA

    phi_log2 = AMNS_inst.phi_log2
    phi = 2**phi_log2

    s = (phi_log2-1)//17+1

    M = AMNS_inst.M
    M_prime = AMNS_inst.M_P

    M_prime_0 = M_prime.map_coefficients(lambda t : t % W)

    #a_int = random.randrange(2**(p_size-1), p)
    #b_int = random.randrange(2**(p_size-1), p)

    a_int = 64578661460212764205744927238529611704927608850925533941595583069809645082738
    b_int = 97313298035541955205503335023042544707119649379354109907990629246026537831178

    A = PolyRing(AMNS_inst.conv_in(a_int))
    B = PolyRing(AMNS_inst.conv_in(b_int))

    A_comp2 = polcomp2(A, (s-1)*w+48)
    B_comp2 = polcomp2(B, (s-1)*w+48)
    M_comp2 = polcomp2(M, (s-1)*w+48)

    A_comp2_arr = [A_comp2.map_coefficients(lambda t : (t >> (i*w)) % W) for i in range(s-1)]
    A_comp2_arr.append(A_comp2.map_coefficients(lambda t : (t >> ((s-1)*w)) % (2**48)))

    B_comp2_arr = [B_comp2.map_coefficients(lambda t : (t >> (i*w)) % W) for i in range(s-1)]
    B_comp2_arr.append(B_comp2.map_coefficients(lambda t : (t >> ((s-1)*w)) % (2**48)))

    M_comp2_arr = [M_comp2.map_coefficients(lambda t : (t >> (i*w)) % W) for i in range(s-1)]
    M_comp2_arr.append(M_comp2.map_coefficients(lambda t : (t >> ((s-1)*w)) % (2**48)))

    res_arr = AMNS_FIOS(A_comp2_arr, B_comp2_arr, E, M_comp2_arr, M_prime_0)

    res = PolyRing(0)
    for i in range(s):
        res = res + res_arr[i].map_coefficients(lambda t : t << (i*w))
        
    res = poldecomp2(res, s*w)

    verif = (a_int*b_int*inverse_mod(phi, p)) % p

    print("p : ", hex(p), "\na : ", hex(a_int), "\nb : ", hex(b_int))

    print("\ntest  : ", hex(res(gamma) % p), "\nverif : ", hex(verif), "\nmatch : ", res(gamma) % p == verif)
    
    print("A : ", list(map(hex, list(A_comp2))))
    print("B : ", list(map(hex, list(B_comp2))))
