ttcTest <-
function(design = c("CRD", "RCB"), data, respvar, tester, f2lines, rep=NULL, block=NULL, individual=NULL, environment=NULL, codeP1, codeP2, codeF1, alpha=0.05) {
	
	options(show.signif.stars=FALSE)
	data <- eval(parse(text = data))
	
	#trim the strings
	respvar <- trim.strings(respvar)
	tester <- trim.strings(tester)
	f2lines <- trim.strings(f2lines)
	block <- trim.strings(block)
	rep <- trim.strings(rep)
	individual <- trim.strings(individual)
	if (!is.null(environment)) {environment <-trim.strings(environment)}
	codeP1 <- trim.strings(codeP1)
	codeP2 <- trim.strings(codeP2)
	codeF1 <- trim.strings(codeF1)
  alpha <- trim.strings(alpha)
	
	# --- create titles --- #
	cat("\nDESIGN: TRIPLE TEST CROSS (NO PARENTS) IN ",design, "\n", sep="")
	
	# --- get number of environment levels --- #
	if (!is.null(environment)) {
	  data[,match(environment, names(data))] <- factor(trim.strings(data[,match(environment, names(data))]))
	  envNumLevels<-nlevels(data[,match(environment, names(data))])
	} else {envNumLevels<-1}
	
	result <- list()
	for (i in (1:length(respvar))) {
	  result[[i]] <- list()
	  cat("\n\nRESPONSE VARIABLE: ", respvar[i], "\n", sep="")
	  for (j in (1:envNumLevels)) {
	    result[[i]]$site[[j]] <- list()
	    if (!is.null(environment)) {
	      crdVars<-c(respvar[i], tester, f2lines, rep, environment)
	      rcbVars<-c(respvar[i], tester, f2lines, block, environment)
	    } else {
	      crdVars<-c(respvar[i], tester, f2lines, rep)
	      rcbVars<-c(respvar[i], tester, f2lines, block)
	    }
	    if (design == "CRD") {temp.data <- data[sort(match(crdVars, names(data)))]}
	    if (design == "RCB") {temp.data <- data[sort(match(rcbVars, names(data)))]}
	    if (!is.null(environment)) {
	      cat("\n-----------------------------")
	      cat("\nANALYSIS FOR: ",environment, " = " ,levels(temp.data[,match(environment, names(temp.data))])[j],"\n", sep="")
	      cat("-----------------------------\n")
	      temp.data <- subset(temp.data, temp.data[,match(environment, names(temp.data))] == levels(temp.data[,match(environment, names(temp.data))])[j])
	      temp.data[,match(environment, names(temp.data))] <- factor(trim.strings(temp.data[,match(environment, names(temp.data))]))
	    }
	    
	    # --- define factors --- #  
			temp.data[,match(tester, names(temp.data))] <- factor(trim.strings(temp.data[,match(tester, names(temp.data))]))
			temp.data[,match(f2lines, names(temp.data))] <- factor(trim.strings(temp.data[,match(f2lines, names(temp.data))]))
			if (design == "CRD") {temp.data[,match(rep, names(temp.data))] <- factor(trim.strings(temp.data[,match(rep, names(temp.data))])) }
			if (design == "RCB") {temp.data[,match(block, names(temp.data))] <- factor(trim.strings(temp.data[,match(block, names(temp.data))]))	}
			
			# --- check if raw data is balanced. If not, generate estimates for missing values --- #
			temp.data <- subset(temp.data, subset = (is.na(temp.data[,match(respvar[i], names(temp.data))]) == FALSE))
			if (design == "CRD") {
				tempDataForAnova<-temp.data[,c(f2lines, tester, rep, respvar[i])]
				balancedData<-generateBalancedData(design="FACTORIAL", data=tempDataForAnova, respvar[i], f2lines, tester, rep)
			}
			if (design == "RCB") {
				tempDataForAnova<-temp.data[,c(f2lines, tester, block, respvar[i])]
				balancedData<-generateBalancedData(design="FACTORIAL", data=tempDataForAnova, respvar[i], f2lines, tester, block)
			}
      
	    # --- data summary --- #
	    funcTrialSum <- class.information2(names(temp.data),temp.data)
	    cat("\nDATA SUMMARY: ","\n", sep="")
	    print(funcTrialSum)
	    cat("\nNumber of observations read: ",nrow(temp.data), sep="")
	    cat("\nNumber of missing observations: ",nrow(balancedData)-nrow(temp.data), sep="")
	    
	    # --- ANOVA for TTC experiment --- #
	    cat("\n\n\nANOVA TABLE FOR THE EXPERIMENT\n")
			if ((nrow(temp.data)/nrow(balancedData)) >= 0.90) {
				if (nrow(temp.data) == nrow(balancedData)) {
				  anovaRemark <- "REMARK: Raw dataset is balanced."
					dataForAnova<-tempDataForAnova  
				} else {
					if (design == "CRD") {dataForAnova<-estimateMissingData(design="CRD", data=balancedData, respvar[i], f2lines, tester, rep)  }
					if (design == "RCB") {dataForAnova<-estimateMissingData(design="RCB", data=balancedData, respvar[i], f2lines, tester, block)  }
					anovaRemark  <- "REMARK: Raw data and estimates of the missing values are used."
				}  

				if (design == "CRD") {myformula <- paste(respvar[i], " ~ ", tester, "*", f2lines, sep = "")  }
				if (design == "RCB") {myformula <- paste(respvar[i], " ~ ", block, " + ", tester, "*", f2lines, sep = "")  }
				anova.factorial<-summary(aov(formula(myformula), data=dataForAnova))		
				print(anova.factorial)
				cat("-------\n")
				cat(anovaRemark)
				result[[i]]$site[[j]]$ttc.anova <- anova.factorial
				
			} else {anovaRemark <- "ERROR: Too many missing values. Cannot perform ANOVA for balanced data." 
			        cat("\n",anovaRemark)
			}
			
	    # --- test significance of tester:f2lines --- #
			Trt <- temp.data[,match(tester, names(temp.data))]:temp.data[,match(f2lines, names(temp.data))]
	    pValue <- 0
	    cat("\n\n\nANOVA TABLE: (Trt = ", tester,":", f2lines, ")", sep="")
			
			if (design == "CRD") {
        myformula1 <- paste(respvar[i], " ~ Trt",sep = "") 
        model1 <- aov(formula(myformula1), data=temp.data)
        anova.table<-summary(model1)
        rownames(anova.table[[1]])<-c(" Trt", " Residuals")
        pValue<-anova.table[[1]]$"Pr(>F)"[[1]]
        
        # print anova table
        p<-formatC(as.numeric(format(anova.table[[1]][1,5], scientific=FALSE)), format="f")
        f<-round(anova.table[[1]][1,4],digits=2)
        anova_new<-cbind(round(anova.table[[1]][1:3],digits=4),rbind(f," "),rbind(p, " "))
        anova_print<-replace(anova_new, is.na(anova_new), " ")
        colnames(anova_print)<-c("Df", "Sum Sq", "Mean Sq", "F value", "Pr(>F)")
        cat("\n Formula: ", myformula1, "\n\n", sep="")
      }
			if (design == "RCB") {
				myformula1 <- paste(respvar[i], " ~ Trt + (1|", block, ")", sep = "") 
				myformula2 <- paste(respvar[i], " ~ (1|", block, ")", sep = "")
				library(lme4)
				model1 <- lmer(formula(myformula1), data=temp.data) 
				model2 <- lmer(formula(myformula2), data=temp.data)  
				anova1<-anova(model1)
				anova.table<-anova(model1, model2)
        pValue<-anova.table$"Pr(>Chisq)"[[2]]

				# print anova table
				p<-formatC(as.numeric(format(anova.table[2,7], scientific=FALSE)), format="f")
				anova_new<-cbind(round(anova.table[1:6],digits=2), rbind(" ",p))
				rownames(anova_new)<-c(" model2", " model1")
				colnames(anova_new)<-c("Df", "AIC", "BIC", "logLik", "Chisq", "Chi Df","Pr(>Chisq)" )
				anova_print<-replace(anova_new, is.na(anova_new), " ")
				cat("\n Formula for Model 1: ", myformula1, sep="")
				cat("\n Formula for Model 2: ", myformula2,"\n\n", sep="")
			}
			print(anova_print)
	    result[[i]]$site[[j]]$testerF2.test <-anova_print
      
	    # --- check if tester:f2lines is significant. if significant, proceed to test for epistasis --- #
	    alpha <- as.numeric(alpha)
	    if (pValue < alpha) {
	      cat("\n\nANOVA FOR TESTING EPISTASIS:")
	      if ((nrow(temp.data)/nrow(balancedData)) >= 0.90) {
          
          # --- reshape data --- #
          if (design == "CRD") {
				   dataForAnova<-dataForAnova[,c(f2lines, tester, rep, respvar[i])]
				   data2 <- reshape(dataForAnova, v.names=respvar[i],idvar=c(f2lines,rep),timevar=tester,direction="wide",sep=".")
			    }
			    if (design == "RCB") {
			   	  dataForAnova<-dataForAnova[,c(f2lines, tester, block, respvar[i])]
			  	  data2 <- reshape(dataForAnova, v.names=respvar[i],idvar=c(f2lines,block),timevar=tester,direction="wide",sep=".")
			    }
			    respvardot<-paste(respvar[i],".", sep = "")
			    colnames(data2) <- gsub(respvardot, "", colnames(data2))
			
			    data2$s <- data2[,match(codeP1, names(data2))] + data2[,match(codeP2, names(data2))] + data2[,match(codeF1, names(data2))]
			    data2$d <- data2[,match(codeP1, names(data2))] - data2[,match(codeP2, names(data2))]
			    data2$sd <- data2[,match(codeP1, names(data2))] + data2[,match(codeP2, names(data2))] - 2*data2[,match(codeF1, names(data2))]
			
			    m <- nlevels(factor(trim.strings(data2[,match(f2lines, names(data2))])))
			    if (design == "CRD") {r <- nlevels(factor(trim.strings(data2[,match(rep, names(data2))]))) }
			    if (design == "RCB") {r <- nlevels(factor(trim.strings(data2[,match(block, names(data2))]))) }
			
			    # --- Test for epistasis --- #
			
			    # --- ANOVA for sd --- #
			    if (design == "CRD") {sd_formula1<-paste("sd ~ ",rep," + ",f2lines, sep="") }
			    if (design == "RCB") {sd_formula1<-paste("sd ~ ",block," + ",f2lines, sep="") }
			
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
  			  SV <- c("SV", "AxA", "AxD and DxD", "Total", "Residual")
	  		  DF <- format(rbind("Df",format(round(rbind(DFaxa, DFad.dd, DFE, DFe_sd),digits=0),nsmall=0)),justify="right")
		  	  SS <- format(rbind("Sum Sq",format(round(rbind(SSaxa, SSad.dd, SSE, SSe_sd),digits=4),nsmall=4)), justify="right")
			    MS <- format(rbind("Mean Sq",format(round(rbind(MSaxa, MSad.dd, MSE, MSe_sd),digits=4),nsmall=4)), justify="right")
  			  Fvalue <- format(rbind("F value",format(round(rbind(Faxa, Fad.dd, FE),digits=2),nsmall=2)," "),justify="right")
  			  Paxa2<-formatC(as.numeric(format(Paxa,scientific=FALSE)),format="f")
	  		  Pad.dd2<-formatC(as.numeric(format(Pad.dd,scientific=FALSE)),format="f")
	  		  PE2<-formatC(as.numeric(format(PE,scientific=FALSE)),format="f")
		  	  Prob <-format(rbind("Pr(>F)",Paxa2, Pad.dd2, PE2, " "),justify="right")
			    AOV <- noquote(cbind(SV, DF, SS, MS, Fvalue, Prob))
			    colnames(AOV) <- c("", "", "", "", "", "")
			    rownames(AOV) <- rep("",nrow(AOV))
          print(AOV)
          cat("-------\n")
          cat(anovaRemark)
			    result[[i]]$site[[j]]$epistasis.test <- AOV		
          # --- NOTE: There is epistatis if either the AxA or AxD and DxD or both are significant. --- #
	      
          #--- estimates of variance components --- #
          
          #---  ANOVA FOR s ---#
          if (design == "CRD") {s_formula1<-paste("s ~ ",rep," + ",f2lines, sep="") }
          if (design == "RCB") {s_formula1<-paste("s ~ ",block," + ",f2lines, sep="") }
          
          model_s <- aov(formula(s_formula1), data=data2)
          out_s <- anova(model_s)
          SSg_s <- out_s[rownames(out_s)==f2lines, "Sum Sq"]/3
          SSe_s <- out_s[rownames(out_s)=="Residuals", "Sum Sq"]/3
          
          DFg_s <- out_s[rownames(out_s)==f2lines, "Df"]
          DFe_s <- out_s[rownames(out_s)=="Residuals", "Df"]
          
          MSg_s <- SSg_s/DFg_s
          MSe_s <- SSe_s/DFe_s
          
          Fg_s <- round(MSg_s/MSe_s,digits=2)
          Fe_s <-" "
          
          Pg_s <- 1-round(pf(Fg_s,DFg_s,DFe_s),6)
          Pe_s <- " "
          
          #---  ANOVA FOR d --- #
          if (design == "CRD") {d_formula1<-paste("d ~ ",rep," + ",f2lines, sep="") }
          if (design == "RCB") {d_formula1<-paste("d ~ ",block," + ",f2lines, sep="") }
          
          model_d <- aov(formula(d_formula1), data=data2)
          out_d <- anova(model_d)
          SSg_d <- out_d[rownames(out_d)==f2lines, "Sum Sq"]/2
          SSe_d <- out_d[rownames(out_d)=="Residuals", "Sum Sq"]/2
          
          DFg_d <- out_d[rownames(out_d)==f2lines, "Df"]
          DFe_d <- out_d[rownames(out_d)=="Residuals", "Df"]
          
          MSg_d <- SSg_d/DFg_d
          MSe_d <- SSe_d/DFe_d
          
          Fg_d <- round(MSg_d/MSe_d,digits=2)
          Fe_d <-" "
          
          Pg_d <- 1-round(pf(Fg_d,DFg_d,DFe_d),6)
          Pe_d <- " "
          
          SV <- c("SV","s", "e(s)", "d", "e(d)")
          DF <- format(rbind("Df",format(round(rbind(DFg_s, DFe_s, DFg_d, DFe_d),digits=0),nsmall=0)),justify="right")
          SS <- format(rbind("Sum Sq",format(round(rbind(SSg_s, SSe_s, SSg_d, SSe_d),digits=4),nsmall=4)),justify="right")
          MS <- format(rbind("Mean Sq",format(round(rbind(MSg_s, MSe_s, MSg_d, MSe_d),digits=4),nsmall=4)),justify="right")
          Fvalue <- format(rbind("F value",format(Fg_s,nsmall=2), Fe_s, format(Fg_d,nsmall=2), Fe_d),justify="right")
          Pg_s2 <- formatC(as.numeric(format(Pg_s,scientific=FALSE)),format="f")
          Pg_d2 <- formatC(as.numeric(format(Pg_d,scientific=FALSE)),format="f")
          Prob <-format(rbind("Pr(>F)",Pg_s2, Pe_s, Pg_d2, Pe_d),justify="right")
          
          AOV2 <- cbind(SV, DF, SS, MS, Fvalue, Prob)
          colnames(AOV2) <- rep("",ncol(AOV2))
          rownames(AOV2) <- rep("",nrow(AOV2))
          AOV2 <- noquote(AOV2)
          cat("\n\n\nANOVA TABLE:")
          print(AOV2)
          result[[i]]$site[[j]]$sd.anova <-AOV2
          
          #--- Genetic variance estimates ---#
          sigma2A <- (MSg_s - MSe_s)/(3*r)
          sigma2D <- (MSg_d - MSe_d)/(2*r)
          fvalue <- 0
          
          if (fvalue==0)   {
            VA <- 4*sigma2A
            VVA <- (32/(9*(r^2)))*(((MSg_s^2)/(m-1+2))+((MSe_s^2)/((m-1)*(r-1)+2)))
            VD <- 2*sigma2D
            VVD <- (2/(r^2))*(((MSg_d^2)/(m-1+2)) + ((MSe_d^2)/((m-1)*(r-1)+2)))
            VE <- MSe_s
            VP <- VA + VD + VE
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
          
          cat("\n\nESTIMATES OF GENETIC VARIANCE COMPONENTS:")
          cat("\n VA = ",format(round(VA, digits=4)), ";  se = " , format(round(VVA, digits=5)), sep="")
          cat("\n VD = ",format(round(VD, digits=4)), ";  se = " , format(round(VVD, digits=5)), sep="")
          cat("\n VE = ",format(round(VE, digits=4)), sep="")
          cat("\n VP = ",format(round(VP, digits=4)), sep="")
          cat("\n Heritability, Broad sense = ",format(round(h2B, digits=4)), ";  se = " , format(round(Vh2B, digits=5)), sep="")
          cat("\n Heritability, Narrow sense = ",format(round(h2N, digits=4)), ";  se = " , format(round(Vh2N, digits=5)), sep="")
          cat("\n Dominance Ratio = ",format(round(dominance.ratio, digits=4)), sep="")
          cat("\n\n")
          
        } else {cat("\n\n ERROR: Too many missing values. Cannot perform test for epistasis and estimation of genetic variance components.\n\n")}      
      } ## end of if statement
		} ## end of for loop (j)	
	  cat("\n==============================================================\n")
	}## end of loop (i)
	detach("package:lme4")
	return(list(output = result))
}

