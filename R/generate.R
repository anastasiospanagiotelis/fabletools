#' Generate responses from a mable
#' 
#' Use a model's fitted distribution to simulate additional data with similar
#' behaviour to the response. This is a tidy implementation of 
#' `\link[stats]{simulate}`.
#' 
#' Innovations are sampled by the model's assumed error distribution. 
#' If `bootstrap` is `TRUE`, innovations will be sampled from the model's 
#' residuals. If `new_data` contains the `.innov` column, those values will be
#' treated as innovations for the simulated paths..
#' 
#' @param x A mable.
#' @param new_data The data to be generated (time index and exogenous regressors)
#' @param h The simulation horizon (can be used instead of `new_data` for regular
#' time series with no exogenous regressors).
#' @param times The number of replications.
#' @param seed The seed for the random generation from distributions.
#' @param ... Additional arguments for individual simulation methods.
#' 
#' @examples
#' if (requireNamespace("fable", quietly = TRUE)) {
#' library(fable)
#' library(dplyr)
#' UKLungDeaths <- as_tsibble(cbind(mdeaths, fdeaths), pivot_longer = FALSE)
#' UKLungDeaths %>% 
#'   model(lm = TSLM(mdeaths ~ fourier("year", K = 4) + fdeaths)) %>% 
#'   generate(UKLungDeaths, times = 5)
#' }
#' @export
generate.mdl_df <- function(x, new_data = NULL, h = NULL, times = 1, seed = NULL, ...){
  kv <- c(key_vars(x), ".model")
  mdls <- x%@%"model"
  if(!is.null(new_data)){
    x <- bind_new_data(x, new_data)
  }
  x <- gather(x, ".model", ".sim", !!!syms(mdls))
  
  # Evaluate simulations
  x$.sim <- map2(x[[".sim"]], 
                 x[["new_data"]] %||% rep(list(NULL), length.out = NROW(x)),
                 generate, h = h, times = times, seed = seed, ...)
  unnest_tsbl(x, ".sim", parent_key = kv)
}

#' @rdname generate.mdl_df
#' @export
generate.mdl_ts <- function(x, new_data = NULL, h = NULL, times = 1, seed = NULL, ...){
  if (!exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) 
    stats::runif(1)
  if (is.null(seed))
    RNGstate <- get(".Random.seed", envir = .GlobalEnv)
  else {
    R.seed <- get(".Random.seed", envir = .GlobalEnv)
    set.seed(seed)
    RNGstate <- structure(seed, kind = as.list(RNGkind()))
    on.exit(assign(".Random.seed", R.seed, envir = .GlobalEnv))
  }
  
  if(is.null(new_data)){
    new_data <- make_future_data(x$data, h)
  }
  
  if(is.null(new_data[[".rep"]])){
    new_data <- map(seq_len(times), function(rep){
      new_data[[".rep"]] <- rep
      update_tsibble(new_data, key = c(".rep", key_vars(new_data)),
                     validate = FALSE)
    }) %>% 
      invoke("rbind", .)
  }
  
  # Compute specials with new_data
  x$model$stage <- "generate"
  x$model$add_data(new_data)
  specials <- tryCatch(parse_model_rhs(x$model)$specials,
                       error = function(e){
                         abort(sprintf(
                           "%s
Unable to compute required variables from provided `new_data`.
Does your model require extra variables to produce simulations?", e$message))
                       }, interrupt = function(e) {
                         stop("Terminated by user", call. = FALSE)
                       })
  
  x$model$remove_data()
  x$model$stage <- NULL
  
  if(length(x$response) > 1) abort("Generating paths from multivariate models is not yet supported.")
  .sim <- generate(x[["fit"]], new_data = new_data, specials = specials, ...)
  .sim[[".sim"]] <- invert_transformation(x$transformation[[1]])(.sim[[".sim"]])
  .sim
}