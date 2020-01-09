using Documenter, VoxelRayTracers

makedocs(;
    modules=[VoxelRayTracers],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/jw3126/VoxelRayTracers.jl/blob/{commit}{path}#L{line}",
    sitename="VoxelRayTracers.jl",
    authors="Jan Weidner <jw3126@gmail.com>",
    assets=String[],
)

deploydocs(;
    repo="github.com/jw3126/VoxelRayTracers.jl",
)
