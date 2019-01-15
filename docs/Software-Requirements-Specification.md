# Introduction

## Purpose

The purpose of this project is to provide a digital environment in which treatment of a virtual Type 1 diabetes patient with an algorithm-controlled insulin pump can be simulated. This simulation environment can therefore provide an inexpensive way to test insulin injection algorithms on a wide data set of potential patients before going to an expensive clinical trial.

## Definitions

- ODE : Ordinary differential equation.
- Virtual Patient : A set of ODEs describing the time response of the pancreatic system to various inputs.
- Virtual Population : A group of virtual patients.
- Flux : Random variations in parameters over the length of a simulation.
- Algorithm : The closed-loop algorithm that will produce the dosage of insulin and glucagon to administer to a patient based on the current state of the patient.
- Controller : The entity responsible for executing the algorithm.
- Infusions : The dosage of insulin and glucagon to administer to a patient.
- Bolus : A one-time administration (referring to infusions).
- Basal : A continuous administration (referring to infusions).
- Outcome Calculation : A statistical parameter computed from the simulation data representing some outcome of the experiment, for example the mean glucose level or the number of hypoglycemic events.

## System Overview

The system consists of a software program that will simulate the glucose level of a type 1 diabetes patient using a set of ordinary differential equations (ODEs). The software will poll an insulin and glucagon administration algorithm with the current state of the patient and obtain the infusions to administer. It will then simulate the state progression of the patient for a certain time interval, and poll the algorithm again. This loop continues for a period of time specified by the user. Finally, a set of outcomes is calculated for the simulation, and is either displayed to the user or stored for later processing. The simulator is required to be written in MATLAB due to the accessibility of this programming environment to the researchers who will be using and maintaining the software.

# Overall Description

## User Interface

The user must be provided with an interface which will be easy to use for a typical user, as defined in the user characteristics. This interface will allow them to select the simulation type they wish to perform and specify a set of configuration options for said simulation. This interface can be either graphical or text based, but must be easy to set up and use for a typical user. Advanced users must also be provided with the option of bypassing this basic interface and making modifications to suit their particular needs.

## User Characteristics

### Typical User

The typical user is a person that has little experience with programming concepts. They will be somewhat familiar with the basics and will be able to use a text editor to modify existing source code in simple ways. These ways include modifying the contents of numeric and string literals. They will not be able to create a non-trivial program with conditional statements and loops without assistance. They will require step-by-step guides on how to use the software in order to get it up and running.

### Advanced User

The advanced user is a person with experience in programming. They will be familiar with programming concepts like object-oriented programming and will be able to make extensive modification of the code to suit their particular purpose. They will make use of in-code documentation like comments and will require in-depth documentation on how the system works and how to modify it to suit their particular needs. They are specialized users who will prefer flexibility in terms of how to perform their simulations rather than being locked into a restricted graphical user interface.

# Specific Requirements

## Functional Requirements

### Standard Simulation

A standard simulation is a simulation in which the state of a virtual population is simulated over a long period of time using a specific controller algorithm. This type of simulation requires the user to specify:
- The duration of the simulation
- The time of the day at which the simulation starts
- The step size to be used between infusions
- The virtual population to be simulated
- The controller algorithm to use
- The way in which results will be processed

### Comparison Simulation

A comparison simulation is a simulation in which the state of a virtual population is first simulated over a period of time using a specific baseline controller algorithm. Then, the data obtained from this baseline simulation is given to a second controller for a short period of time to see how it would perform compared to the baseline controller. The outputs of this second controller are ignored for the purpose of virtual patient simulation. This type of simulation requires the user to specify:
- The duration of the first part of the simulation
- The duration of the second part of the simulation
- The time of the day at which the simulation starts
- The step size to be used between infusions
- The virtual population to be simulated
- The baseline controller algorithm to use
- The second controller algorithm to use
- The way in which the results will be processed

### Validation Simulation

A validation simulation is a simulation in which the patient and controller states are predefined from clinical data. The simulation polls a controller which produces a new infusion dosage at every time step based on the clinical data at the previous times. The outputs of this controller are ignored since the state of the patient is predefined from clinical data. This type of simulation requires the user to specify:
- The duration of the simulation
- The time of day at which the simulation starts
- The step size to be used between infusions
- The clinical data for the state of the patient during the simulation
- The clinical data for the state of the controller during the simulation
- The controller algorithm to use
- The way in which the results will be processed

## Performance Requirements

The ODE solver used should be configurable by the user to allow them to select the optimal solver for the task. The software should also be parallelizable to the maximum extent possible to allow for execution on multiple cores or multiple machines in the future.

## Reliability

The software should store simulation data intermittently and be able to resume from the recovered data should it crash.

## Maintainability

The software should be maintainable by advanced users. Documentation should be automated to the maximum extent possible to ensure that it is never out-of-date with respect to the code.
