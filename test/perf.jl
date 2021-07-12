module Perf
using Test
using BenchmarkTools
using VoxelRayTracers

using BenchmarkTools

function _count(itr)
    ret = 0
    for x in itr
        ret += 1
    end
    return ret
end

position = [0.01,-100, -100]
velocity = [0.001, 1,1]
#edgs = (-2:100.0, -50:50.0, sort!(randn(100)))
edgs = (-2:100.0, -50:50.0, -100:1:100)
for dim in 1:3
    ray = (position=position[1:dim], velocity=velocity[1:dim])
    itr = @inferred eachtraversal(ray, edgs[1:dim])
    @show dim
    b = @benchmark _count($itr)
    display(b)
    @test b.allocs == 0
    @show _count(itr)
end

# position = [0.01,-100, -100]
# velocity = [0.001, 1,1]
# edgs = (-2:100.0, -50:50.0, sort!(randn(100)))
# ray = (position=position, velocity=velocity)
# itr = eachtraversal(ray, edgs)
# function doit(itr)
#     ret = 0.0
#     for hit in itr
#         ret += hit.entry_time
#     end
#     ret
# end
#
#
#

@testset "eachtraversal no allocs $dim" for dim in 1:3
    nwalls = 20
    edges = Tuple(range(-10, stop=10, length=nwalls) for _ in 1:dim)
    ray = (position=randn(dim), velocity=randn(dim))
    data = randn((nwalls - 1 for _ in 1:dim)...)

    function raysum(ray, edges, data)
        out = 0.0
        for i in 1:1000
            for hit in eachtraversal(ray, edges)
                out += data[hit.voxelindex]
            end
        end
        out
    end

    b = @benchmark $raysum($ray, $edges, $data) samples=2 evals=2
    display(b)
    @test b.allocs < 100
end

end#module
