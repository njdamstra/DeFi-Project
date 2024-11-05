// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Configured, ConfigLib, Config} from 'bend-code/config/Configured.sol';

import 'bend-code/lib/forge-std-f73c73d2018eb6a111f35e4dae7b4f27401e9421/src/Script.sol';

abstract contract DeployBase is Script, Configured {
  using ConfigLib for Config;
  address internal deployer;
  bytes32 internal gitCommitHash;
  string internal etherscanKey;

  function run() external {
    _initConfig();

    _loadConfig();

    deployer = vm.addr(vm.envUint('PRIVATE_KEY'));

    gitCommitHash = vm.envBytes32('GIT_COMMIT_HASH');

    etherscanKey = vm.envString('ETHERSCAN_KEY');

    vm.startBroadcast(deployer);

    _deploy();

    vm.stopBroadcast();
  }

  function _deploy() internal virtual {}
}
