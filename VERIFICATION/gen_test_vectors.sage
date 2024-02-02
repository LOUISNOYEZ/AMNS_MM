import argparse
import random
import os
load("AMNS_FIOS.sage")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description = "Generate test FIOS test vectors.")
    parser.add_argument("-w", metavar = "WIDTH", type = int, default = 256,
                        help = "Bit-width of the test vectors.")
    parser.add_argument("-n", metavar = "NUMBER", type = int, default = None,
                        help = "Number of test vectors.")
    parser.add_argument("-N", metavar = "COEFF", type = int, default = None,
                        help = "Number of coefficients.")
    parser.add_argument("-L", metavar = "LAMBDA", type = int, default = 2,
                        help = "LAMBDA parameter.")
    parser.add_argument("--name", metavar = "FILE NAME", type = str, default = None,
                        help = "Name of test vector file. Default : sim_<WIDTH>")
                        
    args = parser.parse_args()

    WIDTH = args.w
    N = args.N
    LAMBDA = args.L

    if args.n is not None:
        test_vectors_nb = args.n
    else:
        test_vectors_nb = 1

    if args.name is not None:
        filename = args.name + ".txt"
    else:
        filename = "sim_" + str(WIDTH) + "_" + str(N) + "_" + str(LAMBDA) + ".txt"
        

    filename = os.path.abspath(os.path.dirname(__file__)) + "/TEST_VECTORS/" + filename

    PolyRing = PolynomialRing(ZZ, x)
    
    with open(filename, "w") as test_file:

        for i in range(test_vectors_nb):                    
        
            valid = 0
            count = 0
            while (not(valid) and count < 10) :
                
                p = random_prime(2**WIDTH, False, 2**(WIDTH-1))
            
                try:
                    AMNS_inst = PMNS(p, f"x**{N}-{LAMBDA}", phi_word_width=17)
                    valid = 1
                except Exception as error:
                    valid = 0
                    print(error)
                    print(p)
                    print(N)
                    print(LAMBDA)
                count += 1
                    
            w = 17
            W = 2**w
                    
            a_int = random.randrange(2**(WIDTH-1), p)
            b_int = random.randrange(2**(WIDTH-1), p)
                    
            E = AMNS_inst.E
            gamma = AMNS_inst.gamma

            phi_log2 = len(bin(AMNS_inst.phi)[2:])-1
            print(phi_log2)
            phi = 2**phi_log2

            s = (phi_log2-1)//17+1

            M = AMNS_inst.M_poly
            M_prime = AMNS_inst.M_prime_poly

            M_prime_0 = M_prime.map_coefficients(lambda t : t % W)

            A = AMNS_inst(a_int, mgt=False)
            B = AMNS_inst(b_int, mgt=False)

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
            
            test_file.write(f'WIDTH\n{WIDTH}\n\nPHI_LOG2\n{phi_log2}\n\nsw\n{s*w}\n\nGAMMA\n{gamma}\n\np\n{p}\n\na_int\n{a_int}\n\nb_int\n{b_int}\n\n')

            test_file.write("M\n")
            for i in range(N):
                test_file.write(f'{hex(list(M_comp2.map_coefficients(lambda t : t % 2**(s*w)))[i])[2:]}\n')
                
            test_file.write("\nM_prime_0\n")
            for i in range(N):
                test_file.write(f'{hex(list(M_prime_0)[i])[2:]}\n')

            test_file.write("\nA\n")
            for i in range(N):
                test_file.write(f'{hex(list(A_comp2.map_coefficients(lambda t : t % 2**(s*w)))[i])[2:]}\n')
            
            test_file.write("\nB\n")
            for i in range(N):
                test_file.write(f'{hex(list(B_comp2.map_coefficients(lambda t : t % 2**(s*w)))[i])[2:]}\n')
                
            test_file.write("\nres\n")
            for i in range(N):
                test_file.write(f'{hex(list(res)[i])[2:]}\n')
                
            test_file.write("\n\n")
            
            print(poldecomp2(res, s*w)(gamma)*2**(s*w) % p)
            print(a_int*b_int % p)
