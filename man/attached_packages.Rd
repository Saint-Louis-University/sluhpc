% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/slurm.R
\name{attached_packages}
\alias{attached_packages}
\title{Currently Attached Packages with Exclusions}
\usage{
attached_packages(exclude = c("sluhpc"))
}
\arguments{
\item{exclude}{character vector of package names to exclude}
}
\value{
character vector of currently attached packages less those listed in the exclude argument
}
\description{
Currently Attached Packages with Exclusions
}
\examples{
\dontrun{
# exclude sluhpc
attached_packages()

# exclude base
attached_packages("base")

# exclude base and stats
attached_packages(c("base", "stats"))
}

}
\seealso{
\code{\link[base]{.packages}}
}
