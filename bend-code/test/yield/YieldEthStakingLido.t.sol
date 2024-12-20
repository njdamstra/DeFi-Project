// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Constants} from 'bend-code/src/libraries/helpers/Constants.sol';

import 'bend-code/test/setup/TestWithPrepare.sol';
import 'bend-code/lib/forge-std-f73c73d2018eb6a111f35e4dae7b4f27401e9421/src/Test.sol';

contract TestYieldEthStakingLido is TestWithPrepare {
  struct YieldTestVars {
    uint32 poolId;
    uint8 state;
    uint256 debtAmount;
    uint256 yieldAmount;
    uint256 unstakeFine;
    uint256 withdrawAmount;
    uint256 withdrawReqId;
  }

  function onSetUp() public virtual override {
    super.onSetUp();

    initCommonPools();

    initYieldEthStaking();
  }

  function test_Should_stake() public {
    YieldTestVars memory testVars;

    prepareWETH(tsDepositor1);

    uint256[] memory tokenIds = prepareIsolateBAYC(tsBorrower1);

    uint256 stakeAmount = tsYieldEthStakingLido.getNftValueInUnderlyingAsset(address(tsBAYC));
    stakeAmount = (stakeAmount * 80) / 100;

    tsHEVM.prank(address(tsBorrower1));
    tsYieldEthStakingLido.createYieldAccount(address(tsBorrower1));

    tsHEVM.prank(address(tsBorrower1));
    tsYieldEthStakingLido.stake(tsCommonPoolId, address(tsBAYC), tokenIds[0], stakeAmount);

    (testVars.poolId, testVars.state, testVars.debtAmount, testVars.yieldAmount) = tsYieldEthStakingLido
      .getNftStakeData(address(tsBAYC), tokenIds[0]);
    assertEq(testVars.poolId, tsCommonPoolId, 'poolId not eq');
    assertEq(testVars.state, Constants.YIELD_STATUS_ACTIVE, 'state not eq');
    testEquality(testVars.debtAmount, stakeAmount, 'debtAmount not eq');
    testEquality(testVars.yieldAmount, stakeAmount, 'yieldAmount not eq');

    uint256 debtAmount = tsYieldEthStakingLido.getNftDebtInUnderlyingAsset(address(tsBAYC), tokenIds[0]);
    testEquality(debtAmount, stakeAmount, 'debtAmount not eq');

    (uint256 yieldAmount, ) = tsYieldEthStakingLido.getNftYieldInUnderlyingAsset(address(tsBAYC), tokenIds[0]);
    testEquality(yieldAmount, stakeAmount, 'yieldAmount not eq');
  }

  function test_Should_unstake() public {
    YieldTestVars memory testVars;

    prepareWETH(tsDepositor1);

    uint256[] memory tokenIds = prepareIsolateBAYC(tsBorrower1);

    uint256 stakeAmount = tsYieldEthStakingLido.getNftValueInUnderlyingAsset(address(tsBAYC));
    stakeAmount = (stakeAmount * 80) / 100;

    tsHEVM.prank(address(tsBorrower1));
    address yieldAccount = tsYieldEthStakingLido.createYieldAccount(address(tsBorrower1));

    tsHEVM.prank(address(tsBorrower1));
    tsYieldEthStakingLido.stake(tsCommonPoolId, address(tsBAYC), tokenIds[0], stakeAmount);

    uint256 deltaAmount = (stakeAmount * 35) / 1000;
    tsStETH.rebase{value: deltaAmount}(yieldAccount);

    (uint256 yieldAmount, ) = tsYieldEthStakingLido.getNftYieldInUnderlyingAsset(address(tsBAYC), tokenIds[0]);
    testEquality(yieldAmount, (stakeAmount + deltaAmount), 3, 'yieldAmount not eq');

    tsHEVM.prank(address(tsBorrower1));
    tsYieldEthStakingLido.unstake(tsCommonPoolId, address(tsBAYC), tokenIds[0], 0);

    (testVars.poolId, testVars.state, testVars.debtAmount, testVars.yieldAmount) = tsYieldEthStakingLido
      .getNftStakeData(address(tsBAYC), tokenIds[0]);
    assertEq(testVars.state, Constants.YIELD_STATUS_UNSTAKE, 'state not eq');

    (testVars.unstakeFine, testVars.withdrawAmount, testVars.withdrawReqId) = tsYieldEthStakingLido.getNftUnstakeData(
      address(tsBAYC),
      tokenIds[0]
    );
    assertEq(testVars.unstakeFine, 0, 'unstakeFine not eq');
    assertEq(testVars.withdrawAmount, yieldAmount, 'withdrawAmount not eq');
    assertGt(testVars.withdrawReqId, 0, 'withdrawReqId not gt');
  }

  function test_Should_repay() public {
    YieldTestVars memory testVars;

    prepareWETH(tsDepositor1);

    uint256[] memory tokenIds = prepareIsolateBAYC(tsBorrower1);

    uint256 stakeAmount = tsYieldEthStakingLido.getNftValueInUnderlyingAsset(address(tsBAYC));
    stakeAmount = (stakeAmount * 80) / 100;

    tsHEVM.prank(address(tsBorrower1));
    tsYieldEthStakingLido.createYieldAccount(address(tsBorrower1));

    tsHEVM.prank(address(tsBorrower1));
    tsYieldEthStakingLido.stake(tsCommonPoolId, address(tsBAYC), tokenIds[0], stakeAmount);

    advanceTimes(7 days); // accure some debt but without any yield

    tsHEVM.prank(address(tsBorrower1));
    tsYieldEthStakingLido.unstake(tsCommonPoolId, address(tsBAYC), tokenIds[0], 0);

    (testVars.unstakeFine, testVars.withdrawAmount, testVars.withdrawReqId) = tsYieldEthStakingLido.getNftUnstakeData(
      address(tsBAYC),
      tokenIds[0]
    );
    tsUnstETH.setWithdrawalStatus(testVars.withdrawReqId, true, false);

    tsHEVM.prank(address(tsBorrower1));
    tsWETH.approve(address(tsYieldEthStakingLido), type(uint256).max);

    tsHEVM.prank(address(tsBorrower1));
    tsYieldEthStakingLido.repay(tsCommonPoolId, address(tsBAYC), tokenIds[0]);

    (testVars.poolId, testVars.state, testVars.debtAmount, testVars.yieldAmount) = tsYieldEthStakingLido
      .getNftStakeData(address(tsBAYC), tokenIds[0]);
    assertEq(testVars.state, 0, 'state not eq');
    assertEq(testVars.debtAmount, 0, 'debtAmount not eq');
    assertEq(testVars.yieldAmount, 0, 'yieldAmount not eq');
  }

  function test_Should_batch() public {
    YieldTestVars memory testVars;

    prepareWETH(tsDepositor1);

    uint256[] memory tokenIds = prepareIsolateBAYC(tsBorrower1);
    address[] memory nfts = new address[](tokenIds.length);
    for (uint i = 0; i < tokenIds.length; i++) {
      nfts[i] = address(tsBAYC);
    }

    uint256 stakeAmount = tsYieldEthStakingLido.getNftValueInUnderlyingAsset(address(tsBAYC));
    stakeAmount = (stakeAmount * 80) / 100;

    uint256[] memory stakeAmounts = new uint256[](tokenIds.length);
    for (uint i = 0; i < tokenIds.length; i++) {
      stakeAmounts[i] = stakeAmount;
    }

    tsHEVM.startPrank(address(tsBorrower1));

    tsYieldEthStakingLido.createYieldAccount(address(tsBorrower1));

    tsYieldEthStakingLido.batchStake(tsCommonPoolId, nfts, tokenIds, stakeAmounts);

    advanceTimes(7 days); // accure some debt but without any yield

    tsYieldEthStakingLido.batchUnstake(tsCommonPoolId, nfts, tokenIds, 0);

    for (uint i = 0; i < tokenIds.length; i++) {
      (testVars.unstakeFine, testVars.withdrawAmount, testVars.withdrawReqId) = tsYieldEthStakingLido.getNftUnstakeData(
        nfts[i],
        tokenIds[i]
      );
      tsUnstETH.setWithdrawalStatus(testVars.withdrawReqId, true, false);
    }

    tsWETH.approve(address(tsYieldEthStakingLido), type(uint256).max);

    tsYieldEthStakingLido.batchRepay(tsCommonPoolId, nfts, tokenIds);

    tsHEVM.stopPrank();
  }

  function test_Should_unstake_bot() public {
    YieldTestVars memory testVars;

    prepareWETH(tsDepositor1);

    uint256[] memory tokenIds = prepareIsolateBAYC(tsBorrower1);

    uint256 stakeAmount = tsYieldEthStakingLido.getNftValueInUnderlyingAsset(address(tsBAYC));
    stakeAmount = (stakeAmount * 80) / 100;

    tsHEVM.prank(address(tsBorrower1));
    tsYieldEthStakingLido.createYieldAccount(address(tsBorrower1));

    tsHEVM.prank(address(tsBorrower1));
    tsYieldEthStakingLido.stake(tsCommonPoolId, address(tsBAYC), tokenIds[0], stakeAmount);

    // add some debt interest
    advanceTimes(360 days);

    // drop down price
    adjustNftPrice(address(tsBAYC), 100);

    // ask bot to do the unstake forcely
    tsHEVM.prank(address(tsPoolAdmin));
    tsYieldEthStakingLido.setBotAdmin(address(tsBorrower2));

    tsHEVM.prank(address(tsBorrower2));
    tsYieldEthStakingLido.unstake(tsCommonPoolId, address(tsBAYC), tokenIds[0], 0.001 ether);

    (testVars.unstakeFine, testVars.withdrawAmount, testVars.withdrawReqId) = tsYieldEthStakingLido.getNftUnstakeData(
      address(tsBAYC),
      tokenIds[0]
    );
    tsUnstETH.setWithdrawalStatus(testVars.withdrawReqId, true, false);

    // ask bot to do the repay
    tsHEVM.prank(address(tsBorrower2));
    tsYieldEthStakingLido.repay(tsCommonPoolId, address(tsBAYC), tokenIds[0]);

    (testVars.poolId, testVars.state, testVars.debtAmount, testVars.yieldAmount) = tsYieldEthStakingLido
      .getNftStakeData(address(tsBAYC), tokenIds[0]);
    assertEq(testVars.state, Constants.YIELD_STATUS_CLAIM, 'bot - state not eq');
    assertGt(testVars.debtAmount, 0, 'bot - debtAmount not gt');

    // owner to do the remain repay
    tsHEVM.prank(address(tsBorrower1));
    tsWETH.approve(address(tsYieldEthStakingLido), type(uint256).max);

    tsHEVM.prank(address(tsBorrower1));
    tsYieldEthStakingLido.repay(tsCommonPoolId, address(tsBAYC), tokenIds[0]);

    (testVars.poolId, testVars.state, testVars.debtAmount, testVars.yieldAmount) = tsYieldEthStakingLido
      .getNftStakeData(address(tsBAYC), tokenIds[0]);
    assertEq(testVars.state, 0, 'owner - state not eq');
  }

  function adjustNftPrice(address nftAsset, uint256 percentage) internal {
    uint256 oldPrice = tsBendNFTOracle.getAssetPrice(nftAsset);
    uint256 newPrice = (oldPrice * percentage) / 1e4;
    tsBendNFTOracle.setAssetPrice(nftAsset, newPrice);
  }
}
