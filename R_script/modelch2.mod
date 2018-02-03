#Variables
var x_1 >= 0;
var x_2 >= 0;
var dp_1 >= 0;
var dn_1 >= 0;

#Model
minimize z: dp_1;

#Constraints
subject to tax: x_1*0.10 + x_2*0.20 - dp_1 = 0;
#Hard constraints
subject to ratio: x_1 + x_2 = 1i:;
