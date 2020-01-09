using RecipesBase

@recipe function plot(o::EachVoxelEntered{2})
    hits = collect(o)
    @series begin
        seriestype := :vline
        o.edges[1]
    end
    @series begin
        seriestype := :hline
        o.edges[2]
    end
    xs = map(hits) do hit
        hit.position[1]
    end
    ys = map(hits) do hit
        hit.position[2]
    end
    marker --> :x
    xs, ys
end

