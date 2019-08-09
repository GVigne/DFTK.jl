"""
    self_consistent_field(ham::Hamiltonian, n_bands::Int, n_electrons::Int;
                          ρ=nothing, tol=1e-6, max_iter=100, algorithm=:scf_nlsolve,
                          lobpcg_prec=PreconditionerKinetic(ham, α=0.1))

Run a self-consistent field iteration for the Hamiltonian `ham`, returning the
self-consistnet density, Hartree potential values and XC potential values.
`n_bands` selects the number of bands to be computed, `n_electrons` the number of
electrons, `ρ` is the initial density, e.g. constructed via a SAD guess.
`lobpcg_prec` specifies the preconditioner used in the LOBPCG algorithms used
for diagonalisation. Possible `algorithm`s are `:scf_nlsolve` or `:scf_damped`.
"""
function self_consistent_field(ham::Hamiltonian, n_bands::Int, n_electrons::Int;
                               ρ=nothing, tol=1e-6, T=0, smearing=nothing,
                               lobpcg_prec=PreconditionerKinetic(ham, α=0.1),
                               max_iter=100, algorithm=:scf_nlsolve, kwargs...)
    if smearing === nothing
        compute_occupation(basis, energies, Psi) = occupation_step(basis, energies, Psi,
                                                                   n_electrons)
    else
        function compute_occupation(basis, energies, Psi)
            occupation_temperature(basis, energies, Psi, n_electrons, T, smearing=smearing)
        end
    end

    ρ === nothing && ρ = guess_hcore(ham, n_bands, compute_occupation,
                                     lobpcg_prec=lobpcg_prec)
    if algorithm == :scf_nlsolve
        res = scf_nlsolve(ham, n_bands, compute_occupation, ρ, tol=tol,
                          lobpcg_prec=lobpcg_prec, max_iter=max_iter; kwargs...)
    elseif algorithm == :scf_damped
        res = scf_damped(ham, n_bands, compute_occupation, ρ, tol=tol,
                         lobpcg_prec=lobpcg_prec, max_iter=max_iter; kwargs...)
    else
        error("Unknown algorithm " * string(algorithm))
    end

    res
end
