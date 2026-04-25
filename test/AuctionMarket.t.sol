// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {AuctionMarket} from "../src/AuctionMarket.sol";
import {TitanNFT} from "../src/TitanNFT.sol";
import {MockPriceFeed} from "../src/mocks/MockPriceFeed.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
contract AuctionMarketTest is Test {
   // 定义合约变量
    AuctionMarket public market;
    TitanNFT public nft;
    MockPriceFeed public priceFeed;

    // 定义测试用的虚拟地址
    address public admin = address(1);
    address public seller = address(2);
    address public bidder = address(3);

 function setUp() public {
        vm.startPrank(admin);

        // 1. 部署预言机，设置初始价格为 3000 USD (8位精度)
        priceFeed = new MockPriceFeed(3000 * 1e8);

        // 2. 部署拍卖市场逻辑合约
        AuctionMarket implementation = new AuctionMarket();

        // 3. 构造初始化数据 (调用 initialize 函数)
        bytes memory initData = abi.encodeWithSelector(
            AuctionMarket.initialize.selector,
            address(priceFeed)
        );

        // 4. 部署 UUPS 代理合约，并关联逻辑合约
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        
        // 5. 将代理地址强制转换为市场合约接口
        market = AuctionMarket(address(proxy));

        // 6. 部署 NFT 合约
        nft = new TitanNFT();

        vm.stopPrank();
    }
  function test_CreateAuction() public {
        // 第一步：管理员铸造一个 NFT 给卖家
        vm.prank(admin);
        nft.safeMint(seller);

        // 第二步：卖家授权 NFT 给拍卖市场
        vm.startPrank(seller);
        nft.approve(address(market), 0);

        // 第三步：卖家创建拍卖 (起拍价 1000 USD, 18位精度; 持续时间 1天)
        market.createAuction(address(nft), 0, 1000 * 1e18, 1 days);
        vm.stopPrank();

        // 重点修复：结构体有 8 个字段，左边必须有 7 个逗号来对应 8 个位置
        // 顺序：0:seller, 1:nftAddr, 2:tokenId, 3:minPrice, 4:bidder, 5:amount, 6:endTime, 7:isActive
        (
            address auctionSeller, // 0
            ,                      // 1: nftAddr (忽略)
            ,                      // 2: tokenId (忽略)
            ,                      // 3: minPriceInUsd (忽略)
            ,                      // 4: highestBidder (忽略)
            ,                      // 5: highestBidAmount (忽略)
            ,                      // 6: endTime (忽略)
            bool active            // 7: isActive (获取)
        ) = market.auctions(1);

        // 验证结果
        assertEq(auctionSeller, seller, "Seller mismatch");
        assertTrue(active, "Auction should be active");
    }

    /**
     * @dev 测试出价成功逻辑
     */
    function test_BidSuccess() public {
        // 1. 先跑一遍创建拍卖的流程
        test_CreateAuction();

        // 2. 给投标人发钱 (10 ETH)
        vm.deal(bidder, 10 ether);

        // 3. 投标人出价 1 ETH (按照 3000USD 汇率，满足 1000USD 门槛)
        vm.startPrank(bidder);
        market.bid{value: 1 ether}(1);
        vm.stopPrank();

        // 重点修复：同样需要 8 个字段对应
        (
            ,                       // 0
            ,                       // 1
            ,                       // 2
            ,                       // 3
            address highestBidder,  // 4: 获取最高出价者
            uint256 highestAmount,  // 5: 获取最高出价金额
            ,                       // 6
            // 这里末尾也需要一个逗号占位第 8 个字段 isActive
        ) = market.auctions(1);

        // 验证结果
        assertEq(highestBidder, bidder, "Highest bidder mismatch");
        assertEq(highestAmount, 1 ether, "Highest amount mismatch");
    }
}