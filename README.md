# heco-pippi-query

[皮皮虾](https://app.pippi.finance/farms)是运行在火币 Heco 链上的去中心化交易所。
查询合约 `PippiQuery.sol`，主要用于查询该交易所下各交易对的年化收益率（APY）。

## 为什么要写一个查询合约

官方是在前端多次查询遍历 MasterChef 合约然后再计算的。
有以下缺点：

- 查询效率低，延时大
- 不如通过合约查询来得直接和易理解

另外通过编写查询合约，可进一步理解对方的合约，甚至发现其中的问题。


## 前端 lib 和测试

见目录 `front`。
运行 ：
```js
node front/test.js
```

## 合约部署

```bash
yarn flatten
```

复制 flatten/PippiQuery.sol 到 [remix](https://remix.ethereum.org/) 部署


