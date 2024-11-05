// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'bend-code/src/interfaces/IBendNFTOracle.sol';

contract MockBendNFTOracle is IBendNFTOracle {
  mapping(address => uint256) public prices;
  mapping(address => uint256) public latestTimestamps;

  function getAssetPrice(address _nftContract) public view returns (uint256 price) {
    price = prices[_nftContract];
  }

  function setAssetPrice(address _nftContract, uint256 price) public {
    prices[_nftContract] = price;
    latestTimestamps[_nftContract] = block.timestamp;
  }

  function getLatestTimestamp(address _nftContract) public view returns (uint256) {
    return latestTimestamps[_nftContract];
  }
}
