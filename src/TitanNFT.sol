// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// 修改点：使用具名导入，消除 forge-lint 的 unaliased-plain-import 提示
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract TitanNFT is ERC721, Ownable {
    uint256 private _nextTokenId;

    constructor() ERC721("Titan NFT", "TNFT") Ownable(msg.sender) {}

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _nextTokenId;
        _nextTokenId++;
        _safeMint(to, tokenId);
    }
}