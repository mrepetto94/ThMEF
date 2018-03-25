library("ggplot2")

load("data_tradeoff.Rda")

ggplot(df, aes(x=x, y=y)) + 
  geom_point(aes(size=obj, alpha = greenratio)) +
  scale_alpha_continuous(name="Green ratio") +
  scale_size_continuous(name="Objective") +
  scale_fill_grey()

ggsave("tradeoff.png")
