#!/usr/bin/env Rscript
library(ggplot2)
library(optparse)
library(scales)

option_list = list(
  make_option(c("--width"), type="integer", default=1, 
              help="width scale factor [default= %default]", metavar="integer"),
	make_option(c("--height"), type="integer", default=500, 
              help="max ping [default= %default]", metavar="integer")
); 
 
opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);


data <- read.csv("../../Ruby/CLI apps/InternetUptime/ping.csv", header=TRUE, colClasses=c("timestamp"="integer", "ping"="numeric"))
# data <- data[ order(data$timestamp), ]

sampleCount <- length(data[[1]])
targetSamples <- 1250*opt$width
skip <- sampleCount/targetSamples

collapse_ <- function(x, func) {
	return(tapply(x, rep(1:ceiling(length(x)/skip), each = skip, length.out = length(x)), func))
}
avg <- function(x) {
	return(collapse_(x, mean))
}
any <- function(x, yes, no) {
	return(collapse_(x, function(z) if(TRUE %in% z) yes else no))
}


unixDate <- function(x) as.POSIXct(x/1000, origin="1970-01-01", tz = 'GMT')



times <- avg(data[[1]]) #apply(avg(data[[1]]), 1, unixDate)
pings <- avg(data[[2]])
drops <- collapse_(data[[2]], function(x) {
	return(sum(x < 0) / length(x))
})

timeorder <- order(times)
times <- times[timeorder]
pings <- pings[timeorder]
drops <- drops[timeorder]

groups <- cumsum(c(TRUE, diff(times) > skip*2))

timesplit <- split(times, groups)
pingsplit <- split(pings, groups)
dropsplit <- split(drops, groups)

for(i in 1:max(groups)) {
	time_ <- timesplit[[i]]
	timesplit[[i]] <- c(min(time_)-1, time_, max(time_)+1)
	
	pingsplit[[i]] <- c(0, pingsplit[[i]], 0)
	dropsplit[[i]] <- c(0, dropsplit[[i]], 0)
}

times <- unlist(timesplit)
pings <- unlist(pingsplit)
drops <- unlist(dropsplit)

pings[pings > opt$height] <- opt$height
pings[pings < 0] <- 0

# quartz()

# plot(x=c(0),
#       y=c(0),
#       xlim=c(min(times), max(times)),
#       ylim=c(min(pings), max(pings))
# )


graph <- data.frame(time=times,ping=pings,drop=drops*-(opt$height/2))

graph$time <- as.POSIXct(graph$time, origin="1970-01-01", tz="GMT")

g <- ggplot(graph, aes(x=time)) +
	ylim(-opt$height/2,opt$height) +
	geom_area(aes(y=ping, fill=I("blue"))) +
	geom_area(aes(y=drop, fill=I("red"))) +
	scale_x_datetime(breaks = date_breaks("days"), minor_breaks = date_breaks("2 hour"), labels = date_format("%m/%d"))
 # 	scale_y_continuous(labels = function(x) {
 # 		return(sapply(x, function(z) {
 # 			if(z > 0)
 # 				return(z)
 # 			return(c((-z / opt$height)*100, "%"))
 # 		}))
 # 	})

ggsave("Rplots.pdf", plot=g, height=4, width=8*opt$width, units="in", limitsize=FALSE)

#' Create the two plots.
# plot1 <-
#   ggplot(graph) +
#   geom_area(aes(x = time, y = ping)) +
#   ylab("Ping") +
#   theme_minimal() +
#   theme(axis.title.x = element_blank())

# plot2 <- graph %>%
#   select(time, drop) %>%
#   na.omit() %>%
#   ggplot() +
#   geom_area(aes(x = time, y = drop)) +
#   ylab("Drops") +
#   theme_minimal() +
#   theme(axis.title.x = element_blank())
#
# grid.newpage()
# grid.draw(rbind(ggplotGrob(plot1), ggplotGrob(plot2), size = "last"))

# g <- ggplot(graph, aes(x=time,y=ping))
# g + geom_area()
# # palette <- colorRampPalette(c('blue','red'))
#
# # par(col="blue")
# for(i in 1:max(groups)) {
# 	time_ <- timesplit[[i]]
# 	ping_ <- pingsplit[[i]]
#
# 	# colors <- palette(500)[as.numeric(cut(ping_,breaks = 500))]
#
# 	# lines(time_, ping_, col=colors)
# }
#
# # groups <- collapse(groups, function(x) sort(table(x),decreasing=TRUE)[1])
#
#
# # plot(times, pings, type="l", col="black")
# # plot.new()
#
#
#
# # par(col="black")
# # lines(times, pings)
# # axis.POSIXct(1, at = seq(unixDate(min(times)), unixDate(max(times)), "days"))
#
#
#
# # par(col="blue")
# # for(i in 1:(index-1)) {
# # 	lines(times[groups == i], pings[groups == i])
# # }
# #
# # par(col="red")
# # for(i in 1:(index-1)) {
# # 	lines(times[groups == i], downs[groups == i])
# # }
#
# Sys.sleep(1000)