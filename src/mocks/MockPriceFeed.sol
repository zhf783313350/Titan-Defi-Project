// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MockPriceFeed{
    int256 private _price;
    constructor(int256 initialPrice){
        _price=initialPrice;
    }
       // 允许我们在测试中手动修改价格
    function updatePrice(int256 newPrice) public {
        _price = newPrice;
    }
        // 模拟 Chainlink 的接口函数
    function latestRoundData()
        external
        view
        returns (uint80, int256, uint256, uint256, uint80)
    {
        return (0, _price, 0, block.timestamp, 0);
    }
}