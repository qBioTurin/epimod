
library(ggplot2)

reference <- as.data.frame(read.csv("../Input/reference_data.csv",
                                      header = FALSE,
                                      sep = ""))
traces <-read.csv("../results_model_analysis/SIR_analysis-1.trace",sep = "")

plI<-ggplot( )+
  geom_line(data=traces,
            aes(x=Time/7,y=I))+
  geom_line(data=reference,
            aes(x=V1/7,y=V3),
            col="red",linetype="dashed")+
  theme(axis.text=element_text(size=18),
        axis.title=element_text(size=20,face="bold"),
        legend.text=element_text(size=18),
        legend.title=element_text(size=20,face="bold"),
        legend.position="right",
        legend.key.size = unit(1.3, "cm"),
        legend.key.width = unit(1.3,"cm") )+
  labs(x="Weeks", y="I",col="Distance")

ggsave("../plI_analysis.pdf")

plS<-ggplot( )+
  geom_line(data=traces,
            aes(x=Time/7,y=S))+
  geom_line(data=reference,
            aes(x=V1/7,y=V2),
            col="red",linetype="dashed")+
  theme(axis.text=element_text(size=18),
        axis.title=element_text(size=20,face="bold"),
        legend.text=element_text(size=18),
        legend.title=element_text(size=20,face="bold"),
        legend.position="right",
        legend.key.size = unit(1.3, "cm"),
        legend.key.width = unit(1.3,"cm") )+
  labs(x="Weeks", y="S",col="Distance")

ggsave("../plS_analysis.pdf")

plR<-ggplot( )+
  geom_line(data=traces,
            aes(x=Time/7,y=R))+
  geom_line(data=reference,
            aes(x=V1/7,y=V4),
            col="red",linetype="dashed")+
  theme(axis.text=element_text(size=18),
        axis.title=element_text(size=20,face="bold"),
        legend.text=element_text(size=18),
        legend.title=element_text(size=20,face="bold"),
        legend.position="right",
        legend.key.size = unit(1.3, "cm"),
        legend.key.width = unit(1.3,"cm") )+
  labs(x="Weeks", y="R",col="Distance")

ggsave("../plR_analysis.pdf")
