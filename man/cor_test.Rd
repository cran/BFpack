% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/BF.cortest.R
\name{cor_test}
\alias{cor_test}
\title{Bayesian correlation analysis}
\usage{
cor_test(
  ...,
  formula = NULL,
  iter = 10000,
  burnin = 2000,
  nugget.scale = 0.999
)
}
\arguments{
\item{...}{matrices (or data frames) of dimensions \emph{n} (observations) by  \emph{p} (variables)
for different groups (in case of multiple matrices or data frames).}

\item{formula}{an object of class \code{\link[stats]{formula}}. This allows for including
control variables in the model (e.g., \code{~ education}).}

\item{iter}{total number of iterations from posterior. The total is split across three chains. By default, the total number of iterations is 10000,
implying 3333 iterations per chain.}

\item{burnin}{number of iterations for burnin (default is 2000).}

\item{nugget.scale}{a scalar to avoid computational issues due to posterior draws for the corralations
too close to 1 in absolute value. Posterior draws for the correlations are multiplied with this nugget.scale.
So \code{nugget.scale} should be close to 1 (the default is .999). If the traceplots show that draws are stuck
at 1 or -1 too long try a slightly smaller \code{nugget.scale}.}
}
\value{
list of class \code{cor_test}:
\itemize{
\item \code{meanF} posterior means of Fisher transform correlations
\item \code{covmF} posterior covariance matrix of Fisher transformed correlations
\item \code{correstimates} posterior estimates of correlation coefficients
\item \code{corrdraws} list of posterior draws of correlation matrices per group
\item \code{corrnames} names of all correlations
}
}
\description{
Estimate the unconstrained posterior for the correlations using a joint uniform prior (Mulder and Gelissen,
2023) or a marginally uniform prior (Barnard et al., 2000, Mulder, 2016). Correlation matrices are sampled from the posterior
using the MCMC algorithm of Talhouk et al. (2012).
}
\examples{
\donttest{
# Bayesian correlation analysis of the 6 variables in 'memory' object
# we consider a correlation analysis of the first three variable of the memory data.
fit <- cor_test(BFpack::memory[,1:3])

# Bayesian correlation of variables in memory object in BFpack while controlling
# for the Cat variable
fit <- cor_test(BFpack::memory[,c(1:4)],formula = ~ Cat)

# Example of Bayesian estimation of polyserial correlations
memory_example <- memory[,c("Im","Rat")]
memory_example$Rat <- as.ordered(memory_example$Rat)
fit <- cor_test(memory_example)

# Bayesian correlation analysis of first three variables in memory data
# for two different groups
HC <- subset(BFpack::memory[,c(1:3,7)], Group == "HC")[,-4]
SZ <- subset(BFpack::memory[,c(1:3,7)], Group == "SZ")[,-4]
fit <- cor_test(HC,SZ)

}
}
\references{
Barnard, J., McCulloch, R., & Meng, X. L. (2000). Modeling covariance matrices in terms of standard deviations and
correlations, with application to shrinkage. Statistica Sinica, 1281-1311. <https://www.jstor.org/stable/24306780>

Joe, H. (2006). Generating random correlation matrices based on partial correlations. Journal of Multivariate
Analysis, 97(10), 2177-2189. <https://doi.org/10.1016/j.jmva.2005.05.010>

Mulder, J., & Gelissen, J. P. (2023). Bayes factor testing of equality and order constraints on measures of
association in social research. Journal of Applied Statistics, 50(2), 315-351. <https://doi.org/10.1080/02664763.2021.1992360>

Mulder, J. (2016). Bayes factors for testing order-constrained hypotheses on correlations. Journal of Mathematical
Psychology, 72, 104-115. <https://doi.org/10.1016/j.jmp.2014.09.004>

Talhouk, A., Doucet, A., & Murphy, K. (2012). Efficient Bayesian inference for multivariate probit models with
sparse inverse correlation matrices. Journal of Computational and Graphical Statistics, 21(3), 739-757.
<https://doi.org/10.1080/10618600.2012.679239>
}
