/*********************************************
 * OPL 12.6.2.0 Model
 * Author: DELL
 * Creation Date: May 11, 2021 at 10:07:11 AM
 *********************************************/
/*********************************************
 * OPL 12.6.2.0 Model
 * Author: DELL
 * Creation Date: Jul 8, 2021 at 9:15:45 AM
 *********************************************/
 
 /******The code is testing with 5 retailers*/
int NumberOfVehicle=4;
int NumberOfRetailer=5;
int NumberOfTrip=NumberOfRetailer;
range Trip=1..NumberOfTrip;
range Vehicle=1..NumberOfVehicle;
range RetailerD=0..NumberOfRetailer;
range RetailerOnly=1..NumberOfRetailer;
range RetailerExtra=0..NumberOfRetailer+1; //Depot + out
range RetailerOut=1..NumberOfRetailer+1;


float nb1[0..NumberOfRetailer+1, 1..NumberOfVehicle*(NumberOfRetailer+2)] = ...;
float Vcost[p in Vehicle, m in RetailerExtra ,s in RetailerExtra] = nb1[m,s+1+(NumberOfRetailer+2)*(p-1)];
float nb2[0..NumberOfRetailer+1, 1..NumberOfVehicle*(NumberOfRetailer+2)] = ...;
float Pcost[p in Vehicle, m in RetailerExtra ,s in RetailerExtra] = nb2[m,s+1+(NumberOfRetailer+2)*(p-1)];
float nb3[0..NumberOfRetailer+1, 1..NumberOfVehicle*(NumberOfRetailer+2)]=...;
float TravelTime[p in Vehicle, m in RetailerExtra ,s in RetailerExtra] = nb3[m,s+1+(NumberOfRetailer+2)*(p-1)];
float nb4[0..NumberOfRetailer+1, 1..NumberOfVehicle*(NumberOfRetailer+2)]=...;
float Scost[p in Vehicle, m in RetailerExtra ,s in RetailerExtra] = nb4[m,s+1+(NumberOfRetailer+2)*(p-1)];
{int} Depot={0};
{int} TripSt={1};

int M=1000000;
 execute Setting {
 cplex.epagap=0.001;
 cplex.tilim =10*60;
}

int E[RetailerOnly]=...;
int L[RetailerOnly]=...;
float S[RetailerExtra]=...;// time of service of customer i by vehicle k
int bcost[RetailerOnly]=...; //unit cost of unsastisfied demand for dth retailer
int Demand[RetailerExtra]=...; // Total demand for dth retailer;
int Q[Vehicle]=...;
int VehicleCost[Vehicle]=...;
float CostEarly[Vehicle][RetailerOnly]=[[0.5,0.5,0.5,0.5,0.5],[0.3,0.3,0.3,0.3,0.3],[0.2,0.2,0.2,0.2,0.2],[0.2,0.2,0.2,0.2,0.2]];
float CostLate[RetailerOnly]=...;

//decision variable
dvar boolean z[Vehicle];//if vehicle used
dvar boolean v[Vehicle][Trip][RetailerExtra][RetailerExtra];
dvar int+ x[Vehicle][Trip][RetailerExtra][RetailerExtra];
dvar int+ u[RetailerExtra];// ;flow of unsatisfied demand
dvar int+ a[Vehicle][Trip][RetailerExtra];// arrival time;
dvar int+ p[Vehicle][Trip][RetailerExtra];// departure time;
dvar int+ gLate[Vehicle][RetailerExtra];//Tardiness
dvar int+ gEarly[Vehicle][RetailerExtra];//Earliness
dvar int+ pDepot[Vehicle][TripSt][Depot];

dexpr float Totalcost = 
sum(t in Trip, m in Vehicle, i in RetailerExtra, j in RetailerExtra)(Vcost[m][i][j]+Pcost[m][i][j]+Scost[m][i][j])*v[m][t][i][j]
+sum(d in RetailerOnly)bcost[d]*u[d]
+sum(m in Vehicle)z[m]*VehicleCost[m]
+sum(m in Vehicle, i in RetailerOnly)gEarly[m][i]*CostEarly[m][i]
+sum(m in Vehicle, i in RetailerOnly )gLate[m][i]*CostLate[i];
minimize Totalcost;

subject to
{
//Multi-trip
forall(t in Trip, m in Vehicle)sum(i in RetailerOut)v[m][t][0][i]==1;
forall(t in Trip, m in Vehicle)sum(i in RetailerD)v[m][t][i][NumberOfRetailer+1]==1;
forall(j in RetailerOnly)sum(m in Vehicle, t in Trip, i in RetailerD)v[m][t][i][j]>=0;//Retailer are not necessary all serviced
forall(t in Trip, m in Vehicle,i in RetailerOnly)sum(j in RetailerOut)v[m][t][i][j]-sum(k in RetailerD)v[m][t][k][i]==0;
forall(t in Trip, m in Vehicle,k in RetailerOnly, i in RetailerOnly,j in RetailerOnly)v[m][t][k][i]-(1-v[m][t][i][j])*M<=0;// subtour
forall(t in Trip, m in Vehicle)sum( i in RetailerExtra)v[m][t][NumberOfRetailer+1][i]==0;// no going back from sink node
forall(m in Vehicle, t in Trip, j in RetailerOnly)sum(l in t..NumberOfTrip,i in RetailerD)(v[m][l][i][j])+(1-v[m][t][0][NumberOfRetailer+1])*M>=0;// not necessary use all trip
forall(m in Vehicle, t in Trip, j in RetailerOnly)sum(l in t..NumberOfTrip,i in RetailerD)(v[m][l][i][j])-(1-v[m][t][0][NumberOfRetailer+1])*M<=0;
forall(t in Trip, m in Vehicle,i in RetailerExtra, j in RetailerExtra: j==i)v[m][t][i][j]==0;
//Time window
forall(m in Vehicle,t in 1..NumberOfTrip-1, i in RetailerD)a[m][t+1][0]-a[m][t][NumberOfRetailer+1]>=TravelTime[m][NumberOfRetailer+1][0];//Time start from next trip must equal or greater than the previous
forall(m in Vehicle,t in Trip)a[m][t][NumberOfRetailer+1]-a[m][t][0]>=TravelTime[m][0][NumberOfRetailer+1];
forall(m in Vehicle,t in Trip)v[m][t][0][NumberOfRetailer+1]==1=>a[m][t][NumberOfRetailer+1]==a[m][t][0];
forall(m in Vehicle, j in RetailerOut)a[m][1][j]-pDepot[m][1][0]-(1-v[m][1][0][j])*M<=TravelTime[m][0][j];
forall(m in Vehicle, t in Trip, i in RetailerD, j in RetailerOut)a[m][t][j]-a[m][t][i]+(1-v[m][t][i][j])*M >=S[j]+TravelTime[m][i][j];
forall(m in Vehicle, t in Trip, j in RetailerOnly)sum(i in RetailerD)v[m][t][i][j]==0 =>a[m][t][j]==0;
forall(m in Vehicle,j in RetailerOnly)gEarly[m][j]>=sum(t in Trip,i in RetailerD)v[m][t][i][j]*E[j]-sum(t in Trip)a[m][t][j];
forall(m in Vehicle,j in RetailerOnly)gLate[m][j]>=sum(t in Trip)a[m][t][j]-L[j] ;
forall(m in Vehicle,t in Trip)v[m][t][0][6]==1=>a[m][t][6]==a[m][t][0];
//Load
forall( m in Vehicle, t in Trip,i in RetailerExtra, j in RetailerExtra)v[m][t][i][j]==0 => x[m][t][i][j]==0;
forall(m in Vehicle, t in Trip)sum(i in RetailerD, j in RetailerOnly)x[m][t][i][j]<=Q[m];
forall(d in RetailerOnly) sum(m in Vehicle,t in Trip, i in RetailerExtra)x[m][t][i][d]+u[d]==Demand[d];
forall(m in Vehicle, j in RetailerOnly)z[m]+(1-sum(t in Trip,i in RetailerD)v[m][t][i][j])*M>=1;// use of vehicle

}
execute Output1 {
writeln(cplex.getObjValue());

   writeln("----------------------"); 
   writeln("Route:      ");
for (var m in Vehicle)
	{	
	writeln("Vehicle ",m);
	for (var t in Trip)
	for (var j in RetailerExtra)
		if ( v[m][t][0][j]==1)
		{	if(j==NumberOfRetailer+1){
			write("Trip ",t," :","stay at Depot"," ");
 			}			
			else	
				write("Trip ",t," :",j," (at period ",a[m][t][j],") ");
  							
			var l=j;			
		for (var k in RetailerExtra)
			{
			if ( v[m][t][l][k]==1)
				{if(k==NumberOfRetailer+1){
				write("Depot"," (at period ",a[m][t][k],") ");				
				}
				else				
					write(k," (at period ",a[m][t][k],") ");
 					l=k;
   				 } 									
			}
			 		 writeln("   ");			
		}
	}
}
execute Output2{
	writeln("----------------------"); 
   	write("Vehicle used: ");
for (var m in Vehicle)
if (z[m]==1)
 write(m," ");

} 







 