from sage.modules.free_module_integer import IntegerLattice


class PMNS_element(
    sage.rings.polynomial.polynomial_quotient_ring_element.PolynomialQuotientRingElement
):
    def __init__(self, parent, polynomial, **kwds):
        sage.rings.polynomial.polynomial_quotient_ring_element.PolynomialQuotientRingElement.__init__(
            self, parent, polynomial, **kwds
        )

    def _mul_(self, right):
        R = self.parent()
        prod = self._polynomial * right._polynomial % R.E
        return self.__class__(
            R,
            R.mgt(PolynomialRing(ZZ, x)(self.__class__(R, prod)._polynomial)),
            check=False,
        )

    def _add_(self, right):
        R = self.parent()
        temp = self._polynomial + right._polynomial
        if temp.norm(infinity) >= R.rho:
            temp = R.mgt(temp)
            temp = R.mgt(temp*R.phi_2_rep % R.E)
        return self.__class__(R, temp, check=False)

    def conv_out(self):
        return self.parent().conv_out(self)

    def _integer_(self, Z=None):
        return self.parent().conv_out(self)


class PMNS(
    sage.rings.polynomial.polynomial_quotient_ring.PolynomialQuotientRing_domain,
):
    """
    A class used to represent a Polynomial Modular Number System.

    ...

    Attributes
    ----------
    VALID_MAT_RED_METHODS : set(str)
        Set of supported matrix reduction methods available to sage (LLL, BKZ, HKZ).
    mat_red_method : str
        Matrix reduction method used to generate a reduced basis of the lattice of representatives of zero within the PMNS and subsequent internal reduction parameters.
    delta : NN
        Number of additions of PMNS elements expected to occur before a multiplication and reduction of PMNS elements is performed.
    PolyRing : PolynomialRing
        Base ring of polynomial elements.
    p : NN
        An integer such that elements of the PMNS represent integers modulo p.
        Must be greater than or equal to 3.
    E : Expression
        The external reduction polynomial.
        Must be monic, irreducible and with degree greater or equal to 1.
        Must have at least one root modulo p.
    n : NN
        Degree of E. Number of coefficients of PMNS elements.
        Must be greater or equal to 1.
    gamma_list : list(ZZ.quo(p))
        List of roots of E modulo p.
    gamma : ZZ.quo(p)
        Root of E modulo p used for conversions in and out of the PMNS.
    rho : NN
        maximum infinite norm of PMNS elements.
    phi : NN
        Power of 2 which divides intermediate results during PMNS internal reduction.
    M : Matrix(ZZ)
        Internal reduction matrix M derived from M_poly.
    M_prime : Matrix(ZZ.quo(phi))
        Internal reduction matrix M_prime derived from M_prime_poly.
    tau : ZZ.quo(phi)
        phi^n modulo p.
    phi_2_rep : PMNS_elt
        PMNS representative of phi^2 modulo p.
    rho_phi_rep : PMNS_elt
        PMNS representative of rho*phi modulo p.
    rho_pow_rep_list : list(PMNS_elt)
        list of PMNS representatives of rho^i*phi^2 modulo p used for conversions into the PMNS.
    """

    VALID_MAT_RED_METHODS = {"LLL", "BKZ", "HKZ"}
    Element = PMNS_element
    PolyRing = PolynomialRing(ZZ, x)

    def _element_constructor_(self, *args, **kwds):
        mgt = True
        if "mgt" in kwds:
            mgt = kwds["mgt"]
        kwds = {i:kwds[i] for i in kwds if i!="mgt"}
        if len(args) == 1:
            temp = args[0]
            if isinstance(temp, PMNS_element):
                return temp
            elif isinstance(temp, Polynomial):
                temp = temp % self.E
                while (temp.norm(infinity) > self.rho):
                    temp = self.mgt(temp)
                    temp = self.mgt(temp * self.phi_2_rep % self.E)
                if mgt:
                    temp = self.mgt(temp * self.phi_2_rep % self.E)
                return self.element_class(self, temp, **kwds)
            elif isinstance(temp, Integer) or isinstance(temp, int):
                if not(mgt):
                    return self.element_class(self, self.mgt(self.conv(temp % self.p)), **kwds)
                return self.element_class(self, self.conv(temp % self.p), **kwds)
        return self.element_class(self, self.conv(*args), **kwds)

    def _coerce_map_from_(self, S):
        if S == ZZ:
            return True

    def __init__(self, p: NN, E: Expression, mat_red_method="LLL", delta=0, gamma=None, phi_word_width=None):
        """
        Parameters
        ----------
        p : NN
            An integer such that elements of the PMNS represent integers modulo p.
            Must be greater than or equal to 3.
        E : Expression
            The external reduction polynomial.
            Must be monic, irreducible and with degree greater or equal to 1.
            Must have at least one root modulo p.
        mat_red_method : str
            Matrix reduction method used to generate a reduced basis of the lattice of representatives of zero within the PMNS and subsequent internal reduction parameters.
        delta : NN
            Number of additions of PMNS elements expected to occur before a multiplication and reduction of PMNS elements is performed.
        phi_word_width : NN
            If set, phi will be chosen as a power of two whose binary width is (a multiple of phi_word_width)+1. This is meant to emulate internal reduction on computing hardware.
        """

        self.phi_word_width = phi_word_width

        (
            self.mat_red_method,
            self.delta,
            self.p,
            self.E,
            self.gamma_list,
        ) = self.check_params(p, E, mat_red_method, delta, gamma)

        self.n = self.E.degree()

        if gamma:
            self.gamma = gamma
        else:
            self.gamma = NN(self.gamma_list[0][0])

        (
            self.rho,
            self.phi,
            self.M,
            self.M_prime,
        ) = self.gen_internal_reduction_parameters()

        self.tau = self.phi**self.n % self.p

        (
            self.phi_rep,
            self.phi_2_rep,
            self.rho_phi_rep,
            self.rho_pow_rep_list,
        ) = self.gen_conversion_parameters()

        sage.rings.polynomial.polynomial_quotient_ring.PolynomialQuotientRing_domain.__init__(
            self, PolynomialRing(ZZ, x), self.E, x
        )

    @staticmethod
    def check_params(p, E, mat_red_method="LLL", delta=0, gamma=None):
        VALID_MAT_RED_METHODS = {"LLL", "BKZ", "HKZ"}
        if not (mat_red_method in VALID_MAT_RED_METHODS):
            raise ValueError(
                "mat_red_method is not supported (Valid matrix reduction methods : LLL, BKZ, HKZ). mat_red_method = {mat_red_method}".format(
                    mat_red_method=repr(mat_red_method)
                )
            )

        if not (delta in NN):
            raise TypeError(
                "delta must be a positive integer. delta = {delta}".format(
                    delta=repr(delta)
                )
            )

        if not (p in NN):
            raise TypeError(
                "p must be an integer greater than or equal to 3. p = {p}".format(
                    p=repr(p)
                )
            )
        if not (p >= 3):
            raise ValueError(
                "p must be an integer greater than or equal to 3. p = {p}".format(
                    p=repr(p)
                )
            )

        temp_E = PolynomialRing(ZZ, x)(E)

        if not (temp_E.is_monic()):
            raise ValueError("E must be monic. E = {E}".format(E=repr(E)))
        if not (temp_E.is_irreducible()):
            raise ValueError("E must be irreducible. E = {E}".format(E=repr(E)))
        if not (temp_E.degree() >= 1):
            raise ValueError(
                "E must have degree greater or equal to 1. E = {E}".format(E=repr(E))
            )

        gamma_list = PolynomialRing(ZZ.quo(p), x)(temp_E).roots()

        if len(gamma_list) == 0:
            raise ArithmeticError(
                "E has no root modulo p. E = {E}. p = {p}".format(E=repr(E), p=repr(p))
            )

        if gamma and not (gamma in gamma_list):
            raise ValueError(
                "Provided gamma is not a root of E modulo p. Leave out gamma parameter to automatically select a root if possible."
            )

        return mat_red_method, delta, p, temp_E, gamma_list

    def gen_internal_reduction_parameters(self):
        """
        Generates PMNS elements coefficient bounds parameters (rho, phi).
        Generates PMNS elements internal reduction parameters (M_poly, M_prime_poly, M, M_prime).
        """

        PolyRing = self.PolyRing

        E = self.E
        p = self.p
        n = self.n
        gamma = self.gamma

        zero_lattice_basis = Matrix(
            [
                [p, *[0 for j in range(n - 1)]],
                *[
                    [-(gamma**i) % p, *[1 if (j == i) else 0 for j in range(1, n)]]
                    for i in range(1, n)
                ],
            ]
        )
        zero_lattice = IntegerLattice(zero_lattice_basis)
        zero_lattice_reduced_basis = zero_lattice.basis_matrix()

        rho = 2 ** (ceil(log(2 * zero_lattice_reduced_basis.norm(1), 2)))

        E_prime_matrix = Matrix(
            [
                [
                    *map(lambda elt: abs(elt), coeff_list),
                    *[0 for _ in range(n - len(coeff_list))],
                ]
                for coeff_list in [
                    list(PolyRing(x**i) % E) for i in range(n, 2 * n - 1)
                ]
            ]
        )
        w = (
            vector(range(1, n + 1)) + vector(range(n - 1, 0, -1)) * E_prime_matrix
        ).norm(infinity)

        phi = 2 ** (ceil(log(2 * w * rho, 2)))
        
        
        if self.phi_word_width:
            phi = 2**(((len(bin(phi)[2:])-1)//self.phi_word_width+1)*self.phi_word_width)

        for i in range(1, 2**n - 1):
            M_poly = PolyRing(
                list(
                    zero_lattice.linear_combination_of_basis(
                        list(map(int, list(bin(i)[-1:1:-1])))
                    )
                )
            )
            M = Matrix([list(PolyRing(x**j) * M_poly % E) for j in range(n)])
            if det(M % 2) == 1:
                break

        M_prime_poly = PolyRing(
            list(
                map(
                    lambda t: t % phi,
                    PolynomialRing(QQ, "x").quo(E)(-M_poly).inverse_mod(E),
                )
            )
        )
        self.M_poly = M_poly
        self.M_prime_poly = M_prime_poly
        M_prime = Matrix([list(PolyRing(x**j) * M_prime_poly % E) for j in range(n)])

        return rho, phi, M, M_prime

    def mgt(self, a):
        """
        Performs internal reduction of PMNS element a.
        ----------
        Parameters
        ----------
        a : PolynomialRing(ZZ, x)
            Polynomial element of degree n to be reduced.
        """

        PolyRing = self.PolyRing
        n = self.n
        phi = self.phi
        M = self.M
        M_prime = self.M_prime

        vect = vector([*list(a), *(0 for i in range(n - len(list(a))))])
        Q = vect * M_prime % phi
        T = vect + Q * M
        S = T / phi
        return PolyRing([*S.list(), *(0 for i in range(n - len(S.list())))])

    def exact_conv(self, a):
        """
        Performs exact conversion of integer a to the PMNS. Used to generate representatives of powers of rho.
        ----------
        Parameters
        ----------
        a : ZZ.quo(p)
            Integer to be converted to the PMNS.
        """

        PolyRing = self.PolyRing

        p = self.p
        n = self.n
        tau = self.tau
        mgt = self.mgt

        alpha = (a * tau) % p
        RES = PolyRing(alpha)
        for i in range(n):
            RES = mgt(RES)
        return RES

    def conv(self, a):
        """
        Performs conversion of integer a to the PMNS once representatives of powers of rho have been generated.
        ----------
        Parameters
        ----------
        a : ZZ.quo(p)
            Integer to be converted to the PMNS.
        """

        PolyRing = self.PolyRing
        E = self.E
        n = self.n
        rho = self.rho
        rho_pow_rep_list = self.rho_pow_rep_list
        mgt = self.mgt

        temp = a
        RES = PolyRing(0)
        for i in range(n):
            RES += mgt(PolyRing(temp % rho) * rho_pow_rep_list[i] % E)
            temp = temp >> (ceil(log(rho, 2)))

        return RES

    def gen_conversion_parameters(self):
        """
        Generates conversion parameters phi_2_rep, rho_phi_rep, rho_pow_rep_list.
        """

        p = self.p
        n = self.n
        E = self.E
        rho = self.rho
        phi = self.phi
        mgt = self.mgt
        exact_conv = self.exact_conv

        phi_2_rep = exact_conv((phi**2) % p)
        phi_rep = self.mgt(phi_2_rep)
        rho_phi_rep = exact_conv(rho * phi % p)
        rho_pow_rep_list = [phi_2_rep]
        for i in range(n - 1):
            rho_pow_rep_list.append(mgt(rho_pow_rep_list[-1] * rho_phi_rep % E))

        return phi_rep, phi_2_rep, rho_phi_rep, rho_pow_rep_list

    def conv_out(self, elt):
        return elt.lift()(self.gamma) * inverse_mod(self.phi, self.p) % self.p
