function patient0(this)
% Patient 0 has a random set of parameters chosen around
% the mean Hovorka parameter.
% [1] M. E. Wilinska et al., "Simulation models for in silico testing of
% closed-loop glucose controllers in type 1 diabetes,", 2009.
% [2] D. Boiroux et al., "Adaptive control in an artificial pancreas for
% people with type 1 diabetes,", 2017.

this.param.w = 65 + (95 - 65) * rand(1); % Patient weight (kg).

% Glucose submodel.
this.param.EGP0 = 16.9 * (1 + 0.05 * randn(1)); % Endogenous glucose production extrapolated to zero insulin concentration (umol / (kg min)).
this.param.F01 = 11.1 * (1 + 0.05 * randn(1)); % Noninsulin-dependent glucose flux (umol / (kg min)).
while 0.8 * this.param.EGP0 < 5.5 * (this.param.F01 / 0.85) / (5.5 + 1)
    this.param.EGP0 = 16.9 * (1 + 0.05 * randn(1)); % Endogenous glucose production extrapolated to zero insulin concentration (umol / (kg min)).
    this.param.F01 = 11.1 * (1 + 0.05 * randn(1)); % Noninsulin-dependent glucose flux (umol / (kg min)).
end
this.param.k12 = 0.060 * (1 + 0.05 * randn(1)); % Transfer rate from non-accessible to accessible glucose compartment (1/min).
this.param.RTh = 9 * (1 + 0.05 * randn(1)); % Renal clearance threshold (mmol/L).
this.param.RCl = 0.01 * (1 + 0.05 * randn(1)); % Renal clearance rate (1/min).

% Insulin submodel.
this.param.ka1 = 0.0034 * (1 + 0.05 * randn(1)); % Activation rate of remote insulin effect on glucose distribution (1/min).
this.param.ka2 = 0.056 * (1 + 0.05 * randn(1)); % Activation rate of remote insulin effect on glucose disposal (1/min).
this.param.ka3 = 0.024 * (1 + 0.05 * randn(1)); % Activation rate of remote insulin effect on endogenous glucose production (1/min).
this.param.St = 18.41e-4 * (1 + 0.05 * randn(1)); % Insulin sensitivity of glucose disposal (L / (min mU)).
this.param.Sd = 5.05e-4 * (1 + 0.05 * randn(1)); % Insulin sensitivity of glucose disposal (L / (min mU)).
this.param.Se = 190e-4 * (1 + 0.05 * randn(1)); % Insulin sensitivity of suppression of endogenous glucose production (L/mU).
this.param.ka = 0.018 * (1 + 0.05 * randn(1)); % Insulin absorption rate (1/min).
this.param.ke = 0.14 * (1 + 0.05 * randn(1)); % Insulin elimination rate (1/min).

% Meal submodel.
this.param.Bio = 1; % Bioavailability of CHO (%).
this.param.TauM = 40; % Time-to-maximum of CHO absorption (min).

% Glucagon submodel.
this.param.TauGlu = 19 * (1 + 0.05 * randn(1)); % Time-to-maximum of glucagon absorption (min).
this.param.TGlu = 0.0012 * (1 + 0.05 * randn(1)); % Glucagon sensitivity (mL/pg).
this.param.MCRGlu = 0.012 * (1 + 0.05 * randn(1)); % Metabolic clearance rate of glucagon (L/kg/min).

% Sensor submodel.
this.param.TauS = 15; % Time constant between interstitial and plasma glucose compartment (min).

% Other constants.
this.param.Vi = 120; % Insulin distribution volume (mL/kg).
this.param.Vg = 160; % Glucose distribution volume (mL/kg).
this.param.MCHO = 180.1577; % Molecular wight of glucose (g/mol).

end
