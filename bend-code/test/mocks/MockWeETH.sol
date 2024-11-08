// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable2Step} from '@openzeppelin/contracts/access/Ownable2Step.sol';
import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {IeETH} from 'bend-code/src/yield/etherfi/IeETH.sol';
import {ILiquidityPool} from 'bend-code/src/yield/etherfi/ILiquidityPool.sol';

contract MockWeETH is ERC20, Ownable2Step {
  //--------------------------------------------------------------------------------------
  //---------------------------------  STATE-VARIABLES  ----------------------------------
  //--------------------------------------------------------------------------------------

  IeETH public eETH;
  ILiquidityPool public liquidityPool;

  //--------------------------------------------------------------------------------------
  //----------------------------  STATE-CHANGING FUNCTIONS  ------------------------------
  //--------------------------------------------------------------------------------------

  constructor(address _liquidityPool, address _eETH) ERC20('Wrapped eETH', 'weETH') {
    require(_liquidityPool != address(0), 'No zero addresses');
    require(_eETH != address(0), 'No zero addresses');
    eETH = IeETH(_eETH);
    liquidityPool = ILiquidityPool(_liquidityPool);
  }

  /// @dev name changed from the version initially deployed
  function name() public view virtual override returns (string memory) {
    return 'Wrapped eETH';
  }

  /// @notice Wraps eEth
  /// @param _eETHAmount the amount of eEth to wrap
  /// @return returns the amount of weEth the user receives
  function wrap(uint256 _eETHAmount) public returns (uint256) {
    require(_eETHAmount > 0, "weETH: can't wrap zero eETH");
    uint256 weEthAmount = liquidityPool.sharesForAmount(_eETHAmount);
    _mint(msg.sender, weEthAmount);
    eETH.transferFrom(msg.sender, address(this), _eETHAmount);
    return weEthAmount;
  }

  /// @notice Unwraps weETH
  /// @param _weETHAmount the amount of weETH to unwrap
  /// @return returns the amount of eEth the user receives
  function unwrap(uint256 _weETHAmount) external returns (uint256) {
    require(_weETHAmount > 0, 'Cannot unwrap a zero amount');
    uint256 eETHAmount = liquidityPool.amountForShare(_weETHAmount);
    _burn(msg.sender, _weETHAmount);
    eETH.transfer(msg.sender, eETHAmount);
    return eETHAmount;
  }

  //--------------------------------------------------------------------------------------
  //------------------------------------  GETTERS  ---------------------------------------
  //--------------------------------------------------------------------------------------

  /// @notice Fetches the amount of weEth respective to the amount of eEth sent in
  /// @param _eETHAmount amount sent in
  /// @return The total number of shares for the specified amount
  function getWeETHByeETH(uint256 _eETHAmount) external view returns (uint256) {
    return liquidityPool.sharesForAmount(_eETHAmount);
  }

  /// @notice Fetches the amount of eEth respective to the amount of weEth sent in
  /// @param _weETHAmount amount sent in
  /// @return The total amount for the number of shares sent in
  function getEETHByWeETH(uint256 _weETHAmount) public view returns (uint256) {
    return liquidityPool.amountForShare(_weETHAmount);
  }

  // Amount of weETH for 1 eETH
  function getRate() external view returns (uint256) {
    return getEETHByWeETH(1 ether);
  }

  function transferStETH(address receiver) public onlyOwner {
    uint256 amount = IERC20(eETH).balanceOf(address(this));
    IERC20(eETH).transfer(receiver, amount);
  }
}
