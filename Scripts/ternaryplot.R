library("ggtern")

central <- seq(0, 1, length.out=7) 		
sides <- (1 - central)/2 

w1 <- c(central,sides,sides)
w2 <- c(sides,central,sides)
w3 <- c(sides,sides,central)

obj <-c(67082550,
        67082550,
        67084290,
	67084290,
	67108120,
	91388310,
	95658150,
	67082550,
        67082550,
	67084290,
	67082550,
	69516930,
	151413800,
	162554400,
	92543760,
	67084290,
	67084290,
	67082550,
	67082550,
	67082550,
	67082550)


df  <- data.frame(w1,w2,w3, obj)
ggtern( data = df, aes(x=w1,y=w2,z=w3, size=obj)) + 
	geom_point() +
	scale_size_continuous(name="Objective") +
	theme_showarrows()
ggsave(filename = "ternary.png")
