// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// 修改点：具名导入消除 Linter 提示
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract AuctionMarket is 
    Initializable, 
    UUPSUpgradeable, 
    OwnableUpgradeable, 
    ReentrancyGuardUpgradeable 
{
    struct Auction {
        address seller;
        address nftAddr;
        uint256 tokenId;
        uint256 minPriceInUsd; // 修改点：USD -> Usd 符合命名规范
        address highestBidder;
        uint256 highestBidAmount;
        uint256 endTime;
        bool isActive;
    }

    mapping(uint256 => Auction) public auctions;
    uint256 public totalAuctions;
    AggregatorV3Interface internal ethUsdPriceFeed;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _priceFeed) public initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeed);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function getLatestPrice() public view returns (int256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        return price;
    }

    function createAuction(
        address _nftAddr, 
        uint256 _tokenId, 
        uint256 _minPriceUsd, // 修改点：USD -> Usd
        uint256 _duration
    ) external {
        IERC721(_nftAddr).transferFrom(msg.sender, address(this), _tokenId);

        totalAuctions++;
        auctions[totalAuctions] = Auction({
            seller: msg.sender,
            nftAddr: _nftAddr,
            tokenId: _tokenId,
            minPriceInUsd: _minPriceUsd,
            highestBidder: address(0),
            highestBidAmount: 0,
            endTime: block.timestamp + _duration,
            isActive: true
        });
    }

    function bid(uint256 _auctionId) external payable nonReentrant {
        Auction storage auction = auctions[_auctionId];
        require(auction.isActive, "Auction is not active");
        require(block.timestamp < auction.endTime, "Auction expired");
        require(msg.value > auction.highestBidAmount, "Bid more than current highest");

int256 ethPrice = getLatestPrice();
        // 确保价格为正数，保证下方的 uint256 强制类型转换是安全的
        require(ethPrice > 0, "Invalid oracle price");

        // 使用注释消除 lint 警告，因为我们已经在上面通过 require 保证了 ethPrice 为正
        // forge-lint: disable-next-line(unsafe-typecast)
        uint256 bidValueInUsd = (uint256(ethPrice) * msg.value) / 1e8; 
        require(bidValueInUsd >= auction.minPriceInUsd, "Bid value below USD floor");

        if (auction.highestBidder != address(0)) {
            // 修改点：使用 call 代替 transfer，消除过时警告并增加错误检查
            (bool success, ) = payable(auction.highestBidder).call{value: auction.highestBidAmount}("");
            require(success, "Refund failed");
        }

        auction.highestBidder = msg.sender;
        auction.highestBidAmount = msg.value;
    }

    function endAuction(uint256 _auctionId) external nonReentrant {
        Auction storage auction = auctions[_auctionId];
        require(auction.isActive, "Already closed");
        require(block.timestamp >= auction.endTime, "Not finished");

        auction.isActive = false;

        if (auction.highestBidder != address(0)) {
            IERC721(auction.nftAddr).transferFrom(address(this), auction.highestBidder, auction.tokenId);
            // 修改点：使用 call 代替 transfer
            (bool success, ) = payable(auction.seller).call{value: auction.highestBidAmount}("");
            require(success, "Payment to seller failed");
        } else {
            IERC721(auction.nftAddr).transferFrom(address(this), auction.seller, auction.tokenId);
        }
    }
}