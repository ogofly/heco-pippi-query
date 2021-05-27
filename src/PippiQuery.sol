// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;
pragma experimental ABIEncoderV2;

import "./libraries/SafeMath.sol";

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

interface PipiPair {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function token0() external view returns (address);

    function token1() external view returns (address);

    // 忽略其他接口
}

struct PipiPoolInfo {
    address lpToken; // Address of LP token contract.
    uint256 allocPoint; // How many allocation points assigned to this pool. PIPIs to distribute per block.
    uint256 lastRewardBlock; // Last block number that PIPIs distribution occurs.
    uint256 accPipiPerShare; // Accumulated PIPIs per share, times 1e12. See below.
}

struct PoolInfo {
    uint256 pid;
    address lpToken;
    uint256 allocPoint;
    uint256 lastRewardBlock;
    uint256 accPipiPerShare;
}

interface PippiMaterChef {
    function pipiPerBlock() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function poolLength() external view returns (uint256);

    function poolInfo(uint256 index)
        external
        view
        returns (PipiPoolInfo memory);
}

contract PippiQuery {
    using SafeMath for uint256;

    address public pippiMasterChefAddr =
        0xa02fF30986211B7ca571AcAE5AD4D25ab1e58426;

    address public husdHtPairAddr = 0x2129E956d7157FfbcFa65ABBAB3C66C9456dbA0d;
    address public htPipiPairAddr = 0xf9783240EcC6126727A43ff43316d932e942Fc3a;

    address public usdtTokenAddr = 0xa71EdC38d189767582C38A3145b5873052c3e47a;
    address public husdTokenAddr = 0x0298c2b32eaE4da002a15f36fdf7615BEa3DA047;
    address public htTokenAddr = 0x5545153CCFcA01fbd7Dd11C0b23ba694D9509A6F;
    address public pipiTokenAddr = 0xaAaE746b5e55D14398879312660e9fDe07FBC1DC;

    uint256 public PRICE_PRECISION = 1e4;
    uint256 public PERCENT_PRECISION = 1e4;

    struct PairInfo {
        uint256 pid;
        address lpToken;
        address token0;
        address token1;
        string symbol0;
        string symbol1;
        uint256 allocPoint;
        uint256 apy;
        string error;
    }

    struct BaseInfo {
        uint256 totalReward;
        uint256 pipiPerBlock;
        uint256 totalAllocPoint;
        uint256 htPrice;
        uint256 pipiPrice;
    }

    constructor() public {}

    function getHtPrice() public view returns (uint256 htPrice) {
        uint256 husdBal = IERC20(husdTokenAddr).balanceOf(husdHtPairAddr);
        uint256 htBal = IERC20(htTokenAddr).balanceOf(husdHtPairAddr);
        htPrice = husdBal
            .mul(PRICE_PRECISION)
            .mul(uint256(10)**IERC20(htTokenAddr).decimals())
            .div(htBal.mul(uint256(10)**IERC20(husdTokenAddr).decimals()));
    }

    function getPipiPrice() public view returns (uint256 pipiPrice) {
        uint256 htBal = IERC20(htTokenAddr).balanceOf(htPipiPairAddr);
        uint256 pipiBal = IERC20(pipiTokenAddr).balanceOf(htPipiPairAddr);
        uint256 htPrice = getHtPrice();
        pipiPrice = htPrice
            .mul(htBal)
            .mul(uint256(10)**IERC20(pipiTokenAddr).decimals())
            .div(pipiBal.mul(uint256(10)**IERC20(htTokenAddr).decimals()));
    }

    function getPools(uint256 _from, uint256 _to)
        public
        view
        returns (PoolInfo[] memory pools)
    {
        uint256 len = PippiMaterChef(pippiMasterChefAddr).poolLength();
        uint256 from = _from;
        uint256 to = _to;
        // pool info 第一个不是 Pair 而是 PIPI Token ，忽略第一个
        if (from > 0) {
            require(from > 0 && to >= from && to < len, "FROM TO INVALID");
        } else if (from == 0 && to == 0) {
            from = 1;
            to = len - 1;
        }
        pools = new PoolInfo[](to - from + 1);
        for (uint256 i = from; i <= to; i++) {
            PipiPoolInfo memory pPool =
                PippiMaterChef(pippiMasterChefAddr).poolInfo(i);
            pools[i - from] = PoolInfo(
                i,
                pPool.lpToken,
                pPool.allocPoint,
                pPool.lastRewardBlock,
                pPool.accPipiPerShare
            );
        }
    }

    function getPairsApy(uint256 from, uint256 to)
        public
        view
        returns (PairInfo[] memory pairs)
    {
        PoolInfo[] memory pools = getPools(from, to);
        pairs = new PairInfo[](pools.length);

        BaseInfo memory baseInfo =
            BaseInfo(
                0,
                PippiMaterChef(pippiMasterChefAddr).pipiPerBlock(),
                PippiMaterChef(pippiMasterChefAddr).totalAllocPoint(),
                getHtPrice(),
                getPipiPrice()
            );
        baseInfo.totalReward = baseInfo
            .pipiPrice
            .mul((60 / 3) * 60 * 24 * 365)
            .mul(baseInfo.pipiPerBlock)
            .div(1e18);
        for (uint256 i = 0; i < pools.length; i++) {
            try this.getPair(pools[i], baseInfo) returns (
                PairInfo memory pair
            ) {
                pairs[i] = pair;
            } catch Error(string memory reason) {
                pairs[i] = PairInfo(
                    pools[i].pid,
                    pools[i].lpToken,
                    address(0),
                    address(0),
                    "",
                    "",
                    pools[i].allocPoint,
                    0,
                    reason
                );
            } catch (
                bytes memory /* lowLevelData */
            ) {
                pairs[i] = PairInfo(
                    pools[i].pid,
                    pools[i].lpToken,
                    address(0),
                    address(0),
                    "",
                    "",
                    pools[i].allocPoint,
                    0,
                    "LowLevelError"
                );
            }
        }
    }

    function getPair(PoolInfo memory pool, BaseInfo memory baseInfo)
        public
        view
        returns (PairInfo memory)
    {
        PairInfo memory pair =
            PairInfo(
                pool.pid,
                pool.lpToken,
                PipiPair(pool.lpToken).token0(),
                PipiPair(pool.lpToken).token1(),
                IERC20(PipiPair(pool.lpToken).token0()).symbol(),
                IERC20(PipiPair(pool.lpToken).token1()).symbol(),
                pool.allocPoint,
                0,
                ""
            );
        address tokenAddr = pair.token0;
        uint256 tokenPrice = baseInfo.htPrice;
        if (pair.token0 == htTokenAddr) {
            // default
        } else if (pair.token1 == htTokenAddr) {
            tokenAddr = pair.token1;
        } else if (
            pair.token0 == usdtTokenAddr || pair.token0 == husdTokenAddr
        ) {
            tokenAddr = pair.token0;
            tokenPrice = PRICE_PRECISION;
        } else if (
            pair.token1 == usdtTokenAddr || pair.token1 == husdTokenAddr
        ) {
            tokenAddr = pair.token1;
            tokenPrice = PRICE_PRECISION;
        } else {
            return pair;
        }

        uint256 poolAmount = getPoolAmount(pool, tokenAddr, tokenPrice);
        if (poolAmount > 0) {
            pair.apy = baseInfo
                .totalReward
                .mul(PERCENT_PRECISION)
                .mul(pool.allocPoint)
                .div(baseInfo.totalAllocPoint)
                .div(poolAmount);
        }
        return pair;
    }

    function getPoolAmount(
        PoolInfo memory pool,
        address tokenAddr,
        uint256 tokenPrice
    ) internal view returns (uint256) {
        if (PipiPair(pool.lpToken).balanceOf(pippiMasterChefAddr) == 0)
            return 0;
        return
            IERC20(tokenAddr)
                .balanceOf(pool.lpToken)
                .mul(tokenPrice)
                .mul(2)
                .mul(PipiPair(pool.lpToken).balanceOf(pippiMasterChefAddr))
                .div(PipiPair(pool.lpToken).totalSupply())
                .div(uint256(10)**IERC20(tokenAddr).decimals());
    }
}
