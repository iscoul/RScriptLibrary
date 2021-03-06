# --------------------------------------------------------
# ARGUMENTS:
# data - a dataframe
# respvar - a string; variable name of the response variable
# env - a string; variable name of the environment variable
# result - output of single environment analysis
# box - logical; indicates if boxplot(s) is(are) to be created
# hist - logical; indicates if histogram(s) is(are) to be created
# --------------------------------------------------------


graph.sea.predint <- function(data, respvar, env, geno, result) {

  dir.create("plots")
  
  # Prediction intervals of Genotype means #added 090411
  for (i in (1:length(respvar))) {
	  for (j in (1:nlevels(data[,match(env, names(data))]))) {
      filename = paste(getwd(), "/plots/predIntSea_",respvar[i],"_",result$output[[i]]$site[[j]]$env,".png",sep="");
		  png(filename); #par(mfrow = n2mfrow(length(respvar)*nlevels(result[[i]]$site[[j]]$data[,match(env, names(result[[i]]$site[[j]]$data))]))); 
		  if (length(levels(result$output[[i]]$site[[j]]$data[,match(geno, names(result$output[[i]]$site[[j]]$data))])) <= 50) {
			  print(dotplot(ranef(result$output[[i]]$site[[j]]$model1, postVar=TRUE))[[1]]) } else { (qqmath(ranef(result$output[[i]]$site[[j]]$model1, postVar=TRUE))[1]) }; #,xlab=xlabel
		  dev.off();
	  }
  }
  
}
