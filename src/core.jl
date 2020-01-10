export eachtraversal

using StaticArrays
using LinearAlgebra
using ArgCheck

struct EachTraversal{N,T, E}
    edges::E
    position::SVector{N, T}
    velocity::SVector{N, T}
    invvelocity::SVector{N, T}
    signs::NTuple{N,Int}
end

Base.IteratorSize(::Type{<:EachTraversal}) = Base.SizeUnknown()
function Base.eltype(::Type{<:EachTraversal{N,T}}) where {N,T}
    NamedTuple{(:index, :entry_time, :exit_time), Tuple{CartesianIndex{N}, T, T}}
end

function eachtraversal(ray, edges)
    EachTraversal(edges, ray.position, ray.velocity)

end
function EachTraversal(edges::NTuple{N, AbstractVector}, position::AbstractVector{T}, velocity::AbstractVector{T}) where {N,T}
    @argcheck norm(velocity) > 0
    @argcheck length(edges) == length(position) == length(velocity)
    invvelocity = map(velocity) do vel
        if vel == 0
            typeof(vel)(Inf)
        else
            inv(vel)
        end
    end
    signs = map(Int∘sign, Tuple(velocity))
    E = typeof(edges)
    EachTraversal{N,T,E}(edges, position, velocity, invvelocity, signs)
end

function Base.iterate(tracer::EachTraversal)
    limits = map(extrema, tracer.edges)
    t_entry, t_exit = enter_exit_time(tracer.position, tracer.velocity, limits)
    t_entry = max(t_entry, zero(t_entry))
    pos = t_entry * tracer.velocity + tracer.position
    index = _containing_bin_index(pos, tracer.edges, tracer.signs)::Tuple
    state = (index=index, entry_time=t_entry, stop_time=t_exit)
    iterate(tracer, state)
end

@inline function Base.iterate(tracer::EachTraversal, state)
    if state.entry_time >= state.stop_time
        return nothing
    end
    walls::Tuple = map(state.index, tracer.signs, tracer.edges) do ivoxel, sign, xs
        iwall = ifelse(sign <= 0, ivoxel, ivoxel+1)
        xs[iwall]
    end

    ts = map(Tuple(tracer.position), Tuple(tracer.invvelocity), walls) do pos, invvel, wall
        (wall - pos) * invvel
    end::Tuple

    exit_time = nanminimum(ts)
    @assert (exit_time > state.entry_time)
    # @show state
    # @show walls
    # @show ts

    #     error()
    # end
    new_index = map(state.index, ts, tracer.signs) do i, ti, sign
        ifelse(exit_time == ti, i + sign, i)::Int
    end
    @assert new_index != state.index
    item = (index=CartesianIndex(state.index), entry_time = state.entry_time, exit_time=exit_time)
    new_state = (index=new_index, entry_time=exit_time, stop_time=state.stop_time)
    return item, new_state
end

function nanminimum(ts)
    minimum(ts) do t
        ifelse(isnan(t), typeof(t)(Inf), t)
    end
end

function _containing_bin_index(pos, edges, signs)
    map(_containing_interval_index, Tuple(pos), edges, signs)
end

function _containing_interval_index(pos, walls, sign)
    # TODO this is hacky
    index = searchsortedlast(walls, pos)
    clamp(index, firstindex(walls), lastindex(walls) - 1)
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
    ts = map(interval_enter_exit_time, Tuple(pos), Tuple(vel), Tuple(limits))::Tuple
    enter_time = maximum(first, ts)
    exit_time = minimum(last, ts)
    enter_time, exit_time
end

