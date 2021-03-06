#
# Test functions
#

# verify min <= test < maxPlusOne
Function Test-Between {
    Param(
        [Parameter(Mandatory)][int]$min,
        [Parameter(Mandatory)][int]$test,
        [Parameter(Mandatory)][int]$maxPlusOne
    )

    If (($min -le $test) -and ($test -lt $maxPlusOne)) {
        # test passes
    } Else {
        Throw "$min <= $test < $maxPlusOne check fails";
    }
}
Export-ModuleMember -Function Test-Between;

# verify lhs = rhs
Function Test-Equal {
    Param(
        [Parameter(Mandatory)][int]$leftHandSide,
        [Parameter(Mandatory)][int]$rightHandSide
    )

    If ($leftHandSide -eq $rightHandSide) {
        # test passes
    } Else {
        Throw "$leftHandSide = $rightHandSide check fails";
    }
}
Export-ModuleMember -Function Test-Equal;

# verify test >= min
Function Test-GreaterThanOrEqual {
    Param(
        [Parameter(Mandatory)][int]$test,
        [Parameter(Mandatory)][int]$min
    )

    If ($test -ge $min) {
        # test passes
    } Else {
        Throw "$test >= $min check fails";
    }
}
Export-ModuleMember -Function Test-Between;

# verify a given number is prime
Function Test-Prime {
    Param(
        [Parameter(Mandatory)][int]$prime
    )

    If ($prime -ge 2) {
        For ($i = 2; $i * $i -le $prime; $i++) {
            If ($prime % $i -eq 0) {
                Throw "$prime is divisible by $i and so isn't prime";
            }
        }

        # check passes
    } Else {
        Throw "$prime is too small to be prime";
    }
}
Export-ModuleMember -Function Test-Prime;

# verify a given number is a generator of a given prime field
Function Test-Generator {
    Param(
        [Parameter(Mandatory)][int]$generator,
        [Parameter(Mandatory)][int]$prime
    )

    Test-Prime -prime $prime;
    Test-Between -min 1 -test $generator -maxPlusOne $prime;

    # g^0 = 1
    ($exponent, $power) = (0, 1);

    Do {
        $exponent++;
        $power = Get-ModularProduct -factor1 $power -factor2 $generator -modulus $prime;
    } While ($power -ne 1);

    If ($exponent -ne ($prime - 1)) {
        Throw "$generator^$exponent = 1 mod $prime so $generator is not a generator of GF($prime)";
    }
}
Export-ModuleMember -Function Test-Generator;

# Given two numbers, return the greatest common divisor of those numbers
Function Get-GreatestCommonDivisor {
    Param(
        [Parameter(Mandatory)][int]$term1,
        [Parameter(Mandatory)][int]$term2
    )

    $original_term1 = $term1;
    $original_term2 = $term2;

    Test-GreaterThanOrEqual -test $term1 -min 0;
    Test-GreaterThanOrEqual -test $term2 -min 0;

    # Use Stein's algorithm for finding the GCD using binary operations
    # https://en.wikipedia.org/wiki/Binary_GCD_algorithm

    # gcd(a, 0) = a
    If ($term2 -eq 0) {
        Return $term1;
    }

    # likewise gcd(0, b) = b
    If ($term1 -eq 0) {
        Return $term2;
    }

    # from this point, term1 and term2 are nonzero

    # count the number of common factors of two
    $commonFactorsOfTwo = 0;
    While ((($term1 -bor $term2) -band 1) -eq 0) {
        $commonFactorsOfTwo++;
        $term1 = ($term1 -shr 1);
        $term2 = ($term2 -shr 1);
    }

    # throw away any extra factors of two in term1
    While (($term1 -band 1) -eq 0) {
        # this loop terminates because term1 is nonzero
        # it doesn't affect the gcd because
        # either term2 is already odd
        # or the loop terminates immediately without doing anything
        $term1 = ($term1 -shr 1);
    }

    # from this point, term1 is odd
    Do {
        # throw away any factors of 2 in term2
        While (($term2 -band 1) -eq 0) {
            # this loop terminates because term2 is nonzero
            # it doesn't affect the gcd because term1 is odd
            $term2 = ($term2 -shr 1);
        }

        # term1 and term2 are both odd
        # swap them if necessary so term2 >= term1
        If ($term1 -gt $term2) {
            ($term1, $term2) = ($term2, $term1);
        }

        # term2 >= term1
        # subtract term1 from term2
        $term2 -= $term1;
    } While ($term2 -ne 0);

    $gcd = ($term1 -shl $commonFactorsOfTwo);

    # Test that gcd divides both of the original terms
    # TODO: external tests to verify that this is the GREATEST common denominator
    Test-Equal -leftHandSide 0 -rightHandSide ($original_term1 % $gcd);
    Test-Equal -leftHandSide 0 -rightHandSide ($original_term2 % $gcd);

    Return $gcd;
}

Export-ModuleMember -Function Get-GreatestCommonDivisor;

#
# Modular arithmetic
#

# Given two numbers x and y and a modulus m
# find the sum x + y mod m
Function Get-ModularSum {
    Param(
        [Parameter(Mandatory)][int]$term1,
        [Parameter(Mandatory)][int]$term2,
        [Parameter(Mandatory)][int]$modulus
    )

    Test-Between -min 0 -test $term1 -maxPlusOne $modulus;
    Test-Between -min 0 -test $term2 -maxPlusOne $modulus;

    $sum = $term1 + $term2;

    If ($sum -ge $modulus) {
        $sum -= $modulus;
    }

    Test-Between -min 0 -test $sum -maxPlusOne $modulus;

    Return $sum;
}
Export-ModuleMember -Function Get-ModularSum;

# Given a number x and a modulus m
# find the number y such that x + y = 0 mod m
Function Get-ModularNegative {
    Param(
        [Parameter(Mandatory)][int]$term,
        [Parameter(Mandatory)][int]$modulus
    )

    Test-Between -min 0 -test $term -maxPlusOne $modulus;

    If ($term -eq 0) {
        $negative = 0;
    } Else {
        $negative = $modulus - $term;
    }

    Test-Between -min 0 -test $negative -maxPlusOne $modulus;
    Test-Equal `
        -leftHandSide 0 `
        -rightHandSide (Get-ModularSum -term1 $term -term2 $negative -modulus $modulus);

    Return $negative;
}
Export-ModuleMember -Function Get-ModularNegative;

# Given two numbers x and y and a modulus m
# find the difference x - y mod m
Function Get-ModularDifference {
    Param(
        [Parameter(Mandatory)][int]$minuend,
        [Parameter(Mandatory)][int]$subtrahend,
        [Parameter(Mandatory)][int]$modulus
    )

    Test-Between -min 0 -test $minuend -maxPlusOne $modulus;
    Test-Between -min 0 -test $subtrahend -maxPlusOne $modulus;

    $difference = Get-ModularSum `
        -term1 $minuend `
        -term2 (Get-ModularNegative -term $subtrahend -modulus $modulus) `
        -modulus $modulus;

    Test-Between -min 0 -test $difference -maxPlusOne $modulus;
    Test-Equal `
        -leftHandSide $minuend `
        -rightHandSide (Get-ModularSum -term1 $subtrahend -term2 $difference -modulus $modulus);

    Return $difference;
}
Export-ModuleMember -Function Get-ModularDifference;

# Given two numbers x and y and a modulus m
# find the product x * y mod m
Function Get-ModularProduct {
    Param(
        [Parameter(Mandatory)][int]$factor1,
        [Parameter(Mandatory)][int]$factor2,
        [Parameter(Mandatory)][int]$modulus
    )

    Test-Between -min 0 -test $factor1 -maxPlusOne $modulus;
    Test-Between -min 0 -test $factor2 -maxPlusOne $modulus;

    $product = ($factor1 * $factor2) % $modulus;

    Test-Between -min 0 -test $product -maxPlusOne $modulus;

    Return $product;
}
Export-ModuleMember -Function Get-ModularProduct;

# Given a number x and a modulus m,
# find the number y such that x * y = 1 mod m
Function Get-ModularInverse {
    Param(
        [Parameter(Mandatory)][int]$term,
        [Parameter(Mandatory)][int]$modulus
    )

    Test-Between -min 0 -test $term -maxPlusOne $modulus;

    # a necessary and sufficient condition for the inverse to exist
    # is that GCD(x, m) = 1
    Test-Equal -leftHandSide 1 -rightHandSide (Get-GreatestCommonDivisor -term1 $term -term2 $modulus);

    # use the extended Euclidean algorithm to find the inverse
    # https://en.wikipedia.org/wiki/Extended_Euclidean_algorithm
    #
    # ma + xy = 1 mod m
    # reducing mod m we find xy = 1 mod m
    ([int]$t, [int]$t_new) = (0, 1);
    ([int]$r, [int]$r_new) = ($modulus, $term);

    While ($r_new -ne 0) {
        $quotient = [Math]::Floor($r / $r_new);
        ($t, $t_new) = ($t_new, ($t - ($quotient * $t_new)));
        ($r, $r_new) = ($r_new, ($r - ($quotient * $r_new)));
    }

    # If this doesn't hold there is no inverse
    Test-Equal -leftHandSide 1 -rightHandSide $r;

    # Make the answer positive if necessary
    If ($t -lt 0) {
        $t += $modulus;
    }

    $inverse = $t;
    Test-Between -min 0 -test $inverse -maxPlusOne $modulus;

    Test-Equal `
        -leftHandSide 1 `
        -rightHandSide (Get-ModularProduct -factor1 $term -factor2 $inverse -modulus $modulus);

    Return $inverse;
}
Export-ModuleMember -Function Get-ModularInverse;

# Given two numbers x and y and a modulus m
# find the quotient z such that x = y * z mod m
Function Get-ModularQuotient {
    Param(
        [Parameter(Mandatory)][int]$numerator,
        [Parameter(Mandatory)][int]$denominator,
        [Parameter(Mandatory)][int]$modulus
    )

    Test-Between -min 0 -test $numerator -maxPlusOne $modulus;
    Test-Between -min 0 -test $denominator -maxPlusOne $modulus;

    $quotient = Get-ModularProduct `
        -factor1 $numerator `
        -factor2 (Get-ModularInverse -term $denominator -modulus $modulus) `
        -modulus $modulus;

    Test-Between -min 0 -test $quotient -maxPlusOne $modulus;

    Test-Equal `
        -leftHandSide $numerator `
        -rightHandSide (Get-ModularProduct -factor1 $denominator -factor2 $quotient -modulus $modulus);

    Return $quotient;
}
Export-ModuleMember -Function Get-ModularQuotient;

# Given two numbers x and y and a modulus m
# find the power x ^ y mod m
Function Get-ModularPower {
    Param(
        [Parameter(Mandatory)][int]$base,
        [Parameter(Mandatory)][int]$exponent,
        [Parameter(Mandatory)][int]$modulus
    )

    Test-Between -min 0 -test $numerator -maxPlusOne $modulus;
    Test-Between -min 0 -test $denominator -maxPlusOne $modulus;

    $power = 1;
    $base_2_k = $base;

    # consider y as a binary number
    # this decomposes the power into a product of x^(powers of 2)
    # e.g. x^9 = x^1001_b = x^8 x^1
    While ($exponent -ne 0) {
        # if the kth bit of y is 1, multiply the answer so far by x^(2^k)
        If (($exponent -band 1) -eq 1) {
            $power = Get-ModularProduct -factor1 $power -factor2 $base_2_k -modulus $modulus;
        }

        $exponent = ($exponent -shr 1);
        $base_2_k = Get-ModularProduct -factor1 $base_2_k -factor2 $base_2_k -modulus $modulus;
    }

    Test-Between -min 0 -test $power -maxPlusOne $modulus;

    Return $power;
}
Export-ModuleMember -Function Get-ModularPower;
