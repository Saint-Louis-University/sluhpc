% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/slurm.R
\name{slurm_dir}
\alias{slurm_dir}
\title{SLURM Directory}
\usage{
slurm_dir(slurm_job)
}
\arguments{
\item{slurm_job}{a slurm_job object created with \code{\link{slurm_apply}}}
}
\value{
string of directory name containing the job files
}
\description{
SLURM Directory
}
\examples{
\dontrun{
do_search <- function(x, y) x + y
slurm_job <- slurm_apply(do_search,
                         data.frame(x = seq( 0, 42,  21),
                                    y = seq(42,  0, -21)),
                         "find_meaning")
slurm_dir(slurm_job)
}

}
\seealso{
\code{\link{slurm_apply}}
}
