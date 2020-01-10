module TestCore
using StaticArrays, VoxelRayTracers
using Test

@testset "eachtraversal" begin
    pos = @SVector[0.0,-100]
    vel = @SVector[0.0,1]

    edges = (-2:5.0, [-10, -6.0, -2.0, 2.0])
    ray = (position=pos, velocity=vel)
    itr = eachtraversal(ray, edges)
    hits = @inferred collect(itr)
    @test eltype(hits) == typeof(first(hits))
    @test hits == [
        (voxelindex = CartesianIndex(3, 1), entry_time = 90.0, exit_time = 94.0),
        (voxelindex = CartesianIndex(3, 2), entry_time = 94.0, exit_time = 98.0),
        (voxelindex = CartesianIndex(3, 3), entry_time = 98.0, exit_time = 102.0),
    ]

    ray = (position=@SVector[100.0], velocity=@SVector[-1.0])
    edges = ([-10, -6.0, -2.0, 2.0], )
    itr = eachtraversal(ray, edges)
    hits = collect(itr)
    # foreach(println, hits)
    @test hits == [
        (voxelindex = CartesianIndex(3), entry_time = 98.0, exit_time = 102.0),
        (voxelindex = CartesianIndex(2), entry_time = 102.0, exit_time = 106.0),
        (voxelindex = CartesianIndex(1), entry_time = 106.0, exit_time = 110.0),
    ]
end

@testset "diagonal2d" begin
    ray = (position=@SVector[0.0, 0.0], velocity=@SVector[1.0, 1.0])
    edges = ([1,3,4],1:4)
    itr = @inferred eachtraversal(ray, edges)
    @test collect(itr) == [
     (voxelindex = CartesianIndex(1, 1), entry_time = 1.0, exit_time = 2.0),
     (voxelindex = CartesianIndex(1, 2), entry_time = 2.0, exit_time = 3.0),
     (voxelindex = CartesianIndex(2, 3), entry_time = 3.0, exit_time = 4.0),
    ]
end

@testset "spurious intersection 2d" begin
    ray = (position=@SVector[0.0, 5.0], velocity=@SVector[1.0, -2.0])
    edges = ([1, 10],[-10,3,4])
    itr = @inferred eachtraversal(ray, edges)
    @test collect(itr) == [
        (voxelindex = CartesianIndex(1, 1), entry_time = 1.0, exit_time = 7.5) 
    ]
end

# exit()

using BenchmarkTools

ray = (
    position = @SVector[0.01,-100, -100],
    velocity = @SVector[0.001, 1,1],
)

using Random
rng = MersenneTwister(1)
for s in 1:100
    Random.seed!(rng, s)
    edgs = (-2:100.0, -50:50.0, sort!(randn(rng, 100)))
    itr = eachtraversal(ray, edgs)
    collect(itr)
end
edgs = (-2:100.0, -50:50.0, sort!(randn(rng, 100)))
itr = eachtraversal(ray, edgs)
# foreach(println, itr)
truthy(x) = true
b = @benchmark $count($truthy, $itr)
@test b.allocs == 0
@show count(truthy, itr)
show(b)

end#module
