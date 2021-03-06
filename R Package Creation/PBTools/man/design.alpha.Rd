\name{design.alpha}
\alias{design.alpha}
%- design.alpha.
\title{ Alpha design type (0,1) }
\description{
  Creates alpha designs starting from the alpha design fixing under
  the 4 series formulated by Patterson and Williams.
  }
\usage{
design.alpha(trt, k, r, number = 1, seed = 0, kinds = "Super-Duper")
}
\arguments{
  \item{trt}{ Treatments}
  \item{k}{ size block }
  \item{r}{ Replications }
  \item{number}{ number of first plot }
  \item{seed}{ seed }
  \item{kinds}{ method for to randomize }
}
\details{

Series:
I. 	r=2, k <= s;
II.	r=3, s odd, k <= s;
III.r=3, s even, k <= s-1;
IV.	r=4, s odd but not a multiple of 3, k<=s

r= replications
s=number of blocks
k=size of block
Number of treatment is equal to k*s

}
\value{
  \item{trt }{vector, name of the treatments}
  \item{k }{Constant, numeric}
  \item{r}{ Constant, numeric }
  \item{number }{Constant, numeric}
  \item{seed }{Constant, numeric}
  \item{kinds}{ character }
}
\references{ 
 H.D. Patterson and E.R. Williams. Biometrika (1976) 
 A new class of resolvable incomplete block designs. printed in Great Britain. 
 Online: http://biomet.oxfordjournals.org/cgi/content/abstract/63/1/83 
 }
\author{ Felipe de Mendiburu of package agricolae}
\keyword{ design }
