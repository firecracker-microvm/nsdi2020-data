library(ggthemes)
library(ggplot2)
library(reshape2)

# Firecracker vs. QEMU, serial boots
d <- read.table("boot-times-serial.csv", header=TRUE, sep=",")
gg2 <- ggplot(d, aes(bootsecs*1000, color=vmm)) + stat_ecdf(geom="step") + ylab("CDF") + xlab("Boot Time (ms)") + theme_tufte() + theme(legend.position="bottom") + xlim(0,300);
ggsave("boot-times-serial.pdf", width=3, height=2);


