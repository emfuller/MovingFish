library(fields)
library(lattice)
library(colorspace)
library(RCurl)
source("biomass_synergy.R")
source("critical_parameters.R")
source("load_data.R")
require(stringr)
require(colorspace)
require(reshape2)
require(gridExtra)
require(ggplot2)
require(ggthemes)

data <- where_load(load_it="local")

sim <- data[[1]]
mpas <- data[[2]]
mpas2 <- data[[3]]
thresh <- data[[4]]
ebm <- data[[7]]

###################################### Figure 1
	analytical_ebm=ebm
	cvals=matrix(seq(0,1,by=0.01),nrow=1)

	nr=3
	ns=2
	rvals=c(rep(3,ns),rep(5,ns),rep(10,ns))
	rcols=c(rep('black',ns),rep('red',ns),rep('blue',ns))
	xvals=c(.1,.5)
	sigvals=rep(pi/2*xvals^2,nr)
	sigltys=rep(c(1,2),nr)
	l=length(rvals)

# save data as list
	h = vector("list",length=l)

	for(i in 1:l){
		r=rvals[i]
		sig2=sigvals[i]
		h[[i]]=apply(cvals,2,hstar_g,r=r,sig2=sig2)
	}
	
	melted_h <- melt(h)
	names(melted_h) <- c("h", "Param_combo")
	melted_h$speed <- rep(cvals, 6)
	melted_h$R <- rep(rvals, each = 101)
	melted_h$d <- round(rep(xvals, each =101),digits=2)

	plot1 <- ggplot(melted_h, aes(x=speed, y = h, group=Param_combo)) + 
		geom_line(aes(color=factor(R), linetype=factor(d)),size=1) + 
		theme_tufte() + 
		scale_color_manual(values=c("grey", "dark grey", "black")) + 
		theme(text=element_text(family="Helvetica", size=10), plot.margin=unit(c(0,0,0,0),"cm")) + 
		xlab("Climate velocity") + ylab("Harvesting rate") + 
		theme(axis.line = element_line(colour = 'black')) +
		scale_x_continuous(expand = c(0, 0)) + scale_y_continuous(expand = c(0, 0))+
		 expand_limits(y = c(0,1), x=c(0,1)) +
		labs(linetype=expression(symbol("\341")*d*symbol("\361")), color=expression("R"[0]), title="")
	
# png("Fig1.png",height=3,width=4,units="in",res=300)
	# print(plot1)
	# dev.off() 
	pdf(file="Fig1.pdf",width=2.9,height=2)
print(plot1)
dev.off()
	
################################################################## FIGURE 2

#### A
	melted_ebm <- melt(ebm)
	speeds <- rep(seq(0,1, 0.01), 100)
	harvests <- rep(seq(0.01,1,0.01), each = 101)
	melted_ebm$speed = speeds
	melted_ebm$harvest = harvests

	plot2a <- ggplot(melted_ebm, aes(x=speed, y = harvest, fill=value)) + 
		geom_tile() + theme_tufte() + 
		scale_fill_gradient(low="black", high="white") + 
		theme(text=element_text(family="Helvetica", size=10), plot.margin=unit(c(0,0,0,0),"cm"),plot.title=element_text(size=10)) + 
		scale_x_continuous(expand = c(0, 0)) + scale_y_continuous(expand = c(0, 0))+
		guides(fill = guide_colorbar(barwidth=1, barheight=10, title.position="top", title="Equilibrium\nbiomass")) + 
		xlab("") + 
		ylab("Harvesting rate") + 
		labs(title="A")

#### B

# making data
	ebm=analytical_ebm
	cvals=as.numeric(str_sub(row.names(ebm),start=3))
	hvals=as.numeric(str_sub(dimnames(ebm)[[2]],start=3))
	tol=.00001
	ebm=as.matrix(ebm,nrow=length(hvals))
	syn=synergy(ebm,2)
	syn=round(syn,3)
	syn[is.na(syn)]=0
	syn[syn<0]=-.03
	
# reshaping data for ggplot
	melt_syn <- melt(syn)
	names(melt_syn) <- c("Speed","Harvest","Synergy")
	speeds <- rep(seq(0.01,1, 0.01), 99)
	harvests <- rep(seq(0.02,1,0.01), each = 100)
	
	melt_syn$Speed = speeds
	melt_syn$Harvest = harvests
	
  # change any negative values to 0, due to numerical rounding error - EB
  melt_syn$Synergy[which(melt_syn$Synergy<0)] = 0

plot2b <- ggplot(melt_syn, aes(x=Speed, y = Harvest, fill=Synergy)) + 
	geom_tile() + 
	theme_tufte() + 
	scale_fill_gradient(low="black", high="white") + 
	theme(text=element_text(family="Helvetica", size=10), plot.margin=unit(c(0,0,0,0),"cm")) + 
	scale_x_continuous(expand = c(0, 0)) + scale_y_continuous(expand = c(0, 0))+
	guides(fill = guide_colorbar(barwidth=1, barheight=10, title.position="top", title="Synergy")) + 
	xlab("") + 
	ylab("")  + 
	theme(panel.grid.major=element_blank(), panel.grid.minor=element_blank(),plot.title=element_text(size=10)) + labs(title="B")

#### Together
# png("Fig2.png",height=3, width=8,units="in",res=300)
# grid.arrange(plot2a, plot2b, ncol=2, sub = textGrob("Climate velocity", gp=gpar(fontsize=10),just="bottom"))
# dev.off() 
pdf(file="Fig2.pdf",width=6.1,height=2.6)
grid.arrange(plot2a, plot2b, ncol=2, sub=textGrob("Climate velocity",gp=gpar(fontsize=10),just='bottom'))
dev.off() 
################################################################### Figure 3
# data
	threshz = thresh
	fishmpa = mpas
	consmpa = mpas2
	consTrue = data[[5]]
	if(any(is.na(consTrue))){consTrue[is.na(consTrue)]<-0}
	fishTrue = data[[6]]

	sim$management = rep("No MPAs",nrow(sim))
	consmpa$management = rep("Few Large Reserves - Proportional Effort", nrow(consmpa))
	fishmpa$management = rep("Many Small Reserves - Proportional Effort", nrow(fishmpa))
	threshz$management = rep("Thresholds", nrow(threshz))
	threshz$ord_thresh <- threshz$thresh/max(threshz$thresh)
	consTrue$management = "Few Large Reserves- Constant Effort"
	fishTrue$managemetn = "Many Small Reserves - Constant Effort"
	
	plotA <- ggplot(sim, aes(x=speed, y = harvest, fill = Equil.pop)) + geom_raster(interpolate=TRUE) + theme_tufte() + scale_fill_gradient(low="black", high="gray95")  + labs(title="A") + xlab("") + ylab("Harvesting rate") + theme(text=element_text(family="Helvetica", size=10),axis.title=element_text(size=10),plot.title=element_text(size=10),plot.margin=unit(c(0,0,0,0),"cm"), legend.position="none") +
	scale_x_continuous(expand = c(0, 0)) + scale_y_continuous(expand = c(0, 0))


	plotB <- ggplot(threshz, aes(x=speed, y = ord_thresh, fill = Equil.pop)) + geom_raster(interpolate=TRUE) + theme_tufte() + scale_fill_gradient(low="black", high="gray95") + labs(title="B")+ xlab("") + ylab("Harvest threshold")+ theme(text=element_text(family="Helvetica", size=10), axis.title=element_text(size=10),axis.title=element_text(size=10),plot.title=element_text(size=10),plot.margin=unit(c(0,0,0,0),"cm"),legend.position="none") + scale_y_reverse(expand = c(0, 0))+
	scale_x_continuous(expand = c(0, 0)) 


	
	plotC <-ggplot(fishmpa, aes(x=speed, y = harvest, fill = Equil.pop)) + 
		geom_raster(interpolate=TRUE) + theme_tufte() + 
		scale_fill_gradient(low="black", high="gray95")  + 
		labs(title="C") + xlab("") + ylab("Harvesting rate") + 
		theme(text=element_text(family="Helvetica", size=10), axis.title=element_text(size=10),plot.title=element_text(size=10),plot.margin=unit(c(.0,0,0,0),"cm"),legend.position="none") +
		scale_x_continuous(expand = c(0, 0)) + scale_y_continuous(expand = c(0, 0))


	
	plotD <- ggplot(consmpa, aes(x=speed, y = harvest, fill = Equil.pop)) + 
		geom_raster(interpolate=TRUE) + theme_tufte() + 
		scale_fill_gradient(low="black", high="gray95") + 
		labs(title="D")+ xlab("") + ylab("Harvesting rate") + 
		theme(text=element_text(family="Helvetica", size=10), axis.title=element_text(size=10),plot.title=element_text(size=10),plot.margin=unit(c(.0,0,0,0), "cm"), legend.position="none")+
		scale_x_continuous(expand = c(0, 0)) + scale_y_continuous(expand = c(0, 0))
			
	plotE <- ggplot(fishTrue, aes(x=speed, y = harvest, fill=Equil.pop)) + 
		geom_raster(interploate=TRUE) + theme_tufte() +
		scale_fill_gradient(low="black",high="gray95") + 
		labs(title="E") + xlab("") + ylab("Harvesting rate") + 
		theme(text=element_text(family="Helvetica", size=10), axis.title=element_text(size=10),plot.title=element_text(size=10),plot.margin=unit(c(.0,0,0,0), "cm"), legend.position="none")+
		scale_x_continuous(expand = c(0, 0)) + scale_y_continuous(expand = c(0, 0))
	
	plotF <- ggplot(consTrue, aes(x=speed, y = harvest, fill=Equil.pop)) + 
		geom_raster(interploate=TRUE) + theme_tufte() +
		scale_fill_gradient(low="black",high="gray95") + 
		labs(title="F") + xlab("") + ylab("Harvesting rate") + 
		theme(text=element_text(family="Helvetica", size=10),axis.title=element_text(size=10),plot.title=element_text(size=10), plot.margin=unit(c(.0,0,0,0), "cm")) + 
		scale_x_continuous(expand = c(0, 0)) + scale_y_continuous(expand = c(0, 0))+
		guides(fill = guide_colorbar(barwidth = 1, barheight = 18, title.position="top", title="Equilibrium\nbiomass"))

	
# grabbing the legend from the last plot

library(gridExtra)
g_legend<-function(a.gplot){
tmp <- ggplot_gtable(ggplot_build(a.gplot))
leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box")
legend <- tmp$grobs[[leg]]
return(legend)}

legend <- g_legend(plotF)
lwidth <- sum(legend$width)

# png(file="fig3.png",width=8,height=8,res=300,units="in")
pdf(file="Fig3.pdf",width=6.1,height=6.8)
		grid.arrange(arrangeGrob(plotA, plotB , plotC,plotD,plotE, plotF + theme(legend.position="none")), legend, sub=textGrob("Climate velocity\n",gp=gpar(fontsize=10)), widths=unit.c(unit(1, "npc") - lwidth,lwidth),ncol=2)
		dev.off()


############## Appendix

source("append_data.R")

## plot rockfish simulations ----
library(fields)
library(ggplot2)
library(ggthemes)
setwd("/Users/efuller/Documents/Projects/Moving_fish/MovingFish/Simluations/Aspatial_fast/rockfish_sim/Data/")
noThresh <- read.csv('MPAnull_NA_2015-02-09.csv')
rockMPA_eff <- read.csv('MPArock_yes_2015-02-09.csv')
rockMPA_na <- read.csv('MPArock_NA_2015-02-09.csv')
thresh_noMPA <- read.csv('Thresh_2015-02-09.csv')

# change speeds units
L=1000;
gen_time=7;
noThresh$speed <- noThresh$speed * L/gen_time*10
rockMPA_eff$speed <- rockMPA_eff$speed * L/gen_time*10
rockMPA_na$speed <- rockMPA_na$speed * L/gen_time*10
thresh_noMPA$speed <- thresh_noMPA$speed * L/gen_time*10


plotA <- ggplot(noThresh, aes(x=speed, y = harvest, fill = Equil.pop)) + geom_raster(interpolate=TRUE) + theme_tufte() + scale_fill_gradient(low="black", high="gray95")  + labs(title="A") + xlab("") + ylab("Harvesting rate") + theme(text=element_text(family="Helvetica", size=10),axis.title=element_text(size=10),plot.title=element_text(size=10), plot.margin=unit(c(0,0,0,0),"cm"), legend.position="none") +
	scale_x_continuous(expand = c(0, 0)) + scale_y_continuous(expand = c(0, 0))


thresh_noMPA$ord_thresh <- thresh_noMPA$thresh/max(thresh_noMPA$thresh)


plotB <- ggplot(thresh_noMPA, aes(x=speed, y = ord_thresh, fill = Equil.pop)) + geom_raster(interpolate=TRUE) + theme_tufte() + scale_fill_gradient(low="black", high="gray95") + labs(title="B")+ xlab("") + ylab("Harvest threshold")+ theme(text=element_text(family="Helvetica", size=10),axis.title=element_text(size=10),plot.title=element_text(size=10), plot.margin=unit(c(0,0,0,0),"cm"), legend.position="none") +
	scale_x_continuous(expand = c(0, 0)) + scale_y_reverse(expand=c(0,0))

plotC <-ggplot(rockMPA_na, aes(x=speed, y = harvest, fill = Equil.pop)) + 
  geom_raster(interpolate=TRUE) + theme_tufte() + 
  scale_fill_gradient(low="black", high="gray95")  + 
  labs(title="C") + xlab("") + ylab("Harvesting rate") + theme(text=element_text(family="Helvetica", size=10),axis.title=element_text(size=10),plot.title=element_text(size=10), plot.margin=unit(c(0,0,0,0),"cm"), legend.position="none") +
	scale_x_continuous(expand = c(0, 0))+scale_y_continuous(expand=c(0,0))

rockMPA_eff$Equil.pop[which(is.na(rockMPA_eff$Equil.pop))] <- 0

plotD <- ggplot(rockMPA_eff, aes(x=speed, y = harvest, fill = Equil.pop)) + 
  geom_raster(interpolate=TRUE) + theme_tufte() + 
  scale_fill_gradient(low="black", high="gray95") + 
  labs(title="D")+ xlab("") + ylab("Harvesting rate") + 
  theme(legend.position="right", text=element_text(family="Helvetica", size = 10),axis.title=element_text(size=10),plot.title=element_text(size=10),plot.margin=unit(c(.0,0,0,0),"cm")) + 
  guides(fill = guide_colorbar(barwidth = 1, barheight = 18, title.position="top", title="Equilibrium\nBiomass"))+scale_x_continuous(expand = c(0, 0))+scale_y_continuous(expand=c(0,0))


# grabbing the legend from the last plot

library(gridExtra)
g_legend<-function(a.gplot){
  tmp <- ggplot_gtable(ggplot_build(a.gplot))
  leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box")
  legend <- tmp$grobs[[leg]]
  return(legend)}

legend <- g_legend(plotD)
lwidth <- sum(legend$width)

pdf(file="FigA4.pdf",width=8,height=6)
grid.arrange(arrangeGrob(plotA, plotB , plotC,plotD + theme(legend.position="none")), legend,  sub=textGrob("Climate velocity (km/decade)\n",gp=gpar(fontsize=10)), widths=unit.c(unit(1, "npc") - lwidth,lwidth),ncol=2)
dev.off()
