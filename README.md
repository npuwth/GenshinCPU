# nontrivalCPU

 1. Uncache的 lb 指令的Arsize未修改      -> 已修复
 2. 旁路 HILO移到EXE级 CP0移到MEM级      -> 已修复
 3. 重构CP0 & 中断的bug修复              -> 已修复
 4. 乘法的bug                            -> 已修复

+ TODO:
    +  1. CP0中TLB例外

    +  2. 重写cache

    +  3. 阅读相关PMON资料，准备添加指令，并启动操作系统

    +  4. 现在时钟中断未经过测试，可能存在bug
