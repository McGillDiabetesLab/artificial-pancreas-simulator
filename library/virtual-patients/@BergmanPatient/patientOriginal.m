function patientOriginal(this)
%patientOriginal
% Parameters are taken from
% 
% R. N. Bergman et al., "Quantitative estimation of insulin
% sensitivity," Am J Physiol, vol. 236, no. 6, pp. E667-77, Jun 1979.
%
% Parameter in the original paper are based on experminents on non-diabetic
% dogs. Consequently, they result on a non-diabetic individual for Gbasal <
% 5.0 mmol/L.
% 

% patient Specific
this.param.w = 70;

% Constants
this.param.MCR = 0.02; % Insulin distribution volume (L / kg / min)
this.param.Bio = 0.9; % Bioavailability of CHO (%)
this.param.Vg = 0.117; % Glucose distribution volume (L / kg)
this.param.MCHO = 180.1577; % Molecular wight of glucose (g / mol)
this.param.Km = 1e3 / (this.param.w * this.param.MCHO); % mmol / g / Kg

% meata parameter
basalRatio = 0.48; 
mmolPerDay = 110;

% glucose submodel
this.param.P1 = 4.9e-2; % Glucose decay (1/min)
this.param.P2 = 9.1e-2; % Activation rate of remote insulin effect on glucose (1/min)
this.param.P3 = 8.96e-5; % (1/min2 per (mU/L))
this.param.P4 = 4.42; 
this.param.Gb = this.param.P4 / this.param.P1 / (this.param.MCHO / 10); % mmol/L

% insulin submodel
this.param.TauI = 70; % min
this.param.Ub0 = 60e-3 * (this.param.P1*this.param.P2 / this.param.P3)*(this.param.Gb/this.param.GBasal - 1)*(this.param.MCR * this.param.w);
if this.param.Ub0 < 0
    this.param.Ub0 = 0.0;
end
this.param.Ip0 = 1e3  * (this.param.Ub0 / 60) / (this.param.MCR * this.param.w); % (mU/L) (uU/mL)

% exercise submodel
this.param.e1 = 2.0; % (unitless)
this.param.e2 = 2.0; % (unitless)

% meal submodel
this.param.TauM = 40; % Time-to-maximum of CHO absorption (min)

% sensor submodel
this.param.TauS = 10; % Time constant between interstitial and plasma glucose compartment (min)

% patient therapy parameter
this.param.Si = (1e3/(this.param.MCR * this.param.w))*(this.param.P3 / this.param.P2) * this.param.GBasal; % mmol / L / U
this.param.TDD = mmolPerDay / this.param.Si;
this.param.carbFactors.value = this.param.Si / (this.param.Bio * this.param.Km / this.param.Vg); % g / U
this.param.carbFactors.time = 0;
this.param.pumpBasals.value = this.param.Ub0;
this.param.pumpBasals.time = 0;
this.param.insulinSensitivty.value = this.param.Si;
this.param.insulinSensitivty.time = 0;
end
