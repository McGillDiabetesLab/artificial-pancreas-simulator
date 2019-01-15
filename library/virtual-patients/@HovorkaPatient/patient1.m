function patient1(this)
% Patient 1 is inspired of Hovorka parameters. But tuned for the purpose of the simulation.
% [1] M. E. Wilinska et al., "Simulation models for in silico testing of
% closed-loop glucose controllers in type 1 diabetes,", 2009.

this.param.w = 70; % Patient weight (kg).

% Glucose submodel.
this.param.EGP0 = 17.0; % Endogenous glucose production extrapolated to zero insulin concentration (umol / (kg min)).
this.param.F01 = 11.1; % Noninsulin-dependent glucose flux (umol / (kg min)).
this.param.k12 = 0.05; % Transfer rate from non-accessible to accessible glucose compartment (1/min).
this.param.RTh = 11; % Renal clearance threshold (mmol/L).
this.param.RCl = 0.01; % Renal clearance rate (1/min).

% Insulin submodel.
this.param.ka1 = 0.0035; % Activation rate of remote insulin effect on glucose distribution (1/min).
this.param.ka2 = 0.055; % Activation rate of remote insulin effect on glucose disposal (1/min).
this.param.ka3 = 0.025; % Activation rate of remote insulin effect on endogenous glucose production (1/min).
this.param.St = 18.0e-4; % Insulin sensitivity of glucose transport (L / (min mU)).
this.param.Sd = 5.0e-4; % Insulin sensitivity of glucose disposal (L / (min mU)).
this.param.Se = 190e-4; % Insulin sensitivity of suppression of endogenous glucose production (L/mU).
this.param.ka = 0.018; % Insulin absorption rate (1/min).
this.param.ke = 0.14; % Insulin elimination rate (1/min).

% Meal submodel.
this.param.Bio = 0.9; % Bioavailability of CHO (%).
this.param.TauM = 1 / 0.028; % Time-to-maximum of CHO absorption (min).

% Glucagon submodel.
this.param.TauGlu = 19; % Time-to-maximum of glucagon absorption (min).
this.param.TGlu = 0.0012; % Glucagon sensitivity (mL/pg).
this.param.MCRGlu = 0.012; % Metabolic clearance rate of glucagon (L/kg/min).

% Sensor submodel.
this.param.TauS = 12; % Time constant between interstitial and plasma glucose compartment (min).

% Other constants.
this.param.Vi = 120; % Insulin distribution volume (mL/kg).
this.param.Vg = 160; % Glucose distribution volume (mL/kg).
this.param.MCHO = 180.1577; % Molecular wight of glucose (g/mol).

end
