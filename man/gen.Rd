% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/genscore.R
\name{gen}
\alias{gen}
\title{Random data generator from general \code{a}-\code{b} distributions with general domain types, assuming a and b are rational numbers.}
\usage{
gen(
  n,
  setting,
  abs,
  eta,
  K,
  domain,
  finite_infinity = NULL,
  xinit = NULL,
  seed = NULL,
  burn_in = 1000,
  thinning = 100,
  verbose = TRUE,
  remove_outofbound = TRUE
)
}
\arguments{
\item{n}{An integer, number of observations.}

\item{setting}{A string that indicates the distribution type, must be one of \code{"exp"}, \code{"gamma"}, \code{"gaussian"}, \code{"log_log"}, \code{"log_log_sum0"}, or of the form \code{"ab_NUM1_NUM2"}, where \code{NUM1} is the \code{a} value and \code{NUM2} is the \code{b} value, and \code{NUM1} and \code{NUM2} must be integers or two integers separated by "/", e.g. "ab_2_2", "ab_2_5/4" or "ab_2/3_1/2".}

\item{abs}{A boolean. If TRUE, density is rewritten as f(|x|), i.e. with |x|^(a_numer/a_denom) and |x|^(b_numer/b_denom)}

\item{eta}{A vector, the linear part in the distribution.}

\item{K}{A square matrix, the interaction matrix. There should exist some C > 0 such that \deqn{{\boldsymbol{x}^a}^{\top}\mathbf{K}{\boldsymbol{x}}^a/({\boldsymbol{x}^a}^{\top}{\boldsymbol{x}}^a) >= C} for all x in the domain (i.e. \code{K} is positive definite if \code{domain$type == "R"} and \code{K} is co-positive if \code{domain$type == "R+"}.). If \code{a_numer == a_denom == b_numer == b_denom == 0 && domain$type == "simplex"}, K can also have all row and column sums equal to 0 but have all but one eigenvalues (0) positive.}

\item{domain}{A list returned from \code{make_domain()} that represents the domain.}

\item{finite_infinity}{A finite positive number. \code{Inf} in actual generation will be truncated to \code{finite_infinity} if applicable. Although the code will adaptively increase \code{finite_infinity}, the user should set it to a large number initially so that \code{abs(x) > finite_infinity} with very small probability.}

\item{xinit}{Optional. A \code{p}-vector, an initial point in the domain. If the domain is defined by more than one ineq or by one ineq containing negative coefficients, this must be provided. In the unlikely case where the function fails to automatically generate an initial point this should also be provided.}

\item{seed}{Optional. A number, the seed for the random generator.}

\item{burn_in}{Optional. A positive integer, the number of burn-in samples in ARMS to be discarded, meaning that samples from the first \code{burn_in} x \code{thinning} iterations will be discarded.}

\item{thinning}{Optional. A positive integer, thinning factor in ARMS. Samples are taken at iteration steps \eqn{(\mathrm{burn\_in}+1)\times\mathrm{thinning}}{(burn_in+1) x thinning}, ..., \eqn{(\mathrm{burn\_in}+n)\times\mathrm{thinning}}{(burn_in+n) x thinning}. Default to \code{100}.}

\item{verbose}{Optional. A boolean. If \code{TRUE}, prints a progress bar showing the progress. Defaults to \code{TRUE}.}

\item{remove_outofbound}{Optional. A logical, defaults to \code{TRUE}. If \code{TRUE}, a test whether each sample lies inside the domain will be done, which may take a while for larger sample sizes, and rows that do not lie in the domain will be removed (may happen for \code{domain$type == "polynomial"} with more than 1 ineq and an OR ("|") in \code{domain$rule}.).}
}
\value{
An \eqn{n\times p}{n*p} matrix of samples, where \eqn{p} is the length of \code{eta}.
}
\description{
Random data generator from general \code{a}-\code{b} graphs with general domain types using adaptive rejection metropolis sampling (ARMS). x^(0/0) treated as log(x) and x^(n/0) as exp(x) for n non-zero. Density only guaranteed to be a proper density when 2*a > b >= 0 or when a = b = 0.
}
\details{
NOTE: For polynomial domains with many ineqs and a rule containing "OR" ("|"), not all samples generated are guaranteed to be inside the domain. It is thus recommended to set \code{remove_outofbound} to \code{TRUE} and rerun the function with new initial points until the desired number of in-bound samples have been generated.

Randomly generates \code{n} samples from the \code{p}-variate \code{a}-\code{b} distributions with parameters \eqn{\boldsymbol{\eta}}{\eta} and \eqn{\mathbf{K}}{K}, where \code{p} is the length of \eqn{\boldsymbol{\eta}}{\eta} or the dimension of the square matrix \eqn{\mathbf{K}}{K}.

Letting \code{a=a_numer/a_denom} and \code{b=b_numer/b_denom}, the \code{a}-\code{b} distribution is proportional to
\deqn{\exp\left(-\frac{1}{2a}{\boldsymbol{x}^a}^{\top}\mathbf{K}{\boldsymbol{x}}^a+\boldsymbol{\eta}^{\top}\frac{\boldsymbol{x}^b-\mathbf{1}_p}{b}\right)}{exp(-x^a'Kx^a/(2a)+eta'(x^b-rep(1,p))/b)}.
Note that \code{x^(0/0)} is understood as \code{log(x)}, and \code{x^(n/0)} with nonzero \code{n} is \code{exp(n*x)}, and in both cases the \code{a} and \code{b} in the denominators in the density are treated as 1.
}
\examples{
n <- 20
p <- 10
eta <- rep(0, p)
K <- diag(p)
dm <- 1 + (1-1/(1+4*exp(1)*max(6*log(p)/n, sqrt(6*log(p)/n))))

# Gaussian on sum(x^2) > 10 && sum(x^(1/3)) > 10 with x allowed to be negative
domain <- make_domain("polynomial", p=p, rule="1 && 2",
       ineqs=list(list("expression"="sum(x^2)>10", abs=FALSE, nonnegative=FALSE),
                      list("expression"="sum(x^(1/3))>10", abs=FALSE, nonnegative=FALSE)))
xinit <- rep(sqrt(20/p), p)
x <- gen(n, setting="gaussian", abs=FALSE, eta=eta,  K=K, domain=domain,
       finite_infinity=100, xinit=xinit, seed=2, burn_in=1000, thinning=100)

# exp on ([0, 1] v [2,3])^p
domain <- make_domain("uniform", p=p, lefts=c(0,2), rights=c(1,3))
x <- gen(n, setting="exp", abs=FALSE, eta=eta, K=K, domain=domain,
       xinit=NULL, seed=2, burn_in=1000, thinning=100, verbose=TRUE)

# gamma on {x1 > 1 && log(1.3) < x2 < 1 && x3 > log(1.3) && ... && xp > log(1.3)}
domain <- make_domain("polynomial", p=p, rule="1 && 2 && 3",
       ineqs=list(list("expression"="x1>1", abs=FALSE, nonnegative=TRUE),
                      list("expression"="x2<1", abs=FALSE, nonnegative=TRUE),
                      list("expression"="exp(x)>1.3", abs=FALSE, nonnegative=FALSE)))
set.seed(1)
xinit <- c(1.5, 0.5, abs(stats::rnorm(p-2))+log(1.3))
x <- gen(n, setting="gamma", abs=FALSE, eta=eta, K=K, domain=domain,
       finite_infinity=100, xinit=xinit, seed=2, burn_in=1000, thinning=100)

# a0.6_b0.7 on {x in R_+^p: sum(log(x))<2 || (x1^(2/3)-1.3x2^(-3)<1 && exp(x1)+2.3*x2>2)}
domain <- make_domain("polynomial", p=p, rule="1 || (2 && 3)",
       ineqs=list(list("expression"="sum(log(x))<2", abs=FALSE, nonnegative=TRUE),
                      list("expression"="x1^(2/3)-1.3x2^(-3)<1", abs=FALSE, nonnegative=TRUE),
                      list("expression"="exp(x1)+2.3*x2^2>2", abs=FALSE, nonnegative=TRUE)))
xinit <- rep(1, p)
x <- gen(n, setting="ab_3/5_7/10", abs=FALSE, eta=eta, K=K, domain=domain,
       finite_infinity=1e4, xinit=xinit, seed=2, burn_in=1000, thinning=100)

# log_log model exp(-log(x) \%*\% K \%*\% log(x)/2 + eta \%*\% log(x)) on {x in R_+^p: sum_j j * xj <= 1}
domain <- make_domain("polynomial", p=p,
       ineqs=list(list("expression"=paste(paste(sapply(1:p,
                           function(j){paste(j, "x", j, sep="")}), collapse="+"), "<1"),
                     abs=FALSE, nonnegative=TRUE)))
x <- gen(n, setting="log_log", abs=FALSE, eta=eta, K=K, domain=domain,
       finite_infinity=100, xinit=NULL, seed=2, burn_in=1000, thinning=100)

# log_log model on the simplex with K having row and column sums 0 (Aitchison model)
domain <- make_domain("simplex", p=p)
K <- -cov_cons("band", p=p, spars=3, eig=1)
diag(K) <- diag(K) - rowSums(K) # So that rowSums(K) == colSums(K) == 0
eigen(K)$val[(p-1):p] # Make sure K has one 0 and p-1 positive eigenvalues
x <- gen(n, setting="log_log_sum0", abs=FALSE, eta=eta, K=K, domain=domain,
       xinit=NULL, seed=2, burn_in=1000, thinning=100, verbose=TRUE)

# Gumbel_Gumbel model exp(-exp(2x) \%*\% K \%*\% exp(2x)/2 + eta \%*\% exp(-3x)) on {sum(|x|) < 1}
domain <- make_domain("polynomial", p=p,
       ineqs=list(list("expression"="sum(x)<1", abs=TRUE, nonnegative=FALSE)))
K <- diag(p)
x <- gen(n, setting="ab_2/0_-3/0", abs=FALSE, eta=eta, K=K, domain=domain,
       finite_infinity=100, xinit=NULL, seed=2, burn_in=1000, thinning=100)
}
