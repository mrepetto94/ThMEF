set D_CITY; #declare the set of distribution center
set W_CITY; #declare the set of retail center
set R_CITY; #declare the set of recycling cente

set DW_LINKS within (D_CITY cross W_CITY); #declare the links distribution vs retail;
set WR_LINKS within (W_CITY cross R_CITY); #declare the links retail vs recycling
set WW_LINKS within (W_CITY cross W_CITY);

set WEIGHTS = 1..5;

param p_supply >= 0; #amount produced by the plant in Taipei
param w_demand {W_CITY} >= 0; #amount requred at the retail centers
param r_demand >= 0;
param we{WEIGHTS} >=0, <=1;

#check: p_supply = sum{j in W_CITY} w_demand[j]; #check that demand do not overflow supply
#check: sum{j in W_CITY} w_demand[j] = r_demand;

param pd_cost {D_CITY} >= 0; #shipment cost from plant to distribution
param dw_cost {DW_LINKS} >= 0; #shipment cost from distribution to retail
param wr_cost {WR_LINKS} >= 0; #shipment cost from retail to recycling
param rr_cost {R_CITY} >= 0; #shipment cost from recycling to plant

param pd_cap {D_CITY} >= 0; #capacities for each entity
param dw_cap {DW_LINKS} >= 0;
param wr_cap {WR_LINKS} >= 0;
param rr_cap {R_CITY} >= 0;
#cost parameters (node part)
param production_cost >= 0;
param distribution_cost{D_CITY} >= 0;
param retail_cost{W_CITY} >= 0;
param recycle_cost{R_CITY} >= 0;
param reuse_cost >= 0;
#recycling part
param return_coefficient{W_CITY} >= 0;

#Fuzzy membership function
param limit1 {R_CITY} > 0;
param goal {R_CITY} >= 0;

#Opportunity cost of not using the waste
param waste_cost >= 0;

#Goalprogramming deviational variables
var pd_pdcost{D_CITY} >= 0;
var pd_dwcost{DW_LINKS} >= 0;
var pd_wrcost{WR_LINKS} >= 0;
var pd_rrcost{R_CITY} >= 0;
var nd_fuzzy{R_CITY} >= 0;

var pd_production >= 0;
var pd_distribution{D_CITY} >= 0;
var pd_retail{W_CITY} >= 0;
var pd_recycle{R_CITY} >= 0;
var pd_reuse >= 0;

var pd_waste >= 0;

var waste >=0;

var nd_retail_demand{W_CITY} >=0;
#
var collected {W_CITY} >= 0; #variable indicating the collected units per retail

var mu{R_CITY} >= 0, <= 1;

var obj{WEIGHTS};	

minimize z: we[1] * sum {i in D_CITY} pd_pdcost[i] +
            we[1] * sum {(i,j) in DW_LINKS} pd_dwcost[i,j] +
            we[1] * sum {(i,j) in WR_LINKS} pd_wrcost[i,j] +
            we[1] * sum {i in R_CITY} pd_rrcost[i] +
            we[2] * pd_production +
            we[2] * sum {i in D_CITY} pd_distribution[i] +
            we[2] * sum {i in W_CITY} pd_retail[i] +
            we[2] * sum {i in R_CITY} pd_recycle[i] +
	    we[2] * pd_reuse +
	    we[3] * sum {i in R_CITY} nd_fuzzy[i] +
            we[4] * sum {i in W_CITY} nd_retail_demand[i] +
            we[5] * pd_waste;

node Plant: net_out = p_supply;
node Dist {i in D_CITY};
node Whse {j in W_CITY};
node Whse_collection {j in W_CITY}; #specific nodes for the collection
node Recy {k in R_CITY};
node Retu: net_in = r_demand + waste ;

arc PD_Ship {i in D_CITY} >= 0, <= pd_cap[i],
  from Plant, to Dist[i];

arc DW_Ship {(i,j) in DW_LINKS} >= 0,  <= dw_cap[i,j],
  from Dist[i], to Whse [j];

arc WW_Ship {(i,j) in WW_LINKS} >= 0,
  from Whse[i], to Whse_collection[i] return_coefficient[i];

arc WR_Ship {(i,j) in WR_LINKS} >= 0,  <= wr_cap[i,j],
  from Whse_collection[i], to Recy[j];

arc RR_Ship {i in R_CITY} >= 0,  <= rr_cap[i],
  from Recy[i], to Retu;

#Soft constraints of the arcs in the network
subject to pd_obj{i in D_CITY}: 
	PD_Ship[i]*pd_cost[i] - pd_pdcost[i] = 0;
subject to dw_obj{(i,j) in DW_LINKS}: 
	DW_Ship[i,j]*dw_cost[i,j] - pd_dwcost[i,j] = 0;
subject to wr_obj{(i,j) in WR_LINKS}: 
	WR_Ship[i,j]*wr_cost[i,j] - pd_wrcost[i,j] = 0;
subject to rr_obj{i in R_CITY}: 
	RR_Ship[i]*rr_cost[i] - pd_rrcost[i] = 0;
#Soft constraints of the node (operation costs)
subject to production: 
	p_supply * production_cost - pd_production = 0;
subject to distribution{i in D_CITY}: 
	PD_Ship[i] * distribution_cost[i] - pd_distribution[i] = 0;
subject to retail{j in W_CITY}: 
	sum {(i,j) in DW_LINKS} DW_Ship[i,j] * retail_cost[j] - pd_retail[j] = 0;
subject to recycle{j in R_CITY}: 
	sum {(i,j) in WR_LINKS} WR_Ship[i,j] * recycle_cost[j] - pd_recycle[j] = 0;
subject to reuse: 
	r_demand * reuse_cost - pd_reuse = 0;
#Soft constraint waste minimization
subject to wastecontroll: (RR_Ship["NOCO"] * waste_cost) - pd_waste = 0; 
#Collection variable (just for showing how many units are collected per retail)
subject to collection{j in W_CITY}: 
	sum {(i,j) in DW_LINKS} DW_Ship[i,j] * return_coefficient [j] - collected[j] = 0;

#Fuzzy goal programming part -not working-
subject to fuzzy_recy{j in R_CITY}: 
	sum {(i,j) in WR_LINKS} WR_Ship [i,j] + nd_fuzzy[j] >= goal[j];
subject to fuzzy_recy2{j in R_CITY}:
        sum {(i,j) in WR_LINKS} mu[j] + (nd_fuzzy[j]/limit1[j]) = 1;

subject to dw_obj_flow{j in W_CITY}:
	sum {(i,j) in DW_LINKS} DW_Ship[i,j] + nd_retail_demand[j] = w_demand[j];

#OBJECTIVE definition
subject to obj1: 
	sum {i in D_CITY} pd_pdcost[i]	+
	sum {(i,j) in DW_LINKS} pd_dwcost[i,j] +
	sum {(i,j) in WR_LINKS} pd_wrcost[i,j] +
	sum {i in R_CITY} pd_rrcost[i] = obj[1];
subject to obj2: 
	pd_production +
	sum {i in D_CITY} pd_distribution[i] +
        sum {i in W_CITY} pd_retail[i] +
        sum {i in R_CITY} pd_recycle[i] +
	pd_reuse = obj[2];
subject to obj3: 
	sum {i in R_CITY} nd_fuzzy[i] = obj[3];
subject to obj4: 
	sum {i in W_CITY} nd_retail_demand[i] = obj[4];
subject to obj5: 
	pd_waste = obj[5];
