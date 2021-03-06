% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/genscore.R
\name{h_of_dist}
\alias{h_of_dist}
\title{Finds the distance of each element in a matrix x to the its boundary of the domain while fixing the others in the same row (dist(x, domain)), and calculates element-wise h(dist(x, domain)) and h\'(dist(x, domain)) (w.r.t. each element in x).}
\usage{
h_of_dist(h_hp, x, domain)
}
\arguments{
\item{h_hp}{A function, the \eqn{h} and \eqn{hp} (the derivative of \code{h}) functions. \code{h_hp(x)} should return a list of elements \code{hx} (\code{h(x)}) and \code{hpx} (\code{hp(x)}), both of which have the same size as \code{x}.}

\item{x}{An \code{n} by \code{p} matrix, the data matrix, where \code{n} is the sample size and \code{p} the dimension.}

\item{domain}{A list returned from \code{make_domain()} that represents the domain.}
}
\value{
A list that contains \code{h(dist(x, domain))} and \code{h\'(dist(x, domain))}.
  \item{hdx}{\code{h(dist(x, domain))}.}
  \item{hpdx}{\code{hp(dist(x, domain))}.}
}
\description{
Finds the distance of each element in a matrix  \code{x} to its boundary of the \code{domain} while fixing the others in the same row (\code{dist(x, domain)}), and calculates element-wise \code{h(dist(x, domain))} and \code{h\'(dist(x, domain))} (w.r.t. each element in \code{x}).
}
\details{
Define \code{dist(x, domain)} as the matrix whose \code{i,j}-th component is the distance of \eqn{x_{i,j}} to the boundary of \code{domain}, assuming \eqn{x_{i,-j}} are fixed. The matrix has the same size of \code{x} (\code{n} by \code{p}), or if \code{domain$type == "simplex"} and \code{x} has full dimension \code{p}, it has \code{p-1} columns.\cr
Define \code{dist\'(x, domain)} as the component-wise derivative of \code{dist(x, domain)} in its components. That is, its \code{i,j}-th component is 0 if \eqn{x_{i,j}} is unbounded or is bounded from both below and above or is at the boundary, or -1 if \eqn{x_{i,j}} is closer to its lower boundary (or if its bounded from below but unbounded from above), or 1 otherwise.\cr
\code{h_of_dist(h_hp, x, domain)} simply returns \code{h_hp(dist(x, domain))$hx} and \code{h_hp(dist(x, domain))$hpx * dist\'(x, domain)} (element-wise derivative of \code{h_hp(dist(x, domain))$hx} w.r.t. \code{x}).
}
\examples{
n <- 20
p <- 10
eta <- rep(0, p)
K <- diag(p)
dm <- 1 + (1-1/(1+4*exp(1)*max(6*log(p)/n, sqrt(6*log(p)/n))))

# Gaussian on R^p:
domain <- make_domain("R", p=p)
x <- mvtnorm::rmvnorm(n, mean=solve(K, eta), sigma=solve(K))
# Equivalently:
#x <- gen(n, setting="gaussian", abs=FALSE, eta=eta, K=K, domain=domain,
#       finite_infinity=100, xinit=NULL, burn_in=1000, thinning=100)
h_hp <- get_h_hp("pow", 2) # For demonstration only
hd <- h_of_dist(h_hp, x, domain)
# hdx is all Inf and hpdx is all 0 since each coordinate is unbounded with domain R
c(all(is.infinite(hd$hdx)), all(hd$hpdx==0))


# exp on R_+^p:
domain <- make_domain("R+", p=p)
x <- gen(n, setting="exp", abs=FALSE, eta=eta, K=K, domain=domain,
       finite_infinity=100, xinit=NULL, seed=2, burn_in=1000, thinning=100)
h_hp <- get_h_hp("pow", 2) # For demonstration only
hd <- h_of_dist(h_hp, x, domain)
# hdx is x^2 and hpdx is 2*x; with domain R+, the distance of x to the boundary is just x itself
c(max(abs(hd$hdx - x^2)), max(abs(hd$hpdx - 2*x)))


# Gaussian on sum(x^2) > p with x allowed to be negative
domain <- make_domain("polynomial", p=p,
       ineqs=list(list("expression"=paste("sum(x^2)>", p), abs=FALSE, nonnegative=FALSE)))
x <- gen(n, setting="gaussian", abs=FALSE, eta=eta, K=K, domain=domain,
       finite_infinity=100, xinit=NULL, seed=2, burn_in=1000, thinning=100)
dist <- get_dist(x, domain)
quota <- p - (rowSums(x^2) - x^2) # How much should xij^2 at least be so that sum(xi^2) > p?
# How far is xij from +/-sqrt(quota), if quota >= 0?
dist_to_bound <- abs(x[quota >= 0]) - abs(sqrt(quota[quota >= 0]))
# Should be equal to our own calculations
max(abs(dist$dx[is.finite(dist$dx)] - dist_to_bound))
# dist'(x) should be the same as the sign of x
all(dist$dpx[is.finite(dist$dx)] == sign(x[quota >= 0]))
# quota is negative <-> sum of x_{i,-j}^2 already > p <-> xij unbounded given others
#      <-> distance to boundary is Inf
all(quota[is.infinite(dist$dx)] < 0)

h_hp <- get_h_hp("pow", 2) # For demonstration only
# Now confirm that h_of_dist indeed applies h and hp to dists
hd <- h_of_dist(h_hp, x, domain)
# hdx = dist ^ 2
print(max(abs(hd$hdx[is.finite(dist$dx)] - dist$dx[is.finite(dist$dx)]^2)))
# hdx = Inf if dist = Inf
print(all(is.infinite(hd$hdx[is.infinite(dist$dx)])))
 # hpdx = 2 * dist' * dist
print(max(abs(hd$hpdx[is.finite(dist$dx)] - 2*(dist$dpx*dist$dx)[is.finite(dist$dx)])))
print(all(hd$hpdx[is.infinite(dist$dx)] == 0)) # hpdx = 0 if dist = Inf


# gamma on ([0, 1] v [2,3])^p
domain <- make_domain("uniform", p=p, lefts=c(0,2), rights=c(1,3))
x <- gen(n, setting="gamma", abs=FALSE, eta=eta, K=K, domain=domain,
       xinit=NULL, seed=2, burn_in=1000, thinning=100)
dist <- get_dist(x, domain)
# If 0 <= xij <= 1, distance to boundary is min(x-0, 1-x)
max(abs(dist$dx - pmin(x, 1-x))[x >= 0 & x <= 1])
# If 0 <= xij <= 1, dist'(xij) is 1 if it is closer to 0, or -1 if it is closer 1,
#   assuming xij \%in\% c(0, 0.5, 1) with probability 0
all((dist$dpx == 2 * (1-x > x) - 1)[x >= 0 & x <= 1])
# If 2 <= xij <= 3, distance to boundary is min(x-2, 3-x)
max(abs(dist$dx - pmin(x-2, 3-x))[x >= 2 & x <= 3])
# If 2 <= xij <= 3, dist'(xij) is 1 if it is closer to 2, or -1 if it is closer 3,
#   assuming xij \%in\% c(2, 2.5, 3) with probability 0
all((dist$dpx == 2 * (3-x > x-2) - 1)[x >= 2 & x <= 3])
h_hp <- get_h_hp("pow", 2) # For demonstration only
# Now confirm that h_of_dist indeed applies h and hp to dists
hd <- h_of_dist(h_hp, x, domain)
# hdx = dist ^ 2
print(max(abs(hd$hdx - dist$dx^2)))
# hpdx = 2 * dist' * dist
print(max(abs(hd$hpdx - 2*dist$dpx*dist$dx)))


# a0.6_b0.7 on {x1 > 1 && log(1.3) < x2 < 1 && x3 > log(1.3) && ... && xp > log(1.3)}
domain <- make_domain("polynomial", p=p, rule="1 && 2 && 3",
       ineqs=list(list("expression"="x1>1", abs=FALSE, nonnegative=TRUE),
                      list("expression"="x2<1", abs=FALSE, nonnegative=TRUE),
                      list("expression"="exp(x)>1.3", abs=FALSE, nonnegative=FALSE)))
set.seed(1)
xinit <- c(1.5, 0.5, abs(stats::rnorm(p-2)) + log(1.3))
x <- gen(n, setting="ab_3/5_7/10", abs=FALSE, eta=eta, K=K, domain=domain,
       finite_infinity=100, xinit=xinit, seed=2, burn_in=1000, thinning=100)
dist <- get_dist(x, domain)
# x_{i1} has uniform bound [1, +Inf), so its distance to its boundary is x_{i1} - 1
max(abs(dist$dx[,1] - (x[,1] - 1)))
# x_{i2} has uniform bound [log(1.3), 1], so its distance to its boundary
#    is min(x_{i2} - log(1.3), 1 - x_{i2})
max(abs(dist$dx[,2] - pmin(x[,2] - log(1.3), 1 - x[,2])))
# x_{ij} for j >= 3 has uniform bound [log(1.3), +Inf), so its distance to its boundary is
#    simply x_{ij} - log(1.3)
max(abs(dist$dx[,3:p] - (x[,3:p] - log(1.3))))
# dist'(xi2) is 1 if it is closer to log(1.3), or -1 if it is closer 1,
#    assuming x_{i2} \%in\% c(log(1.3), (1+log(1.3))/2, 1) with probability 0
all((dist$dpx[,2] == 2 * (1 - x[,2] > x[,2] - log(1.3)) - 1))
all(dist$dpx[,-2] == 1) # x_{ij} for j != 2 is bounded from below but unbounded from above,
#    so dist'(xij) is always 1
h_hp <- get_h_hp("pow", 2) # For demonstration only
# Now confirm that h_of_dist indeed applies h and hp to dists
hd <- h_of_dist(h_hp, x, domain)
# hdx = dist ^ 2
print(max(abs(hd$hdx - dist$dx^2)))
# hpdx = 2 * dist' * dist
print(max(abs(hd$hpdx - 2*dist$dpx*dist$dx)))


# log_log model on {x in R_+^p: sum_j j * xj <= 1}
domain <- make_domain("polynomial", p=p,
       ineqs=list(list("expression"=paste(paste(sapply(1:p,
                           function(j){paste(j, "x", j, sep="")}), collapse="+"), "<1"),
                     abs=FALSE, nonnegative=TRUE)))
x <- gen(n, setting="log_log", abs=FALSE, eta=eta, K=K, domain=domain,
       finite_infinity=100, xinit=NULL, seed=2, burn_in=1000, thinning=100)
dist <- get_dist(x, domain)
# Upper bound for j * xij so that sum_j j * xij <= 1
quota <- 1 - (rowSums(t(t(x) * 1:p)) - t(t(x) * 1:p))
# Distance of xij to its boundary is min(xij - 0, quota_{i,j} / j - xij)
max(abs(dist$dx - pmin((t(t(quota) / 1:p) - x), x)))
h_hp <- get_h_hp("pow", 2) # For demonstration only
# Now confirm that h_of_dist indeed applies h and hp to dists
hd <- h_of_dist(h_hp, x, domain)
# hdx = dist ^ 2
print(max(abs(hd$hdx - dist$dx^2)))
# hpdx = 2 * dist' * dist
print(max(abs(hd$hpdx - 2*dist$dpx*dist$dx)))


# log_log_sum0 model on the simplex with K having row and column sums 0 (Aitchison model)
domain <- make_domain("simplex", p=p)
K <- -cov_cons("band", p=p, spars=3, eig=1)
diag(K) <- diag(K) - rowSums(K) # So that rowSums(K) == colSums(K) == 0
eigen(K)$val[(p-1):p] # Make sure K has one 0 and p-1 positive eigenvalues
x <- gen(n, setting="log_log_sum0", abs=FALSE, eta=eta, K=K, domain=domain,
       xinit=NULL, seed=2, burn_in=1000, thinning=100, verbose=TRUE)
# Note that dist$dx and dist$dpx only has p-1 columns -- excluding the last coordinate in x
dist <- get_dist(x, domain)
# Upper bound for x_{i,j} so that x_{i,1} + ... + x_{i,p-1} <= 1
quota <- 1 - (rowSums(x[,-p]) - x[,-p])
# Distance of x_{i,j} to its boundary is min(xij - 0, quota_{i,j} - xij)
max(abs(dist$dx - pmin(quota - x[,-p], x[,-p])))
h_hp <- get_h_hp("pow", 2) # For demonstration only
# Now confirm that h_of_dist indeed applies h and hp to dists
hd <- h_of_dist(h_hp, x, domain)
# hdx = dist ^ 2
print(max(abs(hd$hdx - dist$dx^2)))
# hpdx = 2 * dist' * dist
print(max(abs(hd$hpdx - 2*dist$dpx*dist$dx)))
}
