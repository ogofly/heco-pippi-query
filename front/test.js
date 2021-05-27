const lib = require("./pippi-lib");
// 皮皮虾交易对白名单，官方说有部分交易对无效，以下是目前（2021-05-27）有效的。
const PIPPI_PAIR_PIDS = [
  1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22,
  23, 24, 25, 27, 29, 31, 32, 33, 34, 35,
];

// test
lib.getApys(PIPPI_PAIR_PIDS).then((apys) => console.log(apys));
