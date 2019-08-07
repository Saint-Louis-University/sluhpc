#' SLURM Directory
#'
#' @param slurm_job a slurm_job object created with \code{\link{slurm_apply}}
#'
#' @return string of directory name containing the job files
#' @export
#'
#' @examples
#' \dontrun{
#' do_search <- function(x, y) x + y
#' slurm_job <- slurm_apply(do_search,
#'                          data.frame(x = seq( 0, 42,  21),
#'                                     y = seq(42,  0, -21)),
#'                          "find_meaning")
#' slurm_dir(slurm_job)
#' }
#'
#' @seealso
#' \code{\link{slurm_apply}}
slurm_dir <- function(slurm_job) {
  paste0("_rslurm_", slurm_job$jobname)
}

#' Currently Attached Packages with Exclusions
#'
#' @param exclude character vector of package names to exclude
#'
#' @return character vector of currently attached packages less those listed in the exclude argument
#' @export
#'
#' @examples
#' \dontrun{
#' # exclude sluhpc
#' attached_packages()
#'
#' # exclude base
#' attached_packages("base")
#'
#' # exclude base and stats
#' attached_packages(c("base", "stats"))
#' }
#'
#' @seealso \code{\link[base]{.packages}}
attached_packages <- function(exclude = c("sluhpc")) {
  attached_pkgs <- base::.packages()
  include <- !(attached_pkgs %in% exclude)
  attached_pkgs[include]
}

#' SLURM Apply
#'
#' @param f a function that accepts one or many single values as parameters and may return any type of R object
#' @param params a data frame of parameter values to apply f to. Each column corresponds to a  parameter of f (Note: names must match) and each row corresponds to a separate function call
#' @param jobname the name of the slurm job
#' @param nodes the (maximum) number of cluster nodes to spread the calculation over. slurm_apply automatically divides params in chunks of approximately equal size to send to each node. Less nodes are allocated if the parameter set is too small to use all CPUs on the requested nodes
#' @param cpus_per_node the number of CPUs per node on the cluster; determines how many processes are run in parallel per node
#' @param add_objects a character vector containing the name of R objects to be saved in a .RData file and loaded on each cluster node prior to calling f.
#' @param pkgs a character vector containing the names of packages that must be loaded on each cluster node. By default, it includes all packages loaded by the user when slurm_apply is called with the exception of the sluhpc package.
#' @param libPaths a character vector describing the location of additional R library trees to search through, or NULL. The default value of NULL corresponds to libraries returned by .libPaths() on a cluster node. Non-existent library trees are silently ignored.
#' @param slurm_options a named list of options recognized by sbatch; see Details below for more information.
#' @param submit whether or not to submit the job to the cluster with sbatch. See \code{\link[rslurm]{slurm_apply}} details for more information
#'
#' @return a slurm_job object containing the job name and the number of nodes effectively used
#' @export
#'
#' @examples
#' \dontrun{
#' do_search <- function(x, y) x + y
#' slurm_job <- slurm_apply(do_search,
#'                          data.frame(x = seq( 0, 42,  21),
#'                                     y = seq(42,  0, -21)),
#'                          "find_meaning")
#' }
#'
#' @note this function overrides \code{\link[rslurm]{slurm_apply}} to add a command in the submission script to load R on APEX and call RScript with a relative path
slurm_apply <- function (f,
                         params,
                         jobname,
                         nodes = 2,
                         cpus_per_node = 2,
                         add_objects = NULL,
                         pkgs = rev(attached_packages()),
                         libPaths = NULL,
                         slurm_options = list(),
                         submit = FALSE) {
  slurm_job <- rslurm::slurm_apply(f,
                                   params,
                                   jobname,
                                   nodes,
                                   cpus_per_node,
                                   add_objects,
                                   pkgs,
                                   libPaths,
                                   slurm_options,
                                   submit)

  job_directory <- slurm_dir(slurm_job)

  setwd(job_directory)

  # re-write submit.sh to load mro and use relative RScript path
  submit_lines <- readLines("submit.sh")
  submit_lines <- c(submit_lines[-length(submit_lines)],
                    "module load r/mro-3.3",
                    "Rscript slurm_run.R")
  n_lines <- length(submit_lines)
  ## write in binary to get unix line endings as required by slurm
  submit_file <- file("./submit.sh", "wb")
  write(submit_lines[1], submit_file)
  write(submit_lines[2:n_lines], submit_file, append = TRUE)
  close(submit_file)

  setwd("..")

  return(slurm_job)
}

#' SLURM Upload
#'
#' @param session ssh connection created with \code{\link{apex_connect}}
#' @param slurm_job a slurm_job object created with \code{\link{slurm_apply}}
#' @param ... further arguments passed to \code{\link{apex_upload}}
#'
#' @return target location as string
#' @export
#'
#' @examples
#' \dontrun{
#' session <- apex_connect()
#' do_search <- function(x, y) x + y
#' slurm_job <- slurm_apply(do_search,
#'                          data.frame(x = seq( 0, 42,  21),
#'                                     y = seq(42,  0, -21)),
#'                          "find_meaning")
#' slurm_upload(session, slurm_job)
#' }
#'
#' @seealso \code{\link{apex_upload}}
slurm_upload <- function(session,
                         slurm_job,
                         ...) {
  job_directory <- slurm_dir(slurm_job)
  out <- apex_upload(session, job_directory, ...)
  paste0(out, "/", job_directory)
}

#' SLURM Submit
#'
#' @param session ssh connection created with \code{\link{apex_connect}}
#' @param slurm_job a slurm_job object created with \code{\link{slurm_apply}}
#' @param parent_directory location of slurm job folder on apex
#'
#' @return character representation of stdout
#' @export
#'
#' @examples
#' \dontrun{
#' session <- apex_connect()
#' do_search <- function(x, y) x + y
#' slurm_job <- slurm_apply(do_search,
#'                          data.frame(x = seq( 0, 42,  21),
#'                                     y = seq(42,  0, -21)),
#'                          "find_meaning")
#' slurm_upload(session, slurm_job)
#' slurm_submit(session, slurm_job)
#' }
#'
#' @seealso \code{\link{apex_execute}}
slurm_submit <- function(session,
                         slurm_job,
                         parent_directory = "Documents") {
  out <- apex_execute(session,
                      c(paste("cd", parent_directory),
                        paste("cd", slurm_dir(slurm_job)),
                        "sbatch submit.sh"))
  rawToChar(out$stdout)
}

#' SLURM Is Job Running
#'
#' @param session ssh connection created with \code{\link{apex_connect}}
#' @param slurm_job a slurm_job object created with \code{\link{slurm_apply}}
#'
#' @return TRUE or FALSE depending on whether the job is currently running on apex
#' @export
#'
#' @examples
#' \dontrun{
#' session <- apex_connect()
#' do_search <- function(x, y) x + y
#' slurm_job <- slurm_apply(do_search,
#'                          data.frame(x = seq( 0, 42,  21),
#'                                     y = seq(42,  0, -21)),
#'                          "find_meaning")
#' slurm_upload(session, slurm_job)
#' slurm_submit(session, slurm_job)
#' slurm_is_running(session, slurm_job)
#' }
#'
#' @seealso \code{\link{apex_execute}}
slurm_is_running <- function(session,
                             slurm_job) {
  out <- apex_execute(session,
                      paste("squeue -n", slurm_job$jobname))
  lines <- strsplit(rawToChar(out$stdout), "\n")[[1]]
  length(lines) != 1
}

#' SLURM Download
#'
#' @param session ssh connection created with \code{\link{apex_connect}}
#' @param slurm_job a slurm_job object created with \code{\link{slurm_apply}}
#' @param parent_directory location of slurm job folder on apex
#' @param seconds seconds between job completion checks
#' @param ... further arguments passed to \code{\link{apex_download}}
#'
#' @export
#'
#' @examples
#' \dontrun{
#' session <- apex_connect()
#' do_search <- function(x, y) x + y
#' slurm_job <- slurm_apply(do_search,
#'                          data.frame(x = seq( 0, 42,  21),
#'                                     y = seq(42,  0, -21)),
#'                          "find_meaning")
#' slurm_upload(session, slurm_job)
#' slurm_submit(session, slurm_job)
#' slurm_download(session, slurm_job)
#' }
#'
#' @note This function will block until the job finishes on the cluster.
#'
#' @seealso \code{\link{apex_download}}
slurm_download <- function(session,
                           slurm_job,
                           parent_directory = "Documents",
                           seconds = 10,
                           ...) {
  while(slurm_is_running(session, slurm_job)) {
    Sys.sleep(seconds)
  }
  job_directory <- slurm_dir(slurm_job)
  apex_download(session,
                paste0(parent_directory, "/", job_directory),
                ...)
}

#' SLURM Read executed job output into data frame
#'
#' @param slurm_job a slurm_job object created with \code{\link{slurm_apply}}
#'
#' @return a data frame with one column by return value of the function passed to \code{\link{slurm_apply}}, where each row is the output of the corresponding row in the params data frame passed to \code{\link{slurm_apply}}
#' @export
#'
#' @examples
#' \dontrun{
#' session <- apex_connect()
#' do_search <- function(x, y) x + y
#' slurm_job <- slurm_apply(do_search,
#'                          data.frame(x = seq( 0, 42,  21),
#'                                     y = seq(42,  0, -21)),
#'                          "find_meaning")
#' slurm_upload(session, slurm_job)
#' slurm_submit(session, slurm_job)
#' slurm_download(session, slurm_job)
#' results <- slurm_output_dfr(slurm_job)
#' }
#'
#' @seealso \code{\link[rslurm]{get_slurm_out}}
slurm_output_dfr <- function(slurm_job) {
  rslurm::get_slurm_out(slurm_job, outtype = "table")
}

#' SLURM Cancel
#'
#' @param session ssh connection created with \code{\link{apex_connect}}
#' @param slurm_job a slurm_job object created with \code{\link{slurm_apply}}
#'
#' @return character representation of stdout
#' @export
#'
#' @examples
#' \dontrun{
#' session <- apex_connect()
#' do_search <- function(x, y) x + y
#' slurm_job <- slurm_apply(do_search,
#'                          data.frame(x = seq( 0, 42,  21),
#'                                     y = seq(42,  0, -21)),
#'                          "find_meaning")
#' slurm_upload(session, slurm_job)
#' slurm_submit(session, slurm_job)
#' if(slurm_is_running(session, slurm_job))
#'   slurm_cancel(session, slurm_job)
#' }
#'
#' @seealso \code{\link{apex_execute}}
slurm_cancel <- function(session, slurm_job) {
  out <- apex_execute(session,
                      paste("scancel -n", slurm_job$jobname))
  rawToChar(out$stdout)
}

#' SLURM Remove Job Directory on APEX
#'
#' @param session ssh connection created with \code{\link{apex_connect}}
#' @param slurm_job a slurm_job object created with \code{\link{slurm_apply}}
#' @param parent_directory location of slurm job folder on apex
#'
#' @return character representation of stdout
#' @export
#'
#' @examples
#' \dontrun{
#' session <- apex_connect()
#' do_search <- function(x, y) x + y
#' slurm_job <- slurm_apply(do_search,
#'                          data.frame(x = seq( 0, 42,  21),
#'                                     y = seq(42,  0, -21)),
#'                          "find_meaning")
#' slurm_upload(session, slurm_job)
#' slurm_submit(session, slurm_job)
#' slurm_download(session, slurm_job)
#' results <- slurm_output_dfr(slurm_job)
#' slurm_remove_apex(session, slurm_job)
#' apex_disconnect(session)
#' }
#'
#' @seealso \code{\link{apex_execute}}
slurm_remove_apex <- function(session,
                              slurm_job,
                              parent_directory = "Documents") {
  job_directory <- slurm_dir(slurm_job)
  out <- apex_execute(session,
                      c(paste("cd", parent_directory),
                        paste("rm -r", job_directory)))
  rawToChar(out$stdout)
}

#' SLURM Remove Local Job Directory
#'
#' @param slurm_job a slurm_job object created with \code{\link{slurm_apply}}
#'
#' @export
#'
#' @examples
#' \dontrun{
#' session <- apex_connect()
#' do_search <- function(x, y) x + y
#' slurm_job <- slurm_apply(do_search,
#'                          data.frame(x = seq( 0, 42,  21),
#'                                     y = seq(42,  0, -21)),
#'                          "find_meaning")
#' slurm_upload(session, slurm_job)
#' slurm_submit(session, slurm_job)
#' slurm_download(session, slurm_job)
#' results <- slurm_output_dfr(slurm_job)
#' slurm_remove_apex(session, slurm_job)
#' apex_disconnect(session)
#' slurm_remove_local(slurm_job)
#' }
#'
#' @seealso \code{\link[rslurm]{cleanup_files}}
slurm_remove_local <- function(slurm_job) {
  rslurm::cleanup_files(slurm_job)
}
