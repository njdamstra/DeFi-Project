// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Constants} from 'bend-code/src/libraries/helpers/Constants.sol';

import {PoolManager} from 'bend-code/src/PoolManager.sol';
import {Installer} from 'bend-code/src/modules/Installer.sol';
import {ConfiguratorPool} from 'bend-code/src/modules/ConfiguratorPool.sol';
import {Configurator} from 'bend-code/src/modules/Configurator.sol';
import {BVault} from 'bend-code/src/modules/BVault.sol';
import {CrossLending} from 'bend-code/src/modules/CrossLending.sol';
import {CrossLiquidation} from 'bend-code/src/modules/CrossLiquidation.sol';
import {IsolateLending} from 'bend-code/src/modules/IsolateLending.sol';
import {IsolateLiquidation} from 'bend-code/src/modules/IsolateLiquidation.sol';
import {Yield} from 'bend-code/src/modules/Yield.sol';
import {FlashLoan} from 'bend-code/src/modules/FlashLoan.sol';
import {PoolLens} from 'bend-code/src/modules/PoolLens.sol';
import {UIPoolLens} from 'bend-code/src/modules/UIPoolLens.sol';

import {Configured, ConfigLib, Config} from 'bend-code/config/Configured.sol';
import {DeployBase} from './DeployBase.s.sol';

import 'bend-code/lib/forge-std-f73c73d2018eb6a111f35e4dae7b4f27401e9421/src/Script.sol';

contract InstallModule is DeployBase {
  using ConfigLib for Config;

  function _deploy() internal virtual override {
    address addressInCfg = config.getPoolManager();
    require(addressInCfg != address(0), 'PoolManager not exist in config');

    PoolManager poolManager = PoolManager(payable(addressInCfg));

    Installer installer = Installer(poolManager.moduleIdToProxy(Constants.MODULEID__INSTALLER));

    address[] memory modules = _allModules();
    // address[] memory modules = _someModules();

    if (block.chainid != 1) {
      installer.installModules(modules);
    }
  }

  function _someModules() internal returns (address[] memory) {
    address[] memory modules = new address[](1);
    uint modIdx = 0;

    Configurator tsConfiguratorImpl = new Configurator(gitCommitHash);
    modules[modIdx++] = address(tsConfiguratorImpl);

    return modules;
  }

  function _allModules() internal returns (address[] memory) {
    address[] memory modules = new address[](11);
    uint modIdx = 0;

    ConfiguratorPool tsConfiguratorPoolImpl = new ConfiguratorPool(gitCommitHash);
    modules[modIdx++] = address(tsConfiguratorPoolImpl);

    Configurator tsConfiguratorImpl = new Configurator(gitCommitHash);
    modules[modIdx++] = address(tsConfiguratorImpl);

    BVault tsVaultImpl = new BVault(gitCommitHash);
    modules[modIdx++] = address(tsVaultImpl);

    CrossLending tsCrossLendingImpl = new CrossLending(gitCommitHash);
    modules[modIdx++] = address(tsCrossLendingImpl);

    CrossLiquidation tsCrossLiquidationImpl = new CrossLiquidation(gitCommitHash);
    modules[modIdx++] = address(tsCrossLiquidationImpl);

    IsolateLending tsIsolateLendingImpl = new IsolateLending(gitCommitHash);
    modules[modIdx++] = address(tsIsolateLendingImpl);

    IsolateLiquidation tsIsolateLiquidationImpl = new IsolateLiquidation(gitCommitHash);
    modules[modIdx++] = address(tsIsolateLiquidationImpl);

    Yield tsYieldImpl = new Yield(gitCommitHash);
    modules[modIdx++] = address(tsYieldImpl);

    FlashLoan tsFlashLoanImpl = new FlashLoan(gitCommitHash);
    modules[modIdx++] = address(tsFlashLoanImpl);

    PoolLens tsPoolLensImpl = new PoolLens(gitCommitHash);
    modules[modIdx++] = address(tsPoolLensImpl);

    UIPoolLens tsUIPoolLensImpl = new UIPoolLens(gitCommitHash);
    modules[modIdx++] = address(tsUIPoolLensImpl);

    return modules;
  }
}
