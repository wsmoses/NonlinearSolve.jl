"""
    GaussNewton(; concrete_jac = nothing, linsolve = nothing, linesearch = nothing,
        precs = DEFAULT_PRECS, adkwargs...)

An advanced GaussNewton implementation with support for efficient handling of sparse
matrices via colored automatic differentiation and preconditioned linear solvers. Designed
for large-scale and numerically-difficult nonlinear least squares problems.

### Keyword Arguments

  - `autodiff`: determines the backend used for the Jacobian. Note that this argument is
    ignored if an analytical Jacobian is passed, as that will be used instead. Defaults to
    `nothing` which means that a default is selected according to the problem specification!
    Valid choices are types from ADTypes.jl.
  - `concrete_jac`: whether to build a concrete Jacobian. If a Krylov-subspace method is used,
    then the Jacobian will not be constructed and instead direct Jacobian-vector products
    `J*v` are computed using forward-mode automatic differentiation or finite differencing
    tricks (without ever constructing the Jacobian). However, if the Jacobian is still needed,
    for example for a preconditioner, `concrete_jac = true` can be passed in order to force
    the construction of the Jacobian.
  - `linsolve`: the [LinearSolve.jl](https://github.com/SciML/LinearSolve.jl) used for the
    linear solves within the Newton method. Defaults to `nothing`, which means it uses the
    LinearSolve.jl default algorithm choice. For more information on available algorithm
    choices, see the [LinearSolve.jl documentation](https://docs.sciml.ai/LinearSolve/stable/).
  - `precs`: the choice of preconditioners for the linear solver. Defaults to using no
    preconditioners. For more information on specifying preconditioners for LinearSolve
    algorithms, consult the
    [LinearSolve.jl documentation](https://docs.sciml.ai/LinearSolve/stable/).
  - `linesearch`: the line search algorithm to use. Defaults to [`NoLineSearch()`](@ref),
    which means that no line search is performed.  Algorithms from `LineSearches.jl` must be
    wrapped in `LineSearchesJL` before being supplied.
  - `vjp_autodiff`: Automatic Differentiation Backend used for vector-jacobian products.
    This is applicable if the linear solver doesn't require a concrete jacobian, for eg.,
    Krylov Methods. Defaults to `nothing`, which means if the problem is out of place and
    `Zygote` is loaded then, we use `AutoZygote`. In all other, cases `FiniteDiff` is used.
"""
function GaussNewton(; concrete_jac = nothing, linsolve = nothing, precs = DEFAULT_PRECS,
        linesearch = NoLineSearch(), vjp_autodiff = nothing, autodiff = nothing)
    descent = NewtonDescent(; linsolve, precs)

    if !(linesearch isa AbstractNonlinearSolveLineSearchAlgorithm)
        Base.depwarn("Passing in a `LineSearches.jl` algorithm directly is deprecated. \
                      Please use `LineSearchesJL` instead.", :GaussNewton)
        linesearch = LineSearchesJL(; method = linesearch)
    end

    forward_ad = ifelse(autodiff isa ADTypes.AbstractForwardMode, autodiff, nothing)
    reverse_ad = vjp_autodiff

    return GeneralizedFirstOrderRootFindingAlgorithm{concrete_jac, :GaussNewton}(linesearch,
        descent, autodiff, forward_ad, reverse_ad)
end
