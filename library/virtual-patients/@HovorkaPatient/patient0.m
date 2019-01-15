function patient0(this)
% Patient 0 has a random set of parameters chosen around
% the mean Hovorka parameter.
% [1] M. E. Wilinska et al., "Simulation models for in silico testing of
% closed-loop glucose controllers in type 1 diabetes,", 2009.
% [2] D. Boiroux et al., "Adaptive control in an artificial pancreas for
% people with type 1 diabetes,", 2017.

this.param.w = 45 + (95 - 45) * rand(1); % Patient weight (kg).

% Glucose submodel.
resampleValidParam = true;
iter = 0;
while iter < 1e2 && resampleValidParam
    iter = iter + 1;
    resampleValidParam = false;
    
    this.param.EGP0 = lognrnd(log(17.0), 0.2); % Endogenous glucose production extrapolated to zero insulin concentration (umol / (kg min)).
    this.param.F01 = lognrnd(log(11.0), 0.1); % Noninsulin-dependent glucose flux (umol / (kg min)).
    while 0.8 * this.param.EGP0 < 5.5 * (this.param.F01 / 0.85) / (5.5 + 1)
        this.param.EGP0 = lognrnd(log(17.0), 0.2); % Endogenous glucose production extrapolated to zero insulin concentration (umol / (kg min)).
        this.param.F01 = lognrnd(log(11.0), 0.1); % Noninsulin-dependent glucose flux (umol / (kg min)).
    end
    this.param.k12 = lognrnd(log(0.05), 0.4); % Transfer rate from non-accessible to accessible glucose compartment (1/min).
    this.param.RTh = 11; % Renal clearance threshold (mmol/L).
    this.param.RCl = lognrnd(log(0.01), 0.2); % Renal clearance rate (1/min).
    
    % Insulin submodel.
    this.param.ka1 = lognrnd(log(0.0035), 0.4); % Activation rate of remote insulin effect on glucose distribution (1/min).
    this.param.ka2 = lognrnd(log(0.055), 0.4); % Activation rate of remote insulin effect on glucose disposal (1/min).
    this.param.ka3 = lognrnd(log(0.025), 0.4); % Activation rate of remote insulin effect on endogenous glucose production (1/min).
    this.param.St = lognrnd(log(18.0e-4), 0.4); % Insulin sensitivity of glucose transport (L / (min mU)).
    this.param.Sd = lognrnd(log(5.0e-4), 0.4); % Insulin sensitivity of glucose disposal (L / (min mU)).
    this.param.Se = lognrnd(log(190e-4), 0.4); % Insulin sensitivity of suppression of endogenous glucose production (L/mU).
    this.param.ka = lognrnd(log(0.018), 0.2); % Insulin absorption rate (1/min).
    this.param.ke = lognrnd(log(0.14), 0.2); % Insulin elimination rate (1/min).
    
    % Meal submodel.
    this.param.Bio = 0.9; % Bioavailability of CHO (%).
    this.param.TauM = 1 / lognrnd(log(0.028), 0.2); % Time-to-maximum of CHO absorption (min).
    
    % Glucagon submodel.
    this.param.TauGlu = lognrnd(log(19), 0.2); % Time-to-maximum of glucagon absorption (min).
    this.param.TGlu = lognrnd(log(0.0012), 0.2); % Glucagon sensitivity (mL/pg).
    this.param.MCRGlu = lognrnd(log(0.012), 0.2); % Metabolic clearance rate of glucagon (L/kg/min).
    
    % Sensor submodel.
    this.param.TauS = 12; % Time constant between interstitial and plasma glucose compartment (min).
    
    % Other constants.
    this.param.Vi = lognrnd(log(120), 0.05); % Insulin distribution volume (mL/kg).
    this.param.Vg = lognrnd(log(160), 0.05); % Glucose distribution volume (mL/kg).
    this.param.MCHO = 180.1577; % Molecular wight of glucose (g/mol).
    
    % Validate parameters
    Gs0 = 6.5;
    Q10 = Gs0 * this.param.Vg;
    
    Fn = Q10 * (this.param.F01 / 0.85) / (Q10 + this.param.Vg);
    Fr = this.param.RCl * (Q10 - this.param.RTh * this.param.Vg) * (Q10 > this.param.RTh * this.param.Vg);
    Slin = roots([ ...
        (-Q10 * this.param.St * this.param.Sd - this.param.EGP0 * this.param.Sd * this.param.Se), ...
        (-this.param.k12 * this.param.EGP0 * this.param.Se + (this.param.EGP0 - Fr - Fn) * this.param.Sd), ...
        this.param.k12 * (this.param.EGP0 - Fn - Fr), ...
        ]);
    syms x positive
    S = vpasolve(-Fn ...
        -Q10*this.param.St*x ...
        +this.param.k12*(Q10 * this.param.St * x)/(this.param.k12 + this.param.Sd * x) ...
        -Fr ...
        +this.param.EGP0*exp(-this.param.Se*x) == 0, x, max(double(Slin)));
    
    % Insulin plasma (mU/L).
    if ~isempty(S) && isreal(double(S))
        Ip0 = double(S);
    else
        Ip0 = abs(S);
        warning('Couldn''t solve for initial conditions!');
    end
    
    % Basal insulin.
    Ub = 60 * Ip0 * this.param.ke / (1e6 / (this.param.Vi * this.param.w));
    
    if Ub > 2.2 || Ub < 0.1
        resampleValidParam = true;
    end
    
    % Carb factor.
    meanCarbF = (this.param.MCHO * (0.4 * max(this.param.St, 16e-4) + 0.6 * min(max(this.param.Sd, 3e-4), 7e-4)) * 5.0 * this.param.Vg) / (this.param.ke * this.param.Vi); % g/U.
    
    if meanCarbF > 24 || meanCarbF < 2
        resampleValidParam = true;
    end
end

if iter >= 1e2
    warning('Couldn''t sample valid parameters!');
end
end
