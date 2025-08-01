// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import "../src/vest/EdenVestCore.sol";
import "../src/vest/InvestmentPool.sol";
import "../src/vest/PoolFactory.sol";
import "../src/vest/LPToken.sol";
import "../src/vest/TaxCollector.sol";
import "../src/vest/SwapRouter.sol";
import "../src/vest/NFTPositionManager.sol";
import "../src/EdenPoolNFT.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./mocks/MockERC20.sol";

contract MockcNGN is MockERC20 {
    constructor() MockERC20("Mock cNGN", "McNGN", 18) {
        _mint(msg.sender, 1000000e18);
    }
}

contract EdenVestTestBase is Test {
    EdenVestCore public edenCore;
    PoolFactory public poolFactory;
    TaxCollector public taxCollector;
    SwapRouter public swapRouter;
    NFTPositionManager public nftManager;
    EdenPoolNFT public nftRenderer;

    MockcNGN public cNGN;
    MockERC20 public usdt;

    address public admin = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);
    address public multisig = address(0x4);
    address public treasury = address(0x5);
    address[] public multisigSigners;

    IPoolFactory.PoolParams public defaultPoolParams;

    function setUp() public virtual {
        cNGN = new MockcNGN();
        usdt = new MockERC20("USDT", "USDT", 18);

        multisigSigners.push(address(0x6));
        multisigSigners.push(address(0x7));
        multisigSigners.push(address(0x8));

        nftRenderer = new EdenPoolNFT();
        nftManager = new NFTPositionManager(address(nftRenderer), admin);
        poolFactory = new PoolFactory(admin);

        address mockUniswapRouter = address(0x100);
        address mockUniswapQuoter = address(0x101);
        swapRouter = new SwapRouter(mockUniswapRouter, mockUniswapQuoter, admin);

        edenCore = new EdenVestCore();
        edenCore.initialize(address(cNGN), treasury, admin, 250, multisigSigners); // 2.5% tax
        taxCollector = new TaxCollector(treasury, admin, address(edenCore));

        vm.startPrank(admin);
        edenCore.setPoolFactory(address(poolFactory));
        edenCore.setTaxCollector(address(taxCollector));
        edenCore.setSwapRouter(address(swapRouter));
        edenCore.setNFTManager(address(nftManager));

        poolFactory.setEdenCore(address(edenCore));
        poolFactory.setNFTManager(address(nftManager));
        vm.stopPrank();

        defaultPoolParams = IPoolFactory.PoolParams({
            name: "Test Pool",
            symbol: "TP",
            admin: admin,
            cNGN: address(cNGN),
            poolMultisig: multisig,
            multisigSigners: multisigSigners,
            lockDuration: 30 days,
            minInvestment: 1_000e18,
            maxInvestment: 10_000_000e18,
            utilizationCap: 10000000e18,
            expectedRate: 1500, // 15% APY
            taxRate: 0
        });

        cNGN.mint(user1, 100000e18);
        cNGN.mint(user2, 100000e18);
        cNGN.mint(multisig, 1000000e18);
        usdt.mint(user1, 100000e18);
        usdt.mint(user2, 100000e18);

        vm.label(admin, "Admin");
        vm.label(user1, "User1");
        vm.label(user2, "User2");
        vm.label(multisig, "Multisig");
        vm.label(treasury, "Treasury");
        vm.label(address(edenCore), "EdenCore");
        vm.label(address(poolFactory), "PoolFactory");
        vm.label(address(cNGN), "cNGN");
    }
}
