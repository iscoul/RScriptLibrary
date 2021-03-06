#----------------------------------------------------------------
# Half-sib mating, Triple Test Cross                    
# P1,P2,F1 (Female) are crossed with F2 lines (Male)    
# Tests presence of epistasis                           
# Computes genetic variance components
#                  
# Script Created by: Violeta Bartolome   07.2011
# Script Modified by: Nellwyn M. Levita  08.31.2011                                     
#---------------------------------------------------------------- 

ttcTest <-function(design = c("CRD", "RCB", "Alpha", "RowColumn"), data, respvar, tester, f2lines, rep=NULL, block=NULL, row=NULL, column=NULL, individual=NULL, environment=NULL, codeP1, codeP2, codeF1, alpha=0.05) UseMethod("ttcTest")

ttcTest.default <-function(design = c("CRD", "RCB", "Alpha", "RowColumn"), data, respvar, tester, f2lines, rep=NULL, block=NULL, row=NULL, column=NULL, individual=NULL, environment=NULL, codeP1, codeP2, codeF1, alpha=0.05) {
	
	options(show.signif.stars=FALSE)
	data <- eval(parse(text = data))
	
	# --- trim the strings --- #
	respvar <- trimStrings(respvar)
	tester <- trimStrings(tester)
	f2lines <- trimStrings(f2lines)
	if (!is.null(block)) {block <- trimStrings(block) }
	if (!is.null(rep)) {rep <- trimStrings(rep) }
	if (!is.null(row)) {row <- trimStrings(row) }
	if (!is.null(column)) {column <- trimStrings(column) }
	if (!is.null(individual)) {individual <- trimStrings(individual) }
	if (!is.null(environment)) {environment <-trimStrings(environment) }
	codeP1 <- trimStrings(codeP1)
	codeP2 <- trimStrings(codeP2)
	codeF1 <- trimStrings(codeF1)
  alpha <- trimStrings(alpha)
	
	# --- create titles --- #
	if (design == "CRD") { designName<-"CRD"}
	if (design == "RCB") { designName<-"RCB"}
	if (design == "Alpha") { designName<-"ALPHA-LATTICE"}
	if (design == "RowColumn") { designName<-"ROW-COLUMN"}
	cat("\nDESIGN: TRIPLE TEST CROSS (NO PARENTS) IN ",designName, "\n", sep="")
	
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
	      if (design == "CRD") {groupVars<-c(respvar[i], tester, f2lines, environment) }
	      if (design == "RCB") {groupVars<-c(respvar[i], tester, f2lines, block, environment) }
	      if (design == "Alpha") {groupVars<-c(respvar[i], tester, f2lines, rep, block, environment) }
	      if (design == "RowColumn") {groupVars<-c(respvar[i], tester, f2lines, rep, row, column, environment) }
	    } else {
	      if (design == "CRD") {groupVars<-c(respvar[i], tester, f2lines) }
	      if (design == "RCB") {groupVars<-c(respvar[i], tester, f2lines, block) }
	      if (design == "Alpha") {groupVars<-c(respvar[i], tester, f2lines, rep, block) }
	      if (design == "RowColumn") {groupVars<-c(respvar[i], tester, f2lines, rep, row, column) }
	    }
	    temp.data <- data[sort(match(groupVars, names(data)))]
	    
	    if (!is.null(environment)) {
	      cat("-----------------------------")
	      cat("\nANALYSIS FOR: ",environment, " = " ,levels(temp.data[,match(environment, names(temp.data))])[j],"\n", sep="")
	      cat("-----------------------------\n")
        
	      result[[i]]$site[[j]]$env <- levels(temp.data[,match(environment, names(temp.data))])[j]
        
	      # --- create temp.data that contains data for one environment level only --- #
	      #temp.data <- subset(temp.data, temp.data[,match(environment, names(temp.data))] == levels(temp.data[,match(environment, names(temp.data))])[j])
	      temp.data <- temp.data[temp.data[,match(environment, names(temp.data))] == levels(temp.data[,match(environment, names(temp.data))])[j],]
        temp.data[,match(environment, names(temp.data))] <- factor(trimStrings(temp.data[,match(environment, names(temp.data))]))
	    }
	    
	    # --- define factors --- # 
	    obsread<-nrow(temp.data)
			temp.data[,match(tester, names(temp.data))] <- factor(trimStrings(temp.data[,match(tester, names(temp.data))]))
			temp.data[,match(f2lines, names(temp.data))] <- factor(trimStrings(temp.data[,match(f2lines, names(temp.data))]))
			if (design == "RCB") {temp.data[,match(block, names(temp.data))] <- factor(trimStrings(temp.data[,match(block, names(temp.data))]))	}
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
      
	    if ((obsused/obsread) < 0.80) {
	      cat("\nToo many missing observations. Cannot proceed with the analysis.\n\n")
	      result[[i]]$site[[j]]$tooManyNAWarning <- "YES"
	      next
	    } else {
	      result[[i]]$site[[j]]$tooManyNAWarning <- "NO"
        
	      # --- create new column containing treatment combinations --- #
	      temp.data$cross<-factor(paste(temp.data[,f2lines], ":", temp.data[,tester], sep=""))
	      temp.data<-temp.data[order(temp.data$cross),]
	      
	      # --- compute harmonic mean that will be used later in the estimation of genetic variances --- #
	      lengthPerCross<-tapply(temp.data[,respvar[i]], temp.data$cross, length)
	      repHarmonicMean<-1/mean((1/lengthPerCross), na.rm=TRUE)
	      
	      # --- compute the number of observations for balanced data --- #
	      if (design == "CRD") {
	        # --- add column Rep --- #
	        temp.data<-data.frame(temp.data, Rep=sequence(lengthPerCross))
	        
	        nlevelsRep<-max(lengthPerCross, na.rm=TRUE)
	        balancedDataSize<-3*nlevels(temp.data[,f2lines])*nlevelsRep
	      }
	      if (design == "RCB") {
	        tempDataForAnova<-temp.data[,c(f2lines, tester, block, respvar[i])]
	        balancedData<-generateBalancedData(design="FACTORIAL", data=tempDataForAnova, respvar[i], f2lines, tester, block)
	        balancedDataSize<-3*nlevels(temp.data[,f2lines])*nlevels(temp.data[,block])
	      }
	      if (design == "Alpha" || design == "RowColumn") {
	        tempDataForAnova<-temp.data[,c(f2lines, tester, rep, respvar[i])]
	        balancedData<-generateBalancedData(design="FACTORIAL", data=tempDataForAnova, respvar[i], f2lines, tester, rep)
	        balancedDataSize<-3*nlevels(temp.data[,f2lines])*nlevels(temp.data[,rep])
	      }
	      temp.data<-temp.data[-c(match("cross", names(temp.data)))]
	      
	      # --- data summary --- #
	      #funcTrialSum <- class.information2(names(temp.data),temp.data)
	      funcTrialSum <- class.information(names(temp.data),temp.data)
	      cat("\nDATA SUMMARY: ","\n\n", sep="")
	      print(funcTrialSum)
	      cat("\nNumber of observations read: ",obsread, sep="")
	      cat("\nNumber of observations used: ",obsused, sep="")
	      missingObs<-balancedDataSize-nrow(temp.data)
	      
	      result[[i]]$site[[j]]$funcTrialSum <- funcTrialSum
	      result[[i]]$site[[j]]$obsread <- obsread
	      result[[i]]$site[[j]]$obsused <- obsused
	      
	      # --- give warning if the number of obs in the dataset exceeds the balanced data size --- #
	      if (balancedDataSize<nrow(temp.data)) {
	        cat("\n\n***\nERROR: The number of observations read in the data exceeds the size of a balanced data.\n       Please check if the column for block/replicate is properly labeled.\n***\n\n")
	        result[[i]]$site[[j]]$exceededWarning <- "YES"
	      } else {
	        result[[i]]$site[[j]]$exceededWarning <- "NO"
	        if (design == "CRD" || design == "RCB") {
	          cat("\n\n\nANOVA TABLE FOR THE EXPERIMENT:\n\n")  
	        }
	        
	        responseRate<-(nrow(temp.data)/balancedDataSize)
	        result[[i]]$site[[j]]$responseRate <- responseRate
	        
	        if ((nrow(temp.data)/balancedDataSize) >= 0.90) {
	          if (nrow(temp.data) == balancedDataSize) {
	            anovaRemark <- "Raw dataset is balanced."
	            dataForAnova<-temp.data
	          } else {
	            if (design == "CRD") {
	              dataForAnova<-temp.data
	              anovaRemark  <- "Raw dataset is unbalanced."
	            }
	            if (design == "RCB") {
	              dataForAnova<-estimateMissingData(design="RCB", data=balancedData, respvar[i], f2lines, tester, block)
	              anovaRemark  <- "Raw data and estimates of the missing values are used."
	            }
	            if (design == "Alpha" || design == "RowColumn") {
	              dataForAnova<-estimateMissingData(design="RCB", data=balancedData, respvar[i], f2lines, tester, rep)
	              anovaRemark  <- "Raw data and estimates of the missing values are used."
	            }
	          }
	          result[[i]]$site[[j]]$anovaRemark <- anovaRemark
	          
	          if (design == "CRD" || design == "RCB") {
	            if (design == "CRD") {myformula <- paste(respvar[i], " ~ ", tester, "*", f2lines, sep = "")  }
	            if (design == "RCB") {myformula <- paste(respvar[i], " ~ ", block, " + ", tester, "*", f2lines, sep = "")  }
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
	            cat(paste("REMARK: ",anovaRemark, sep=""))
	            result[[i]]$site[[j]]$ttc.anova <- anovaFormat
	            
	          }
	        } else {
	          if (design == "CRD" || design == "RCB") {
	            anovaRemark <- "ERROR: Too many missing values. Cannot perform ANOVA for balanced data." 
	            cat("\n",anovaRemark)
	          }
	        }
	        
	        # --- test significance of tester:f2lines --- #
	        Crosses <- temp.data[,match(tester, names(temp.data))]:temp.data[,match(f2lines, names(temp.data))]
	        pValue <- 0
	        cat("\n\n\nTESTING FOR THE SIGNIFICANCE OF CROSS EFFECT: (Crosses = ", tester,":", f2lines, ")\n", sep="")
	        
	        if (design == "CRD") {
	          myformula1 <- paste(respvar[i], " ~ Crosses",sep = "") 
	          model1 <- aov(formula(myformula1), data=temp.data)
	          anova.table<-summary(model1)
	          pValue<-anova.table[[1]]$"Pr(>F)"[[1]]
	          
	          # print anova table
	          anova_print <- formatAnovaTable(anova.table)
	          cat("\n Formula: ", myformula1, "\n\n", sep="")
	          
	          result[[i]]$site[[j]]$testerF2.test <-anova_print
	          result[[i]]$site[[j]]$pValue <- pValue
	        }
	        if (design == "RCB") {
	          myformula1 <- paste(respvar[i], " ~ Crosses + (1|", block, ")", sep = "") 
	          #	myformula2 <- paste(respvar[i], " ~ (1|", block, ")", sep = "")
	          #	library(lme4)
	          #	model1 <- lmer(formula(myformula1), data=temp.data) 
	          #	model2 <- lmer(formula(myformula2), data=temp.data)  
	          #	anova1<-anova(model1)
	          #	anova.table<-anova(model1, model2)
	          # pValue<-anova.table$"Pr(>Chisq)"[[2]]
	          
	          # print anova table
	          #	p<-formatC(as.numeric(format(anova.table[2,7], scientific=FALSE)), format="f")
	          #	anova_new<-cbind(round(anova.table[1:6],digits=2), rbind(" ",p))
	          #	rownames(anova_new)<-c(" model2", " model1")
	          #	colnames(anova_new)<-c("Df", "AIC", "BIC", "logLik", "Chisq", "Chi Df","Pr(>Chisq)" )
	          #	anova_print<-replace(anova_new, is.na(anova_new), " ")
	          #	cat("\n Formula for Model 1: ", myformula1, sep="")
	          #	cat("\n Formula for Model 2: ", myformula2,"\n\n", sep="")
	        }
	        if (design == "Alpha") {
	          myformula1 <- paste(respvar[i], " ~ Crosses + (1|", rep, ") + (1|", block, ":", rep, ")", sep = "") 
	          # myformula2 <- paste(respvar[i], " ~ (1|", rep, ") + (1|", block, ":", rep, ")", sep = "")
	          #library(lme4)
	          # model1 <- lmer(formula(myformula1), data=temp.data) 
	          # model2 <- lmer(formula(myformula2), data=temp.data)  
	          # anova1<-anova(model1)
	          # anova.table<-anova(model1, model2)
	          # pValue<-anova.table$"Pr(>Chisq)"[[2]]
	          
	          # print anova table
	          #p<-formatC(as.numeric(format(anova.table[2,7], scientific=FALSE)), format="f")
	          #anova_new<-cbind(round(anova.table[1:6],digits=2), rbind(" ",p))
	          #rownames(anova_new)<-c(" model2", " model1")
	          #colnames(anova_new)<-c("Df", "AIC", "BIC", "logLik", "Chisq", "Chi Df","Pr(>Chisq)" )
	          #anova_print<-replace(anova_new, is.na(anova_new), " ")
	          #cat("\n Formula for Model 1: ", myformula1, sep="")
	          #cat("\n Formula for Model 2: ", myformula2,"\n\n", sep="")
	        }
	        if (design == "RowColumn") {
	          myformula1 <- paste(respvar[i], " ~ Crosses + (1|", rep, ") + (1|", row, ":", rep, ") + (1|", column, ":", rep, ")", sep = "") 
	          # myformula2 <- paste(respvar[i], " ~ (1|", rep, ") + (1|", row, ":", rep, ") + (1|", column, ":", rep, ")", sep = "")
	          # library(lme4)
	          # model1 <- lmer(formula(myformula1), data=temp.data) 
	          # model2 <- lmer(formula(myformula2), data=temp.data)  
	          # anova1<-anova(model1)
	          # anova.table<-anova(model1, model2)
	          # pValue<-anova.table$"Pr(>Chisq)"[[2]]
	          
	          # print anova table
	          # p<-formatC(as.numeric(format(anova.table[2,7], scientific=FALSE)), format="f")
	          # anova_new<-cbind(round(anova.table[1:6],digits=2), rbind(" ",p))
	          # rownames(anova_new)<-c(" model2", " model1")
	          # colnames(anova_new)<-c("Df", "AIC", "BIC", "logLik", "Chisq", "Chi Df","Pr(>Chisq)" )
	          # anova_print<-replace(anova_new, is.na(anova_new), " ")
	          # cat("\n Formula for Model 1: ", myformula1, sep="")
	          # cat("\n Formula for Model 2: ", myformula2,"\n\n", sep="")
	        }
	        #print(anova_print)
	        result[[i]]$site[[j]]$formula1 <- myformula1
	        result[[i]]$site[[j]]$data <- cbind(temp.data, Crosses)
	        
	        
	        # --- check if tester:f2lines is significant. if significant, proceed to test for epistasis --- #
	        alpha <- as.numeric(alpha)
	        #if (pValue < alpha) {
	        cat("\n\nANOVA FOR TESTING EPISTASIS:\n")
	        if ((nrow(temp.data)/balancedDataSize) >= 0.90) {
	          
	          # --- reshape data --- #
	          if (design == "CRD") {
	            dataForAnova<-dataForAnova[,c(f2lines, tester, "Rep", respvar[i])]
	            data2 <- reshape(dataForAnova, v.names=respvar[i],idvar=c(f2lines,"Rep"),timevar=tester,direction="wide",sep=".")
	            data2 <- data2[complete.cases(data2),]
	          }
	          if (design == "RCB") {
	            dataForAnova<-dataForAnova[,c(f2lines, tester, block, respvar[i])]
	            data2 <- reshape(dataForAnova, v.names=respvar[i],idvar=c(f2lines,block),timevar=tester,direction="wide",sep=".")
	          }
	          if (design == "Alpha" || design == "RowColumn") {
	            dataForAnova<-dataForAnova[,c(f2lines, tester, rep, respvar[i])]
	            data2 <- reshape(dataForAnova, v.names=respvar[i],idvar=c(f2lines, rep),timevar=tester,direction="wide",sep=".")
	          }
	          
	          respvardot<-paste(respvar[i],".", sep = "")
	          colnames(data2) <- gsub(respvardot, "", colnames(data2))
	          
	          data2$s <- data2[,match(codeP1, names(data2))] + data2[,match(codeP2, names(data2))] + data2[,match(codeF1, names(data2))]
	          data2$d <- data2[,match(codeP1, names(data2))] - data2[,match(codeP2, names(data2))]
	          data2$sd <- data2[,match(codeP1, names(data2))] + data2[,match(codeP2, names(data2))] - 2*data2[,match(codeF1, names(data2))]
	          
	          m <- nlevels(factor(trimStrings(data2[,match(f2lines, names(data2))])))
	          if (design == "CRD") {r <- repHarmonicMean }
	          if (design == "RCB") {r <- nlevels(factor(trimStrings(data2[,match(block, names(data2))]))) }
	          if (design == "Alpha" || design == "RowColumn") {r <- nlevels(factor(trimStrings(data2[,match(rep, names(data2))]))) }
	          
	          # --- Test for epistasis --- #
	          
	          # --- ANOVA for sd --- #
	          #if (design == "CRD") {sd_formula1<-paste("sd ~ Rep"," + ",f2lines, sep="") }
	          if (design == "CRD") {sd_formula1<-paste("sd ~ ",f2lines, sep="") }
	          if (design == "RCB") {sd_formula1<-paste("sd ~ ",block," + ",f2lines, sep="") }
	          if (design == "Alpha" || design == "RowColumn") {sd_formula1<-paste("sd ~ ",rep," + ",f2lines, sep="") }
	          
	          model_sd <- aov(formula(sd_formula1), data=data2)
	          out_sd <- anova(model_sd)
	          SSg_sd <- out_sd[rownames(out_sd)==f2lines, "Sum Sq"]/6
	          SSe_sd <- out_sd[rownames(out_sd)=="Residuals", "Sum Sq"]/6
	          
	          DFg_sd <- out_sd[rownames(out_sd)==f2lines, "Df"]
	          DFe_sd <- out_sd[rownames(out_sd)=="Residuals", "Df"]
	          
	          MSg_sd <- SSg_sd/DFg_sd
	          MSe_sd <- SSe_sd/DFe_sd
	          
	          SSaxa <- (sum(data2$sd))^2/(6*m*r)
	          DFaxa <- 1
	          MSaxa <- SSaxa/DFaxa
	          
	          SSad.dd <- (1/(6*r))*(sum(data2$sd^2)) -SSaxa 
	          DFad.dd <- m-1
	          MSad.dd <- SSad.dd/DFad.dd
	          
	          SSE <- (1/(6*r))*(sum(data2$sd^2))
	          DFE <- m
	          MSE <- SSE/DFE
	          
	          Faxa <- round(MSaxa/MSe_sd,4)
	          Fad.dd <- round(MSad.dd/MSe_sd,4)
	          FE <- round(MSE/MSe_sd,4)
	          Fe_sd <- " "
	          
	          Paxa <- round(1-pf(Faxa,DFaxa,DFe_sd),6)
	          Pad.dd <- round(1-pf(Fad.dd,DFad.dd,DFe_sd),6)
	          PE <- round(1-pf(FE,DFE,DFe_sd),6)
	          Pe_sd <- " "
	          
	          # --- format and print epistasis test table --- #
	          DF <- c(DFaxa, DFad.dd, DFE, DFe_sd)
	          SS <- c(SSaxa, SSad.dd, SSE, SSe_sd)
	          MS <- c(MSaxa, MSad.dd, MSE, MSe_sd)
	          Fvalue <- c(Faxa, Fad.dd, FE, NA)
	          Prob <-c(Paxa, Pad.dd, PE, NA)
	          AOV <- cbind(DF, SS, MS, Fvalue, Prob)
	          rownames(AOV) <- c("AxA", "AxD and DxD", "Total", "Residuals")
	          AOV<-as.data.frame(AOV)
            AOV_print <- formatAnovaTable(AOV)
	          
	          print(AOV_print)
	          cat("-------\n")
	          cat(paste("REMARK: ",anovaRemark, sep=""))
	          result[[i]]$site[[j]]$epistasis.test <- AOV_print		
	          # --- NOTE: There is epistatis if either the AxA or AxD and DxD or both are significant. --- #
	          
	          #--- estimates of variance components --- #
	          
	          #---  ANOVA FOR s ---#
	          if (design == "CRD") {s_formula1<-paste("s ~ ",f2lines, sep="") }
	          if (design == "RCB") {s_formula1<-paste("s ~ ",block," + ",f2lines, sep="") }
	          if (design == "Alpha" || design == "RowColumn") {s_formula1<-paste("s ~ ",rep," + ",f2lines, sep="") }
	          
	          model_s <- aov(formula(s_formula1), data=data2)
	          out_s <- anova(model_s)
	          SSg_s <- out_s[rownames(out_s)==f2lines, "Sum Sq"]/3
	          SSe_s <- out_s[rownames(out_s)=="Residuals", "Sum Sq"]/3
	          
	          DFg_s <- out_s[rownames(out_s)==f2lines, "Df"]
	          DFe_s <- out_s[rownames(out_s)=="Residuals", "Df"]
	          
	          MSg_s <- SSg_s/DFg_s
	          MSe_s <- SSe_s/DFe_s
	          
	          Fg_s <- round(MSg_s/MSe_s,digits=2)
	          Fe_s <-NA
	          
	          Pg_s <- 1-round(pf(Fg_s,DFg_s,DFe_s),6)
	          Pe_s <- NA
	          
	          #---  ANOVA FOR d --- #
	          if (design == "CRD") {d_formula1<-paste("d ~ ",f2lines, sep="") }
	          if (design == "RCB") {d_formula1<-paste("d ~ ",block," + ",f2lines, sep="") }
	          if (design == "CRD" || design == "Alpha" || design == "RowColumn") {d_formula1<-paste("d ~ ",rep," + ",f2lines, sep="") }
	          
	          model_d <- aov(formula(d_formula1), data=data2)
	          out_d <- anova(model_d)
	          SSg_d <- out_d[rownames(out_d)==f2lines, "Sum Sq"]/2
	          SSe_d <- out_d[rownames(out_d)=="Residuals", "Sum Sq"]/2
	          
	          DFg_d <- out_d[rownames(out_d)==f2lines, "Df"]
	          DFe_d <- out_d[rownames(out_d)=="Residuals", "Df"]
	          
	          MSg_d <- SSg_d/DFg_d
	          MSe_d <- SSe_d/DFe_d
	          
	          Fg_d <- round(MSg_d/MSe_d,digits=2)
	          Fe_d <-NA
	          
	          Pg_d <- 1-round(pf(Fg_d,DFg_d,DFe_d),6)
	          Pe_d <- NA
	          
	          DF <- c(DFg_s, DFe_s, DFg_d, DFe_d)
	          SS <- c(SSg_s, SSe_s, SSg_d, SSe_d)
	          MS <- c(MSg_s, MSe_s, MSg_d, MSe_d)
	          Fvalue <- c(Fg_s, Fe_s, Fg_d, Fe_d)
	          Prob <-c(Pg_s, Pe_s, Pg_d, Pe_d)
	          
	          AOV2 <- cbind(DF, SS, MS, Fvalue, Prob)
	          rownames(AOV2) <- c("s", "e(s)", "d", "e(d)")
	          AOV2 <- as.data.frame(AOV2)
            AOV2 <- formatAnovaTable(AOV2)
	          cat("\n\n\nANOVA TABLE:\n")
	          print(AOV2)
	          cat("-------\n")
	          cat(paste("REMARK: ",anovaRemark, sep=""))
	          cat("\n")
	          result[[i]]$site[[j]]$sd.anova <-AOV2
	          
	          #--- Genetic variance estimates ---#
	          sigma2A <- (MSg_s - MSe_s)/(3*r)
	          sigma2D <- (MSg_d - MSe_d)/(2*r)
	          if (sigma2A < 0) sigma2A<-0
	          if (sigma2D < 0) sigma2D<-0
	          fvalue <- 0
	          
	          if (fvalue==0)   {
	            VA <- 4*sigma2A
	            VVA <- (32/(9*(r^2)))*(((MSg_s^2)/(m-1+2))+((MSe_s^2)/((m-1)*(r-1)+2)))
	            VD <- 2*sigma2D
	            VVD <- (2/(r^2))*(((MSg_d^2)/(m-1+2)) + ((MSe_d^2)/((m-1)*(r-1)+2)))
	            VE <- MSe_s
	            VP <- VA + VD + VE
              
	            if (VA < 0 || VA < 1e-10) VA <- 0
	            if (VD < 0 || VD < 1e-10) VD <- 0
	            if (VE < 0 || VE < 1e-10) VE <- 0
	            if (VP < 0 || VP < 1e-10) VP <- 0
              
	            h2B <- (VA+VD)/VP
	            Vh2B <- (2*(1-h2B)^2*(1+(r-1)*h2B)^2)/(r*(r-1)*(m-1))
	            h2N <- VA/VP
	            Vh2N <- (2*(1-h2N)^2*(1+(r-1)*h2N)^2)/(r*(r-1)*(m-1))
	            dominance.ratio <- sqrt(2*VD/VA)
	          }
	          
	          #if (fvalue==1)    {
	          #  VA <- 2*sigma2A
	          #  VVA <- (8/(9*(r^2)))*(((MSg_s^2)/(m-1+2))+((MSe_s^2)/((m-1)*(r-1)+2)))
	          #  VD <- sigma2D
	          #  VVD <- (1/(2*r^2))*(((MSg_d^2)/(m-1+2)) + ((MSe_d^2)/((m-1)*(r-1)+2)))
	          #  VE <- MSe_s
	          #  VP <- VA + VD + VE
	          #  h2B <- (VA+VD)/VP
	          #  Vh2B <- (2*(1-h2B)^2*(1+(r-1)*h2B)^2)/(r*(r-1)*(m-1))
	          #  h2N <- VA/VP
	          #	 Vh2N <- (2*(1-h2N)^2*(1+(r-1)*h2N)^2)/(r*(r-1)*(m-1))
	          #  dominance.ratio <- sqrt(2*VD/VA)
	          #}
	          
	          cat("\n\nESTIMATES OF GENETIC VARIANCE COMPONENTS:\n")
	          cat("\n VA = ",format(round(VA, digits=4)), ";  se = " , format(round(VVA, digits=5)), sep="")
	          cat("\n VD = ",format(round(VD, digits=4)), ";  se = " , format(round(VVD, digits=5)), sep="")
	          cat("\n VE = ",format(round(VE, digits=4)), sep="")
	          cat("\n VP = ",format(round(VP, digits=4)), sep="")
	          cat("\n Heritability, Broad sense = ",format(round(h2B, digits=4)), ";  se = " , format(round(Vh2B, digits=5)), sep="")
	          cat("\n Heritability, Narrow sense = ",format(round(h2N, digits=4)), ";  se = " , format(round(Vh2N, digits=5)), sep="")
	          cat("\n Dominance Ratio = ",format(round(dominance.ratio, digits=4)), sep="")
	          cat("\n\n\n")
	          
	          RowNamesVector<-c("VA","VD", "VE", "VP", "Broad Sense Heritability", "Narrow Sense Heritability", "Dominance Ratio")
	          Estimate<-rbind(formatNumericValue(VA), formatNumericValue(VD), formatNumericValue(VE), formatNumericValue(VP),
	                          formatNumericValue(h2B), formatNumericValue(h2N), formatNumericValue(dominance.ratio))
	          SE<-rbind(formatNumericValue(VVA), formatNumericValue(VVD), "", "", formatNumericValue(Vh2B), formatNumericValue(Vh2N), "")
	          genVar<-data.frame(Estimate=Estimate, SE=SE, row.names=RowNamesVector)
	          result[[i]]$site[[j]]$genVar <- genVar
	          
	        } else {cat("\n ERROR: Too many missing values. Cannot perform test for epistasis and estimation of genetic variance components.\n\n")}      
	        #} ## end of if statement
	      }
	    }
		} ## end of for loop (j)	
	}## end of loop (i)
	cat("\n==============================================================\n")
	#if (design != "CRD") {detach("package:lme4")}
	return(list(output = result))
}

