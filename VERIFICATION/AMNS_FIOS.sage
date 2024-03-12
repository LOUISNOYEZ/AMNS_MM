load("PMNS.sage")
import pdb
import random
PolyRing = PolynomialRing(ZZ, x)

def polcomp2(A, width):
    if isinstance(A, PMNS_element):
        A = A.lift()
    return A.map_coefficients(lambda t : t if (t >= 0) else 2**width-abs(t))
    
def poldecomp2(A, width):
    if isinstance(A, PMNS_element):
        A = A.lift()
    return A.map_coefficients(lambda t : -(2**width-t) if ((t >> (width-1)) != 0) else t)
    
def polsignext(A, init_width, final_width):
    return polcomp2(poldecomp2(A, init_width), final_width)

def sra(a,init_width,shift_width):
    if a & 2**(init_width-1) != 0:
        filler = int('1'*shift_width + '0'*(init_width-shift_width),2)
        a = (a >> shift_width) | filler
        return a
    else:
        return a >> shift_width
        
def polsra(A, init_width, shift_width):
    if isinstance(A, PMNS):
        A = A.lift()
    return A.map_coefficients(lambda t : sra(t, init_width, shift_width))
    
def AMNS_FIOS(A_arr, B_arr, E, M_arr, M_prime_0):

    w = 17
    
    W = 2**17

    s = len(A_arr)
    
    res_arr = s*[PolyRing(0)]
    
    for i in range(s):
        res_arr[0] = (res_arr[0] + (A_arr[i]*B_arr[0] % E)).map_coefficients(lambda t : t % 2**(48))
        #breakpoint()
        q = (((res_arr[0].map_coefficients(lambda t : t % W))*M_prime_0) % E).map_coefficients(lambda t : t % W)
        #breakpoint()
        res_arr[0] = (res_arr[0] + (q*M_arr[0] % E)).map_coefficients(lambda t : t % 2**(48))
        #breakpoint()
        res_arr[0] = polsra(res_arr[0], 48, w)
        #breakpoint()
        for j in range(1, s):
            res_arr[j-1] = (res_arr[j-1] + res_arr[j])
            #breakpoint()
            res_arr[j-1] = (res_arr[j-1] + (A_arr[i]*B_arr[j] % E))
            #breakpoint()
            res_arr[j-1] = (res_arr[j-1] + (q*M_arr[j] % E))
            #breakpoint()
            res_arr[j-1] = res_arr[j-1].map_coefficients(lambda t : t % 2**(48))
            #breakpoint()
            res_arr[j] = polsra(res_arr[j-1], 48, w)
            #breakpoint()
            res_arr[j-1] = res_arr[j-1].map_coefficients(lambda t : t % W)
            #breakpoint()
                    
    res_arr[s-1] = res_arr[s-1].map_coefficients(lambda t : t % (2**w))
    #breakpoint()
    
    return res_arr

#if __name__=="__main__":
def test(p_size):
    PolyRing = PolynomialRing(ZZ, name = "x", sparse = False)

    p = random_prime(2**p_size-1, False, 2**(p_size-1))

    w = 17
    W = 2**w

    E = PolyRing("x**11-2")

    PMNS_inst = PMNS(p, E, phi_word_width=w)

    E = PMNS_inst.E
    gamma = PMNS_inst.gamma

    phi = PMNS_inst.phi

    s = (len(bin(phi)[2:])-1-1)//17+1

    M = PMNS_inst.M_poly
    M_prime = PMNS_inst.M_prime_poly

    M_prime_0 = M_prime.map_coefficients(lambda t : t % W)

    a = random.randrange(2**(p_size-1), p)
    b = random.randrange(2**(p_size-1), p)

    A = PMNS_inst(a, mgt=False)
    B = PMNS_inst(b, mgt=False)

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

    res_temp = PolyRing(0)
    for i in range(s):
        res_temp = res_temp + res_arr[i].map_coefficients(lambda t : t << (i*w))

    print(res_temp)
        
    res = poldecomp2(res_temp, s*w)
    
    verif = (a*b*inverse_mod(phi, p)) % p
    
    print("p : ", hex(p), "\na : ", hex(a), "\nb : ", hex(b))
    
    print("\ntest  : ", hex(res(gamma) % p), "\nverif : ", hex(verif), "\nmatch : ", res(gamma) % p == verif)

