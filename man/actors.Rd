% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/actors.R
\docType{data}
\name{actors}
\alias{actors}
\title{Actors from a small hypothetical network}
\format{
dataframe (25 rows, 4 columns)

\tabular{lll}{
   \strong{actors$id} \tab \code{integer} \tab ID of the employee, corresponding to
   the sender and receiver IDs in the events dataframe \cr
   \strong{actors$location} \tab \code{numeric} \tab Location of the actor,
   ranging from 1-4 \cr
   \strong{actors$culture} \tab \code{character} \tab Categorical variable, indicating the
   culture of the employee \cr
}
}
\usage{
data(actors)
}
\description{
The related data files 'events', 'same_location', 'same_culture' contain
information on the  event sequence and the two event statistics respectively.
}
\keyword{datasets}
