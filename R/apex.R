#' APEX Connect
#'
#' @param user apex username as string
#' @param pass either a string or a callback function for password prompt
#' @param verbose either TRUE/FALSE or a value between 0 and 4 indicating log level: 0: no logging, 1: only warnings, 2: protocol, 3: packets or 4: full stack trace.
#'
#' @return ssh session
#' @export
#'
#' @examples
#' \dontrun{
#' # retrive user and pass from .Renviron file in user home directory
#' session <- apex_connect()
#' }
#'
#' @seealso \code{\link[ssh]{ssh_connect}}
apex_connect <- function(user = Sys.getenv("APEX.SLU.EDU_USER"),
                         pass = Sys.getenv("APEX.SLU.EDU_PASS"),
                         verbose = FALSE) {
  user_at_apex <- paste0(user, "@apex.slu.edu")
  ssh::ssh_connect(host = user_at_apex,
                   passwd = pass,
                   verbose = verbose)
}

#' APEX Execute
#'
#' @param session ssh connection created with \code{\link{apex_connect}}
#' @param command The command or script to execute
#' @param error automatically raise an error if the exit status is non-zero
#'
#' @return list containing exit status, buffered raw stdout, and buffered raw stderr
#' @export
#'
#' @examples
#' \dontrun{
#' session <- apex_connect()
#' out <- apex_execute(session)
#' rawToChar(out$stdout)
#' }
#'
#' @seealso \code{\link[ssh]{ssh_exec_internal}}
apex_execute <- function(session,
                         command = "whoami",
                         error = TRUE) {
  ssh::ssh_exec_internal(session, command, error)
}

#' APEX Download
#'
#' @param session ssh connection created with \code{\link{apex_connect}}
#' @param files path to files or directory to transfer
#' @param to existing directory on the destination where files will be copied into
#' @param verbose print progress while copying files
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # recursively download files and directories
#' session <- apex_connect()
#' apex_download(session, "~/target/*", tempdir())
#' }
#'
#' @seealso \code{\link[ssh]{scp_download}}
apex_download <- function(session,
                          files,
                          to = ".",
                          verbose = FALSE) {
  ssh::scp_download(session, files, to, verbose)
}

#' APEX Upload
#'
#' @param session ssh connection created with \code{\link{apex_connect}}
#' @param files path to files or directory to transfer
#' @param to existing directory on the destination where files will be copied into
#' @param verbose print progress while copying files
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # recursively upload files and directories
#' session <- apex_connect()
#' files <- c(R.home("doc"), R.home("COPYING"))
#' apex_upload(session, files, "~/target")
#' }
#'
#' @seealso \code{\link[ssh]{scp_upload}}
apex_upload <- function(session,
                        files,
                        to = "Documents",
                        verbose = FALSE) {
  ssh::scp_upload(session, files, to, verbose)
}

#' APEX Disconnect
#'
#' @param session ssh connection created with \code{\link{apex_connect}}
#'
#' @export
#'
#' @examples
#' \dontrun{
#' session <- apex_connect()
#' apex_disconnect(session)
#' }
#'
#' @seealso \code{\link[ssh]{ssh_disconnect}}
apex_disconnect <- function(session) {
  ssh::ssh_disconnect(session)
}
