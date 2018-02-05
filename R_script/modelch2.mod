param n;
param m;

set J := {1..n};
set I := {1..m};

param ProcV {I,J} >= 0;
param ProcF {I,J} >= 0;
param K {I} >= 0;

var X {I,J} >= 0 integer;
var DP {I,J} >= 0;
var u{I,J} binary;

minimize z: sum {i in I, j in J} DP[i,j];

s.t. Inbound{i in I}:
	sum {j in J} ProcV[i,j] * X[i,j] - DP[i,1] = 0;

s.t. InboundF{i in I}:
	sum {j in J} ProcF[i,j] * u[i,j] - DP[i,2] = 0;

#Binarity condition and ratio
s.t. Binarity{i in I, j in J}:
	X[i,j] <= 99999 * u[i,j];

s.t. Ratio {i in I}:
	sum {j in J} X[i,j] = K[i];
