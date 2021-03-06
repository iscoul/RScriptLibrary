nc2TestME <-
function(design = c("CRD", "RCB"), data, respvar, female, male, rep=NULL, block=NULL, inbred=TRUE, individual=NULL, environment) {
	
  options(show.signif.stars=FALSE)
  data <- eval(parse(text = data))
	
	#trim the strings
	respvar <- trim.strings(respvar)
	female <- trim.strings(female)
	male <- trim.strings(male)
	block <- trim.strings(block)
	rep <- trim.strings(rep)
	individual <- trim.strings(individual)
	environment <-trim.strings(environment)
	
	# --- create titles --- #
	if (inbred) {parentsType<-"INBRED"
	} else {parentsType<-"CROSS"}
	cat("\nMULTIPLE ENVIRONMENT ANALYSIS\n")
	cat("\nDESIGN: NORTH CAROLINA EXPERIMENT II IN ",design, " (", parentsType, ")\n", sep="")
	
	#define factors
	data[,match(female, names(data))] <- factor(trim.strings(data[,match(female, names(data))]))
	data[,match(male, names(data))] <- factor(trim.strings(data[,match(male, names(data))]))
	data[,match(environment, names(data))] <- factor(trim.strings(data[,match(environment, names(data))]))
	if (design == "CRD") {data[,match(rep, names(data))] <- factor(trim.strings(data[,match(rep, names(data))])) }
	if (design == "RCB") {data[,match(block, names(data))] <- factor(trim.strings(data[,match(block, names(data))]))	}
	
	result <- list()
	for (i in (1:length(respvar))) {
		result[[i]] <- list()
		temp.data <- subset(data, subset = (is.na(data[,match(respvar[i], names(data))]) == FALSE))
		cat("\n\nRESPONSE VARIABLE: ", respvar[i], "\n", sep="")
		
		# --- data summary --- #
		funcTrialSum <- class.information2(names(temp.data),temp.data)
		cat("\nDATA SUMMARY: ","\n", sep="")
		print(funcTrialSum)
		cat("\n Number of observations read: ",nrow(temp.data), sep="")
		#cat("\n Number of missing observations: ",nrow(balancedData)-nrow(temp.data), sep="")
		
		# --- LMER for the design --- #
		if (design == "CRD") {myformula1 <- paste(respvar[i], " ~ 1 + (1|", environment, ") + (1|", male, ") + (1|", female, ") + (1|", male, ":", female, ") + (1|", environment, ":", male, ") + (1|", environment, ":", female, ") + (1|", environment, ":", female, ":", male,")", sep = "") }
		if (design == "RCB") {myformula1 <- paste(respvar[i], " ~ 1 + (1|", environment, ") + (1|", block, ":", environment, ") + (1|", male, ") + (1|", female, ") + (1|", male, ":", female, ") + (1|", environment, ":", male, ") + (1|", environment, ":", female, ") + (1|", environment, ":", female, ":", male,")", sep = "") }		
		library(lme4)
		model <- lmer(formula(myformula1), data = temp.data)
		result[[i]]$lmer.result <- summary(model)
		
		# --- edit format of lmer output before printing --- #
		remat<-summary(model)@REmat
		Groups<-remat[,1]
		Variance<-formatC(as.numeric(remat[,3]), format="f")
		Std.Deviation<-formatC(as.numeric(remat[,4]), format="f")
		Variance2<-format(rbind("Variance", cbind(Variance)), justify="right")
		Std.Deviation2<-format(rbind("Std. Deviation", cbind(Std.Deviation)), justify="right")
		Groups2<-format(rbind("Groups",cbind(Groups)), justify="left")
		rematNew<-noquote(cbind(Groups2, Variance2, Std.Deviation2))
		colnames(rematNew)<-c("", "", "")
		rownames(rematNew)<-rep("",nrow(rematNew))
		cat("\n\n\nLINEAR MIXED MODEL FIT BY RESTRICTED MAXIMUM LIKELIHOOD:\n\n")
		cat(" Formula: ", myformula1,"\n\n")
		print(summary(model)@AICtab) 
		cat("\n Fixed Effects:\n")
		print(round(summary(model)@coefs, digits=4))
		cat("\n Random Effects:")
		print(rematNew)
		
		#--- Estimates of variance components ---#
		varcomp <- summary(model)@REmat
		Ve <- as.numeric(varcomp[varcomp[,1] == "Residual", "Variance"])
		Vm_f <- as.numeric(varcomp[2,3])
		Vf <- as.numeric(varcomp[5,3])
		Vm <- as.numeric(varcomp[6,3])
		Vem_f <- as.numeric(varcomp[1,3])
		Vef <- as.numeric(varcomp[3,3])
		Vem <- as.numeric(varcomp[4,3])
		
		f <- nlevels(temp.data[,match(female, names(temp.data))])
		m <- nlevels(temp.data[,match(male, names(temp.data))])
		e <- nlevels(temp.data[,match(environment, names(temp.data))])	
		if (design == "CRD") {r <- nlevels(temp.data[,match(rep, names(temp.data))])}
		if (design == "RCB") {r <- nlevels(temp.data[,match(block, names(temp.data))]) }
		N <- NROW(temp.data)
		
		#--- Genetic Variance Components ---# 
		
		if (inbred) F<-1
		else F<-0
		
		VA <- (2/(1+F))*(Vm+Vf)
		VD <- (4/(1+F)^2)*Vm_f
		if (VD < 0) VD <- 0
		VAE <- (2/(1+F))*(Vem+Vef)
		VDE <- (4/(1+F)^2)*Vem_f
		if (VDE < 0) VDE <- 0
		VE <- Ve
		VP <- VA + VD + VAE + VDE + VE
		h2B <- (VA + VD) / VP                 # individual based
		h2N <- VA / VP                        # individual based
		Dominance.ratio <- sqrt(2*VD/VA)   
		
		Estimate <- formatC(rbind(VA, VAE,  VD, VDE, h2N, h2B, Dominance.ratio), format="f")
		with.colheader<-format(rbind("Estimate", Estimate), justify="right")
		colnames(with.colheader) <- c("")
		rownames(with.colheader) <- c("", " VA", " VAxE", " VD", " VDxE", " h2-narrow sense", " H2-broad sense", " Dominance Ratio")
		TABLE <- as.table(with.colheader)
		cat("\n\nESTIMATES OF GENETIC VARIANCE COMPONENTS:")
		print(TABLE)
		result[[i]]$genvar.components <- TABLE
		
		#--- Estimates of heritability values ---#
		#--- Family Selection ---#
		
		H2fm <- Vm/(Vm + Vm_f/f + Vem_f/(f*e) +  Ve/(r*e*f))
		H2ff <- Vf/(Vf + Vm_f/m + Vem_f/(m*e) +  Ve/(r*e*m))
		H2ffs <- (f*Vm + m*Vf + Vm_f)/(f*Vm + m*Vf + Vm_f + f*Vem/e + m*Vef/e + Ve/(r*e))
		
		#--- For individual selection ---#
		
		h2m <- (4/(1+F))*Vm/(Vm + Vm_f + Vem  + Vem_f + Ve)
		H2m <- ((4/(1+F))*Vm + (4/(1+F)^2)*Vm_f)/(Vm + Vm_f + Vem  + Vem_f + Ve)
		
		h2f <- (4/(1+F))*Vf/(Vf + Vm_f + Vef  + Vem_f + Ve)
		H2f <- ((4/(1+F))*Vf + (4/(1+F)^2)*Vm_f)/(Vf + Vm_f + Vef  + Vem_f + Ve)
		
		h2fs <- (2/(1+F))*(Vm+Vf)/(Vm + Vf + Vm_f + Vem + Vef  + Vem_f + Ve)
		H2fs <- ((2/(1+F))*(Vm+Vf) + (4/(1+F)^2)*Vm_f)/(Vm + Vf + Vm_f + Vem + Vef  + Vem_f + Ve)
		
		rowMale2<-paste("",male)
		rowFemale2<-paste("",female)
		family <- round(rbind(H2fm, H2ff, H2ffs), digits=2)
		narrowsense <- round(rbind(h2m, h2f, h2fs), digits=2)
		broadsense <- round(rbind(H2m, H2f, H2fs), digits=2)
		
		TABLE2 <- as.table(cbind(family, narrowsense, broadsense))
		colnames(TABLE2) <- c("Family Selection", "Narrow Sense", "Broad sense")
		rownames(TABLE2) <- c(rowMale2, rowFemale2, " Full-sib")
		TABLE2_final <- as.table(TABLE2)
		result[[i]]$heritability <- TABLE2_final
		cat("\n\nESTIMATES OF HERITABILITY:\n")
		print(TABLE2_final) 
		cat("\n")
		cat("\n==============================================================\n")
	}## end of loop (i)
	detach("package:lme4")
	return(list(output = result))
}

