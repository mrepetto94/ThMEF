   set ORIG;   # origins
   set DEST;   # destinations

	 param demand {DEST} >= 0;   # amounts required at destinations
	 param K;
	 param cost {ORIG,DEST} >= 0;   # shipment costs per unit
	 param ProcV {ORIG} >= 0;
	 param ProcF {ORIG} >= 0;

	 check: K <= sum {j in DEST} demand[j];

	 var supply {ORIG} >= 0;   # amounts available at origins
	 var Trans {ORIG,DEST} >= 0;    # units to be shipped
	 var Dev >= 0; #transportation deviational variable
	 var Devp >= 0;
	 var u{ORIG} binary; # unit variable

	 minimize Total_Deviation:
	 		Devp + Dev;

	 s.t. Inbound:
			sum {i in ORIG} ProcV[i] * supply[i] + sum {i in ORIG} ProcF[i] * u[i] - Devp = 0;
	 s.t. Transport:
			sum {i in ORIG, j in DEST} cost[i,j] * Trans[i,j] - Dev = 0;
   s.t. Supply {i in ORIG}:
      sum {j in DEST} Trans[i,j] = supply[i];
   s.t. Demand {j in DEST}:
      sum {i in ORIG} Trans[i,j] <= demand[j];
	 s.t. Allocation:
	 		sum {i in ORIG} supply[i]= K;

	 s.t. Binarity{i in ORIG}:
			supply[i] <= 99999 * u[i];
