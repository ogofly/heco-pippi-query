import { Contract, ethers, BigNumber } from "ethers";
import { deployContract, MockProvider, solidity } from "ethereum-waffle";
import { should, use } from "chai";

import TokenAbi from "../build/BasicTokenExample.json";
import { BigNumber as BN } from "bignumber.js";

use(solidity);
should();

describe("BasicTokenExample", () => {
  let provider = new MockProvider({ ganacheOptions: { gasLimit: 10000000 } });
  const [wallet1, walletDeveloper] = provider.getWallets();

  console.log("Wallet inited.");

  let tokenContract: Contract;

  async function getBlockNumber() {
    const blockNumber = await provider.getBlockNumber();
    console.log("Current block number: " + blockNumber);
    return blockNumber;
  }

  async function mineBlock(
    provider: MockProvider,
    time: number
  ): Promise<void> {
    for (let i = 0; i < time; i++) {
      await provider.send("evm_mine", []);
    }
  }

  function bn2Normal(bnAmount: BigNumber, decimal: number = 18) {
    return parseFloat(
      new BN(bnAmount.toString())
        .dividedBy(new BN(Math.pow(10, decimal)))
        .toFixed()
    );
  }

  async function deployToken() {
    console.log("Token contract deploying");
    tokenContract = await deployContract(walletDeveloper, TokenAbi, [
      ethers.utils.parseEther("100"),
    ]);
    console.log("Token contract deployed");
  }

  before(async () => {
    await deployToken();
  });

  it("BasicToken", async () => {
    const getBalance = async () =>
      bn2Normal(await tokenContract.balanceOf(walletDeveloper.address));

    let blockNumber = await getBlockNumber();
    blockNumber.should.equal(1);
    mineBlock(provider, 3);

    const balance = await getBalance();
    console.log(`balance ${balance}`);
    balance.should.equal(100);

    blockNumber = await getBlockNumber();
    blockNumber.should.equal(3 + 1);
  });
});
