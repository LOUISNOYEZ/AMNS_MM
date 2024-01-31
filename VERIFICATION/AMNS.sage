#########################################################################################
## This file describes class definitions for new sage mathematical structures :
## An AMNS can be described as a set of polynomials used to represent elements
## of Z/pZ where p is a prime number. The set of polynomials and methods used to generate
## such a set are implemented as the AMNS class. In addition it is meant to manipulate elements
## within the Montgomery domain, where polynomials represent elements of the shape a*phi mod p.
## AMNS polynomial elements are implemented as the AMNS_elt object.
## The implementation takes advantage of sage parent/element framework such that
## AMNS elements can be manipulated easily and are compatible with a large number
## of functions manipulating polynomials/ring elements.
##
## This implementation is meant to be a functionnal tool but it is expected the mathematical
## framework of sage combined with the algorithmic advantages of AMNS could lead to better
## performance of modular arithmetic operations (granted it is integrated well with the rest of sage).
#########################################################################################


## AMNS class inherits attributes and methods from polynomial ring object PolynomialRing_general.
## It also inherits from the UniqueRepresentation structure, which makes it so two AMNS structure only evaluate
## to equal if they are exactly identical.
from sage.rings.polynomial.polynomial_ring import PolynomialRing_general
from sage.structure.unique_representation import UniqueRepresentation

## AMNS_elt class inherits attributes and methods from polynomial object Polynomial_generic_dense.
from sage.rings.polynomial.polynomial_element import Polynomial_generic_dense

## The Element structure is used to determine whether the element passed to the constructor of AMNS elements are
## themselves elements of a ring.
from sage.structure.element import Element



## A number of polynomials used within the system are not objects of the AMNS element class :
## Multiplication in an AMNS is achieved through the Montgomery-like algorithm. All polynomials
## involved in this algorithm must be treated as classical polynomial objects (A*B <=> mgt_mul(A, B))
## This includes internal reduction polynomial parameters M and M_P, external reduction parameter E, 
## and operands which are systematically converted to classical polynomial objects for
## each multiplication. The global variable PolyRing represents the ring of classical polynomial objects.
PolyRing = PolynomialRing(ZZ, name = "x", sparse = False)


## If neither LAMBDA nor GAMMA are provided to the constructor of the AMNS object, the constructor attemps to
## build an optimal AMNS with minimal coefficient size for LAMBDA candidate parameters in range LAMBDA_begin to
## LAMBDA_end. the default value of these arguments are given below.
default_LAMBDA_begin = -11
default_LAMBDA_end = 11


###############################################################################################################################################
## The AMNS_elt class for AMNS_element. AMNS elements are polynomials whose degree is strictly less than N 
## and whose coefficients have an absolute value less than rho. when two AMNS polynomials are multiplied 
## together, the degree of the result must be decreased using the external reduction operation mod E.
## The internal reduction operation then ensures that the coefficient values are less than rho.
## Both of these operations are combined in the Montgomery-like multiplication algorithm
##
## The AMNS_elt class inherits from the Polynomial_generic_dense class which means it can be manipulated
## using all of the functions which can manipulate classical polynomials.
## All elements have knowledge of their parent AMNS and can access its parameters and methods, including its
## specific montgomery multiplication method.
##
## init operation is left unchanged. Initialisation polynomial is preprocessed through the _element_constructor_ method
## of the AMNS parent class which operates conversions and ensures polynomials belong to the AMNS
##
## Sage coercion framework and conversions means we can assume operands of arithmetic operations are of the AMNS element type.
##
## Multiplication between two AMNS elements is overloaded to invoke their parent montgomery multiplication method.
##
## Addition or substraction between two AMNS elements is overloaded to operate an internal reduction on the result if
## its infinity norm is more than phi
##
## Left and right multiplication by a scalar is overloaded such that scalars are converted to Z/pZ elements and then
## to AMNS elements if their absolute value is more than rho. The conversion can involve up to N multiplications by a scalar
## thus a special case is made for scalars of absolute values less than rho, whose multiplication only involve two one multiplication by a scalar.
##
## A conv_out method is provided to evaluate mod p the current element in its parent AMNS GAMMA parameter.
############################################################################################################################################### 
class AMNS_elt(Polynomial_generic_dense):


	def __init__(self, parent, *args, **kwds):
		Polynomial_generic_dense.__init__(self, parent, *args, **kwds)

		
	def _add_(self, other):
		C = self.__class__
		temp = PolyRing(self)+PolyRing(other)
		if temp.norm(infinity) >= self.phi:
			return C(self.parent(), self.parent().mgt_mul(temp, self.parent().phi_rep))
		else:
			return C(self.parent(), temp)

	def _sub_(self, other):
		C = self.__class__
		temp = PolyRing(self)-PolyRing(other)
		if temp.norm(infinity) >= self.phi:
			return C(self.parent(), self.parent().mgt_mul(temp, self.parent().phi_rep))
		else:
			return c(self.parent(), temp)

		
	def _lmul_(self, left):
		C = self.__class__
		if abs(left) <= self.parent().rho:
			return C(self.parent(), self.parent().mgt_mul(left*PolyRing(self), self.parent().phi))
		else:
			return C(self.parent(), self.parent().mgt_mul(self.parent().conv_in(left), PolyRing(self)))

		
	def _rmul_(self, right):
		C = self.__class__
		if abs(right) <= self.parent().rho:
			return C(self.parent(), self.parent().mgt_mul(right*PolyRing(self), self.parent().phi))
		else:
			return C(self.parent(), self.parent().mgt_mul(self.parent().conv_in(right), PolyRing(self)))

		
	def _mul_(self, other):
		C = self.__class__
		return C(self.parent(), self.parent().mgt_mul(PolyRing(self), PolyRing(other)))

		
	def conv_out(self):
		return self.parent().mgt_mul(self, 1)(self.parent().GAMMA) % self.parent().p



## The AMNS class is used to represent the set of AMNS elements.
## It inherits from the Ring of Polynomials object and can use its methods.
class AMNS(UniqueRepresentation, PolynomialRing_general):
	
	
	
	## The AMNS class has knowledge of its element class
	Element = AMNS_elt
	
	
	
	## An AMNS requires three parameters to be defined :
	##
	## p is a prime integer (an AMNS represents elements of Z/pZ).
	##
	## N is the number of coefficients of the polynomial elements of the AMNS.
	##
	## LAMBDA is a small integer.
	## p and N are required arguments. If neither GAMMA nor LAMBDA are provided, the "best" LAMBDA is chosen for values in range LAMBDA_begin to LAMBDA_end.
	## Alternatively, GAMMA can be provided and its corresponding LAMBDA deduced (LAMBDA = GAMMA**i mod p).
	##
	## The delta parameter represents the number of AMNS elements that can be added together before their infinite norm becomes higher than the phi parameter
	## used in the Montgomery multiplication. after delta additions of AMNS elements, one internal reduction is required for the infinite norm of the result to be
	## less than rho (and therefore than phi). This parameter is used to fine tune the difference between phi and rho to fit the higher level application of the AMNS.
	## 
	## GAMMA_opt and M_opt are optimization parameters. The AMNS class methods attempt to generate the M parameter from the given LAMBDA parameter (or LAMBDA parameter candidates
	## if neither LAMBDA nor GAMMA have been provided. GAMMA is an N-th root of LAMBDA mod p. A suitable M parameter is computed from GAMMA amongst several candidates. If M_opt is set
	## to True, the best M will be selected between all suitable candidates for a given GAMMA. If GAMMA_opt is set to True, the best M will be selected between all the best M_candidates
	## (after taking into account M_opt).
	## This optimization is meant to minimize the function 2*w*||M|| where w = 1 + (N-1)*LAMBDA and ||M|| is the infinite norm of M. This is the lower bound on the maximum absolute
	## value of AMNS coefficients : rho.
	##
	def __init__(self, p, N, GAMMA = None, LAMBDA = None, LAMBDA_begin = default_LAMBDA_begin, LAMBDA_end = default_LAMBDA_end, delta = 0, GAMMA_opt = True, M_opt = True, ring = ZZ):
		

		self.p = p
		self.N = N
		self.delta = delta
		
		GAMMA_temp = None
		LAMBDA_temp = infinity
		M_temp = None
		
		## If GAMMA is set LAMBDA is not taken into account.
		if GAMMA:
			
			## the AMNS LAMBDA parameter as well as M are computed from GAMMA.			
			GAMMA_temp = GAMMA
			LAMBDA_temp = ZZ(GF(self.p)(GAMMA_temp)**self.N)
			
			GAMMA_temp, M_temp = self.compute_M(GAMMA = GAMMA_temp, GAMMA_opt = GAMMA_opt, M_opt = M_opt)
			

		## If GAMMA is not set and LAMBDA is set it is used to compute the AMNS GAMMA and M parameter according to the optimization strategies specified by GAMMA_opt and M_opt.
		elif LAMBDA:
		
			LAMBDA_temp = LAMBDA
			
			GAMMA_temp, M_temp = self.compute_M(LAMBDA = LAMBDA_temp, GAMMA_opt = GAMMA_opt, M_opt = M_opt)
			

		## If neither GAMMA nor LAMBDA are set the best LAMBDA is select for LAMBDA candidates between LAMBDA_begin and LAMBDA_end.
		## LAMBDA_candidates -1, 0 and 1 are not taken into account as they generate AMNS with significantly higher rho parameter than
		## other values.
		else:
		
			M_temp_norm = infinity
			
			for LAMBDA_candidate in range(LAMBDA_begin, LAMBDA_end+1):

				if not(LAMBDA_candidate in [-1, 0, 1]):
				
					w = 1+(self.N-1)*abs(LAMBDA_candidate)
					
					GAMMA_candidate, M_candidate = self.compute_M(LAMBDA = LAMBDA_candidate, GAMMA_opt = GAMMA_opt, M_opt = M_opt)
					
					## If no N-th root mod p of a LAMBDA candidate have been found, the method compute_M will return (None, None) and
					## the check of the value of the optimization condition will be skipped.
					if not(GAMMA_candidate and M_candidate):
						continue
						
					elif 2*w*M_candidate.norm(infinity) <= 2*(1+(self.N-1)*abs(LAMBDA_temp))*M_temp_norm:
						M_temp = M_candidate
						M_temp_norm = M_temp.norm(infinity)
						GAMMA_temp = GAMMA_candidate
						LAMBDA_temp = LAMBDA_candidate
					
		
		## If no N-th root of LAMBDA have been found for any of the given GAMMA, LAMBDA, or LAMBDA candidates arguments,
		## an exception will be raised and the program will return an error.
		if not(GAMMA_temp and LAMBDA_temp and M_temp):
			raise Exception("M parameter generation failed.")
			
		
		
		self.GAMMA = GAMMA_temp
		self.LAMBDA = LAMBDA_temp
		self.M = M_temp
		
		self.E = PolyRing(x^self.N-self.LAMBDA)
		
		w = 1+abs(self.LAMBDA)*(self.N-1)
		self.rho = 2*w*ZZ(self.M.norm(infinity))
		
		## Phi is taken to be a power of two in order to simplify hardware implementations : it is very easy to compute
		## euclidean divide or modulus by phi by shifting the bits of the operand.
		SECTION_WIDTH = 17
		s = (ceil(log(2*w*self.rho*(self.delta+1)**2, 2))-1+2)//17+1
		self.phi_log2 = s*SECTION_WIDTH
		self.phi = 2**self.phi_log2
		
		
		self.M_P = PolyRing((-inverse_mod(self.M.base_extend(QQ), self.E.base_extend(QQ))).change_ring(ZZ.quo(self.phi)))

		
		## Polynomials phi_rep and phi2_rep are AMNS representation of phi and phi**2 which are used for conversion inside and outside
		## the Montgomery domain.
		self.phi_rep = self.exact_conv(self.phi)
		self.phi2_rep = self.exact_conv(self.phi**2)
		
		## Rho pow is a list of the AMNS representations of (rho**i)*(phi**2) for i in range 0 to N-1. It is used to efficiently
		## convert integers to AMNS polynomials by decomposing them base rho and operating AMNS multiplications with the representations
		## of powers of the base.
		self.rho_pow = self.compute_rho_pow()
		
		
		## The PolynomialRing_general initialisation method is used to initialise all of the parameters related to the polynomial ring.
		## It has knoweldge of our custom AMNS polynomial element class.
		PolynomialRing_general.__init__(self, ZZ, name = "x", sparse = False, element_class = AMNS_elt)
		
		
		
	## compute_M is used to generate M and must take either GAMMA or LAMBDA as its input.
	def compute_M(self, GAMMA = None, LAMBDA = None, GAMMA_opt = True, M_opt = True):
		
		GAMMA_list = []
		
		## If GAMMA is set then LAMBDA is ignored and M is generated according to M_opt.
		if GAMMA:
			GAMMA_list = [GAMMA]
			
		## If GAMMA is not set and LAMBDA is set the list of GAMMA candidates is populated with either
		## a single N-th root of LAMBDA mod p or every N-th root of LAMBDA mod p depending on GAMMA_opt.
		elif LAMBDA:
			if GAMMA_opt:
#				GAMMA_list = [ZZ(-list(A[0])[0]) for A in list((PolyRing(x^self.N-LAMBDA).change_ring(GF(self.p))).factor())]
				try:
					GAMMA_list = list(map(lambda t : ZZ(t), GF(self.p)(LAMBDA).nth_root(self.N, all = True)))
				except:
					GAMMA_list = []
			else:
				try:
#					GAMMA_list = ZZ(-list(list(PolyRing(x^self.N-LAMBDA).change_ring(GF(self.p)).factor())[0][0])[0])
					GAMMA_list = [ZZ(GF(self.p)(LAMBDA).nth_root(self.N, all = False))]
				except:
					GAMMA_list = []
					
		## If neither GAMMA nor LAMBDA are set an exception is raised.
		else:
			raise Exception("GAMMA or LAMBDA parameter required.")

			
		GAMMA_temp = None
		M_temp = None
		M_temp_norm = infinity
		
		
		## The program will attempt to generate an M_candidate for every GAMMA candidate in the GAMMA list.
		for GAMMA_candidate in GAMMA_list:
		
			## LAMBDA_temp and E_temp parameter must be set before generation even if LAMBDA was not provided.
			if LAMBDA:
				LAMBDA_temp = LAMBDA
			else:
				LAMBDA_temp = ZZ(GF(self.p)(GAMMA_candidate)**self.N)
				if abs(LAMBDA_temp-self.p) <= LAMBDA_temp:
					LAMBDA_temp = LAMBDA_temp-self.p
				
			E_temp = PolyRing(x^self.N-LAMBDA_temp)
			
			
			## A matrix base of a lattice is built.
			Lattice_base = matrix([[self.p]+(self.N-1)*[0] if i == 0 else
						[ZZ(-GF(self.p)(GAMMA_candidate)**i) % self.p] + (i-1)*[0]+[1]+(self.N-i-1)*[0] for i in range(self.N)])
						
			## If LAMBDA is odd the base must be altered.
			if LAMBDA_temp % 2 == 1:
				for i in range(1, self.N):
					if Lattice_base[i, 0] % 2 == 1:
						Lattice_base[i, 0] = Lattice_base[i, 0] + self.p

			## The base is reduced using LLL lattice reduction algorithm.  
			Lattice_base = matrix(Lattice_base.LLL(delta = 1, algorithm = 'NTL:LLL'))


			## If LAMBDA is odd there exist at least one polynomial M which is a sum of at most one polynomial of the base each
			## which satisfies the condition of existence of M_P.
			if LAMBDA_temp % 2 == 1:
				for i in range(1, 2**self.N):
					coordinates = list(bin(i))[2:]
					coordinates.reverse()
					coordinates = (coordinates + self.N*[0])[:self.N]
					
					M_candidate = PolyRing((vector(ZZ, coordinates)*Lattice_base).list())
					
					if gcd(M_candidate.change_ring(ZZ.quo(2)), E_temp.change_ring(GF(2))) == 1 and M_candidate.norm(infinity) <= M_temp_norm:
						M_temp = M_candidate
						M_temp_norm = M_temp.norm(infinity)
						GAMMA_temp = GAMMA_candidate
						
						if not(M_opt):
							break
							
			## If LAMBDA is even there exist at least one polynomial M of the base whose constant coefficient is odd, which garantees the existence of M_P.
			else:
				for i in range(self.N):
					M_candidate = PolyRing(Lattice_base[i,:].list())
				
					if Lattice_base[i, 0] % 2 == 1 and M_candidate.norm(infinity) <= M_temp_norm:
						M_temp = M_candidate
						M_temp_norm = M_temp.norm(infinity)
						GAMMA_temp = GAMMA_candidate
						
						if not(M_opt):
							break
							
			## If M_opt is set to True, The M candidate with the lowest infinite norm will be selected. Otherwise, the first candidate found will be selected.
									
		return GAMMA_temp, M_temp
		
		
		
	def mgt_mul(self, A, B):
		C = A*B % self.E
		Q = ((C % self.phi)*self.M_P % self.E) % self.phi
		S = (C+Q*self.M % self.E)//self.phi
		return S
		
			
			
	## The exact_conv function provides a means of converting an integer a of size less than p to an AMNS element by computing
	## a*phi**N mod p and applying N successive internal reductions.
	## It is used to compute AMNS representations of phi and ph**2.
	def exact_conv(self, a):
		res = PolyRing(a*self.phi**self.N % self.p)
		
		for i in range(self.N):
			res = self.mgt_mul(res, 1)
			
		return res
		
		
		
	## The representations phi_rep and phi2_rep of phi and phi**2 are used to compute the list of representations of (rho**i)*(phi**2) : rho_pow[i]
	## by successive Montgomery multiplication of rho_pow[i-1] with rho_pow[1]. rho_pow[0] is effectively phi2_rep.
	def compute_rho_pow(self):
		rho_rep = self.mgt_mul(self.rho, self.phi2_rep)
		rho_pow = []
		rho_pow.append(self.phi2_rep)
		rho_pow.append(self.mgt_mul(rho_rep, self.phi2_rep))
		for i in range(2, self.N):
			rho_pow.append(self.mgt_mul(rho_pow[-1], rho_rep))
			
		return rho_pow
		
		
		
	## Once the list of representations rho_pow has been computed, integer can be converted to the AMNS by separating their
	## rho base digits, computing their representation using rho_pow, and a montgomery multiplication with a scalar.
	def conv_in(self, a):
		a_rho_radix = [a//(self.rho**i) % self.rho for i in range(self.N)]
		
		res = PolyRing(0)
		
		for i in range(self.N):
			res = res + self.mgt_mul(a_rho_radix[i], self.rho_pow[i])
			
		res = self.mgt_mul(res, 1)
		
		return res
	
		
	
	## A get function is provided to get all AMNS specific parameters as a dictionnary.
	## Dictionaries can be used by utility functions to populate database entries with the dictionary keys as columns
	def get_param(self, mode = "normal"):
		
		if mode == "normal":
			return {"p" : self.p, "n" : self.N, "gamma" : self.GAMMA, "lambda" : self.LAMBDA, "delta" : self.delta, "e" : self.E, "m" : self.M, "m_p" : self.M_P,
				"rho" : self.rho, "phi" : self.phi, "phi_log2" : self.phi_log2, "phi_rep" : self.phi_rep, "phi2_rep" : self.phi2_rep, "rho_pow" : self.rho_pow}
		elif mode == "list":
			return {"p" : int(self.p), "n" : int(self.N), "gamma" : int(self.GAMMA), "lambda" : int(self.LAMBDA), "delta" : int(self.delta), "e" : [int(coeff) for coeff in list(self.E)], "m" : [int(coeff) for coeff in list(self.M)], "m_p" : [int(coeff) for coeff in list(self.M_P)],
				"rho" : int(self.rho), "phi" : int(self.phi), "phi_log2" : int(self.phi_log2), "phi_rep" : [int(coeff) for coeff in list(self.phi_rep)], "phi2_rep" : [int(coeff) for coeff in list(self.phi2_rep)], "rho_pow" : [[int(coeff) for coeff in list(poly)] for poly in self.rho_pow]}
			
			
			
	###########################################################################################################################################
	## The _element_constructor_ method is the main method used to construct AMNS element objects through the <AMNS_instance>(literal) syntax
	## ex :
	## AMNS_0 = AMNS(p, N)
	## AMNS_elt_0 = AMNS_0(23*x^4-6*x^2+7*x+1)
	##
	## Integers (or constant polynomials) are converted to AMNS elements in the Montgomery domain.
	## Supported constructors include lists and tuples ex : [1, 7, -6, 0, 23] / (1, 7, -6, 0, 23)
	## as well as existing classical polynomial objects.
	## Polynomials are recursively passed to the element constructor method in order to ensure their degree
	## is less than N and their infinite norm is less than rho.
	## It should be noted that sage provides a powerful framework for element conversion and coercion :
	## To generate polynomial element 10*x^3+2*x^2-x The implementation only has to know three things :
	## - how to convert elements x, x^2 and x^3,
	## - how to convert scalars to polynomial elements,
	## - how to multiply two polynomial elements together,
	## Lists and tuples are processed in a similar way. Thus it is only required to implement arithmetic operations
	## between AMNS elements and conversions to handle a wide range of operand types.
	###########################################################################################################################################
	def _element_constructor_(self, poly=None, check=True, is_gen=False,
	                      construct=False, **kwds):
	        
	        ## Shorthand for the element class.
		C = self.element_class
		## If input is a list or tuple, the elemen class is used to generate a polynom, which is fed back
		## to the element constructor.
		if isinstance(poly, (list, tuple)):
			return self(C(self, poly, check=check, is_gen=False, construct=construct))


		## If input is an Element structure, it is assumed it is either an AMNS element or an integer.
		## If input is a polynomial whose degree is more than N, it is fed back to the element constructor mod E.
		## If input is a polynomial integer with degree less than N and infinite norm more than rho, it is reduced
		## once using the montgomery multiplication algorithm and fed back to the element constructor.
		## If input is a polynomial whose degree is less than N and whose infinite norm is less than rho, it is returned directly.
		## If input is an integer it is converted to an AMNS element using the AMNS conversion function.
		if isinstance(poly, Element):
			P = poly.parent()
			if P is self:
				if poly.degree() >= self.N:
					return self(C(self, poly % self.E, check=check, is_gen = False))
				elif poly.norm(infinity) >= self.rho:
					return self(self.mgt_mul(C(self, poly, check = check, is_gen = False),  self.phi_rep))
				else:
					return poly
			elif P is self.base_ring():
				return self(self.conv_in(poly))
			elif P == self.base_ring():
				return self(C(self, [poly], check=True, is_gen=False,
				 construct=construct))
				 
		## If the input is a literal string (such as example AMNS_0 = (23*x^4-6*x^2+7*x+1) it is parsed to
		## seperate scalar literals from monomial literals. Both are converted to polynomial elements and the result polynomial is reconstructed
		## using basic polynomial arithmetic.
		elif isinstance(poly , str):
			try:
				from sage.misc.parser import Parser, LookupNameMaker
				R = self.base_ring()
				p = Parser(Integer, R, LookupNameMaker({self.variable_name(): self.gen()}, R))
				return self(p.parse(poly))
			except NameError:
				raise TypeError("Unable to coerce string")
				
		## If the input is not supported by the earlier functions or it is a classical polynomial element, the constructor attemps to convert it
		## to an AMNS element object and it is fed back to the constructor.
		return self(C(self, poly, check, is_gen, construct=construct, **kwds))



	## In a classical polynomial ring, integers would be automatically coerced into constant polynomials if used in an arithmetic operation
	## involving a polynomial. In order to force integers to be converted to AMNS elements using conversions methods, the method _coerce_map_from_
	## is overloaded. It returns True if an integer is coerced into an AMNS element, which makes it used the conversion functions defined in the
	## _element_contructor_ method.
	def _coerce_map_from_(self, P):
		if P == ZZ:
			return True
		else:
			return PolynomialRing_general._coerce_map_from_(self, P)
