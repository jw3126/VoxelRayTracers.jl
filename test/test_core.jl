module TestCore
using StaticArrays, VoxelRayTracers
using Test

@testset "eachvoxelentry" begin
    pos = @SVector[0.0,-100]
    vel = @SVector[0.0,1]

    edges = (-2:5.0, [-10, -6.0, -2.0, 2.0])
    ray = (position=pos, velocity=vel)
    itr = eachvoxelentry(ray, edges)
    hits = @inferred collect(itr)
    @test eltype(hits) == typeof(first(hits))
    @test hits == [
        (position = [0.0, -10.0], index = CartesianIndex(3, 1), time = 90.0),
        (position = [0.0,  -6.0], index = CartesianIndex(3, 2), time = 94.0),
        (position = [0.0,  -2.0], index = CartesianIndex(3, 3), time = 98.0),
    ]
end
using BenchmarkTools

ray = (
    position = @SVector[0.01,-100, -100],
    velocity = @SVector[0.001, 1,1],
)

edgs = (-2:100.0, -50:50.0, sort!(randn(100)))
itr = eachvoxelentry(ray, edgs)
truthy(x) = true
b = @benchmark $count($truthy, $itr)
@test b.allocs == 0
show(b)

end#module
