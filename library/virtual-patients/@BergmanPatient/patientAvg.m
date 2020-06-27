function patientAvg(this)
%patientAvg
% Parameters were adapted to achieve reasonable patient therapy parameter:
%
% Basal rate: 0.75 u/h
% Carbohydrate ratio: 9.5 g/u
% Insulin Sensitivity factor: 3.0 mmol/L/u
%

% patient Specific
this.param.w = 70;

% Constants
this.param.MCR = 0.02; % Insulin distribution volume (L / kg / min)
this.param.Bio = 0.8; % Bioavailability of CHO (%)
this.param.Vg = 0.20; % Glucose distribution volume (L / kg)
this.param.MCHO = 180.1577; % Molecular wight of glucose (g / mol)
this.param.Km = 1e3 / (this.param.w * this.param.MCHO); % mmol / g / Kg

% meata parameter
tddPerKg = 0.53; % U / Kg
basalRatio = 0.48;

% patient therapy parameter
this.param.TDD = tddPerKg * this.param.w;

% insulin submodel
this.param.TauI = 70; % min
this.param.Ub0 = (this.param.TDD * basalRatio / 24); % U / h
this.param.Ip0 = 1e3 * (this.param.Ub0 / 60) / (this.param.MCR * this.param.w); % (mU/L) (uU/mL)

% glucose submodel
this.param.P1 = 0.001; % Glucose decay (1/min)
this.param.P2 = 0.075; % Activation rate of remote insulin effect on glucose (1/min)
this.param.P3 = 5e-5; % (1/min2 per (mU/L))
this.param.Gb = this.param.GBasal * (1 + ((this.param.P3 / this.param.P2) * this.param.Ip0) / (this.param.P1));
this.param.Si = (1e3/(this.param.MCR * this.param.w))*(this.param.P3 / this.param.P2) * this.param.GBasal; % mmol / L / U

% exercise submodel
this.param.e1 = 2.0; % (unitless)
this.param.e2 = 2.0; % (unitless)

% meal submodel
this.param.TauM = 40; % Time-to-maximum of CHO absorption (min)

% sensor submodel
this.param.TauS = 10; % Time constant between interstitial and plasma glucose compartment (min)

% patient therapy parameter
this.param.carbFactors.value = this.param.Si / (this.param.Bio * this.param.Km / this.param.Vg); % g / U
this.param.carbFactors.time = 0;
this.param.pumpBasals.value = this.param.Ub0;
this.param.pumpBasals.time = 0;
this.param.insulinSensitivty.value = this.param.Si;
this.param.insulinSensitivty.time = 0;

end
