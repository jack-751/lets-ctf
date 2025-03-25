# 预备知识与工具安装

## 预备知识
为了顺利完成本课程，你需要具备以下基础知识：
- **Move 语言基础**：
  - 熟悉变量声明、基本数据类型（u8、u64、address 等）和控制流（if、while）。
  - 理解模块（module）和资源（struct）的概念。
  - 能够编写和运行简单的 Move 程序（如 Hello World）。
  - 推荐资源：[HOH社区Move共学](https://github.com/move-cn/letsmove) 或 [Sui Move Book](https://move.sui-book.com/index.html)。
- **区块链基础**：
  - 了解智能合约的基本概念（如存储、交易）。
  - 对 Sui 区块链平台有初步认识。
- **CTF 基础**（可选）：
  - 知道 CTF 比赛的基本形式将有助于更快上手。

如果以上知识点有欠缺，建议先完成基础学习再加入课程。本课程将直接聚焦 Move 在 CTF 中的应用，跳过语言基础教学。

## 工具安装
以下是你需要安装的工具，确保在第一节课前配置好开发环境：
1. **Sui CLI**：
   - 用于编译、运行和调试 Move 代码。
   - 安装步骤：
     - Sui：参考 [Sui CLI 安装指南](https://docs.sui.io/build/cli-client)。
   - 验证：运行 `sui -V` 检查安装成功。
   
2. **VS Code + Move 插件**：
   - 提供代码高亮和语法检查。
   
   - 安装步骤：
     1. 下载 [VS Code](https://code.visualstudio.com/)。
     2. 在扩展市场搜索 `Move` 或 `Sui Move`，安装相关插件。
     
     ![image-20250325171039560](./prerequisites.assets/image-20250325171129301.png)
     
     `Move` 和 `Move syntax` 插件为提供代码高亮和语法检查，`Move Formatter Developer Preview`插件提供代码格式化。
     
     

### 环境验证
- 运行以下命令测试环境：
  ```bash
  sui move new <path-to-move-project> && cd <path-to-move-project> && sui move build
  ```
- 如果编译成功，说明环境配置正确。 

准备好这些工具后，你就可以无缝进入课程实践环节。遇到安装问题？请提前联系课程团队或查阅相关文档。

