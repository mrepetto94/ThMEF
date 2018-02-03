param n;
param m;

set J := {1..n};
set I := {1..m};

param A {I,J} >= 0;
param B {I} >= 0;

var X {J} >= 0;
var DP {I} >= 0;
# var dn {J} >= 0;

minimize z: sum {i in I} DP[i];

s.t. Constraint {i in I}:
	sum {j in J} A[i,j] * X[j] - DP[i] = B[i];
s.t. Ratio:
	sum {j in J} X[j] = 1;
