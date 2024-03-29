% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/modifiers.R
\name{f_som}
\alias{f_som}
\title{Soil C concentration}
\usage{
f_som(My_mic, Mo_mic, My_mes, Mo_mes, Delta_z_min, phi_min, gamma_m)
}
\arguments{
\item{My_mic}{One of the four model pools (they are all summed up in this function for calculating the total)}

\item{Mo_mic}{One of the four model pools (they are all summed up in this function for calculating the total)}

\item{My_mes}{One of the four model pools (they are all summed up in this function for calculating the total)}

\item{Mo_mes}{One of the four model pools (they are all summed up in this function for calculating the total)}

\item{Delta_z_min}{minimal soil thickness if no organic matter was present (cm)}

\item{phi_min}{minimal porosity, (\eqn{\frac{cm^3 of water}{cm^3 of soil}})}
}
\value{
one single value
}
\description{
This function calculates the soil C concentration. It relies on \code{\link{Msm}} to calculate the mineral mass.
}
\seealso{
\code{\link{Msm}}
}
