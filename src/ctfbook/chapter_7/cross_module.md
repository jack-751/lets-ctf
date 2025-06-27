### 跨合约安全与溢出漏洞

#### 1. 课程概述
欢迎来到第 7 章！本章将深入探讨区块链智能合约中的“跨合约安全”问题，重点关注多个合约之间的交互如何引入漏洞。我们设计了一个投票系统（`vote::vote`）、一个数学工具模块（`math::math_utils`）和一个标志存储库（`vote::flag_vault`），并提供了一个求解脚本（`solve_chapter_7::solve_chapter_7`）作为参考。你的目标是通过累积 `VOTE` 代币、利用溢出漏洞触发权限，并获取隐藏的 `FLAG{CTF{Letsctf_chapter_7}}`。

#### 2. 系统架构
- **投票系统 (`vote::vote`)**：
  - 初始化时创建 `VotingSystem`、`Votecap` 和 `Mintlist`，分配 10,000 `VOTE` 作为初始余额。
  - `mint` 函数允许每个地址首次铸造 100 `VOTE`，限制重复铸造。
  - `vote` 函数累积用户的投票金额（`vote_list`），通过 `math_utils::calculate_weight` 计算权重，权重超过 1,000,000 时授权。
  - `withdraw` 函数允许提取累积的 `VOTE`。

- **数学工具 (`math::math_utils`)**：
  - `calculate_weight` 函数检查输入是否超过 `mask = 0xff << 1` ，若超过返回 `999999999`，否则返回输入值。

- **标志存储库 (`vote::flag_vault`)**：
  - `get_flag` 函数检查 `VotingSystem` 的 `is_authorized` 状态，授权后触发 `FlagEvent`。


#### 3. 漏洞与挑战
本章设计了跨合约安全漏洞，供你探索和利用：
- **有限铸造限制**：`mint` 限制每个地址一次 100 `VOTE`，但通过 `withdraw` 和重复投票可累积。
- **溢出漏洞**：`math_utils::calculate_weight` 的阈值 `510` 未有效限制大输入，累积 `amount > 510` 可返回 `999999999 > 1000000`，触发授权。
- **跨合约信任**：`vote` 依赖 `math_utils` 的计算，但未验证权重合理性，导致权限误判。
- **目标**：累积足够 `VOTE`（至少 800），触发溢出，获取 `FLAG{CTF{Letsctf_chapter_7}}`。

#### 4. 学习目标
- 理解跨合约交互中的信任边界问题。
- 掌握溢出漏洞的检测和利用技术。
- 学习状态操纵（`withdraw` 和重复投票）绕过限制。
- 实践 CTF 挑战，分析和修复智能合约漏洞。

#### 5. 实践指南
1. **初始化**：
   - 调用 `vote::vote::mint` 获取 100 `VOTE`。
   - 注意：`mint` 仅对新地址生效。

2. **累积代币**：
   - 使用 `vote::vote::vote` 将 100 `VOTE` 加入 `vote_list`。
   - 调用 `vote::vote::withdraw` 提取当前 `vote_list` 值（100）。
   - 重复 `vote` 和 `withdraw`，每次金额翻倍（200, 400, 800...）。
   - 目标：累积 `amount > 510`。

3. **触发漏洞**：
   - 当 `total_amount > 510`，`math_utils::calculate_weight` 返回 `999999999 > 1000000`，设置 `is_authorized = true`。
   - 参考 `solve_chapter_7::solve_chapter_7` 实现：
     - `mint` 获取 100 `VOTE`。
     - `vote` 第一次，`vote_list = 100`。
     - `withdraw` 提取 100，`vote` 第二次，`vote_list = 200`。
     - `withdraw` 提取 200，`vote` 第三次，`vote_list = 400`。
     - `withdraw` 提取 400，`vote` 第四次，`vote_list = 800 > 510`。

4. **获取 FLAG**：
   - 调用 `vote::flag_vault::get_flag`，捕获 `FlagEvent`。