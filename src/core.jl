export eachtraversal
using LinearAlgebra
using ArgCheck

"""
    hits = eachtraversal(ray, edges)

Compute the traversal of `ray` through a grid that is the produce of `edges`.

# Example

```jldoctest
julia> using VoxelRayTracers

julia> edges = (0:1:10, 4:2:10,);

julia> ray = (position=[0,0], velocity=[1,1]);

julia> for hit in eachtraversal(ray, edges)
           println(hit)
       end
(voxelindex = CartesianIndex(5, 1), entry_time = 4.0, exit_time = 5.0)
(voxelindex = CartesianIndex(6, 1), entry_time = 5.0, exit_time = 6.0)
(voxelindex = CartesianIndex(7, 2), entry_time = 6.0, exit_time = 7.0)
(voxelindex = CartesianIndex(8, 2), entry_time = 7.0, exit_time = 8.0)
(voxelindex = CartesianIndex(9, 3), entry_time = 8.0, exit_time = 9.0)
(voxelindex = CartesianIndex(10, 3), entry_time = 9.0, exit_time = 10.0)
```
"""
function eachtraversal end

firstlast(xs) = (first(xs), last(xs))

function _start_voxelindex(pos, edges)
    map(pos, edges) do pos, walls
        voxelindex = searchsortedlast(walls, pos)
        clamp(voxelindex, firstindex(walls), lastindex(walls) - 1)
    end
end

function interval_entry_exit_time(pos, vel, walls)
    x_left, x_right = firstlast(walls)
    invvel = 1/vel
    if vel == 0
        T = typeof((x_left  - pos) *invvel)
        isinside = x_left <= pos <= x_right
        if isinside
            T(-Inf), T(Inf)
        else
            T(Inf), T(-Inf)
        end
    else
        t_left  = (x_left  - pos) * invvel
        t_right = (x_right - pos) * invvel
        minmax(t_left, t_right)
    end
end

function entry_exit_time(pos, vel, limits)
    ts = map(interval_entry_exit_time, pos, vel, limits)::Tuple
    entry_time = maximum(first, ts)
    exit_time = minimum(last, ts)
    entry_time, exit_time
end

struct WallHit{N,T,V}
    position::NTuple{N,T}
    index::NTuple{N,Int}
    hittimes::NTuple{N,T}
    time::T
    velocity::NTuple{N,T}
    voxel_traversal_times::V
end

abstract type AbstractTraversalTime end

struct TraversalTime_Range{T} <: AbstractTraversalTime
    t::T
end
Base.getindex(o::TraversalTime_Range, i) = o.t
has_finite_travel_time(o::TraversalTime_Range) = isfinite(o.t)

struct TraversalTime_Vector{T,V} <: AbstractTraversalTime
    walls::V
    inv_velocity::T
end
Base.@propagate_inbounds function Base.getindex(o::TraversalTime_Vector, i)
    lo = get(o.walls, i , first(o.walls))
    hi = get(o.walls, i+1, last(o.walls))
    o.inv_velocity * (hi - lo)
end
has_finite_travel_time(o::TraversalTime_Vector) = isfinite(o.inv_velocity)

function inv_abs(x)
    T = typeof(x)
    ifelse(iszero(x), T(Inf), inv(abs(x)))
end
function AbstractTraversalTime(walls, velocity)
    TraversalTime_Vector(walls, inv_abs(velocity))
end
function AbstractTraversalTime(walls::AbstractRange, velocity)
    TraversalTime_Range(step(walls)*inv_abs(velocity))
end

function WallHit(;
    position,
    index,
    hittimes,
    time,
    velocity,
    voxel_traversal_times,
    )
    WallHit(
        position,
        index,
        hittimes,
        time,
        velocity,
        voxel_traversal_times,
    )
end
function WallHit(o::WallHit; position, time, index, hittimes, )
    WallHit(position, index, hittimes, time, o.velocity, o.voxel_traversal_times)
end
function Base.show(io::IO, o::WallHit)
    show(io, typeof(o))
    println(io, "(;")
    for pname in propertynames(o)
        val = getproperty(o, pname)
        println(io, "   $pname = $val,")
    end
    println(io, ")")
end

int_sign(x)::Int = Int(sign(x))
function next_wallhit(o::WallHit)
    dim          = argmin(o.hittimes)
    time_new     = o.hittimes[dim]
    position_new = let Δt = time_new-o.time
        map(o.velocity, o.position) do vel, pos
            vel*Δt + pos
        end
    end
    s = int_sign(o.velocity[dim])
    index_dim    = o.index[dim]+s
    index_new    = Base.setindex(o.index, index_dim, dim)
    hittime_new  = o.hittimes[dim] + o.voxel_traversal_times[dim][index_dim]
    hittimes_new = Base.setindex(o.hittimes, hittime_new, dim)
    WallHit(o,
        position=position_new,
        time=time_new,
        index=index_new,
        hittimes=hittimes_new,
    )
end

function enter(focus, velocity, edges)
    entry_time, exit_time = entry_exit_time(focus, velocity, edges)
    if exit_time >= 0
        time = max(entry_time,zero(entry_time))
        position = let time=time
            map(focus, velocity) do foc, vel
                foc + time * vel
            end
        end
        index = _start_voxelindex(position, edges)
        return (;position, index, time)
    else
        return nothing
    end
end

function grid_entry_time(focus, velocity, edges) # this might not be on a wall
    entry_time, exit_time = entry_exit_time(focus, velocity, edges)
    max.(entry_time, zero(entry_time))
end

struct EachTraversal{N,T,E}
    edges::E
    position::NTuple{N,T}
    velocity::NTuple{N,T}
    function EachTraversal(edges::NTuple{N,Any}, position, velocity) where {N}
        E = typeof(edges)
        x1 = sum(first,edges)
        x2 = sum(position)
        x3 = sum(velocity)
        T = typeof(x1 + x2 / x3)
        pos = _makeNTuple(NTuple{N,T}, position)
        vel = _makeNTuple(NTuple{N,T}, velocity)
        new{N,T,E}(edges, pos, vel)
    end
end

function eachtraversal(ray, edges)
    EachTraversal(edges, ray.position, ray.velocity)
end

function _makeNTuple(::Type{NTuple{1,T}}, xs)::Tuple{T} where {T}
    x1, = xs
    (T(x1),)
end
function _makeNTuple(::Type{NTuple{2,T}}, xs)::NTuple{2,T} where {T}
    x1,x2 = xs
    (T(x1),T(x2))
end
function _makeNTuple(::Type{NTuple{3,T}}, xs)::NTuple{3,T} where {T}
    x1,x2,x3 = xs
    (T(x1),T(x2), T(x3))
end
function _makeNTuple(::Type{NTuple{4,T}}, xs)::NTuple{4,T} where {T}
    x1,x2,x3,x4 = xs
    (T(x1),T(x2), T(x3), T(x4))
end
function _makeNTuple(::Type{NTuple{N,T}}, xs)::NTuple{N,T} where {N,T}
    NTuple{N,T}(xs)
end

const VoxelTraversal{N,T} = NamedTuple{(:voxelindex, :entry_time, :exit_time), Tuple{CartesianIndex{N}, T, T}}

Base.eltype(::Type{<:EachTraversal{N,T}}) where {N,T} = VoxelTraversal{N,T}
Base.IteratorSize(::Type{<:EachTraversal}) = Base.SizeUnknown()

function is_inside_walls(x, walls)
    lo, hi = firstlast(walls)
    lo <= x <= hi
end
function is_inside_edges(pos, edges)
    all(is_inside_walls.(pos,edges))
end

function Base.iterate(o::EachTraversal)
    entry_time = grid_entry_time(o.position, o.velocity, o.edges)
    isfinite(entry_time) || return nothing
    position = let t = entry_time
        map(o.position, o.velocity) do pos, vel
            pos + t * vel
        end
    end
    is_inside_edges(position, o.edges) || return nothing
    index = _start_voxelindex(position, o.edges)
    exit_state = _first_wallhit(position, o.velocity, o.edges, index, entry_time)
    exit_state === nothing && return nothing
    any(has_finite_travel_time, exit_state.voxel_traversal_times) || return nothing
    item::eltype(o) = (
        voxelindex=CartesianIndex(index),
        entry_time=entry_time,
        exit_time=exit_state.time,
    )
    item, exit_state
end

function _first_wallhit(position, velocity, edges, index, time)
    limits = map(edges, index) do r, i
        (r[i], r[i+1])
    end
    hittimes = let time = time
        map(position, velocity, limits) do pos, vel, lims
            interval_hit_times(pos,vel,lims) + time
        end
    end
    voxel_traversal_times = map(AbstractTraversalTime, edges,velocity)
    h = WallHit(;
        position,
        index,
        hittimes,
        time,
        velocity,
        voxel_traversal_times,
    )
    next_wallhit(h)
end

function interval_hit_times(pos::T, vel::T, lims) where {T}
    lo,hi = firstlast(lims)
    if iszero(vel)
        T(Inf)
    else
        max((hi - pos) / vel, (lo - pos) / vel)
    end
end

function is_inbound_voxelindex(o::EachTraversal, index::Tuple)
    all(
        map(o.edges,index) do r,i
            firstindex(r) <= i < lastindex(r)
        end
    )
end

function Base.iterate(o::EachTraversal, entry_state::WallHit)
    if !is_inbound_voxelindex(o, entry_state.index)
        return nothing
    end
    exit_state = next_wallhit(entry_state)
    item::eltype(o) = (
        voxelindex=CartesianIndex(entry_state.index),
        entry_time=entry_state.time,
        exit_time=exit_state.time,
    )
    item, exit_state
end

function limited_collect(itr, n)
    ret = eltype(itr)[]
    i = 0
    for x in itr
        i+= 1
        i > n && break
        push!(ret, x)
    end
    return ret
end
