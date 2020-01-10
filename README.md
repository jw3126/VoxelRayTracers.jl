# VoxelRayTracers

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://jw3126.github.io/VoxelRayTracers.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://jw3126.github.io/VoxelRayTracers.jl/dev)
[![Build Status](https://travis-ci.com/jw3126/VoxelRayTracers.jl.svg?branch=master)](https://travis-ci.com/jw3126/VoxelRayTracers.jl)
[![Codecov](https://codecov.io/gh/jw3126/VoxelRayTracers.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/jw3126/VoxelRayTracers.jl)

# Usage

```julia
using VoxelRayTracers
using StaticArrays

edges = (0:1:10, 4:2:10,)
ray = (position=@SVector[0.0,0], velocity=@SVector[1,1.0])
for hit in eachtraversal(ray, edges)
    println(hit)
end
```
```
(voxelindex = CartesianIndex(5, 1), entry_time = 4.0, exit_time = 5.0)
(voxelindex = CartesianIndex(6, 1), entry_time = 5.0, exit_time = 6.0)
(voxelindex = CartesianIndex(7, 2), entry_time = 6.0, exit_time = 7.0)
(voxelindex = CartesianIndex(8, 2), entry_time = 7.0, exit_time = 8.0)
(voxelindex = CartesianIndex(9, 3), entry_time = 8.0, exit_time = 9.0)
(voxelindex = CartesianIndex(10, 3), entry_time = 9.0, exit_time = 10.0)
```
There is also some basic visualization useful for debugging:
```julia
using Plots
plot(eachtraversal(ray, edges))
```
![example](example.png)

# Design goals

* Lightweight and simple
* Support arbitrary dimension and non uniform grids
* Reasonable performance
