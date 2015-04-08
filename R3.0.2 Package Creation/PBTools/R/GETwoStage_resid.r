# -------------------------------------------------------
# This function consolidates the residuals generated by running GETwoStage.test
#
# ARGUMENTS:
# ge2sout - object generated after running GETwoStage.test
# respvar - a vector of strings; variable names of the response variables
# is.genoRandom - logical; indicating whether genotype/treatment is random or not; default value is FALSE (FIXED factor)
#
# File Created by: Alaine A. Gulles
# Script Created by: Alaine A. Gulles
# Script Modified by: Rose Imee Zhella Morantte
#                     Nellwyn L. Sales
# --------------------------------------------------------

GETwoStage_resid <- function(ge2sout, respvar, is.genoRandom = FALSE) UseMethod("GETwoStage_resid")

GETwoStage_resid.default <- function(ge2sout, respvar, is.genoRandom = FALSE) {
  for (m in (1:length(respvar))) {
    
    # --- consolidate residuals --- #
    if (is.genoRandom) {names.resid <- paste(respvar[m],"resid_random",sep="_")
    } else names.resid <- paste(respvar[m],"resid_fixed",sep="_")
    
    if (m == 1) {
      residuals <- as.data.frame(ge2sout[[m]]$residuals)
      if (nrow(residuals) > 0) {
        names(residuals) <- names.resid
        residuals <- cbind(ge2sout[[m]]$data, residuals)
      }
    } else {
      resid2 <- as.data.frame(ge2sout[[m]]$residuals)
      if (nrow(resid2) > 0) {
        if (nrow(residuals) == 0) {
          residuals <- resid2
          names(residuals) <- names.resid
          residuals <- cbind(ge2sout[[m]]$data, residuals)
        } else {
          names(resid2) <- names.resid
          resid2 <- cbind(ge2sout[[m]]$data, resid2)
          residuals <- merge(residuals,resid2, all=TRUE)
        }
      }
    }
  }
  
  # generate status residuals
  if (nrow(residuals) == 0) {
    ge2residWarning<-"empty"
  } else {
    ge2residWarning<-"not empty"
  }
  
  return(list(residuals=residuals, ge2residWarning=ge2residWarning))
}