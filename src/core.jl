export eachvoxelentry

using StaticArrays
using LinearAlgebra
using ArgCheck

struct EachVoxelEntered{N,T, E}
    edges::E
    position::SVector{N, T}
    velocity::SVector{N, T}
    invvelocity::SVector{N, T}
    signs::NTuple{N,Int}
end

Base.IteratorSize(::Type{<:EachVoxelEntered}) = Base.SizeUnknown()
function Base.eltype(::Type{<:EachVoxelEntered{N,T}}) where {N,T}
    NamedTuple{(:position, :index, :time), Tuple{SVector{N,T}, CartesianIndex{N}, T}}
end

function eachvoxelentry(ray, edges)
    EachVoxelEntered(edges, ray.position, ray.velocity)

end
function EachVoxelEntered(edges::NTuple{N}, position::AbstractVector{T}, velocity::AbstractVector{T}) where {N,T}
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
    EachVoxelEntered{N,T,E}(edges, position, velocity, invvelocity, signs)
end

function Base.iterate(prob::EachVoxelEntered)
    limits = map(extrema, prob.edges)
    t_entry, t_exit = enter_exit_time(prob.position, prob.velocity, limits)
    t_entry = max(t_entry, zero(t_entry))
    if t_exit < t_entry
        return nothing
    else
        pos = t_entry * prob.velocity + prob.position
        index = containing_bin_index(pos, prob.edges)::Tuple
        state = index
        item = (position=pos, index=CartesianIndex(index), time=t_entry)
        item, state
    end
end

function Base.iterate(prob::EachVoxelEntered, index)
    walls::Tuple = map(index, prob.signs, prob.edges) do i, sign, xs
        if sign > 0
            xs[i+1]
        else
            xs[i]
        end
    end

    ts = map(Tuple(prob.position), Tuple(prob.invvelocity), walls) do pos, invvel, x
        (x - pos) * invvel
    end::Tuple

    t = nanminimum(ts)
    @assert t > 0
    new_index = map(index, ts, prob.signs) do i, ti, sign 
        if t == ti
            i + sign
        else
            i
        end
    end
    @assert new_index != index
    isinside = all(map(new_index, prob.edges) do i, xs
            firstindex(xs) <= i <= lastindex(xs) - 1
        end::Tuple)

    if isinside
        new_position = prob.position + prob.velocity * t
        item = (position=new_position, index=CartesianIndex(new_index), time = t)
        new_state = new_index
        return item, new_state
    else
        return nothing
    end
end

function nanminimum(ts)
    minimum(ts) do t
        ifelse(isnan(t), typeof(t)(Inf), t)
    end
end

function containing_bin_index(pos, edges)
    map(containing_interval_index, Tuple(pos), edges)
end

function containing_interval_index(pos, walls)
    searchsortedlast(walls, pos)
end

function interval_enter_exit_time(pos, vel, (x_left, x_right))
    if vel == 0
        T = typeof((x_left  - pos) / vel)
        isinside = x_left <= pos <= x_right
        if isinside
            T(-Inf), T(Inf)
        else
            T(Inf), T(-Inf)
        end
    else
        t_left  = (x_left  - pos) / vel
        t_right = (x_right - pos) / vel
        minmax(t_left, t_right)
    end
end

function enter_exit_time(pos, vel, limits)
    ts = map(interval_enter_exit_time, Tuple(pos), Tuple(vel), Tuple(limits))::Tuple
    enter_time = maximum(first, ts)
    exit_time = minimum(last, ts)
    enter_time, exit_time
end

