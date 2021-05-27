const Web3 = require("web3");
const PippiQueryAbi = require("./pipi_query_abi.json");

const PIPPI_QUERY_ADDR = "0x320386A358eB1e7585A081404d4D6A0210e98B2F";

const HttpProvider = Web3.providers.HttpProvider;

const rpcHost = "https://http-mainnet-node.huobichain.com";
const provider = new HttpProvider(rpcHost, {
  keepAlive: true,
  withCredentials: false,
  timeout: 20000, // ms
  headers: [
    {
      name: "Access-Control-Allow-Origin",
      value: "*",
    },
  ],
});

const web3 = new Web3(provider);
const queryContract = new web3.eth.Contract(PippiQueryAbi, PIPPI_QUERY_ADDR);

async function getApys(pids) {
  let apys = await queryContract.methods.getPairsApy(0, 0).call();
  apys = apys
    .filter((item) => pids.includes(+item.pid))
    .map((item) => ({
      pid: item.pid,
      lpToken: item.lpToken,
      token0: item.token0,
      token1: item.token1,
      symbol0: item.symbol0,
      symbol1: item.symbol1,
      apy: +item.apy / 100,
      isError: !!item.error,
    }));
  return apys;
}

module.exports = { getApys };
