// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Ownable2Step} from '@openzeppelin/contracts/access/Ownable2Step.sol';
import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import {ERC721Enumerable} from '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {IStETH} from 'bend-code/src/interfaces/IStETH.sol';
import {IUnstETH} from 'bend-code/src/interfaces/IUnstETH.sol';

contract MockUnstETH is IUnstETH, ERC721Enumerable, Ownable2Step {
  IStETH private _stETH;
  uint256 private _nextRequestId;
  mapping(uint256 => WithdrawalRequestStatus) private _withdrawStatuses;

  constructor(address stETH_) ERC721('MockUnstETH', 'unstETH') {
    _stETH = IStETH(stETH_);
    _nextRequestId = 1;
  }

  function requestWithdrawals(
    uint256[] calldata _amounts,
    address _owner
  ) public override returns (uint256[] memory requestIds) {
    requestIds = new uint256[](_amounts.length);

    for (uint i = 0; i < _amounts.length; i++) {
      uint256 share = _stETH.getSharesByPooledEth(_amounts[i]);
      _stETH.transferFrom(msg.sender, address(this), share);

      requestIds[i] = _nextRequestId++;

      _withdrawStatuses[requestIds[i]].amountOfStETH = _amounts[i];
      _withdrawStatuses[requestIds[i]].amountOfShares = share;
      _withdrawStatuses[requestIds[i]].owner = _owner;
      _withdrawStatuses[requestIds[i]].timestamp = block.timestamp;

      _mint(_owner, requestIds[i]);
    }
  }

  function setWithdrawalStatus(uint256 _requestId, bool isFinalized, bool isClaimed) public {
    require(_withdrawStatuses[_requestId].amountOfStETH != 0, 'invalid _requestId');
    _withdrawStatuses[_requestId].isFinalized = isFinalized;
    _withdrawStatuses[_requestId].isClaimed = isClaimed;
  }

  function getWithdrawalStatus(
    uint256[] calldata _requestIds
  ) public view override returns (WithdrawalRequestStatus[] memory statuses) {
    statuses = new WithdrawalRequestStatus[](_requestIds.length);
    for (uint i = 0; i < _requestIds.length; i++) {
      statuses[i] = _withdrawStatuses[_requestIds[i]];
    }
  }

  function claimWithdrawal(uint256 _requestId) public override {
    require(_withdrawStatuses[_requestId].owner == msg.sender, 'not owner');
    require(!_withdrawStatuses[_requestId].isClaimed, 'already claimed');

    _withdrawStatuses[_requestId].isClaimed = true;

    (bool success, ) = msg.sender.call{value: _withdrawStatuses[_requestId].amountOfStETH}('');
    require(success, 'send value failed');

    _burn(_requestId);
  }

  function transferETH(address to) public onlyOwner {
    _transferETH(to);
  }

  function _transferETH(address to) internal {
    (bool success, ) = to.call{value: address(this).balance}('');
    require(success, 'send value failed');
  }

  function transferStETH(address receiver) public onlyOwner {
    uint256 amount = IERC20(_stETH).balanceOf(address(this));
    IERC20(_stETH).transfer(receiver, amount);
  }

  receive() external payable {}
}
