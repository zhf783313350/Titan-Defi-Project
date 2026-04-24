// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract  TItanNFT is ERC721,Ownable {
      // 定义一个私有变量，用于记录下一个要铸造的 Token ID
    uint256 private _nextTokenId;
     constructor() ERC721("Titan NFT", "TNFT") Ownable(msg.sender) {}

    function safeMint(address to)public onlyOwner() {
         uint256 tokenId =_nextTokenId++;
         _safeMint(to,tokenId);
    }
}