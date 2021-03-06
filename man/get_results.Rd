% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/genscore.R
\name{get_results}
\alias{get_results}
\title{Estimate \eqn{\mathbf{K}}{K} and \eqn{\boldsymbol{\eta}}{\eta} using elts from \code{get_elts()} given one \eqn{\lambda_{\mathbf{K}}}{\lambda_K} (and \eqn{\lambda_{\boldsymbol{\eta}}}{\lambda_\eta} if non-profiled non-centered) and applying warm-start with strong screening rules.}
\usage{
get_results(
  elts,
  symmetric,
  lambda1,
  lambda2 = 0,
  tol = 1e-06,
  maxit = 10000,
  previous_res = NULL,
  is_refit = FALSE
)
}
\arguments{
\item{elts}{A list, elements necessary for calculations returned by \code{get_elts()}.}

\item{symmetric}{A string. If equals \code{"symmetric"}, estimates the minimizer \eqn{\mathbf{K}}{K} over all symmetric matrices; if \code{"and"} or \code{"or"}, use the "and"/"or" rule to get the support.}

\item{lambda1}{A number, the penalty parameter for \eqn{\mathbf{K}}{K}.}

\item{lambda2}{A number, the penalty parameter for \eqn{\boldsymbol{\eta}}{\eta}. Default to \code{0}. Cannot be \code{Inf} if non-profiled non-centered.}

\item{tol}{Optional. A number, the tolerance parameter.}

\item{maxit}{Optional. A positive integer, the maximum number of iterations.}

\item{previous_res}{Optional. A list or \code{NULL}, the returned list by this function run previously with another lambda value.}

\item{is_refit}{A boolean, in the refit mode for BIC estimation if \code{TRUE}. If \code{TRUE}, \code{lambda1}, \code{previous_lambda1} and \code{lambda2} are all set to \code{0}, and estimation is restricted to entries in exclude that are \code{0}.}
}
\value{
\item{converged}{A boolean indicating convergence.}
    \item{crit}{A number, the final penalized loss.}
    \item{edges}{A vector of the indices of entries in the \code{K} estimate that are non-zero.}
    \item{eta}{A p-vector, the \code{eta} estimate. Returned only if \code{elts$centered == FALSE}.}
    \item{eta_support}{A vector of the indices of entries in the \code{eta} estimate that are non-zero. Returned only if \code{elts$centered == FALSE && elts$profiled_if_noncenter == TRUE}.}
    \item{iters}{An integer, number of iterations run.}
    \item{K}{A p*p matrix, the \code{K} estimate.}
    \item{n}{An integer, the number of samples.}
    \item{p}{An integer, the dimension.}
    \item{is_refit,lambda1,maxit,previous_lambda1,symmetric,tol}{Same as in the input.}
    \item{lambda2}{Same as in the input, and returned only if \code{elts$centered == FALSE} and \cr
             \code{elts$profiled_if_noncenter == FALSE}.}
}
\description{
Estimate \eqn{\mathbf{K}}{K} and \eqn{\boldsymbol{\eta}}{\eta} using elts from \code{get_elts()} given one \eqn{\lambda_{\mathbf{K}}}{\lambda_K} (and \eqn{\lambda_{\boldsymbol{\eta}}}{\lambda_\eta} if non-profiled non-centered) and applying warm-start with strong screening rules.
}
\details{
If \code{elts$domain_type == "simplex"}, \code{symmetric != "symmetric"} or \code{elts$centered == FALSE && elts$profiled_if_noncenter} are currently not supported.
If \code{elts$domain_type == "simplex"} and \code{elts$setting} constains substring \code{"sum0"}, it is assumed that the column and row sums of \code{K} are all 0 and estimation will be done by profiling out the diagonal entries.
}
\examples{
# Examples are shown for Gaussian truncated to R+^p only. For other distributions
#   on other types of domains, please refer to \code{gen()} or \code{get_elts()}, as the
#   way to call this function (\code{get_results()}) is exactly the same in those cases.
n <- 50
p <- 30
domain <- make_domain("R+", p=p)
mu <- rep(0, p)
K <- diag(p)
x <- tmvtnorm::rtmvnorm(n, mean = mu, sigma = solve(K),
       lower = rep(0, p), upper = rep(Inf, p), algorithm = "gibbs",
       burn.in.samples = 100, thinning = 10)

h_hp <- get_h_hp("min_pow", 1, 3)
dm <- 1 + (1-1/(1+4*exp(1)*max(6*log(p)/n, sqrt(6*log(p)/n))))
elts_gauss_np <- get_elts(h_hp, x, setting="gaussian", domain=domain,
                centered=FALSE, profiled=FALSE, scale="norm", diag=dm)
test_nc_np <- get_results(elts_gauss_np, symmetric="symmetric", lambda1=0.35,
                lambda2=2, previous_res=NULL, is_refit=FALSE)
test_nc_np2 <- get_results(elts_gauss_np, symmetric="and", lambda1=0.25,
                 lambda2=2, previous_res=test_nc_np, is_refit=FALSE)

elts_gauss_p <- get_elts(h_hp, x, setting="gaussian", domain=domain,
               centered=FALSE, profiled=TRUE, scale="norm", diag=dm)
test_nc_p <- get_results(elts_gauss_p, symmetric="symmetric",
               lambda1=0.35, lambda2=NULL, previous_res=NULL, is_refit=FALSE)

elts_gauss_c <- get_elts(h_hp, x, setting="gaussian", domain=domain,
               centered=TRUE, scale="norm", diag=dm)
test_c <- get_results(elts_gauss_c, symmetric="or", lambda1=0.35,
               lambda2=NULL, previous_res=NULL, is_refit=FALSE)

}
