module TestCore
using VoxelRayTracers
using Test

@testset "1d" begin
    @testset "default" begin
        ray = (position=[100.0], velocity=[-1.0])
        edges = ([-10, -6.0, -2.0, 2.0], )
        itr = eachtraversal(ray, edges)
        hits = collect(itr)
        @test hits == [
            (voxelindex = CartesianIndex(3), entry_time = 98.0, exit_time = 102.0),
            (voxelindex = CartesianIndex(2), entry_time = 102.0, exit_time = 106.0),
            (voxelindex = CartesianIndex(1), entry_time = 106.0, exit_time = 110.0),
        ]
    end

    @testset "no hits" begin
        ray = (position=[3.0], velocity=[1.0])
        edges = (-3:2,)
        itr = @inferred eachtraversal(ray, edges)
        hits = @inferred collect(itr)
        @test isempty(hits)
    end

    @testset "start inside" begin
        ray = (position=[3.0], velocity=[1.0])
        edges = ([0, 2, 4, 6, 7],)
        itr = @inferred eachtraversal(ray, edges)
        hits = @inferred collect(itr)
        @test hits == [
            (voxelindex = CartesianIndex(2,), entry_time = 0.0, exit_time = 1.0),
            (voxelindex = CartesianIndex(3,), entry_time = 1.0, exit_time = 3.0),
            (voxelindex = CartesianIndex(4,), entry_time = 3.0, exit_time = 4.0),
            ]
    end
end

@testset "2d" begin
    @testset "default" begin
        pos = [0.0,-100]
        vel = [0.0,1]

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

    @testset "diagonal" begin
        ray = (position=[0.0, 0.0], velocity=[1.0, 1.0])
        edges = ([1,3,4],1:4)
        itr = @inferred eachtraversal(ray, edges)
        @test collect(itr) == [
         (voxelindex = CartesianIndex(1, 1), entry_time = 1.0, exit_time = 2.0),
         (voxelindex = CartesianIndex(1, 2), entry_time = 2.0, exit_time = 3.0),
         (voxelindex = CartesianIndex(2, 3), entry_time = 3.0, exit_time = 4.0),
        ]
    end

    @testset "spurious intersection" begin
        ray = (position=[0.0, 5.0], velocity=[1.0, -2.0])
        edges = ([1, 10],[-10,3,4])
        itr = @inferred eachtraversal(ray, edges)
        @test collect(itr) == [
            (voxelindex = CartesianIndex(1, 1), entry_time = 1.0, exit_time = 7.5)
        ]
    end

    @testset "no hits, touch corner" begin
        ray = (position=[0,0], velocity=[1,1])
        edges = ([1,2], [-3,1])
        hits = eachtraversal(ray, edges)
        @test isempty(hits)
    end
end

@testset "3d" begin
    ray = (position=[10.0, 20, 30], velocity=[1.0, -1.0, -2])
    edges = ([11, 13, 14, 20], [5, 17, 18], [10, 25])
    itr = @inferred eachtraversal(ray, edges)
    @test collect(itr) == [
        (voxelindex = CartesianIndex(1, 2, 1), entry_time = 2.5, exit_time = 3.0),
        (voxelindex = CartesianIndex(2, 1, 1), entry_time = 3.0, exit_time = 4.0),
        (voxelindex = CartesianIndex(3, 1, 1), entry_time = 4.0, exit_time = 10.0),
    ]
end


@testset "inference" begin
    ray = (
        position = [0.01,-100, -100],
        velocity = [0.001, 1,1],
    )
    edgs = (-2:100.0, -50:50.0, sort!(randn(100)))
    itr = @inferred eachtraversal(ray, edgs)
    item, state = @inferred Nothing iterate(itr)
    item, state = @inferred Nothing iterate(itr, state)
end

@testset "eltype" begin
    for (P,V,E,T) in [
                      (Float32, Float32, Float32, Float32),
                      (Float64, Float64, Float64, Float64),
                      (Int64, Int64, Int64, Float64),
                      (Float64, Int64, Float32, Float64),
                   ]
        ray = (position=P[0,], velocity=V[1])
        edges = (E[1,2,3],)
        itr = @inferred eachtraversal(ray, edges)
        item, state = @inferred Nothing iterate(itr)
        item, state = @inferred Nothing iterate(itr, state)
        @test typeof(item.entry_time) == T
        @test typeof(item.exit_time) == T
    end
end


end#module
