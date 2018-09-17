#' @title Evaluating multiple portfolio functions defined by customer
#'
#' @description Evaluate multiple portfolio functions written in format form
#'
#' @param path absolute path for a folder which contains all (and only) functions to be evaluated
#' @param prices a list of \code{xts} containing the stock prices for the backtesting.
#' @param shortselling whether shortselling is allowed or not (default \code{FALSE}).
#' @param leverage amount of leverage (default is 1, so no leverage).
#' @param T_sliding_window length of the sliding window.
#' @param freq_optim how often the portfolio is to be reoptimized.
#' @param freq_rebalance how often the portfolio is to be rebalanded.
#' @return A list containing the performance in the following elements:
#' \item{\code{TBD}  }{m-by-m matrix, columns corresponding to eigenvectors.}
#' \item{\code{TBD}  }{m-by-1 vector corresponding to eigenvalues.}
#' @author Daniel P. Palomar and Rui Zhou
#' 
#' @import xts
#'         PerformanceAnalytics
#' @export
multiplePortfolioBacktest <- function(path, prices, return_all = FALSE, ...) {
  # extract useful informations
  files <- list.files(path)
  stud_names <- stud_IDs <- time_average <- failure_ratio <- c()
  error_message <- list()
  portfolios_perform <- matrix(NA, length(files), 4)
  if (return_all) results_container <- list()
  
  # save the package and variables list
  packages_default <- search()
  var_fun_default <- ls()
  cat("---------------Default Packages---------------\n")
  cat(paste(packages_default, "\n"))
  cat("----------------------------------------------\n")
  # some functions evaluation here
  for (i in 1:length(files)) {
    
    file <- files[i]
    file_name_cleaned <- gsub("\\s+", "", file)
    tmp <- unlist(strsplit(file_name_cleaned, "-"))
    stud_names <- c(stud_names, paste(tmp[1], tmp[2], collapse = " "))
    stud_IDs <- c(stud_IDs, tmp[3])
    cat(paste0(Sys.time()," - Execute code from ", stud_names[i], " (", stud_IDs[i], ")\n"))
    
    # mirror list of present variables and functions
    var_fun_default <- ls()
    
    
    tryCatch({
      suppressMessages(source(paste0(path, "/", file), local = TRUE))
      res <- backtestPortfolio(portfolio_fun = portfolio_fun, prices = prices, ...)
      portfolios_perform[i, ] <- res$performance_summary
      time_average[i] <- res$time_average
      failure_ratio[i] <- res$failure_ratio
      error_message[[i]] <- res$error_message
      if (return_all) results_container[[i]] <- res
    }, warning = function(w){
      error_message[[i]] <<- w$message
    }, error = function(e){
      error_message[[i]] <<- e$message
    })
    
    
    # detach the newly loaded packages
    packages_now <- search()
    packages_det <- packages_now[!(packages_now %in% packages_default)]
    detach_packages(packages_det)
    
    # delete students' function
    var_fun_now <- ls()
    var_fun_det <- var_fun_now[!(var_fun_now %in% var_fun_default)]
    rm(list = var_fun_det)
  }
  
  return(list(
    "stud_names" = stud_names,
    "stud_IDs" = stud_IDs,
    "performance" = portfolios_perform,
    "eval_time" = eval_time,
    "error_message" = error_message
  ))
}


detach_packages <- function(items) {
  for (item in items) {
    if (item %in% search()) {
      detach(item, unload = TRUE, character.only = TRUE)
    }
  }
}


#' @title Checking uninstalled packages written in the portfolio functions defined by customer
#'
#' @description Checke uninstalled packages of portfolio functions written in format form
#'
#' @param path Absolute path for a folder which contains all (and only) functions to be evaluated
#' 
#' @author Daniel P. Palomar and Rui Zhou
#' 
checkUninstalledPackages <- function(path) {
  if (!require("readtext")) stop("Package \"readtext\" is required to run this function!")
  if (!require("stringi")) stop("Package \"stringi\" is required to run this function!")
  req_pkgs <- c()
  files <- list.files(path)
  for (file in files) {
    suppressWarnings(codes <- readtext(paste0(path, "/", file)))
    pkgs <- stri_extract_all(codes$text, regex = "library\\(.*?\\)", simplify = TRUE)
    req_pkgs <- c(req_pkgs, as.vector(pkgs))
  }
  req_pkgs <- sub(".*\\(", "", req_pkgs)
  req_pkgs <- sub(")", "", req_pkgs)
  uninstalled_pkgs<- req_pkgs[! req_pkgs %in% rownames(installed.packages())]
  return(unique(uninstalled_pkgs))
}