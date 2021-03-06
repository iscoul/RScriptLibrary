# -------------------------------------------------------------------------------------
# designAugmentedLSD: Generate randomization for augmented design in RCBD.
# Created by: Alaine A. Gulles 09.21.2010 for International Rice Research Institute
# Modified by: Alaine A. Gulles 04.10.2013
# -------------------------------------------------------------------------------------


designAugmentedLSD <- function(checkTrmt, newTrmt, trial = 1, numFieldRow, serpentine = FALSE, factorName = NULL, display = TRUE, file = NULL) UseMethod("designAugmentedLSD")

designAugmentedLSD.default <- function(checkTrmt, newTrmt, trial = 1, numFieldRow, serpentine = FALSE, factorName = NULL, display = TRUE, file = NULL) {
     
     if (length(checkTrmt) == 1) { checkTrmt <- paste("check",1:checkTrmt, sep = "") }
     if (length(newTrmt) == 1)   { newTrmt <- paste("new",1:newTrmt, sep = "") }
     
     # CHECK
     if (length(checkTrmt) > numFieldRow) { stop("Too few rows for blocking.") }
     totalNumPlots <- length(checkTrmt)**2 + length(newTrmt)
     if (totalNumPlots%%numFieldRow != 0) { stop("Number of field rows must divide number of plots.") } 
     numFieldCol <- totalNumPlots/numFieldRow
     if (length(checkTrmt) > numFieldCol) { stop("Too few columns for blocking.") }
     errorDf <- (length(checkTrmt) - 1)*(length(checkTrmt) - 2)
     
     embedColInBasicCol <- floor(numFieldCol/length(checkTrmt))
     basicColWAddlCol <- numFieldCol - (length(checkTrmt) * embedColInBasicCol)
     
     plotsInBasicRow <- totalNumPlots/length(checkTrmt) # -- number of plots within basic row of LSD
     embedRowInBasicRow <- floor(numFieldRow/length(checkTrmt)) # -- number of embedded row within the basic row of LSD 
     basicRowWAddlRow <- numFieldRow - (length(checkTrmt) *  embedRowInBasicRow)
     
     plotsInFieldRow <- totalNumPlots/numFieldRow
     plotsInFieldCol <- totalNumPlots/numFieldCol
          
     randomize <- NULL
     plan <- list()
     plotNum <- list()
     capture.output(result <- designLSD(list(tempTrmt = checkTrmt), trial, serpentine = FALSE, display = FALSE))
     tempDesign <- result$fieldbook
     for (i in (1:trial)) {
          tempSample <- tempDesign[tempDesign[,"Trial"] == 1,]
          tempPlan <- result$layout[[i]]  
          tempNewDesign <- NULL
          tempColDesign <- NULL
          if (embedRowInBasicRow == 1 && basicRowWAddlRow == 0) { tempNewDesign <- tempPlan
          } else {
               for (j in (1:length(checkTrmt))) {
                    if (j <= basicRowWAddlRow) { tempRow <- matrix(0, nrow = (embedRowInBasicRow + 1), ncol = length(checkTrmt))
                    } else { tempRow <- matrix(0, nrow = embedRowInBasicRow, ncol = length(checkTrmt)) }
                    for (k in (1:length(checkTrmt))) { 
                         if (j <= basicRowWAddlRow) { tempRow[sample(1:(embedRowInBasicRow + 1),1),k] <- tempPlan[j,k] 
                         } else { tempRow[sample(1:embedRowInBasicRow,1),k] <- tempPlan[j,k] }
                    }
                    tempNewDesign <- rbind(tempNewDesign, tempRow)
               }                
          }
          
          if (embedColInBasicCol == 1 && basicColWAddlCol == 0) { tempColDesign <- tempNewDesign
          } else {
               for (k in (1:length(checkTrmt))) {
                    if (k <= basicColWAddlCol) { tempCol <- matrix(0, nrow = nrow(tempNewDesign), ncol = (embedColInBasicCol + 1))
                    } else { tempCol <- matrix(0, nrow = nrow(tempNewDesign), ncol = embedColInBasicCol) }
                    for (j in (1:nrow(tempNewDesign))) { 
                         if (k <= basicColWAddlCol) { tempCol[j,sample(1:(embedColInBasicCol + 1),1)] <- tempNewDesign[j,k] 
                         } else { tempCol[j,sample(1:embedColInBasicCol,1)] <- tempNewDesign[j,k]  }
                    }
                    tempColDesign <- cbind(tempColDesign, tempCol)
               }               
          }
          tempColDesign[tempColDesign == "0"] <- sample(newTrmt, length(newTrmt))
          tempNewDesign <- as.data.frame.table(tempColDesign)
          if (basicRowWAddlRow == 0) { tempNewDesign$Row <- rep(1:length(checkTrmt), each = embedRowInBasicRow)
          } else {  
               tempNewDesign$Row <- c(rep(1:basicRowWAddlRow, each = (embedRowInBasicRow + 1)), 
                                      rep((basicRowWAddlRow+1):length(checkTrmt), each = embedRowInBasicRow))
          }
          if (basicColWAddlCol == 0) { tempNewDesign$Column <- rep(1:length(checkTrmt), each = nrow(tempColDesign)*embedColInBasicCol)
          } else {
               tempNewDesign$Column <- c(rep(1:basicColWAddlCol, each = ((embedColInBasicCol + 1)*nrow(tempColDesign))), 
                                         rep((basicColWAddlCol+1):length(checkTrmt), each = (embedColInBasicCol*nrow(tempColDesign))))
          }
          tempNewDesign$Trial <- i
          plan[[i]] <- tempColDesign
          plotNum[[i]] <- matrix(1:totalNumPlots, nrow = nrow(tempColDesign), ncol = ncol(tempColDesign), byrow = TRUE)
          if (serpentine) {
               for (j in seq(2, nrow(plotNum[[i]]), by = 2)) { plotNum[[i]][j,] <- rev(plotNum[[i]][j,]) }
          }
          tempNewDesign <- merge(tempNewDesign, as.data.frame.table(plotNum[[i]]), by.x = c("Var1", "Var2"), by.y = c("Var1", "Var2"))
          randomize <- data.frame(rbind(randomize, tempNewDesign))
          dimnames(plan[[i]]) <- list(paste("FieldRow",1:numFieldRow, sep = ""),paste("FieldCol",1:numFieldCol, sep = ""))
          dimnames(plotNum[[i]]) <- dimnames(plan[[i]])
     }
     randomize <- randomize[,c("Trial", "Row", "Column", "Freq.x", "Freq.y", "Var1", "Var2")]
     randomize[,"Var1"] <- as.numeric(randomize[,"Var1"]) # -- fieldRow
     randomize[,"Var2"] <- as.numeric(randomize[,"Var2"]) # -- fieldColumn
     
     if (!is.null(factorName) && is.valid.name(trimStrings(factorName[1]))) {
          colnames(randomize) <- c("Trial", "Row", "Column", factorName, "PlotNum", "FieldRow", "FieldCol")     
     } else { colnames(randomize) <- c("Trial", "Row", "Column", "Treatment", "PlotNum", "FieldRow", "FieldCol") }
     randomize <- randomize[order(randomize$Trial,  randomize$FieldRow, randomize$FieldCol), ]
     
     rownames(randomize) <- 1:nrow(randomize)
     names(plan) <- paste("Trial", 1:trial, sep = "")
     names(plotNum) <- paste("Trial", 1:trial, sep = "")
     
     if (display) {
          cat(toupper("Design Properties:"),"\n",sep = "")
          cat("\t","Augmented Latin Square Design (Augmented LSD)","\n\n",sep = "")
          cat(toupper("Design Parameters:"),"\n",sep = "")
          cat("\t","Number of Trials = ", trial, "\n",sep = "")
          cat("\t","Number of Replicated Treatments = ", length(checkTrmt), "\n",sep = "")
          cat("\t","Levels of Replicated Treatments = ", sep = "")
          if (length(checkTrmt) <= 5) { cat(paste(checkTrmt, collapse = ", ", sep = ""), "\n", sep = "")
          } else {
               cat(paste(checkTrmt[1:3],collapse = ", ", sep = ""), sep = "")
               cat(", ..., ",checkTrmt[length(checkTrmt)], "\n",sep = "")
          }
          cat("\t","Number of Unreplicated Treatments = ", length(newTrmt), "\n",sep = "")
          cat("\t","Levels of UnReplicated Treatments = ", sep = "")
          if (length(newTrmt) <= 5) { cat(paste(newTrmt, collapse = ", ", sep = ""), "\n", sep = "")
          } else {
               cat(paste(newTrmt[1:3],collapse = ", ", sep = ""), sep = "")
               cat(", ..., ",newTrmt[length(newTrmt)], "\n",sep = "")
          }
          cat("\t","Number of Field Row = ", numFieldRow, "\n",sep = "")
          cat("\t","Number of Field Column = ", numFieldCol, "\n\n",sep = "")
          if (errorDf < 12) {
               cat("WARNING: Too few error df.","\n\n")
          }
          #cat("Results of Randomization:\n")
          #printDataFrame(randomize)
          
     }
     
     
     if (!is.null(file)) {
          tempFile <- strsplit(file, split = "\\.")[[1]]
          tempExt <- tolower(tempFile[length(tempFile)])
          if (tempExt != "csv"){ if(tempExt != "rda") tempExt <- "csv" } 
          newFile <- paste(tempFile[1:length(tempFile)-1], collapse = ".", sep = "")
          newFile <- paste(newFile, tempExt, sep = ".")
          if (tempExt == "csv") { write.csv(randomize, file = newFile, row.names = FALSE)
          } else { save(randomize, file = newFile) }
     } else {
          cat("Results of Randomization:\n")
          printDataFrame(randomize)
     }    
     
     return(invisible(list(fieldbook = randomize, layout = plan, plotNum = plotNum)))
}

     