# nontrivalCPU

 1. Uncache的 lb 指令的Arsize未修改      -> 已修复
 2. 旁路 HILO移到EXE级 CP0移到MEM级      -> 已修复
 3. 重构CP0 & 中断的bug修复              -> 已修复
 4. 乘法的bug                             -> 已修复

## TODO:

+  1. CP0中TLB例外

+  2. 重写cache

+  3. 阅读相关PMON资料，准备添加指令，并启动操作系统

+  4. 现在时钟中断未经过测试，可能存在bug



## Caution

+ 系统测试中，为了跑监控程序**必须将cache打开**，否则串口中断的接受存在一定的时序问题（初步估计是线程切换的时间大于两次串口中断的时间）
+ 系统测试中，为了正确运行G指令，由A指令输入的数据 **必须存放在A0000000 - C0000000 段下** ，否则A命令写入的数据会 **优先存在Dcache中**Icache取指令的时候就存在一定的问题。（这与清华监控程序的文档存在偏差，暂时不清楚应该如何处理）
