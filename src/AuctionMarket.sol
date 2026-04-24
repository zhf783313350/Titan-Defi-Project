// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// 引入 UUPS 所需的升级库 (注意路径需与 remappings 对应)
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// 引入 Chainlink 预言机接口
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
contract AuctionMarket  is Initializable,UUPSUpgradeable,OwnableUpgradeable,ReentrancyGuardUpgradeable {
    struct  Auction {
        address seller;
        address nfrAddr;

    }
}