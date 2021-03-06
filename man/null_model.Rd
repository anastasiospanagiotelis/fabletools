% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/model_null.R
\name{null_model}
\alias{null_model}
\alias{is_null_model}
\title{NULL model}
\usage{
null_model(formula, ...)

is_null_model(x)
}
\arguments{
\item{formula}{Model specification (response variable)}

\item{...}{Unused}

\item{x}{The object to be tested.}
}
\description{
Create a NULL model definition. This model produces NA forecasts and does not
require any estimation of the data. It is generally used as a placeholder for
models which have encountered an error (see \code{.safely} in \code{\link[=model]{model()}}).
}
\keyword{internal}
