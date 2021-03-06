#----------------------------------------------------------------
# Half-sib mating, design NC II                        
# From an F2 population m males and f females are      
# randomly selected and each male is crossed to each   
# female.                                              
# Estimates genetic variance components  
#
# ARGUMENTS:
# design - experiment design
# data - name of data frame
# respvar - vector of response variables
# female - string, name of female factor
# male - string, name of male factor
# rep - string, name of rep factor
# block - string, name of block factor
# row - string, name of row factor
# column - string, name of column factor
# inbred - logical
# individual - string, name of individual factor
# environment - string, name of environment factor
#                             
# Script Created by: Violeta Bartolome   07.2011
# Script Modified by: Nellwyn Sales                                      
#----------------------------------------------------------------

nc2Test <-function(design = c("CRD", "RCB", "Alpha", "RowColumn"), data, respvar, female, male, rep=NULL, block=NULL, row=NULL, column=NULL, inbred=TRUE, individual=NULL, environment=NULL) UseMethod("nc2Test")
  
nc2Test.default <-function(design = c("CRD", "RCB", "Alpha", "RowColumn"), data, respvar, female, male, rep=NULL, block=NULL, row=NULL, column=NULL, inbred=TRUE, individual=NULL, environment=NULL) {
	
	options(show.signif.stars=FALSE)
	data <- eval(parse(text = data))
	library(lme4)
	
	# --- trim the strings --- #
	respvar <- trimStrings(respvar)
	female <- trimStrings(female)
	male <- trimStrings(male)
	if (!is.null(block)) {block <- trimStrings(block) }
	if (!is.null(rep)) {rep <- trimStrings(rep) }
	if (!is.null(row)) {row <- trimStrings(row) }
	if (!is.null(column)) {column <- trimStrings(column) }
	if (!is.null(individual)) {individual <- trimStrings(individual) }
	if (!is.null(environment)) {environment <-trimStrings(environment) }
	
	# --- create titles --- #
	if (design == "CRD") { designName<-"CRD"}
	if (design == "RCB") { designName<-"RCB"}
	if (design == "Alpha") { designName<-"ALPHA-LATTICE"}
	if (design == "RowColumn") { designName<-"ROW-COLUMN"}
  
	if (inbred) {parentsType<-"INBRED"
	} else {parentsType<-"CROSS"}
	cat("\nDESIGN: NORTH CAROLINA EXPERIMENT II IN ",designName, " (", parentsType, ")\n", sep="")

	# --- get number of environment levels --- #
	if (!is.null(environment)) {
	  data[,match(environment, names(data))] <- factor(trimStrings(data[,match(environment, names(data))]))
	  envNumLevels<-nlevels(data[,match(environment, names(data))])
	} else {envNumLevels<-1}

	result <- list()
	for (i in (1:length(respvar))) {
	  result[[i]] <- list()
	  cat("\n-----------------------------")
	  cat("\nRESPONSE VARIABLE: ", respvar[i], "\n", sep="")
	  cat("-----------------------------\n")
	  for (j in (1:envNumLevels)) {
	    result[[i]]$site[[j]] <- list()
	    if (!is.null(environment)) {
	      crdVars<-c(respvar[i], female, male, environment)
	      rcbVars<-c(respvar[i], female, male, block, environment)
        alphaVars<-c(respvar[i], female, male, rep, block, environment)
	      rowcolVars<-c(respvar[i], female, male, rep, row, column, environment)
	    } else {
	      crdVars<-c(respvar[i], female, male)
	      rcbVars<-c(respvar[i], female, male, block)
	      alphaVars<-c(respvar[i], female, male, rep, block)
	      rowcolVars<-c(respvar[i], female, male, rep, row, column)
	    }
	    if (design == "CRD") {temp.data <- data[sort(match(crdVars, names(data)))]}
	    if (design == "RCB") {temp.data <- data[sort(match(rcbVars, names(data)))]}
	    if (design == "Alpha") {temp.data <- data[sort(match(alphaVars, names(data)))]}
	    if (design == "RowColumn") {temp.data <- data[sort(match(rowcolVars, names(data)))]}
	    if (!is.null(environment)) {
	      cat("-----------------------------")
	      cat("\nANALYSIS FOR: ",environment, " = " ,levels(temp.data[,match(environment, names(temp.data))])[j],"\n", sep="")
	      cat("-----------------------------\n")
        
	      # --- create temp.data that contains data for one environment level only --- #
	      #temp.data <- subset(temp.data, temp.data[,match(environment, names(temp.data))] == levels(temp.data[,match(environment, names(temp.data))])[j])
	      temp.data <- temp.data[temp.data[,match(environment, names(temp.data))] == levels(temp.data[,match(environment, names(temp.data))])[j],]
        temp.data[,match(environment, names(temp.data))] <- factor(trimStrings(temp.data[,match(environment, names(temp.data))]))
      }
	    
	    # --- define factors --- #
	    obsread<-nrow(temp.data)
			temp.data[,match(female, names(temp.data))] <- factor(trimStrings(temp.data[,match(female, names(temp.data))]))
			temp.data[,match(male, names(temp.data))] <- factor(trimStrings(temp.data[,match(male, names(temp.data))]))
	   	    
	    f <- nlevels(temp.data[,match(female, names(temp.data))])
	    m <- nlevels(temp.data[,match(male, names(temp.data))])
      
			if (design == "RCB") {temp.data[,match(block, names(temp.data))] <- factor(trimStrings(temp.data[,match(block, names(temp.data))]))  }
	    if (design == "Alpha") {
        temp.data[,match(rep, names(temp.data))] <- factor(trimStrings(temp.data[,match(rep, names(temp.data))]))
        temp.data[,match(block, names(temp.data))] <- factor(trimStrings(temp.data[,match(block, names(temp.data))]))
	    }
	    if (design == "RowColumn") {
	      temp.data[,match(rep, names(temp.data))] <- factor(trimStrings(temp.data[,match(rep, names(temp.data))]))
	      temp.data[,match(row, names(temp.data))] <- factor(trimStrings(temp.data[,match(row, names(temp.data))]))
	      temp.data[,match(column, names(temp.data))] <- factor(trimStrings(temp.data[,match(column, names(temp.data))]))
	    }
			
			# --- check if raw data is balanced. If not, generate estimates for missing values --- #
	    # --- remove rows with missing observations --- #
			#temp.data <- subset(temp.data, subset = (is.na(temp.data[,match(respvar[i], names(temp.data))]) == FALSE))
	    temp.data <- temp.data[(is.na(temp.data[,match(respvar[i], names(temp.data))]) == FALSE),]
	    obsused<-nrow(temp.data)
      
	    responseRate<-(obsused/obsread)
	    
	    if (responseRate < 0.80) {
	      cat("\nToo many missing observations. Cannot proceed with the analysis.\n\n")
	      next
	    } else {
	      # --- compute harmonic mean that will be used later in the estimation of genetic variances --- #
	      lengthPerCross<-tapply(temp.data[,respvar[i]], temp.data[,c(male,female)], length)
	      repHarmonicMean<-1/mean((1/lengthPerCross), na.rm=TRUE)
	      
	      # --- compute the number of observations for balanced data --- #
	      if (design == "CRD") {
	        tempDataForAnova<-temp.data[,c(male, female, respvar[i])]
	        nlevelsRep<-max(lengthPerCross, na.rm=TRUE)
	        balancedDataSize<-f*m*nlevelsRep
	      }
	      if (design == "RCB") {
	        tempDataForAnova<-temp.data[,c(male, female, block, respvar[i])]
	        balancedData<-generateBalancedData(design="FACTORIAL", data=tempDataForAnova, respvar[i], male, female, block)
	        balancedDataSize<-nrow(balancedData)
	      }
	      if (design == "Alpha") {
	        balancedDataSize<-nlevels(temp.data[,female])*nlevels(temp.data[,male])*nlevels(temp.data[,rep])
	      }
	      if (design == "RowColumn") {
	        balancedDataSize<-nlevels(temp.data[,female])*nlevels(temp.data[,male])*nlevels(temp.data[,rep])
	      }
	      
	      # --- data summary --- #
	      #funcTrialSum <- class.information2(names(temp.data),temp.data)
	      funcTrialSum <- class.information(names(temp.data),temp.data)
	      cat("\nDATA SUMMARY: ","\n\n", sep="")
	      print(funcTrialSum)
	      cat("\nNumber of observations read: ",obsread, sep="")
	      cat("\nNumber of observations used: ",obsused, sep="")
	      missingObs<-balancedDataSize-nrow(temp.data)
	      
	      # --- ANOVA for NC2 experiment, if design is CRD or RCB --- #
	      if (design == "CRD" || design == "RCB") {
	        cat("\n\n\nANOVA TABLE FOR THE EXPERIMENT:\n\n")
	        if (balancedDataSize<nrow(temp.data)) {
	          cat("***\nERROR: The number of observations read in the data exceeds the size of a balanced data.\n       Please check if the column for block is properly labeled.\n***\n")
	        } else {
	          if ((nrow(temp.data)/balancedDataSize) >= 0.90) {
	            if (nrow(temp.data) == balancedDataSize) {
	              anovaRemark <- "REMARK: Raw dataset is balanced."
	              dataForAnova<-tempDataForAnova  
	            } else {
	              if (design == "CRD") {
	                dataForAnova<-tempDataForAnova
	                anovaRemark  <- "REMARK: Raw dataset is unbalanced."
	              }
	              if (design == "RCB") {
	                dataForAnova<-estimateMissingData(design="RCB", data=balancedData, respvar[i], male, female, block)  
	                anovaRemark  <- "REMARK: Raw data and estimates of the missing values are used."
	              }
	            }  
	            
	            if (design == "CRD") {myformula <- paste(respvar[i], " ~ ", male, "*", female, sep = "")  }
	            if (design == "RCB") {myformula <- paste(respvar[i], " ~ ", block, " + ", male, "*", female, sep = "")  }
	            anova.factorial<-summary(aov(formula(myformula), data=dataForAnova))
	            
	            #rerun aov using temp.data to get the original df's
	            anova.factorial.temp<-summary(aov(formula(myformula), data=temp.data))
	            if (design == "RCB") {
	              anova.factorial.temp[[1]]$"Df"[length(anova.factorial.temp[[1]]$"Df")]<-anova.factorial[[1]]$"Df"[length(anova.factorial[[1]]$"Df")]-missingObs
	            }
	            anovaFormat<-adjustAnovaDf(anova.factorial, anova.factorial.temp[[1]]$"Df")
	            anovaFormat<-formatAnovaTable(anovaFormat)
	            print(anovaFormat)
	            cat("-------\n")
	            cat(anovaRemark)
	            result[[i]]$site[[j]]$nc2.anova <- anovaFormat
	            
	          } else {anovaRemark <- "ERROR: Too many missing values. Cannot perform ANOVA." 
	                  cat(anovaRemark)
	          }
	        }
	      }
	      
	      # --- LMER for factorial ---#
	      if (design == "CRD") {myformula1 <- paste(respvar[i], " ~ 1 + (1|", male, ") + (1|", female, ") + (1|",male,":",female,")", sep = "") }
	      if (design == "RCB") {myformula1 <- paste(respvar[i], " ~ 1 + (1|", block, ") + (1|", male, ") + (1|", female, ") + (1|",male,":",female,")", sep = "") }
	      if (design == "Alpha") {myformula1 <- paste(respvar[i], " ~ 1 + (1|", rep, ") + (1|", block, ":", rep, ") + (1|", male, ") + (1|", female, ") + (1|",male,":",female,")", sep = "") }
	      if (design == "RowColumn") {myformula1 <- paste(respvar[i], " ~ 1 + (1|", rep, ") + (1|", row, ":", rep, ") + (1|", column, ":", rep, ") + (1|", male, ") + (1|", female, ") + (1|",male,":",female,")", sep = "") }
	      
	      model <- lmer(formula(myformula1), data = temp.data)
	      result[[i]]$site[[j]]$lmer.result <- summary(model)
	      
	      # --- edit format of lmer output before printing --- #
           # --- the following code was revised for R Version 3.0.2 by AAGulles
	      #remat<-summary(model)@REmat
	      #Groups<-remat[,1]
	      #Variance<-formatC(as.numeric(remat[,3]), format="f")
	      #Std.Deviation<-formatC(as.numeric(remat[,4]), format="f")
	      #Variance2<-format(rbind("Variance", cbind(Variance)), justify="right")
	      #Std.Deviation2<-format(rbind("Std. Deviation", cbind(Std.Deviation)), justify="right")
	      #Groups2<-format(rbind("Groups",cbind(Groups)), justify="left")
	      #rematNew<-noquote(cbind(Groups2, Variance2, Std.Deviation2))
	      #colnames(rematNew)<-c("", "", "")
	      #rownames(rematNew)<-rep("",nrow(rematNew))
           
           # the above code was replaced by the following code for R version 3.0.2 by AAGulles
	      rematNew <- ConstructVarCorrTable(model)
           
	      cat("\n\n\nLINEAR MIXED MODEL FIT BY RESTRICTED MAXIMUM LIKELIHOOD:\n\n")
	      cat(" Formula: ", myformula1,"\n\n")
	      # print(summary(model)@AICtab) # hide by AAGulles 09.10.2014
	      AICtab <- data.frame(AIC = AIC(model), BIC = BIC(model), logLik = logLik(model), REMLdev = summary(model)$AICtab) # added by AAGulles
	      printDataFrame(AICtab, border = FALSE, digits = 4) # added by AAGulles
	      
	      #cat("\n Fixed Effects:\n")
	      #print(round(summary(model)@coefs, digits=4))
	      cat("\nRandom Effects:\n")
	      # print(rematNew) # hide by AAGulles
	      printDataFrame(rematNew, border = FALSE, digits = 4) # added by AAGulles 09.10.2014
	      	      
	      # --- Estimates of genetic variance components --- #
           # the following code was revised for R version 3.0.2 by AAGulles 09.10.2014
	      #varcomp <- summary(model)@REmat
	      #Ve <- as.numeric(varcomp[varcomp[,1] == "Residual", "Variance"])
	      #Vm_f <- as.numeric(varcomp[varcomp[,1] == paste(male,":",female,sep=""), "Variance"])
	      #Vf <- as.numeric(varcomp[varcomp[,1] == female, "Variance"])
	      #Vm <- as.numeric(varcomp[varcomp[,1] == male, "Variance"])
           
	      # the above code was replaced by the following command for R version 3.0.2 by AAGulles
	      Ve <- rematNew[rematNew[, "Groups"] == "Residual","Variance"]
	      Vm_f <- rematNew[rematNew[, "Groups"] == paste(male, ":", female, sep = ""),"Variance"]
	      Vf <- rematNew[rematNew[, "Groups"] == female,"Variance"]
	      Vm <- rematNew[rematNew[, "Groups"] == male,"Variance"]
	      
	      N <- NROW(temp.data)
	      r <- repHarmonicMean
	      
	      if (inbred) F<-1
	      else F<-0
	      
	      VA <- (2/(1+F))*(Vm+Vf)
	      VD <- (4/(1+F)^2)*Vm_f
	      VE <- Ve
	      if (VD < 0 || VD < 1e-10) VD <- 0
	      if (VA < 0 || VA < 1e-10) VA <- 0
	      VP <- VA + VD + VE
	      h2N <- VA / VP                         # plot-mean based, narrow sense
	      h2B <- (VA + VD) / VP     	      	   # plot-mean based, broad sense
	      # VE <- Ve - (1/2)*VA - (3/4)*(VD)     # formula for individual
	      # formula from Kearsey and Pooni
	      Dominance.ratio <- sqrt(2*VD/VA)
	      
	      # --- format values to print in the table --- #
	      VA_p<-formatNumericValue(VA)
	      VD_p<-formatNumericValue(VD)
	      h2N_p<-formatNumericValue(h2N)
	      h2B_p<-formatNumericValue(h2B)
	      Dominance.ratio_p<-formatNumericValue(Dominance.ratio)
	      Estimate <- rbind(VA_p, VD_p, h2N_p, h2B_p, Dominance.ratio_p)
	      with.colheader<-format(rbind("Estimate", Estimate), justify="right")
	      colnames(with.colheader) <- c("")
	      rownames(with.colheader) <- c("", " VA", " VD", " Narrow sense heritability(plot-mean based)", " Broad sense heritability(plot-mean based)", " Dominance Ratio")
	      TABLE <- as.table(with.colheader)
	      cat("\n\nESTIMATES OF GENETIC VARIANCE COMPONENTS:\n")
	      print(TABLE)
	      result[[i]]$site[[j]]$genvar.components <- TABLE
	      
	      # --- Estimates of heritability values --- #
	      # --- Family Selection ---#
	      H2fm <- Vm/(Vm + Vm_f/f + Ve/(r*f))
	      H2ff <- Vf/(Vf + Vm_f/m + Ve/(r*m))
	      H2ffs <- (f*Vm + m*Vf + Vm_f)/(f*Vm + m*Vf + Vm_f + Ve/r)
	      
	      # --- For individual selection --- #
	      h2m <- (4/(1+F))*Vm/(Vm + Vm_f + Ve)
	      H2m <- ((4/(1+F))*Vm + (4/(1+F)^2)*Vm_f)/(Vm + Vm_f + Ve)
	      
	      h2f <- (4/(1+F))*Vf/(Vf + Vm_f + Ve)
	      H2f <- ((4/(1+F))*Vf + (4/(1+F)^2)*Vm_f)/(Vf + Vm_f + Ve)
	      
	      h2fs <- (2/(1+F))*(Vm+Vf)/(Vm + Vf + Vm_f + Ve)
	      H2fs <- ((2/(1+F))*(Vm+Vf) + (4/(1+F)^2)*Vm_f)/(Vm + Vf + Vm_f + Ve)
	      
	      rowMale2<-paste("",male)
	      rowFemale2<-paste("",female)
	      family <- round(rbind(H2fm, H2ff, H2ffs), digits=2)
	      narrowsense <- round(rbind(h2m, h2f, h2fs), digits=2)
	      broadsense <- round(rbind(H2m, H2f, H2fs), digits=2)
	      
	      TABLE2 <- cbind(family, narrowsense, broadsense)
	      colnames(TABLE2) <- c("Family Selection", "Narrow Sense", "Broad sense")
	      rownames(TABLE2) <- c(rowMale2, rowFemale2, " Full-sib")
	      TABLE2_final <- as.table(TABLE2)
	      result[[i]]$site[[j]]$heritability <- TABLE2_final
	      #cat("\n\nESTIMATES OF HERITABILITY:\n\n")
	      #print(TABLE2_final) 
	      cat("\n\n")
	    }
		} ## end of for loop (j)

	}## end of loop (i)
	cat("\n==============================================================\n")  
	detach("package:lme4")
	return(list(output = result))
}

