export {
    testGFpromote
    }

debug Core

fieldsFLINT = {
    "ZZpFlint 2",
    "ZZpFlint 5",
    "ZZpFlint 101",
    "ZZpFlint 4611686018427387847",
    "ZZpFlint 9223372036854775783"
    }
fieldsFFPACK = {
    "ZZpFFPACK 2",
    "ZZpFFPACK 3",
    "ZZpFFPACK 5",
    "ZZpFFPACK 101",
    "ZZpFFPACK 30000001",
    "ZZpFFPACK maxFFPACKPrime"
    }
fieldsGF = {
    "GF(3,2)",
    "GF(5,12)",
    ///GF(3,2, Strategy=>"New")///,
    ///GF(2,7, Strategy=>"New")///,
    ///GF(3,2, Strategy=>"Givaro")///,
    ///GF(2,7, Strategy=>"Givaro")///,
    ///GF(3,2, Strategy=>"CompleteGivaro")///,
    ///GF(2,7, Strategy=>"CompleteGivaro")///
    }

testFiniteField = (R, charac) -> (
    assert(rawCharacteristic R === charac)
    )

allElements = (p,d,A) -> (
    if d == 0 then for i from 0 to p-1 list i_A
    else (
        elems := allElements(p,d-1,A);
        flatten for f in elems list for i from 0 to p-1 list (f + i*A_0^d)
        )
    )

testGF1 = (p,d,kk) -> (
   A := ambient kk;
   --rawARingGFPolynomial raw kk;
   --rawARingGFGenerator raw kk;
   --rawARingGFCoefficients raw (kk_0^5);
   time elems := allElements(p,d-1,A); -- creating them over the finite field would be faster...
   << "fraction of unique hash vals: " << ((elems/(f -> hash raw f)//unique//length) / (#elems * 1.0)) << endl;
   time elems1 := elems/(f -> promote(f,kk));
   time elems2 := elems1/(f -> lift(f,A)); -- this one is slow for 2^13
   time elems3 := elems2/(f -> promote(f,kk));
   time assert(elems3 == elems1);
   time assert(elems2 == elems);
   time assert(# unique elems == p^d); -- this one is very slow for 2^13
   time assert(# unique elems1 == p^d);
   time m1 := promote(matrix{elems}, kk);
   time m2 := lift(m1, A);
   m1
   )

testGFpromote = (p,d,strategy) -> (
   kk := GF(p^d, Strategy=>strategy);
   testGF1(p,d,kk)
   )
TEST ///
  -- the following should all give errors.
  assert try (ZZpFlint 1; false) else true
  assert try (ZZpFFPACK 1; false) else true
  assert try (ZZp(1, Strategy=>null); false) else true
  assert try (ZZp(1, Strategy=>"ARing"); false) else true
///

debug Core
testGF2 = (p,d,kk) -> (
    << rawARingGFPolynomial raw kk << endl; -- an array
    << rawARingGFGenerator raw kk << endl; -- in kk
    << rawARingGFCoefficients raw (kk_0^5) << endl; -- an array
    << netList(for i from 0 to p^d-1 list {kk_0^i, rawARingGFCoefficients raw (kk_0^i)}) << endl;
    )
TEST ///
    debug Core
    kk = GF(9, Strategy=>"Givaro")
    --testGF2(3,2,kk)
    assert(rawARingGFPolynomial raw kk == {2,2,1})
    assert((new kk from rawARingGFGenerator raw kk) == kk_0)
    (p,d) = (3,2)
    reps = for i from 0 to 8 list rawARingGFCoefficients raw (kk_0^i)
    assert(reps == {{1, 0}, {0, 1}, {1, 1}, {1, 2}, 
            {2, 0}, {0, 2}, {2, 2}, {2, 1}, {1, 0}})
///

TEST ///
    debug Core
    kk = GF(32, Strategy=>"Givaro")
    --testGF2(2,5,kk)
    assert(rawARingGFPolynomial raw kk == {1, 0, 1, 0, 0, 1})
    assert((new kk from rawARingGFGenerator raw kk) == kk_0)
    (p,d) = (2,5)
    reps = for i from 0 to 31 list rawARingGFCoefficients raw (kk_0^i)
    assert(reps == 
        {{1, 0, 0, 0, 0}, {0, 1, 0, 0, 0}, {0, 0, 1, 0, 0}, {0, 0, 0, 1, 0},
         {0, 0, 0, 0, 1}, {1, 0, 1, 0, 0}, {0, 1, 0, 1, 0}, {0, 0, 1, 0, 1},
         {1, 0, 1, 1, 0}, {0, 1, 0, 1, 1}, {1, 0, 0, 0, 1}, {1, 1, 1, 0, 0},
         {0, 1, 1, 1, 0}, {0, 0, 1, 1, 1}, {1, 0, 1, 1, 1}, {1, 1, 1, 1, 1},
         {1, 1, 0, 1, 1}, {1, 1, 0, 0, 1}, {1, 1, 0, 0, 0}, {0, 1, 1, 0, 0},
         {0, 0, 1, 1, 0}, {0, 0, 0, 1, 1}, {1, 0, 1, 0, 1}, {1, 1, 1, 1, 0},
         {0, 1, 1, 1, 1}, {1, 0, 0, 1, 1}, {1, 1, 1, 0, 1}, {1, 1, 0, 1, 0},
         {0, 1, 1, 0, 1}, {1, 0, 0, 1, 0}, {0, 1, 0, 0, 1}, {1, 0, 0, 0, 0}})
///

TEST ///
  {*
    restart
    loadPackage "EngineTests"
  *}
  debug Core
  -- test that around 2^32, flint rings are created correctly, with correct charac.
  primes = for i from -10000 to 10000 list if isPrime (2^32+i) then 2^32+i else continue;
  badprimes = for p in primes list (
    if p != rawCharacteristic raw ZZpFlint p then p else continue
    )
  assert(badprimes === {})
  badprimes = for p in primes list (
    if p != char ZZpFlint p then p else continue
    )
  assert(badprimes === {})
///


TEST ///
  -- Factorization over these finite fields
  debug Core
  R = ZZp(101, Strategy=>"ARING")
  S = R[x]
  F = (x-3)^3*(x^2+x+1)
  factor F 

  R = ZZp(101)  
  S = R[x]  -- display here is messed up
  F = (x-3)^3*(x^2+x+1)
  factor F

  R = ZZ/101
  S = R[x]
  F = (x-3)^3*(x^2+x+1)
  factor F

  R = ZZp(101, Strategy=>"FLINT")
  S = R[x]
  F = (x-3)^3*(x^2+x+1)
  factor F  

  R = ZZp(101, Strategy=>"FFPACK")
  S = R[x]
  F = (x-3)^3*(x^2+x+1)
  factor F  

  R = ZZp(65537, Strategy=>"FLINT")
  S = R[x]
  F = (x-3)^3*(x^2+x+1)
  factor F  

  R = ZZp(536870909, Strategy=>"FLINT")  -- max prime that factory can handle is 2^29-3.
  S = R[x]
  F = (x-3)^3*(x^2+x+1)
  factor F  

  R = ZZp(33554393, Strategy=>"FFPACK") -- max prime that ffpack can handle is 2^25 - 39
  S = R[x]
  F = (x-3)^3*(x^2+x+1)
  factor F  
///

TEST ///
  -- Switch between these rings.
  debug Core -- for ZZp
  R1 = ZZ/101
  R2 = ZZp(101, Strategy=>"ARING")
  R3 = ZZp(101)  
  R4 = ZZp(101, Strategy=>"FLINT")
  R5 = ZZp(101, Strategy=>"FFPACK")
  M1 = matrix(R1, {{0..103}})
  Rs = {R1,R2,R3,R4,R5}
  fs = apply(subsets(Rs,2), rs -> {map(rs#0, rs#1), map(rs#1, rs#0)})
  for rs in fs do (
      f := rs#0;
      g := rs#1;
      M1 = matrix(source f, {{0..103}});
      M2 = matrix(target f, {{0..103}});
      N1 = mutableMatrix M1;
      N2 = mutableMatrix M2;
      assert(f M1 == M2);
      assert(g M2 == M1);
      --assert(f N1 == N2); -- these are not defined yet!
      --assert(g N2 == N1); -- these are not defined yet!
      )
  -- now try it for some larger sizes
  P = 2^25-39 -- largest ffpack prime
  S1 = ZZp(P, Strategy=>"FLINT")
  S2 = ZZp(P, Strategy=>"FFPACK")
  (f,g) = (map(S1,S2), map(S2,S1))
  M1 = matrix(S1, {{-100..100, 2^25..2^25 + 10000}});
  M2 = matrix(S2, {{-100..100, 2^25..2^25 + 10000}});
  assert(f M2 == M1)
  assert(f M2 == M1)
///

///
  -- This is more of a benchmark code, than a test...
  debug Core
  R1 = ZZ/101
  R2 = ZZp(101, Strategy=>"ARING")
  R3 = ZZp(101)  
  R4 = ZZp(101, Strategy=>"FLINT")
  R5 = ZZp(101, Strategy=>"FFPACK")

  S1 = R1[vars(0..4)]  
  S2 = R2 (monoid S1)
  S3 = R3 (monoid S1)
  S4 = R4 (monoid S1)
  S5 = R5 (monoid S1)
  
  I = ideal random(S1^1, S1^{-5,-5,-5,-7});
  I = ideal I_*;
  time gens gb I;
  
  I2 = (map(S2,S1)) I;
  time gens gb I2;

  I3 = (map(S3,S1)) I;
  time gens gb I3;

  I4 = (map(S4,S1)) I;
  time gens gb I4;

  I5 = (map(S5,S1)) I;
  time gens gb I5;

  -- how about mutable matrix multiplication?
  Ma = mutableMatrix(R1, 1000, 1000); fillMatrix Ma;
  Mb = mutableMatrix(R1, 1000, 1000); fillMatrix Mb;
  
  time Mc = Ma*Mb;

  Ma2 = mutableMatrix sub(matrix Ma, R2);
  Mb2 = mutableMatrix sub(matrix Mb, R2);
  time Mc2 = Ma2*Mb2;  

  assert(matrix Mc == sub(matrix Mc2, R1))  
  
  Ma4 = mutableMatrix sub(matrix Ma, R4);
  Mb4 = mutableMatrix sub(matrix Mb, R4);
  time Mc4 = Ma4*Mb4;   -- MUCH faster
  assert(matrix Mc == sub(matrix Mc4, R1))  

  Ma5 = mutableMatrix sub(matrix Ma, R5);
  Mb5 = mutableMatrix sub(matrix Mb, R5);
  time Mc5 = Ma5*Mb5;   -- MUCH faster and it is faster than flint
  assert(matrix Mc == sub(matrix Mc5, R1))  

  time det Ma;
  time det Ma4;
  time det Ma5;
  
  time LUdecomposition Ma;
  time LUdecomposition Ma2;
  time LUdecomposition Ma4;
  time LUdecomposition Ma5;
///

///
  restart
  debug Core
  R = ZZ/5[a]
  new R from rawFindConwayPolynomial(5,2,raw R,false)
  new R from rawFindConwayPolynomial(5,3,raw R,false)
  new R from rawFindConwayPolynomial(5,30,raw R,false)
  rawFindConwayPolynomial(5,20,raw R,true)
  rawFindConwayPolynomial(5,32,raw R,false)
    rawFindConwayPolynomial(5,32,raw R,true)
  ambient GF 125
  for i from 2 to 40 list new R from rawFindConwayPolynomial(5,i,raw R,true) -- crashes!
  for i from 2 to 40 list {i, new R from rawFindConwayPolynomial(5,i,raw R,true)}
  
  for i from 2 to 10 list {i, new R from rawFindConwayPolynomial(5,i,raw R,false)}
  
  for i from 2 to 10 list {i, rawConwayPolynomial(5,i,false)}  
///

TEST ///
  kk = GF 9
  A = kk[x]
  factor(x^9-x)
  factor(x^2-a)
  factor(x^3-x)
  factor(x^4-a)
  F = x^81-x
  facs = factor F
  facs = facs//toList/toList
  assert(#facs == 45)
  assert(all(facs, f -> last f == 1))
  assert(product(facs/first) == F)
  F1 = x^2 - a*x + 1
  F2 = x^2+x-a-1
  G = F1*F2
  facs = factor G
  assert(facs//toList/toList/first//set  === set{F1,F2})
  
  -- test gcd over GF
  F1 = (x-a)^3*(x-a^2)
  F2 = (x-a)*(x-a^3)
  assert(gcd(F1,F2) == x-a)
///  

TEST ///
  debug Core
  kk = GF(9, Strategy=>"New")
  A = kk[x]
  factor(x^9-x)
  factor(x^2-a)
  factor(x^3-x)
  factor(x^4-a)
  F = x^81-x
  facs = factor F
  facs = facs//toList/toList
  assert(#facs == 45)
  assert(all(facs, f -> last f == 1))
  assert(product(facs/first) == F)
  F1 = x^2 - a*x + 1
  F2 = x^2+x-a-1
  G = F1*F2
  facs = factor G
  assert(facs//toList/toList/first//set  === set{F1,F2})
  
  -- test gcd over GF
  F1 = (x-a)^3*(x-a^2)
  F2 = (x-a)*(x-a^3)
  assert(gcd(F1,F2) == x-a)
///  

TEST ///
  -- test of lift/promote for all galois fields which use tables
  -- testGFpromote enumerates all elements, so only use on smaller size...
  topval = 10;  -- 13, although better, makes this too long
  for i from 1 to topval do (<< i << " "; testGFpromote(2,i,"New"))
  for i from 1 to topval do (<< i << " "; testGFpromote(2,i,null))
  for i from 1 to topval do (<< i << " "; testGFpromote(2,i,"Givaro"))
  for i from 1 to topval do (<< i << " "; testGFpromote(2,i,"FlintBig"))  

  topval = 6 -- 8 would be better
  time for i from 1 to topval do (<< i << " "; testGFpromote(3,i,"New"))
  time for i from 1 to topval do (<< i << " " << flush; testGFpromote(3,i,null))  
  time for i from 1 to topval do (<< i << " " << flush; testGFpromote(3,i,"Givaro"))  
  time for i from 1 to topval do (<< i << " " << flush; testGFpromote(3,i,"FlintBig"))  

  time for i from 1 to 5 do (<< i << " " << flush; testGFpromote(5,i,"New"))
  time for i from 1 to 5 do (<< i << " " << flush; testGFpromote(5,i,null))  
  time for i from 1 to 5 do (<< i << " " << flush; testGFpromote(5,i,"Givaro"))  
  time for i from 1 to 5 do (<< i << " " << flush; testGFpromote(5,i,"FlintBig"))  
  
  --time for i from 1 to 4 do (<< i << " " << flush; testGFpromote(7,i,"New"))
  --time for i from 1 to 4 do (<< i << " " << flush; testGFpromote(7,i,null))  
  --time for i from 1 to 4 do (<< i << " " << flush; testGFpromote(7,i,"Givaro"))  
  time for i from 1 to 4 do (<< i << " " << flush; testGFpromote(7,i,"FlintBig"))  
  
  time for i from 1 to 3 do (<< i << " " << flush; testGFpromote(11,i,"New"))
  time for i from 1 to 3 do (<< i << " " << flush; testGFpromote(11,i,null))  
  time for i from 1 to 3 do (<< i << " " << flush; testGFpromote(11,i,"Givaro"))  
  time for i from 1 to 3 do (<< i << " " << flush; testGFpromote(11,i,"FlintBig"))  
  
  --time for i from 1 to 3 do (<< i << " " << flush; testGFpromote(13,i,"New"))
  --time for i from 1 to 3 do (<< i << " " << flush; testGFpromote(13,i,null))  
  --time for i from 1 to 3 do (<< i << " " << flush; testGFpromote(13,i,"Givaro"))  
  time for i from 1 to 3 do (<< i << " " << flush; testGFpromote(13,i,"FlintBig"))  

  --time for i from 1 to 3 do (<< i << " " << flush; testGFpromote(17,i,"New"))
  --time for i from 1 to 3 do (<< i << " " << flush; testGFpromote(17,i,null))  
  --time for i from 1 to 3 do (<< i << " " << flush; testGFpromote(17,i,"Givaro"))  
  time for i from 1 to 3 do (<< i << " " << flush; testGFpromote(17,i,"FlintBig"))  
  
  --time for i from 1 to 3 do (<< i << " " << flush; testGFpromote(19,i,"New"))
  --time for i from 1 to 3 do (<< i << " " << flush; testGFpromote(19,i,null))  
  --time for i from 1 to 3 do (<< i << " " << flush; testGFpromote(19,i,"Givaro"))  
  time for i from 1 to 3 do (<< i << " " << flush; testGFpromote(19,i,"FlintBig"))  
  
  for p from 80 to 100 do if isPrime p then (
      << "doing " << p << endl;
      time for i from 1 to 2 do (<< i << " " << flush; testGFpromote(p,i,"New"));
      time for i from 1 to 2 do (<< i << " " << flush; testGFpromote(p,i,null))  ;
      time for i from 1 to 2 do (<< i << " " << flush; testGFpromote(p,i,"Givaro"));
      time for i from 1 to 2 do (<< i << " " << flush; testGFpromote(p,i,"FlintBig"));
      )
///

TEST ///
  debug Core
  kk = GF(9, Strategy=>"Givaro")
  A = kk[x]
  factor(x^9-x)
  factor(x^2-a)
  factor(x^3-x)
  factor(x^4-a)
  F = x^81-x
  facs = factor F
  facs = facs//toList/toList
  assert(#facs == 45)
  assert(all(facs, f -> last f == 1))
  assert(product(facs/first) == F)
  F1 = x^2 - a*x + 1
  F2 = x^2+x-a-1
  G = F1*F2
  facs = factor G
  assert(facs//toList/toList/first//set  === set{F1,F2})
  
  -- test gcd over GF
  F1 = (x-a)^3*(x-a^2)
  F2 = (x-a)*(x-a^3)
  assert(gcd(F1,F2) == x-a)
///  
  
///
  B = ZZ/5[x,y]
  I = ideal(x^3-x-1, y^2-y-1)
  H = resultant(I_1, sub(I_0, {x => x+y}), y)
  factor H

  debug Core  
  kk = ZZ/3
  R = kk[x,y,a]
  rawFactor(raw(x^80-y^80), raw(a^2-a-1))
  rawFactor(raw(x^80-1), raw(a^2-a-1))
  rawFactor(raw(x^9-x), raw(a^2-a-1))

  debug Core  
  kk = QQ
  R = kk[x,y,a]
  rawFactor(raw(x^2-3*y^2), raw(a^2-3))
  rawFactor(raw(x^80-1), raw(a^2-a-1))
  rawFactor(raw(x^9-x), raw(a^2-a-1))

  debug Core
  kk = ZZ/3
  R = kk[x,y,a]
  F = a^2-a-1
  F1 = (x-a)^3*(x-a^2) % F
  F2 = (x-a)*(x-a^3) % F
  new R from rawGCD(raw F1,raw F2,raw F)
///

///
  restart
  kk = GF(101,5)
  kk = GF(101,5,Strategy=>"FFPACK")
  R = kk[x]
  R1 = ZZ/101[x,a]
  facs = first rawFactor(raw(x^5-a^5), raw(a^5+2*a-2))
  assert(#facs == 5)
  x^5-a^5 == new R1 from times facs 
  factor(x-a)
  kk
  debug Core
  raw kk
///

///
  -- test of primitive elements vs generators of the poly ring
  kk = GF(2,4)
  ambient kk
  elems = for i from 0 to 15 list kk_0^i
  assert(# unique elems == 15)
  -- what is the order of each of these elements?
  ord = (a) -> (if a == 1 then 0 else for i from 1 do if a^i == 1 then return i)
  elems/ord
  select(elems, f -> f != 1 and ord f != 15)
  f = a^3  
  f^2
  f^3
  f^4 + f^3 + f^2 + f + 1
  ZZ/2[x]
  F = x^4 + x^3 + x^2 + x + 1
  A = (ring F)/F
  kk = GF(A, Strategy=>"New")
  kk_0
  kk_0^5 -- order 5
  testGF1(2,4,kk)
  kk = GF(A, Strategy=>"Givaro") -- this gives an error, but it is not a good one.
///

///
  kk = GF(9, Strategy=>"New")
  kk = GF(9, Strategy=>"Givaro")
  testGF1(3,2,kk)
///

///  
  restart
  debug loadPackage "EngineTests"
  kk = GF(9, Strategy=>"FlintBig") -- crashes
  testGF1(3,2,kk)
///

///
  -- how good are the random numbers:
  debug loadPackage "EngineTests"
  kk = GF(9, Strategy=>"FlintBig") -- crashes
  m = mutableMatrix(kk, 100, 100);
  fillMatrix m;
  L = flatten entries m;
  tally L
  tally for i from 1 to 10000 list random kk -- much better random behavior...
///

///
  -- how good are the random numbers.  Let's try it for 2^16
  debug loadPackage "EngineTests"
  kk = GF(2, 16, Strategy=>"FlintBig") -- crashes
  m = mutableMatrix(kk, 100, 100);
  fillMatrix m;
  L = flatten entries m;
  tally L;
  tally for i from 1 to 10000 list random kk -- much better random behavior...
///

///
  R = ZZ/101[a..d]
  time L = for i from 1 to 100000 list random(2,R);  
  time L = for i from 1 to  50000 list random(2,R);  
  debug Core
  L/(x -> hash raw x)//unique//length
  length unique L -- *really* slow on 1.6.  Instantaneous (.05 sec) on linalg branch, 23 May 2014.
  incr1 = 463633
  incr2 = 7858565
  seed1 = 103
  seed2 = 347654
  hash raw a
  hash raw (a^2) - hash raw a
  
  restart
  R = ZZ/101[a..d]
  a
  -a
  -o2
  f = a+b
  f-b
  -f   -- 3 (double) calls to hash
  new HashTable from {a=>b}
  hash oo
  {a,b}
  {a+b}
  hash raw first oo

  L = flatten entries basis(0,7,R)    
  L/(f -> hash raw f)
  oo//unique//length
  #L
  partition(f -> hash raw f, L)
///
