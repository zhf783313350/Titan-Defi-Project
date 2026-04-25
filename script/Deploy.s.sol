// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// 引入 Foundry 脚本工具
import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
// 引入我们的合约
import {AuctionMarket} from "src/AuctionMarket.sol";
import {TitanNFT} from "src/TitanNFT.sol";
import {MockPriceFeed} from "src/mocks/MockPriceFeed.sol";
// 引入 UUPS 代理合约
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployScript is Script {
    function run() external {
        // 1. 从环境变量或命令行读取私钥 (这里先硬编码 Anvil 的第一个私钥用于测试)
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        // 2. 开启广播模式，之后的交易会发送到链上

        // --- 开始部署 ---

        // A. 部署模拟预言机 (价格设为 3500 USD)
        MockPriceFeed priceFeed = new MockPriceFeed(3500 * 1e8);
        console.log("MockPriceFeed deployed at:", address(priceFeed));

        // B. 部署 NFT 合约
        TitanNFT nft = new TitanNFT();
        console.log("TitanNFT deployed at:", address(nft));

        // C. 部署拍卖市场逻辑合约 (Implementation)
        AuctionMarket marketImpl = new AuctionMarket();
        console.log("Market Implementation deployed at:", address(marketImpl));

        // D. 部署 UUPS 代理合约 (Proxy) 并初始化
        // 构造初始化数据
        bytes memory initData = abi.encodeWithSelector(
            AuctionMarket.initialize.selector,
            address(priceFeed)
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(marketImpl), initData);
        console.log("Market Proxy (Use this address!) deployed at:", address(proxy));

        // --- 结束部署 ---
        vm.stopBroadcast();
    }
}