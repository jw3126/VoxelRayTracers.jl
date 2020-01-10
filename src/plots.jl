using RecipesBase

function addline!(xs, ys, from, to)
    x_from, y_from = from
    x_to, y_to = to
    push!(xs, NaN, x_from, x_to, NaN)
    push!(ys, NaN, y_from, y_to, NaN)
    xs, ys
end

struct Grid
    edges
end

@recipe function plot(o::Grid)
    @argcheck length(o.edges) == 2
    xs = Float64[]
    ys = Float64[]
    (x_min, x_max), (y_min, y_max) = map(extrema, o.edges)
    s = 1.1
    xlims --> (s*x_min, s*x_max)
    ylims --> (s*y_min, s*y_max)
    for x in o.edges[1]
        from = [x, y_min]
        to = [x, y_max]
        addline!(xs, ys, from, to)
    end
    for y in o.edges[2]
        from = [x_min, y]
        to = [x_max, y]
        addline!(xs, ys, from, to)
    end
    xs, ys
end

@recipe function plot(o::EachTraversal{2})
    # grid
    legend --> :false
    @series begin
        Grid(o.edges)
    end

    # @series begin
    #     seriestype --> :scatter
    #     marker --> :o
    #     [o.position[1]], [o.position[2]]
    # end

    marker --> :x
    hits = collect(o)
    if isempty(hits)
        xs = [NaN]
        ys = [NaN]
    else
        xs, ys = map(1:2) do axis
            xs = Float64[]
            pos = o.position[axis]
            vel = o.velocity[axis]
            for hit in hits
                t = hit.entry_time
                push!(xs, pos + t*vel)
            end
            if !isempty(hits)
                t = last(hits).exit_time
                push!(xs, pos + t*vel)
            end
        end
    end
    xs, ys
end

