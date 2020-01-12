export eachtraversal

using LinearAlgebra
using ArgCheck

struct EachTraversal{N,T, E <: Tuple}
    edges::E
    position::NTuple{N, T}
    velocity::NTuple{N, T}
    invvelocity::NTuple{N, T}
    signs::NTuple{N,Int}
end

Base.IteratorSize(::Type{<:EachTraversal}) = Base.SizeUnknown()
function Base.eltype(::Type{<:EachTraversal{N,T}}) where {N,T}
    NamedTuple{(:voxelindex, :entry_time, :exit_time), Tuple{CartesianIndex{N}, T, T}}
end

function eachtraversal(ray, edges)
    EachTraversal(edges, ray.position, ray.velocity)
end

function EachTraversal(edges::NTuple{N, AbstractVector}, position::AbstractVector, velocity::AbstractVector) where {N}
    @argcheck norm(velocity) > 0
    @argcheck length(edges) == length(position) == length(velocity)
    T = typeof(first(position) / first(velocity))
    Tup = NTuple{N, T}
    velocity = Tup(velocity)
    position = Tup(position)
    invvelocity = map(velocity) do vel
        if vel == 0
            typeof(vel)(NaN)
        else
            inv(vel)
        end
    end
    signs = map(Int∘sign, velocity)
    E = typeof(edges)
    EachTraversal{N,T,E}(edges, position, velocity, invvelocity, signs)
end

function Base.iterate(tracer::EachTraversal)
    limits = map(tracer.edges) do xs
        first(xs), last(xs)
    end
    t_entry, t_exit = enter_exit_time(tracer.position, tracer.velocity, limits)
    @assert t_exit > t_entry
    t_entry = max(t_entry, zero(t_entry))
    pos = let t_entry = t_entry
        map(tracer.position, tracer.velocity) do pos, vel
            t_entry * vel + pos
        end
    end
    voxelindex = _start_voxelindex(pos, tracer.edges)::Tuple
    state = (voxelindex=voxelindex, entry_time=t_entry, stop_time=t_exit)
    while true
        # do not allow spurious intersections
        res = iterate(tracer, state)
        res == nothing && return res
        new_item, new_state = res
        @assert new_state.voxelindex != state.voxelindex
        if new_item.entry_time != new_item.exit_time
            return res
        end
        state = new_state
    end
end

@inline function Base.iterate(tracer::EachTraversal, state)
    if state.entry_time >= state.stop_time
        return nothing
    end
    walls::Tuple = map(state.voxelindex, tracer.signs, tracer.edges) do ivoxel, sign, xs
        iwall = ifelse(sign <= 0, ivoxel, ivoxel+1)
        xs[iwall]
    end

    ts = map(tracer.position, tracer.invvelocity, walls) do pos, invvel, wall
        (wall - pos) * invvel
    end::Tuple

    exit_time = nanminimum(ts)
    new_voxelindex = map(state.voxelindex, ts, tracer.signs) do i, ti, sign
        ifelse(exit_time == ti, i + sign, i)::Int
    end
    item = (voxelindex=CartesianIndex(state.voxelindex), entry_time = state.entry_time, exit_time=exit_time)
    new_state = (voxelindex=new_voxelindex, entry_time=exit_time, stop_time=state.stop_time)
    item, new_state
end

function nanminimum(ts)
    minimum(ts) do t
        ifelse(isnan(t), typeof(t)(Inf), t)
    end
end

function _start_voxelindex(pos, edges)
    map(pos, edges) do pos, walls
        voxelindex = searchsortedlast(walls, pos)
        clamp(voxelindex, firstindex(walls), lastindex(walls) - 1)
    end
end

function interval_enter_exit_time(pos, vel, (x_left, x_right))
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

function enter_exit_time(pos, vel, limits)
    ts = map(interval_enter_exit_time, pos, vel, limits)::Tuple
    enter_time = maximum(first, ts)
    exit_time = minimum(last, ts)
    enter_time, exit_time
end
