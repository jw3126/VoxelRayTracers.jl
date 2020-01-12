module Perf
using Test
using BenchmarkTools
using VoxelRayTracers

using BenchmarkTools
position = [0.01,-100, -100]
velocity = [0.001, 1,1]
edgs = (-2:100.0, -50:50.0, sort!(randn(100)))
for dim in 1:3
    ray = (position=position[1:dim], velocity=velocity[1:dim])
    itr = @inferred eachtraversal(ray, edgs[1:dim])
    truthy(x) = true
    @show dim
    b = @benchmark $count($truthy, $itr)
    display(b)
    @test b.allocs == 0
    @show count(truthy, itr)
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

end#module
