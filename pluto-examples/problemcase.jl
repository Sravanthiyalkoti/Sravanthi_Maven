### A Pluto.jl notebook ###
# v0.18.0

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ b6b826a1-b52f-41d3-8feb-b6464f76352e
begin
    import Pkg as _Pkg
    developing=false
    if  isfile(joinpath(@__DIR__,"..","src","VoronoiFVM.jl"))
	_Pkg.activate(@__DIR__)
        _Pkg.instantiate()
	using Revise
	developing=true
    end
    initialized=true
end;

# ╔═╡ 60941eaa-1aea-11eb-1277-97b991548781
begin
    if initialized
	using Test
	using VoronoiFVM
	using ExtendableGrids
	using PlutoUI
	using PlutoVista
	using GridVisualize
	default_plotter!(PlutoVista)
    end
end;

# ╔═╡ 5e13b3db-570c-4159-939a-7e2268f0a102
md"""
# Some problems with Voronoi FVM

Draft. J. Fuhrmann, Oct. 29. 2021. Updated Dec 19, 2021.

We discuss one of the critical cases for application the Voronoi finite volume method.
We provide some practical fix and opine that the finite element method proably has the same problems.
"""

# ╔═╡ 556480e0-94f1-4e47-be9a-3e1e0e99555c
TableOfContents(;aside=false)

# ╔═╡ fae47c55-eef8-4428-bb5f-45824978753d
md"""
## Transient problem

This problem was suggested by R. Eymard.
"""

# ╔═╡ 8ba2300c-17ff-44e1-b33a-c5bdf1ce12fe
md"""
Regard the following problem coupling Darcy's equation with Fick's law and transport:
"""

# ╔═╡ 51c9517c-8797-4406-b053-301694fb0484
md"""
```math
  \begin{aligned}
    \vec v &= k \nabla p \\
    \nabla \cdot \vec v &= 0\\
    \partial_t (\phi c) - \nabla \cdot (D\nabla c + c \vec v) &= 0
  \end{aligned}
```
"""

# ╔═╡ 99341e32-9c78-4e31-bec0-d1ffbc85ec32
md"""
The domain is described by the following discretization grid:
"""

# ╔═╡ cd013964-f329-4d2c-ae4b-305093f0ac56
md"""
### Results

In the calculations, we ramp up the inlet concentration and  measure  the amount  of solute flowing  through the outlet - the breaktrough curve.
"""

# ╔═╡ afccbadb-2ca8-4c3e-8c6d-c78df59d8d7e
nref=1

# ╔═╡ dd9f8d38-8812-40ba-88c8-f873ec7d6121
tend=100

# ╔═╡ 5f6ac608-b1a0-450e-910e-d7d8ea2ffae0
ε_fix=1.0e-4


# ╔═╡ 5b60c7d4-7bdb-4989-b055-6695b9fdeedc
md"""
Here, we plot the solutions for the `grid_n` case and the `grid_f` case.
"""

# ╔═╡ f6abea66-1e42-4201-8433-5d092989749d
begin
	vis_n=GridVisualizer(dim=2,resolution=(210,150))
	vis_f=GridVisualizer(dim=2,resolution=(210,150))
	(vis_n,vis_f)
end

# ╔═╡ 98ae56dd-d42d-4a93-bb0b-5956b6e981a3
md"""
Time: $(@bind t Slider(1:tend/100:tend,show_value=true,default=tend*0.1))
"""

# ╔═╡ 99c3b54b-d458-482e-8aa0-d2c2b51fdf25
md"""
## Reaction-Diffusion problem

Here we solve the following problem:

```math
    -\nabla D \nabla u + R u = 0
```
where D is large in the high permeability region and small otherwise. R is a constant.

"""

# ╔═╡ eef85cd7-eba4-4c10-9e1d-38411179314d
md"""
### Results
"""


# ╔═╡ fcd066f1-bcd8-4479-a4e4-7b8c235336c4
md"""
## Discussion

### Transient case
As there will be nearly no flow
in  y-direction, we should  get the  very same  results in  all four
cases for small permeability values in the low permeability region.  

In the `grid_n` case,  the heterogeneous control volumina  ovrestimate the storage
capacity which shows itself  in a underestimation  of the
transferred solute.

With  the high  permeability contrast,  the results  for heterogeneous
domain should be essentially equal to those for 1D domain.
 However,   with  a   coarse  resolution   in
y-direction, we see large  differences in the transient behaviour of
the breaktrough curve compared to the 1D case.
The introduction of a thin  protection layer leads  to  reasonable   results.  


Alternatively, the porosity of the low permeability region can be modified.
Arguably, this is the case in practice, see e.g.
[Ackerer et al, Transport in Porous Media35:345–373, 1999](https://link.springer.com/content/pdf/10.1023/A:1006564309167.pdf)
(eq. 7).

### Reaction diffusion case
In this case, we look at a homogeneous reaction in a domain divided
into a high and low diffusion region. With high contrast in the diffusion
coefficients, the reasonable assumption is that the reaction takes place only
in the high diffusion region, and the un-consumed share of species leaves at the outlet.

In this case we observe a similar related problem which can be fixed by adding a thin layer
of control volumes at the boundary. No problem occurs if the reaction rate at in the low diffusion
region is zero.


### Conclusion

Here, we indeed observe problem with the Voronoi approach: care must be taken to handle the case
of hetero interfaces in connection with transient processes and/or homogeneous reactions.
In these cases it should be analyzed if the problem occurs, and why, and it appears, that the discussion
should not be had without reference to the correct physical models. A remedy based on meshing
is available at least for straight interfaces. 

### Opinion

With standard ways of using finite elements, the issue described here will occur in a similar way, so
the discussion is indeed with the alternative "cell centered" finite volume approach which places interfaces
at the boundaries of the control volumes rather than along the edges of a underlying triangulation.

#### Drawbacks of two point flux Voronoi methods based on simplicial meshes (as tested here):
- Anisotropic diffusion is only correct with aligned meshes
- Reliance on boundary conforming Delaunay property of the underyling mesh, thus narrowing the available meshing strategies
- The issue described  in the present notebook. However, in both cases discussed here, IMHO it might  "go  away"  depending on the correct physics.
  There should be more discussions with relevant application problems at hand.

#### Advantages (compared to the cell centered approach placing collocation points away from interfaces)
- Availability of P1 interpolant on simplices for visualization, interpolation, coupling etc.
- Mesh generators tend to place interfaces at triangle edges.
- Dirichlet BC can be applied exactly 
- There is a straighforward way to link interface processes with bulk processes, e.g. an adsorption reaction is easily described by a reaction term at the boundary which involves interface and bulk value available at the same mesh node.


"""

# ╔═╡ c9d92201-813c-499b-b863-b138c30eb634
md"""
## Appendix
"""

# ╔═╡ a372ac90-c871-4dc0-a44b-a5bddef71823
md"""
### Domain data
"""

# ╔═╡ 124b2a0a-ef19-453e-9e3a-5b5ce7db5fac
md"""
Sizes:
"""

# ╔═╡ 1ad18670-e7cb-4f7a-be0f-3db98cdeb6a4
begin
L=10   # length of the high perm layer
W=0.5  # width of high perm layer
Wlow=2 # width of adjacent low perm layers
end;

# ╔═╡ cc325b2c-6174-4b8d-8e39-202ac68b5705
md"""
In the center of the domain, we assume a layer with high permeability.

As  boundary  conditions for the pressure ``p`` we choose  fixed pressure values at  the left
and right boundaries of the  domain, triggering a constant pressure gradient throughout the domain.

At the inlet of the high  permeability layer, we set ``c=1``, and at the
outlet, we set ``c=0``.

The high permeability layer has length `L`=$( L) and width `W`= $(W).

We solve the time dependent problem on three types of  rectangular grids with the same
resolution in   $x$ direction and different variants to to handle the  high permeability
layer. 


- `grid_n` - a "naive" grid which just resolves the permeability layer and the surrounding material with equally spaced (in y direction) grids
- `grid_1` - a 1D grid  of the high permeability layer. With high permeability contrast, the solution of the 2D case at y=0 should conincide with the 1D solution
- `grid_f` - a "fixed" 2D grid which resolves the permeability layer and the surrounding material with equally spaced (in y direction) grids and "protection layers" of width `ε_fix`=$(ε_fix)  correcting the size of high permeability control volumes


"""

# ╔═╡ 47bc8e6a-e296-42c9-bfc5-967edfb0feb7
md"""
Boundary conditions:
"""

# ╔═╡ d1d5bad2-d282-4e7d-adb9-baf21f58155e
begin 
const Γ_top=3
const Γ_bot=1
const Γ_left=4
const Γ_right=2
const Γ_in=5
const Γ_out=2
end;

# ╔═╡ 9d736062-6821-46d9-9e49-34b43b78e814
begin
    Ω_low=1
    Ω_high=2
end;

# ╔═╡ 83b9931f-9020-4400-8aeb-31ad391184db
function grid_2d(;nref=0,ε_fix=0.0)
    nx=10*2^nref
    ny=1*2^nref
    nylow=3*2^nref	
    xc=linspace(0,L,nx+1)
    y0=linspace(-W/2,W/2,ny+1)
    if ε_fix>0.0
        yfix=[W/2,W/2+ε_fix]
	ytop=glue(yfix,linspace(yfix[end],Wlow,nylow+1))
    else
        ytop=linspace(W/2,Wlow,nylow+1)
    end
    yc=glue(-reverse(ytop),glue(y0,ytop))
    grid=simplexgrid(xc,yc)
    cellmask!(grid, [0,-W/2],[L,W/2],Ω_high)
    bfacemask!(grid, [0,-W/2],[0,W/2],Γ_in)
    bfacemask!(grid, [L,-W/2],[L,W/2],Γ_out)
end

# ╔═╡ 46a0f078-4165-4e37-9e69-e69af8584f6e
gridplot(grid_2d(),resolution=(400,300))

# ╔═╡ 3f693666-4026-4c01-a7aa-8c7dcbc32372
gridplot(grid_2d(;ε_fix=1.0e-1),resolution=(400,300))

# ╔═╡ c402f03c-746a-45b8-aaac-902a2f196094
function grid_1d(;nref=0)
    nx=10*2^nref
    xc=linspace(0,L,nx+1)
    grid=simplexgrid(xc)
    cellmask!(grid, [0],[L],Ω_high)
    bfacemask!(grid, [0],[0],Γ_in)
    bfacemask!(grid, [L],[L],Γ_out)
    grid
end

# ╔═╡ d772ac1b-3cda-4a2b-b0a9-b22b63b30653
md"""
### Transient solver
"""

# ╔═╡ a63a655c-e48b-4969-9409-31cd3db3bdaa
md"""
Pressure index in solution
"""

# ╔═╡ d7009231-4b43-44bf-96ba-9a203c0b5f5a
const ip=1;

# ╔═╡ 26965e38-91cd-4022-bdff-4c503f724bfe
md"""
Concentration index in solution
"""

# ╔═╡ c904c921-fa10-43eb-bd46-b2869fa7f431
const ic=2;

# ╔═╡ b143c846-2294-47f7-a2d1-8a6eabe942a3
md"""
Generate breaktrough courve from transient solution
"""

# ╔═╡ 92e4e4ab-3485-4cb9-9b41-e702a211a477
function breakthrough(sys,tf,sol)
	of=similar(sol.t)
	t=sol.t
	of[1]=0
	for i=2:length(sol.t)
	 of[i]=-integrate(sys,tf,sol[i],sol[i-1],t[i]-t[i-1])[ic]
	end
	of
end

# ╔═╡ 3df8bace-b4f1-4052-84f7-dff21d3a35f0
md"""
Transient solver:
"""

# ╔═╡ e866db69-9388-4691-99f7-879cf0658418
function trsolve(grid;
	κ=[1.0e-3,5], 
	D=[1.0e-12,1.0e-12],
	Δp=1.0,
	ϕ=[1,1],
	tend=100)
    
    function flux(y,u,edge)
        y[ip]=κ[edge.region]*(u[ip,1]-u[ip,2])
	bp,bm=fbernoulli_pm(y[ip]/D[edge.region]) 
        y[ic]=D[edge.region]*(bm*u[ic,1]-bp*u[ic,2])
    end
    
    function stor(y,u,node)
        y[ip]=0
        y[ic]=ϕ[node.region]*u[ic]
    end

 	dim=dim_space(grid)
	function bc(y,u,bnode)
		c0=ramp(bnode.time,dt=(0,0.001),du=(0,1))
	    boundary_dirichlet!(y,u,bnode,ic,Γ_in,c0)
    	boundary_dirichlet!(y,u,bnode,ic,Γ_out,0)
	
		boundary_dirichlet!(y,u,bnode,ip,Γ_in,Δp)
		boundary_dirichlet!(y,u,bnode,ip,Γ_out,0)
		if dim>1
			boundary_dirichlet!(y,u,bnode,ip,Γ_left,Δp)
			boundary_dirichlet!(y,u,bnode,ip,Γ_right,0)
		end
	end
	
    sys=VoronoiFVM.System(grid;check_allocs=true,flux=flux,storage=stor,bcondition=bc,species=[ip,ic])
	
    inival=VoronoiFVM.solve(sys,inival=0,time=0.0)
    factory=VoronoiFVM.TestFunctionFactory(sys)
    tfc=testfunction(factory,[Γ_in,Γ_left,Γ_top,Γ_bot],[Γ_out])
    
    
    sol=VoronoiFVM.solve(sys; inival=inival,times=[0,tend],Δt=1.0e-4,Δt_min=1.0e-6 )
    
    bt=breakthrough(sys,tfc,sol)
    if dim==1
		bt=bt*W
	end
    
    grid,sol,bt
end

# ╔═╡ cd88123a-b042-43e2-99b9-ec925a8794ed
grid_n,sol_n,bt_n=trsolve(grid_2d(nref=nref),tend=tend);

# ╔═╡ 1cf0db37-42cc-4dd9-9da3-ebb94ff63b1b
sum(bt_n)

# ╔═╡ c52ed973-2250-423a-b427-e91972f7ce74
@test sum(bt_n)≈ 17.643110936180495

# ╔═╡ b0ad0adf-6f6c-4fb3-b58e-e05cc8c0c796
grid_1,sol_1,bt_1=trsolve(grid_1d(nref=nref),tend=tend);

# ╔═╡ 02330841-fdf9-4ebe-9da6-cf96529b223c
@test sum(bt_1)≈ 20.412099101959157

# ╔═╡ e36d2aef-1b5a-45a7-9289-8d1e544bcedd
scalarplot(grid_1,sol_1(t)[ic,:],levels=0:0.2:1,resolution=(500,150),
xlabel="x",ylabel="c",title="1D calculation, t=$t")

# ╔═╡ 76b77ec0-27b0-4a02-9ae4-43d756eb09dd
grid_f,sol_f,bt_f=trsolve(grid_2d(nref=nref,ε_fix=ε_fix),tend=tend);

# ╔═╡ d23d6634-266c-43e3-9493-b61fb390bbe7
@test sum(bt_f)≈20.411131554885404

# ╔═╡ 732e79fa-5b81-4401-974f-37ea3427e770
begin
    scalarplot!(vis_n,grid_n,sol_n(t)[ic,:],resolution=(210,200),show=true),
    scalarplot!(vis_f,grid_f,sol_f(t)[ic,:],resolution=(210,200),show=true)
end

# ╔═╡ 904b36f0-10b4-4db6-9252-21668305de9c
grid_ϕ,sol_ϕ,bt_ϕ=trsolve(grid_2d(nref=nref), ϕ=[1.0e-3,1],tend=tend);

# ╔═╡ b260df8a-3721-4203-bc0c-a23bcab9a311
@test sum(bt_ϕ)≈20.4122562994476



# ╔═╡ ce49bb25-b2d0-4d17-a8fe-d7b62e9b20be
begin
    p1=PlutoVistaPlot(resolution=(500,200),xlabel="t",ylabel="outflow",
                     legend=:rb,
                     title="Breakthrough Curves")
    plot!(p1, sol_n.t,bt_n,label="naive grid")
    plot!(p1, sol_1.t,bt_1,label="1D grid",markertype=:x)
    plot!(p1, sol_f.t,bt_f,label="grid with fix",markertype=:circle)
    plot!(p1, sol_ϕ.t,bt_ϕ,label="modified ϕ",markertype=:cross)
end

# ╔═╡ 78d92b4a-bdb1-4117-ab9c-b422eac403b1
md"""
### Reaction-Diffusion solver
"""

# ╔═╡ bb3a50ed-32e7-4305-87d8-4093c054a4d2
function rdsolve(grid;D=[1.0e-12,1.0],R=[1,0.1])
    
    function flux(y,u,edge)
        y[1]=D[edge.region]*(u[1,1]-u[1,2])
    end

	function rea(y,u,node)
        y[1]=R[node.region]*u[1]
    end
	function bc(args...)
	    boundary_dirichlet!(args...,1,Γ_in,1)
   	    boundary_dirichlet!(args...,1,Γ_out,0)
	end
    sys=VoronoiFVM.System(grid,flux=flux,reaction=rea,species=1,bcondition=bc,check_allocs=true)
  	dim=dim_space(grid)
	

    sol=VoronoiFVM.solve(sys)
    factory=VoronoiFVM.TestFunctionFactory(sys)
    tf=testfunction(factory,[Γ_in,Γ_left,Γ_top,Γ_bot],[Γ_out])
   	of=integrate(sys,tf,sol) 
	    fac=1.0
	if dim==1
		fac=W
	end
    grid,sol[1,:],of[1]*fac

end

# ╔═╡ 2f560406-d169-4027-9cfe-7689494edf45
rdgrid_1,rdsol_1,of_1=rdsolve(grid_1d(nref=nref));

# ╔═╡ 40850999-12da-46cd-b86c-45808592fb9e
@test of_1 ≈ -0.013495959676585267

# ╔═╡ 34228382-4b1f-4897-afdd-19db7d5a7c59
scalarplot(rdgrid_1,rdsol_1,resolution=(300,200))

# ╔═╡ a6714eac-9e7e-4bdb-beb7-aca354664ad6
rdgrid_n,rdsol_n,of_n=rdsolve(grid_2d(nref=nref));

# ╔═╡ d1bfac0f-1f20-4c0e-9a9f-c7d36bc338ef
@test of_n ≈ -0.00023622450350365264

# ╔═╡ 20d7624b-f43c-4ac2-bad3-383a9e4e1b42
 rdgrid_f,rdsol_f,of_f=rdsolve(grid_2d(nref=nref,ε_fix=ε_fix));

# ╔═╡ 5d407d63-8a46-4480-94b4-80510eac5166
@test of_f ≈ -0.013466874615165499

# ╔═╡ 6a6d0e94-8f0d-4119-945c-dd48ec0798fd
begin
scalarplot(rdgrid_n,rdsol_n,resolution=(210,200)),
scalarplot(rdgrid_f,rdsol_f,resolution=(210,200))
end

# ╔═╡ c0fc1f71-52ba-41a9-92d1-74e82ac7826c
 rdgrid_r,rdsol_r,of_r=rdsolve(grid_2d(nref=nref),R=[0,0.1]);

# ╔═╡ 43622531-b7d0-44d6-b840-782021eb2ef0
@test of_r ≈ 	-0.013495959676764535

# ╔═╡ c08e86f6-b5c2-4762-af23-382b1b153f45
md"""
We measure the outflow at the outlet. As a result, we obtain:
   - 1D case: $(of_1)
   - 2D case, naive grid: $(of_n)
   - 2D case, grid with "protective layer": $(of_f)
   - 2D case, naive grid, "modified" R: $(of_r)
"""

# ╔═╡ 0cc1c511-f351-421f-991a-a27f26a8db4f
  html"<hr><hr><hr>"

# ╔═╡ 523f8b46-850b-4aab-a571-cc20024431d9
md"""
### Tests & Development
"""

# ╔═╡ 99c8458a-a584-4825-a983-ae1a05e50000
md"""
This notebook is also run during the automatic unit tests.

Furthermore, the cell activates a development environment if the notebook is loaded from a checked out VoronoiFVM.jl. Otherwise, Pluto's built-in package manager is used.
"""

# ╔═╡ 18d5cc77-e2de-4e14-a98d-a4a4b764b3b0
if developing 
	md""" Developing VoronoiFVM at  $(pathof(VoronoiFVM))"""
else
	md""" Loaded VoronoiFVM from  $(pathof(VoronoiFVM))"""
end

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
ExtendableGrids = "cfc395e8-590f-11e8-1f13-43a2532b2fa8"
GridVisualize = "5eed8a63-0fb0-45eb-886d-8d5a387d12b8"
Pkg = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
PlutoVista = "646e1f28-b900-46d7-9d87-d554eb38a413"
Revise = "295af30f-e4ad-537b-8983-00126c2a3abe"
Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
VoronoiFVM = "82b139dc-5afc-11e9-35da-9b9bdfd336f3"

[compat]
ExtendableGrids = "~0.8.7"
GridVisualize = "~0.4.4"
PlutoUI = "~0.7.16"
PlutoVista = "~0.8.12"
Revise = "~3.3.1"
VoronoiFVM = "~0.16.1"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.6.5"
manifest_format = "2.0"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "8eaf9f1b4921132a4cff3f36a1d9ba923b14a481"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.1.4"

[[deps.AbstractTrees]]
git-tree-sha1 = "03e0550477d86222521d254b741d470ba17ea0b5"
uuid = "1520ce14-60c1-5f80-bbc7-55ef81b5835c"
version = "0.3.4"

[[deps.Adapt]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "af92965fb30777147966f58acb05da51c5616b5f"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "3.3.3"

[[deps.ArgCheck]]
git-tree-sha1 = "a3a402a35a2f7e0b87828ccabbd5ebfbebe356b4"
uuid = "dce04be8-c92d-5529-be00-80e4d2c0e197"
version = "2.3.0"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"

[[deps.ArnoldiMethod]]
deps = ["LinearAlgebra", "Random", "StaticArrays"]
git-tree-sha1 = "62e51b39331de8911e4a7ff6f5aaf38a5f4cc0ae"
uuid = "ec485272-7323-5ecc-a04f-4719b315124d"
version = "0.2.0"

[[deps.ArrayInterface]]
deps = ["Compat", "IfElse", "LinearAlgebra", "Requires", "SparseArrays", "Static"]
git-tree-sha1 = "745233d77146ad221629590b6d82fe7f1ddb478f"
uuid = "4fba245c-0d91-5ea0-9b3e-6abc04ee57a9"
version = "4.0.3"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.AutoHashEquals]]
git-tree-sha1 = "45bb6705d93be619b81451bb2006b7ee5d4e4453"
uuid = "15f4f7f2-30c1-5605-9d31-71845cf9641f"
version = "0.2.0"

[[deps.BangBang]]
deps = ["Compat", "ConstructionBase", "Future", "InitialValues", "LinearAlgebra", "Requires", "Setfield", "Tables", "ZygoteRules"]
git-tree-sha1 = "d648adb5e01b77358511fb95ea2e4d384109fac9"
uuid = "198e06fe-97b7-11e9-32a5-e1d131e6ad66"
version = "0.3.35"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.Baselet]]
git-tree-sha1 = "aebf55e6d7795e02ca500a689d326ac979aaf89e"
uuid = "9718e550-a3fa-408a-8086-8db961cd8217"
version = "0.1.1"

[[deps.Bijections]]
git-tree-sha1 = "705e7822597b432ebe152baa844b49f8026df090"
uuid = "e2ed5e7c-b2de-5872-ae92-c73ca462fb04"
version = "0.1.3"

[[deps.Calculus]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "f641eb0a4f00c343bbc32346e1217b86f3ce9dad"
uuid = "49dc2e85-a5d0-5ad3-a950-438e2897f1b9"
version = "0.5.1"

[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "7dd38532a1115a215de51775f9891f0f3e1bac6a"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.12.1"

[[deps.ChangesOfVariables]]
deps = ["ChainRulesCore", "LinearAlgebra", "Test"]
git-tree-sha1 = "bf98fa45a0a4cee295de98d4c1462be26345b9a1"
uuid = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
version = "0.1.2"

[[deps.CodeTracking]]
deps = ["InteractiveUtils", "UUIDs"]
git-tree-sha1 = "9aa8a5ebb6b5bf469a7e0e2b5202cf6f8c291104"
uuid = "da1fd8a2-8d9e-5ec2-8556-3022fb5608a2"
version = "1.0.6"

[[deps.ColorSchemes]]
deps = ["ColorTypes", "Colors", "FixedPointNumbers", "Random"]
git-tree-sha1 = "12fc73e5e0af68ad3137b886e3f7c1eacfca2640"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.17.1"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "024fe24d83e4a5bf5fc80501a314ce0d1aa35597"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.0"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "417b0ed7b8b838aa6ca0a87aadf1bb9eb111ce40"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.8"

[[deps.Combinatorics]]
git-tree-sha1 = "08c8b6831dc00bfea825826be0bc8336fc369860"
uuid = "861a8166-3701-5b0c-9a16-15d98fcdc6aa"
version = "1.0.2"

[[deps.CommonSolve]]
git-tree-sha1 = "68a0743f578349ada8bc911a5cbd5a2ef6ed6d1f"
uuid = "38540f10-b2f7-11e9-35d8-d573e4eb0ff2"
version = "0.2.0"

[[deps.CommonSubexpressions]]
deps = ["MacroTools", "Test"]
git-tree-sha1 = "7b8a93dba8af7e3b42fecabf646260105ac373f7"
uuid = "bbf7d656-a473-5ed7-a52c-81e309532950"
version = "0.3.0"

[[deps.Compat]]
deps = ["Base64", "Dates", "DelimitedFiles", "Distributed", "InteractiveUtils", "LibGit2", "Libdl", "LinearAlgebra", "Markdown", "Mmap", "Pkg", "Printf", "REPL", "Random", "SHA", "Serialization", "SharedArrays", "Sockets", "SparseArrays", "Statistics", "Test", "UUIDs", "Unicode"]
git-tree-sha1 = "44c37b4636bc54afac5c574d2d02b625349d6582"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "3.41.0"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"

[[deps.CompositeTypes]]
git-tree-sha1 = "d5b014b216dc891e81fea299638e4c10c657b582"
uuid = "b152e2b5-7a66-4b01-a709-34e65c35f657"
version = "0.1.2"

[[deps.CompositionsBase]]
git-tree-sha1 = "455419f7e328a1a2493cabc6428d79e951349769"
uuid = "a33af91c-f02d-484b-be07-31d278c5ca2b"
version = "0.1.1"

[[deps.ConstructionBase]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "f74e9d5388b8620b4cee35d4c5a618dd4dc547f4"
uuid = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
version = "1.3.0"

[[deps.DataAPI]]
git-tree-sha1 = "cc70b17275652eb47bc9e5f81635981f13cea5c8"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.9.0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "3daef5523dd2e769dad2365274f760ff5f282c7d"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.11"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DefineSingletons]]
git-tree-sha1 = "0fba8b706d0178b4dc7fd44a96a92382c9065c2c"
uuid = "244e2a9f-e319-4986-a169-4d1fe445cd52"
version = "0.1.2"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"

[[deps.DensityInterface]]
deps = ["InverseFunctions", "Test"]
git-tree-sha1 = "80c3e8639e3353e5d2912fb3a1916b8455e2494b"
uuid = "b429d917-457f-4dbc-8f4c-0cc954292b1d"
version = "0.4.0"

[[deps.DiffResults]]
deps = ["StaticArrays"]
git-tree-sha1 = "c18e98cba888c6c25d1c3b048e4b3380ca956805"
uuid = "163ba53b-c6d8-5494-b064-1a9d43ac40c5"
version = "1.0.3"

[[deps.DiffRules]]
deps = ["IrrationalConstants", "LogExpFunctions", "NaNMath", "Random", "SpecialFunctions"]
git-tree-sha1 = "dd933c4ef7b4c270aacd4eb88fa64c147492acf0"
uuid = "b552c78f-8df3-52c6-915a-8e097449b14b"
version = "1.10.0"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.Distributions]]
deps = ["ChainRulesCore", "DensityInterface", "FillArrays", "LinearAlgebra", "PDMats", "Printf", "QuadGK", "Random", "SparseArrays", "SpecialFunctions", "Statistics", "StatsBase", "StatsFuns", "Test"]
git-tree-sha1 = "9d3c0c762d4666db9187f363a76b47f7346e673b"
uuid = "31c24e10-a181-5473-b8eb-7969acd0382f"
version = "0.25.49"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "b19534d1895d702889b219c382a6e18010797f0b"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.8.6"

[[deps.DomainSets]]
deps = ["CompositeTypes", "IntervalSets", "LinearAlgebra", "StaticArrays", "Statistics"]
git-tree-sha1 = "5f5f0b750ac576bcf2ab1d7782959894b304923e"
uuid = "5b8099bc-c8ec-5219-889f-1d9e522a28bf"
version = "0.5.9"

[[deps.Downloads]]
deps = ["ArgTools", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"

[[deps.DualNumbers]]
deps = ["Calculus", "NaNMath", "SpecialFunctions"]
git-tree-sha1 = "84f04fe68a3176a583b864e492578b9466d87f1e"
uuid = "fa6b7ba4-c1ee-5f82-b5fc-ecf0adba8f74"
version = "0.6.6"

[[deps.DynamicPolynomials]]
deps = ["DataStructures", "Future", "LinearAlgebra", "MultivariatePolynomials", "MutableArithmetics", "Pkg", "Reexport", "Test"]
git-tree-sha1 = "74e63cbb0fda19eb0e69fbe622447f1100cd8690"
uuid = "7c1d4256-1411-5781-91ec-d7bc3513ac07"
version = "0.4.3"

[[deps.EarCut_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "3f3a2501fa7236e9b911e0f7a588c657e822bb6d"
uuid = "5ae413db-bbd1-5e63-b57d-d24a61df00f5"
version = "2.2.3+0"

[[deps.ElasticArrays]]
deps = ["Adapt"]
git-tree-sha1 = "a0fcc1bb3c9ceaf07e1d0529c9806ce94be6adf9"
uuid = "fdbdab4c-e67f-52f5-8c3f-e7b388dad3d4"
version = "1.2.9"

[[deps.EllipsisNotation]]
deps = ["ArrayInterface"]
git-tree-sha1 = "d7ab55febfd0907b285fbf8dc0c73c0825d9d6aa"
uuid = "da5c29d0-fa7d-589e-88eb-ea29b0a81949"
version = "1.3.0"

[[deps.ExprTools]]
git-tree-sha1 = "56559bbef6ca5ea0c0818fa5c90320398a6fbf8d"
uuid = "e2ba6199-217a-4e67-a87a-7c52f15ade04"
version = "0.1.8"

[[deps.ExtendableGrids]]
deps = ["AbstractTrees", "Dates", "DocStringExtensions", "ElasticArrays", "InteractiveUtils", "LinearAlgebra", "Printf", "Random", "SparseArrays", "Test"]
git-tree-sha1 = "fbb0efd29f2ba5e25eeaf73b76257acfc1a28630"
uuid = "cfc395e8-590f-11e8-1f13-43a2532b2fa8"
version = "0.8.11"

[[deps.ExtendableSparse]]
deps = ["DocStringExtensions", "LinearAlgebra", "Printf", "Requires", "SparseArrays", "SuiteSparse", "Test"]
git-tree-sha1 = "793bd32bb280668e80c476ce4a3d0f171c8122d5"
uuid = "95c220a8-a1cf-11e9-0c77-dbfce5f500b3"
version = "0.6.6"

[[deps.FileIO]]
deps = ["Pkg", "Requires", "UUIDs"]
git-tree-sha1 = "80ced645013a5dbdc52cf70329399c35ce007fae"
uuid = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
version = "1.13.0"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FillArrays]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "Statistics"]
git-tree-sha1 = "4c7d3757f3ecbcb9055870351078552b7d1dbd2d"
uuid = "1a297f60-69ca-5386-bcde-b61e274b549b"
version = "0.13.0"

[[deps.FiniteDiff]]
deps = ["ArrayInterface", "LinearAlgebra", "Requires", "SparseArrays", "StaticArrays"]
git-tree-sha1 = "ec299fdc8f49ae450807b0cb1d161c6b76fd2b60"
uuid = "6a86dc24-6348-571c-b903-95158fe2bd41"
version = "2.10.1"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[deps.ForwardDiff]]
deps = ["CommonSubexpressions", "DiffResults", "DiffRules", "LinearAlgebra", "LogExpFunctions", "NaNMath", "Preferences", "Printf", "Random", "SpecialFunctions", "StaticArrays"]
git-tree-sha1 = "1bd6fc0c344fc0cbee1f42f8d2e7ec8253dda2d2"
uuid = "f6369f11-7733-5829-9624-2563aa707210"
version = "0.10.25"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[deps.GeometryBasics]]
deps = ["EarCut_jll", "IterTools", "LinearAlgebra", "StaticArrays", "StructArrays", "Tables"]
git-tree-sha1 = "58bcdf5ebc057b085e58d95c138725628dd7453c"
uuid = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
version = "0.4.1"

[[deps.Graphs]]
deps = ["ArnoldiMethod", "Compat", "DataStructures", "Distributed", "Inflate", "LinearAlgebra", "Random", "SharedArrays", "SimpleTraits", "SparseArrays", "Statistics"]
git-tree-sha1 = "57c021de207e234108a6f1454003120a1bf350c4"
uuid = "86223c79-3864-5bf0-83f7-82e725a168b6"
version = "1.6.0"

[[deps.GridVisualize]]
deps = ["ColorSchemes", "Colors", "DocStringExtensions", "ElasticArrays", "ExtendableGrids", "GeometryBasics", "HypertextLiteral", "LinearAlgebra", "Observables", "OrderedCollections", "PkgVersion", "Printf", "StaticArrays"]
git-tree-sha1 = "a16fc5b8699afedb37aacbcf71d45eb794b589ea"
uuid = "5eed8a63-0fb0-45eb-886d-8d5a387d12b8"
version = "0.4.7"

[[deps.HypergeometricFunctions]]
deps = ["DualNumbers", "LinearAlgebra", "SpecialFunctions", "Test"]
git-tree-sha1 = "65e4589030ef3c44d3b90bdc5aac462b4bb05567"
uuid = "34004b35-14d8-5ef3-9330-4cdb6864b03a"
version = "0.3.8"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[deps.HypertextLiteral]]
git-tree-sha1 = "2b078b5a615c6c0396c77810d92ee8c6f470d238"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.3"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "f7be53659ab06ddc986428d3a9dcc95f6fa6705a"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.2"

[[deps.IfElse]]
git-tree-sha1 = "debdd00ffef04665ccbb3e150747a77560e8fad1"
uuid = "615f187c-cbe4-4ef1-ba3b-2fcf58d6d173"
version = "0.1.1"

[[deps.Inflate]]
git-tree-sha1 = "f5fc07d4e706b84f72d54eedcc1c13d92fb0871c"
uuid = "d25df0c9-e2be-5dd7-82c8-3ad0b3e990b9"
version = "0.1.2"

[[deps.InitialValues]]
git-tree-sha1 = "4da0f88e9a39111c2fa3add390ab15f3a44f3ca3"
uuid = "22cec73e-a1b8-11e9-2c92-598750a2cf9c"
version = "0.3.1"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.IntervalSets]]
deps = ["Dates", "EllipsisNotation", "Statistics"]
git-tree-sha1 = "3cc368af3f110a767ac786560045dceddfc16758"
uuid = "8197267c-284f-5f27-9208-e0e47529a953"
version = "0.5.3"

[[deps.InverseFunctions]]
deps = ["Test"]
git-tree-sha1 = "a7254c0acd8e62f1ac75ad24d5db43f5f19f3c65"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.2"

[[deps.IrrationalConstants]]
git-tree-sha1 = "7fd44fd4ff43fc60815f8e764c0f352b83c49151"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.1.1"

[[deps.IterTools]]
git-tree-sha1 = "fa6287a4469f5e048d763df38279ee729fbd44e5"
uuid = "c8e1da08-722c-5040-9ed9-7db0dc04731e"
version = "1.4.0"

[[deps.IterativeSolvers]]
deps = ["LinearAlgebra", "Printf", "Random", "RecipesBase", "SparseArrays"]
git-tree-sha1 = "1169632f425f79429f245113b775a0e3d121457c"
uuid = "42fd0dbc-a981-5370-80f2-aaf504508153"
version = "0.9.2"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLD2]]
deps = ["FileIO", "MacroTools", "Mmap", "OrderedCollections", "Pkg", "Printf", "Reexport", "TranscodingStreams", "UUIDs"]
git-tree-sha1 = "28b114b3279cdbac9a61c57b3e6548a572142b34"
uuid = "033835bb-8acc-5ee8-8aae-3f567f8a3819"
version = "0.4.21"

[[deps.JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "abc9885a7ca2052a736a600f7fa66209f96506e1"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.4.1"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "3c837543ddb02250ef42f4738347454f95079d4e"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.3"

[[deps.JuliaInterpreter]]
deps = ["CodeTracking", "InteractiveUtils", "Random", "UUIDs"]
git-tree-sha1 = "b55aae9a2bf436fc797d9c253a900913e0e90178"
uuid = "aa1ae85d-cabe-5617-a682-6adf51b2e16a"
version = "0.9.3"

[[deps.LaTeXStrings]]
git-tree-sha1 = "f2355693d6778a178ade15952b7ac47a4ff97996"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.0"

[[deps.LabelledArrays]]
deps = ["ArrayInterface", "ChainRulesCore", "LinearAlgebra", "MacroTools", "StaticArrays"]
git-tree-sha1 = "3696fdc1d3ef6e4d19551c92626066702a5db91c"
uuid = "2ee39098-c373-598a-b85f-a56591580800"
version = "1.7.1"

[[deps.Latexify]]
deps = ["Formatting", "InteractiveUtils", "LaTeXStrings", "MacroTools", "Markdown", "Printf", "Requires"]
git-tree-sha1 = "2a8650452c07a9c89e6a58f296fd638fadaca021"
uuid = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
version = "0.15.11"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LinearAlgebra]]
deps = ["Libdl"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.LogExpFunctions]]
deps = ["ChainRulesCore", "ChangesOfVariables", "DocStringExtensions", "InverseFunctions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "e5718a00af0ab9756305a0392832c8952c7426c1"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.6"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.LoweredCodeUtils]]
deps = ["JuliaInterpreter"]
git-tree-sha1 = "6b0440822974cab904c8b14d79743565140567f6"
uuid = "6f1432cf-f94c-5a45-995e-cdbf5db27b0b"
version = "2.2.1"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "3d3e902b31198a27340d0bf00d6ac452866021cf"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.9"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"

[[deps.Metatheory]]
deps = ["AutoHashEquals", "DataStructures", "Dates", "DocStringExtensions", "Parameters", "Reexport", "TermInterface", "ThreadsX", "TimerOutputs"]
git-tree-sha1 = "0886d229caaa09e9f56bcf1991470bd49758a69f"
uuid = "e9d8d322-4543-424a-9be4-0cc815abe26c"
version = "1.3.3"

[[deps.MicroCollections]]
deps = ["BangBang", "InitialValues", "Setfield"]
git-tree-sha1 = "6bb7786e4f24d44b4e29df03c69add1b63d88f01"
uuid = "128add7d-3638-4c79-886c-908ea0c25c34"
version = "0.1.2"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "bf210ce90b6c9eed32d25dbcae1ebc565df2687f"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.0.2"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"

[[deps.MultivariatePolynomials]]
deps = ["DataStructures", "LinearAlgebra", "MutableArithmetics"]
git-tree-sha1 = "fa6ce8c91445e7cd54de662064090b14b1089a6d"
uuid = "102ac46a-7ee4-5c85-9060-abc95bfdeaa3"
version = "0.4.2"

[[deps.MutableArithmetics]]
deps = ["LinearAlgebra", "SparseArrays", "Test"]
git-tree-sha1 = "842b5ccd156e432f369b204bb704fd4020e383ac"
uuid = "d8a4904e-b15c-11e9-3269-09a3773c0cb0"
version = "0.3.3"

[[deps.NaNMath]]
git-tree-sha1 = "b086b7ea07f8e38cf122f5016af580881ac914fe"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "0.3.7"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"

[[deps.Observables]]
git-tree-sha1 = "fe29afdef3d0c4a8286128d4e45cc50621b1e43d"
uuid = "510215fc-4207-5dde-b226-833fc4488ee2"
version = "0.4.0"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[deps.PDMats]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "ee26b350276c51697c9c2d88a072b339f9f03d73"
uuid = "90014a1f-27ba-587c-ab20-58faa44d9150"
version = "0.11.5"

[[deps.Parameters]]
deps = ["OrderedCollections", "UnPack"]
git-tree-sha1 = "34c0e9ad262e5f7fc75b10a9952ca7692cfc5fbe"
uuid = "d96e819e-fc66-5662-9728-84c9c7592b0a"
version = "0.12.3"

[[deps.Parsers]]
deps = ["Dates"]
git-tree-sha1 = "13468f237353112a01b2d6b32f3d0f80219944aa"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.2.2"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"

[[deps.PkgVersion]]
deps = ["Pkg"]
git-tree-sha1 = "a7a7e1a88853564e551e4eba8650f8c38df79b37"
uuid = "eebad327-c553-4316-9ea0-9fa01ccd7688"
version = "0.1.1"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "Markdown", "Random", "Reexport", "UUIDs"]
git-tree-sha1 = "8979e9802b4ac3d58c503a20f2824ad67f9074dd"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.34"

[[deps.PlutoVista]]
deps = ["ColorSchemes", "Colors", "DocStringExtensions", "GridVisualize", "HypertextLiteral", "UUIDs"]
git-tree-sha1 = "2435d1d3e02db324414f268f30999b5c06a0d10f"
uuid = "646e1f28-b900-46d7-9d87-d554eb38a413"
version = "0.8.12"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "2cf929d64681236a2e074ffafb8d568733d2e6af"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.2.3"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.QuadGK]]
deps = ["DataStructures", "LinearAlgebra"]
git-tree-sha1 = "78aadffb3efd2155af139781b8a8df1ef279ea39"
uuid = "1fd47b50-473d-5c70-9696-f719f8f3bcdc"
version = "2.4.2"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.RecipesBase]]
git-tree-sha1 = "6bf3f380ff52ce0832ddd3a2a7b9538ed1bcca7d"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.2.1"

[[deps.RecursiveArrayTools]]
deps = ["Adapt", "ArrayInterface", "ChainRulesCore", "DocStringExtensions", "FillArrays", "LinearAlgebra", "RecipesBase", "Requires", "StaticArrays", "Statistics", "ZygoteRules"]
git-tree-sha1 = "736699f42935a2b19b37a6c790e2355ca52a12ee"
uuid = "731186ca-8d62-57ce-b412-fbd966d074cd"
version = "2.24.2"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.Referenceables]]
deps = ["Adapt"]
git-tree-sha1 = "e681d3bfa49cd46c3c161505caddf20f0e62aaa9"
uuid = "42d2dcc6-99eb-4e98-b66c-637b7d73030e"
version = "0.1.2"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.Revise]]
deps = ["CodeTracking", "Distributed", "FileWatching", "JuliaInterpreter", "LibGit2", "LoweredCodeUtils", "OrderedCollections", "Pkg", "REPL", "Requires", "UUIDs", "Unicode"]
git-tree-sha1 = "2f9d4d6679b5f0394c52731db3794166f49d5131"
uuid = "295af30f-e4ad-537b-8983-00126c2a3abe"
version = "3.3.1"

[[deps.Rmath]]
deps = ["Random", "Rmath_jll"]
git-tree-sha1 = "bf3188feca147ce108c76ad82c2792c57abe7b1f"
uuid = "79098fc4-a85e-5d69-aa6a-4863f24498fa"
version = "0.7.0"

[[deps.Rmath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "68db32dff12bb6127bac73c209881191bf0efbb7"
uuid = "f50d1b31-88e8-58de-be2c-1cc44531875f"
version = "0.3.0+0"

[[deps.RuntimeGeneratedFunctions]]
deps = ["ExprTools", "SHA", "Serialization"]
git-tree-sha1 = "cdc1e4278e91a6ad530770ebb327f9ed83cf10c4"
uuid = "7e49a35a-f44a-4d26-94aa-eba1b4ca6b47"
version = "0.5.3"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

[[deps.SciMLBase]]
deps = ["ArrayInterface", "CommonSolve", "ConstructionBase", "Distributed", "DocStringExtensions", "IteratorInterfaceExtensions", "LinearAlgebra", "Logging", "RecipesBase", "RecursiveArrayTools", "StaticArrays", "Statistics", "Tables", "TreeViews"]
git-tree-sha1 = "f4862c0cb4e34ed182718221028ba1bf50742108"
uuid = "0bca4576-84f4-4d90-8ffe-ffa030f20462"
version = "1.26.1"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Setfield]]
deps = ["ConstructionBase", "Future", "MacroTools", "Requires"]
git-tree-sha1 = "0afd9e6c623e379f593da01f20590bacc26d1d14"
uuid = "efcf1570-3423-57d1-acb7-fd33fddbac46"
version = "0.8.1"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[deps.SimpleTraits]]
deps = ["InteractiveUtils", "MacroTools"]
git-tree-sha1 = "5d7e3f4e11935503d3ecaf7186eac40602e7d231"
uuid = "699a6c99-e7fa-54fc-8d76-47d257e15c1d"
version = "0.9.4"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "b3363d7460f7d098ca0912c69b082f75625d7508"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.0.1"

[[deps.SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.SparseDiffTools]]
deps = ["Adapt", "ArrayInterface", "Compat", "DataStructures", "FiniteDiff", "ForwardDiff", "Graphs", "LinearAlgebra", "Requires", "SparseArrays", "StaticArrays", "VertexSafeGraphs"]
git-tree-sha1 = "87efd1676d87706f4079e8e717a7a5f02b6ea1ad"
uuid = "47a9eef4-7e08-11e9-0b38-333d64bd3804"
version = "1.20.2"

[[deps.SpecialFunctions]]
deps = ["ChainRulesCore", "IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "8d0c8e3d0ff211d9ff4a0c2307d876c99d10bdf1"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.1.2"

[[deps.SplittablesBase]]
deps = ["Setfield", "Test"]
git-tree-sha1 = "39c9f91521de844bad65049efd4f9223e7ed43f9"
uuid = "171d559e-b47b-412a-8079-5efa626c420e"
version = "0.1.14"

[[deps.Static]]
deps = ["IfElse"]
git-tree-sha1 = "00b725fffc9a7e9aac8850e4ed75b4c1acbe8cd2"
uuid = "aedffcd0-7271-4cad-89d0-dc628f76c6d3"
version = "0.5.5"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "Random", "Statistics"]
git-tree-sha1 = "95c6a5d0e8c69555842fc4a927fc485040ccc31c"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.3.5"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "c3d8ba7f3fa0625b062b82853a7d5229cb728b6b"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.2.1"

[[deps.StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "8977b17906b0a1cc74ab2e3a05faa16cf08a8291"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.33.16"

[[deps.StatsFuns]]
deps = ["ChainRulesCore", "HypergeometricFunctions", "InverseFunctions", "IrrationalConstants", "LogExpFunctions", "Reexport", "Rmath", "SpecialFunctions"]
git-tree-sha1 = "25405d7016a47cf2bd6cd91e66f4de437fd54a07"
uuid = "4c63d2b9-4356-54db-8cca-17b64c39e42c"
version = "0.9.16"

[[deps.StructArrays]]
deps = ["Adapt", "DataAPI", "StaticArrays", "Tables"]
git-tree-sha1 = "d21f2c564b21a202f4677c0fba5b5ee431058544"
uuid = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
version = "0.6.4"

[[deps.SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

[[deps.SymbolicUtils]]
deps = ["AbstractTrees", "Bijections", "ChainRulesCore", "Combinatorics", "ConstructionBase", "DataStructures", "DocStringExtensions", "DynamicPolynomials", "IfElse", "LabelledArrays", "LinearAlgebra", "Metatheory", "MultivariatePolynomials", "NaNMath", "Setfield", "SparseArrays", "SpecialFunctions", "StaticArrays", "TermInterface", "TimerOutputs"]
git-tree-sha1 = "bfa211c9543f8c062143f2a48e5bcbb226fd790b"
uuid = "d1185830-fcd6-423d-90d6-eec64667417b"
version = "0.19.7"

[[deps.Symbolics]]
deps = ["ArrayInterface", "ConstructionBase", "DataStructures", "DiffRules", "Distributions", "DocStringExtensions", "DomainSets", "IfElse", "Latexify", "Libdl", "LinearAlgebra", "MacroTools", "Metatheory", "NaNMath", "RecipesBase", "Reexport", "Requires", "RuntimeGeneratedFunctions", "SciMLBase", "Setfield", "SparseArrays", "SpecialFunctions", "StaticArrays", "SymbolicUtils", "TermInterface", "TreeViews"]
git-tree-sha1 = "074e08aea1c745664da5c4b266f50b840e528b1c"
uuid = "0c5d862f-8b57-4792-8d23-62f2024744c7"
version = "4.3.0"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "TableTraits", "Test"]
git-tree-sha1 = "bb1064c9a84c52e277f1096cf41434b675cd368b"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.6.1"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"

[[deps.TermInterface]]
git-tree-sha1 = "7aa601f12708243987b88d1b453541a75e3d8c7a"
uuid = "8ea1fca8-c5ef-4a55-8b96-4e9afe9c9a3c"
version = "0.2.3"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.ThreadsX]]
deps = ["ArgCheck", "BangBang", "ConstructionBase", "InitialValues", "MicroCollections", "Referenceables", "Setfield", "SplittablesBase", "Transducers"]
git-tree-sha1 = "6dad289fe5fc1d8e907fa855135f85fb03c8fa7a"
uuid = "ac1d9e8a-700a-412c-b207-f0111f4b6c0d"
version = "0.1.9"

[[deps.TimerOutputs]]
deps = ["ExprTools", "Printf"]
git-tree-sha1 = "97e999be94a7147d0609d0b9fc9feca4bf24d76b"
uuid = "a759f4b9-e2f1-59dc-863e-4aeb61b1ea8f"
version = "0.5.15"

[[deps.TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "216b95ea110b5972db65aa90f88d8d89dcb8851c"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.6"

[[deps.Transducers]]
deps = ["Adapt", "ArgCheck", "BangBang", "Baselet", "CompositionsBase", "DefineSingletons", "Distributed", "InitialValues", "Logging", "Markdown", "MicroCollections", "Requires", "Setfield", "SplittablesBase", "Tables"]
git-tree-sha1 = "1cda71cc967e3ef78aa2593319f6c7379376f752"
uuid = "28d57a85-8fef-5791-bfe6-a80928e7c999"
version = "0.4.72"

[[deps.TreeViews]]
deps = ["Test"]
git-tree-sha1 = "8d0d7a3fe2f30d6a7f833a5f19f7c7a5b396eae6"
uuid = "a2a6695c-b41b-5b7d-aed9-dbfdeacea5d7"
version = "0.3.0"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.UnPack]]
git-tree-sha1 = "387c1f73762231e86e0c9c5443ce3b4a0a9a0c2b"
uuid = "3a884ed6-31ef-47d7-9d2a-63182c4928ed"
version = "1.0.2"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.VertexSafeGraphs]]
deps = ["Graphs"]
git-tree-sha1 = "8351f8d73d7e880bfc042a8b6922684ebeafb35c"
uuid = "19fa3120-7c27-5ec5-8db8-b0b0aa330d6f"
version = "0.2.0"

[[deps.VoronoiFVM]]
deps = ["DiffResults", "DocStringExtensions", "ExtendableGrids", "ExtendableSparse", "ForwardDiff", "GridVisualize", "IterativeSolvers", "JLD2", "LinearAlgebra", "Parameters", "Printf", "RecursiveArrayTools", "Requires", "SparseArrays", "SparseDiffTools", "StaticArrays", "Statistics", "SuiteSparse", "Symbolics", "Test"]
git-tree-sha1 = "65c630b0d2b30890a01197a00962740e89d59268"
uuid = "82b139dc-5afc-11e9-35da-9b9bdfd336f3"
version = "0.16.1"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"

[[deps.ZygoteRules]]
deps = ["MacroTools"]
git-tree-sha1 = "8c1a8e4dfacb1fd631745552c8db35d0deb09ea0"
uuid = "700de1a5-db45-46bc-99cf-38207098b444"
version = "0.2.2"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
"""

# ╔═╡ Cell order:
# ╟─5e13b3db-570c-4159-939a-7e2268f0a102
# ╟─556480e0-94f1-4e47-be9a-3e1e0e99555c
# ╠═60941eaa-1aea-11eb-1277-97b991548781
# ╟─fae47c55-eef8-4428-bb5f-45824978753d
# ╟─8ba2300c-17ff-44e1-b33a-c5bdf1ce12fe
# ╟─51c9517c-8797-4406-b053-301694fb0484
# ╟─99341e32-9c78-4e31-bec0-d1ffbc85ec32
# ╟─46a0f078-4165-4e37-9e69-e69af8584f6e
# ╟─cc325b2c-6174-4b8d-8e39-202ac68b5705
# ╟─3f693666-4026-4c01-a7aa-8c7dcbc32372
# ╟─cd013964-f329-4d2c-ae4b-305093f0ac56
# ╠═afccbadb-2ca8-4c3e-8c6d-c78df59d8d7e
# ╠═dd9f8d38-8812-40ba-88c8-f873ec7d6121
# ╠═5f6ac608-b1a0-450e-910e-d7d8ea2ffae0
# ╠═cd88123a-b042-43e2-99b9-ec925a8794ed
# ╠═1cf0db37-42cc-4dd9-9da3-ebb94ff63b1b
# ╠═c52ed973-2250-423a-b427-e91972f7ce74
# ╠═b0ad0adf-6f6c-4fb3-b58e-e05cc8c0c796
# ╠═02330841-fdf9-4ebe-9da6-cf96529b223c
# ╠═76b77ec0-27b0-4a02-9ae4-43d756eb09dd
# ╠═d23d6634-266c-43e3-9493-b61fb390bbe7
# ╠═904b36f0-10b4-4db6-9252-21668305de9c
# ╠═b260df8a-3721-4203-bc0c-a23bcab9a311
# ╟─ce49bb25-b2d0-4d17-a8fe-d7b62e9b20be
# ╟─5b60c7d4-7bdb-4989-b055-6695b9fdeedc
# ╟─f6abea66-1e42-4201-8433-5d092989749d
# ╟─e36d2aef-1b5a-45a7-9289-8d1e544bcedd
# ╟─98ae56dd-d42d-4a93-bb0b-5956b6e981a3
# ╟─732e79fa-5b81-4401-974f-37ea3427e770
# ╟─99c3b54b-d458-482e-8aa0-d2c2b51fdf25
# ╟─eef85cd7-eba4-4c10-9e1d-38411179314d
# ╠═2f560406-d169-4027-9cfe-7689494edf45
# ╠═40850999-12da-46cd-b86c-45808592fb9e
# ╠═a6714eac-9e7e-4bdb-beb7-aca354664ad6
# ╠═d1bfac0f-1f20-4c0e-9a9f-c7d36bc338ef
# ╠═20d7624b-f43c-4ac2-bad3-383a9e4e1b42
# ╠═5d407d63-8a46-4480-94b4-80510eac5166
# ╠═c0fc1f71-52ba-41a9-92d1-74e82ac7826c
# ╠═43622531-b7d0-44d6-b840-782021eb2ef0
# ╟─c08e86f6-b5c2-4762-af23-382b1b153f45
# ╠═34228382-4b1f-4897-afdd-19db7d5a7c59
# ╟─6a6d0e94-8f0d-4119-945c-dd48ec0798fd
# ╟─fcd066f1-bcd8-4479-a4e4-7b8c235336c4
# ╟─c9d92201-813c-499b-b863-b138c30eb634
# ╟─a372ac90-c871-4dc0-a44b-a5bddef71823
# ╟─124b2a0a-ef19-453e-9e3a-5b5ce7db5fac
# ╠═1ad18670-e7cb-4f7a-be0f-3db98cdeb6a4
# ╟─47bc8e6a-e296-42c9-bfc5-967edfb0feb7
# ╠═d1d5bad2-d282-4e7d-adb9-baf21f58155e
# ╠═9d736062-6821-46d9-9e49-34b43b78e814
# ╠═83b9931f-9020-4400-8aeb-31ad391184db
# ╠═c402f03c-746a-45b8-aaac-902a2f196094
# ╟─d772ac1b-3cda-4a2b-b0a9-b22b63b30653
# ╟─a63a655c-e48b-4969-9409-31cd3db3bdaa
# ╠═d7009231-4b43-44bf-96ba-9a203c0b5f5a
# ╟─26965e38-91cd-4022-bdff-4c503f724bfe
# ╠═c904c921-fa10-43eb-bd46-b2869fa7f431
# ╟─b143c846-2294-47f7-a2d1-8a6eabe942a3
# ╠═92e4e4ab-3485-4cb9-9b41-e702a211a477
# ╟─3df8bace-b4f1-4052-84f7-dff21d3a35f0
# ╠═e866db69-9388-4691-99f7-879cf0658418
# ╟─78d92b4a-bdb1-4117-ab9c-b422eac403b1
# ╠═bb3a50ed-32e7-4305-87d8-4093c054a4d2
# ╟─0cc1c511-f351-421f-991a-a27f26a8db4f
# ╟─523f8b46-850b-4aab-a571-cc20024431d9
# ╟─99c8458a-a584-4825-a983-ae1a05e50000
# ╠═b6b826a1-b52f-41d3-8feb-b6464f76352e
# ╟─18d5cc77-e2de-4e14-a98d-a4a4b764b3b0
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
