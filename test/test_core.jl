module TestCore
using StaticArrays, VoxelRayTracers
using Test

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
itr = @inferred eachtraversal(ray, edgs)
# foreach(println, itr)
truthy(x) = true
b = @benchmark $count($truthy, $itr)
display(b)
b = @benchmark $count($truthy, $itr)
show(b)
@test b.allocs == 0
@show count(truthy, itr)


@testset "eachtraversal" begin
    @testset "2d" begin
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
    end
    @testset "1d" begin
        ray = (position=@SVector[100.0], velocity=@SVector[-1.0])
        edges = ([-10, -6.0, -2.0, 2.0], )
        itr = eachtraversal(ray, edges)
        hits = collect(itr)
        @test hits == [
            (voxelindex = CartesianIndex(3), entry_time = 98.0, exit_time = 102.0),
            (voxelindex = CartesianIndex(2), entry_time = 102.0, exit_time = 106.0),
            (voxelindex = CartesianIndex(1), entry_time = 106.0, exit_time = 110.0),
        ]
    end

    @testset "1d no hits" begin
        ray = (position=@SVector[3.0], velocity=@SVector[1.0])
        edges = (-3:2,)
        itr = @inferred eachtraversal(ray, edges)
        hits = @inferred collect(itr)
        @test isempty(hits)
    end

    @testset "1d start inside" begin
        ray = (position=@SVector[3.0], velocity=@SVector[1.0])
        edges = ([0, 2, 4, 6, 7],)
        itr = @inferred eachtraversal(ray, edges)
        hits = @inferred collect(itr)
        @test hits == [
            (voxelindex = CartesianIndex(2,), entry_time = 0.0, exit_time = 1.0),
            (voxelindex = CartesianIndex(3,), entry_time = 1.0, exit_time = 3.0),
            (voxelindex = CartesianIndex(4,), entry_time = 3.0, exit_time = 4.0),
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

    @testset "3d" begin
        ray = (position=@SVector[10.0, 20, 30], velocity=@SVector[1.0, -1.0, -2])
        edges = ([11, 13, 14, 20], [5, 17, 18], [10, 25])
        itr = @inferred eachtraversal(ray, edges)
        @test collect(itr) == [
            (voxelindex = CartesianIndex(1, 2, 1), entry_time = 2.5, exit_time = 3.0),
            (voxelindex = CartesianIndex(2, 1, 1), entry_time = 3.0, exit_time = 4.0),
            (voxelindex = CartesianIndex(3, 1, 1), entry_time = 4.0, exit_time = 10.0),
        ]
    end
end

# exit()

end#module
