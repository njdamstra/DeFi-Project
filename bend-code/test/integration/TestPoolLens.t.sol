// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'bend-code/src/libraries/helpers/Constants.sol';
import 'bend-code/src/libraries/helpers/Errors.sol';

import 'bend-code/test/setup/TestWithPrepare.sol';

contract TestPoolLens is TestWithPrepare {
  function onSetUp() public virtual override {
    super.onSetUp();

    initCommonPools();
  }
}
