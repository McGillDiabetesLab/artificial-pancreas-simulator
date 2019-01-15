# Getting Started

This guide will take you through the process of setting up a basic simulation comparing an artificial pancreas PID controller to basal-bolus therapy.

1. Open MATLAB and navigate to the `src` directory.

2. Copy the `SimulatorOptionsTemplate.m` file from the `src/templates` directory to the `src/user/configurations` directory.

3. Rename the file to a suitable name. This tutorial will use `ExampleOptions.m`. Open the new file and change all instances of `SimulatorOptionsTemplate` to this new name.

4. Change the `virtualPatients` variable in the constructor to

       this.virtualPatients = { ...
           {'HaidarPatient', 5, 'DefaultMealPlan', 'DefaultExercisePlan' 'BBTherapy'}, ...
           {'HaidarPatient', 5, 'DefaultMealPlan', 'DefaultExercisePlan' 'PIDController'}, ...
           };

   This specifies that `HaidarPatient` model \#5 will be used to simulate two patients with default meal and exercise plans, and that the two controllers `BBTherapy` and `PIDController` will be used to determine the insulin infusions to administer to these patients.

5. Change the `resultsManager` variable in the constructor to

       this.resultsManager = 'DefaultResultsManager';

   This specifies that the results will be displayed using a default implementation which produces one plot per patient at the end of the simulation.

6. Run the simulation. This can be done by executing

       configurePaths();
       options = ExampleOptions();
       simulator = ArtificialPancreasSimulator(options);
       simulator.simulate();

   on the MATLAB command line. This set of commands has also been placed in the `simulation.m` file in the `src` directory. You can change the name of the options class used in this file and run it to get the same results. The simulator will then run for both patients and produce results. You should see two plots appear after a short simulation duration.

## Additional Resources

For additional information about the options available for a simulation, execute
```
configurePaths();
doc SimulatorOptions;
```
on the MATLAB command line.
