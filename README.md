# DC-OPF---Luis-Classes
This repository contains functions in Julia Language that solve the DC Power Flow problem.

To run the code and change the input parameters, use the file "main.jl" or the files inside the Input_Data folder.

The code stores input data in DataFrames. Some of the output data is also stored in DataFrames.

To install the required Julia packages, run:

```julia
using Pkg

Pkg.add("LinearAlgebra")
Pkg.add("SparseArrays")
Pkg.add("DataFrames")
Pkg.add("Printf")
Pkg.add("CSV")
Pkg.add("DataStructures")
Pkg.add("JuMP")
Pkg.add("HiGHS")
