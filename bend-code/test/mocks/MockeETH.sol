// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Ownable2Step} from '@openzeppelin/contracts/access/Ownable2Step.sol';
import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {IeETH, IERC20Metadata} from 'bend-code/src/yield/etherfi/IeETH.sol';
import {ILiquidityPool} from 'bend-code/src/yield/etherfi/ILiquidityPool.sol';

contract MockeETH is IeETH, ERC20, Ownable2Step {
  uint8 private _decimals;
  ILiquidityPool private _liquidityPool;

  constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC20(name_, symbol_) {
    _decimals = decimals_;
  }

  function mintShare(address to, uint256 share) public {
    require(msg.sender == owner() || msg.sender == address(_liquidityPool), 'MockERC20: caller not owner');
    _mint(to, share);
  }

  function burnShare(address to, uint256 share) public {
    require(msg.sender == owner() || msg.sender == address(_liquidityPool), 'MockERC20: caller not owner');
    _burn(to, share);
  }

  function decimals() public view override(ERC20, IERC20Metadata) returns (uint8) {
    return _decimals;
  }

  function balanceOf(address _user) public view override(ERC20, IERC20) returns (uint256) {
    return _liquidityPool.amountForShare(shares(_user));
  }

  function shares(address _user) public view returns (uint256) {
    return super.balanceOf(_user);
  }

  function transferETH(address to) public onlyOwner {
    (bool success, ) = to.call{value: address(this).balance}('');
    require(success, 'send value failed');
  }

  function setLiquidityPool(address pool) public onlyOwner {
    _liquidityPool = ILiquidityPool(pool);
  }

  receive() external payable {}
}
