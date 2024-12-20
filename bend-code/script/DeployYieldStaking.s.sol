// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {TransparentUpgradeableProxy} from '@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import {ProxyAdmin} from '@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol';

import {IAddressProvider} from 'bend-code/src/interfaces/IAddressProvider.sol';

import {Constants} from 'bend-code/src/libraries/helpers/Constants.sol';

import {YieldEthStakingLido} from 'bend-code/src/yield/lido/YieldEthStakingLido.sol';
import {YieldEthStakingEtherfi} from 'bend-code/src/yield/etherfi/YieldEthStakingEtherfi.sol';
import {YieldSavingsDai} from 'bend-code/src/yield/sdai/YieldSavingsDai.sol';
import {YieldSavingsUSDS} from 'bend-code/src/yield/susds/YieldSavingsUSDS.sol';

import {YieldRegistry} from 'bend-code/src/yield/YieldRegistry.sol';
import {YieldAccount} from 'bend-code/src/yield/YieldAccount.sol';

import {Configured, ConfigLib, Config} from 'bend-code/config/Configured.sol';
import {DeployBase} from './DeployBase.s.sol';

import 'bend-code/lib/forge-std-f73c73d2018eb6a111f35e4dae7b4f27401e9421/src/Script.sol';

contract DeployYieldStaking is DeployBase {
  using ConfigLib for Config;

  function _deploy() internal virtual override {
    address proxyAdminInCfg = config.getProxyAdmin();
    require(proxyAdminInCfg != address(0), 'ProxyAdmin not exist in config');

    address addrProviderInCfg = config.getAddressProvider();
    require(addrProviderInCfg != address(0), 'AddressProvider not exist in config');

    // _deployYieldRegistry(proxyAdminInCfg, addrProviderInCfg);

    // _deployYieldEthStakingLido(proxyAdminInCfg, addrProviderInCfg);

    // _deployYieldEthStakingEtherfi(proxyAdminInCfg, addrProviderInCfg);

    // _deployYieldSavingsDai(proxyAdminInCfg, addrProviderInCfg);

    // _deployYieldSavingsUSDS(proxyAdminInCfg, addrProviderInCfg);
  }

  function _deployYieldRegistry(address proxyAdmin_, address addressProvider_) internal returns (address) {
    YieldRegistry yieldRegistryImpl = new YieldRegistry();

    TransparentUpgradeableProxy yieldRegistryProxy = new TransparentUpgradeableProxy(
      address(yieldRegistryImpl),
      address(proxyAdmin_),
      abi.encodeWithSelector(yieldRegistryImpl.initialize.selector, address(addressProvider_))
    );
    YieldRegistry yieldRegistry = YieldRegistry(address(yieldRegistryProxy));
    console.log('yieldRegistry:', address(yieldRegistry));

    IAddressProvider(addressProvider_).setYieldRegistry(address(yieldRegistry));

    YieldAccount accountImpl = new YieldAccount();

    yieldRegistry.setYieldAccountImplementation(address(accountImpl));

    return address(yieldRegistry);
  }

  function _deployYieldEthStakingLido(address proxyAdmin_, address addressProvider_) internal returns (address) {
    address weth = address(0);
    address stETH = address(0);
    address unstETH = address(0);

    uint256 chainId = config.getChainId();
    if (chainId == 1) {
      // mainnet
      weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
      stETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
      unstETH = 0x889edC2eDab5f40e902b864aD4d7AdE8E412F9B1;
    } else if (chainId == 11155111) {
      // sepolia
      weth = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;
      stETH = 0x7E294171098b172a223ABEc020e5e0644853E68C;
      unstETH = 0xfAA017B0B36BDf3fd705eE2c1a63e227b2EbE791;
    } else {
      revert('not support');
    }

    YieldEthStakingLido yieldLidoImpl = new YieldEthStakingLido();

    TransparentUpgradeableProxy yieldLidoProxy = new TransparentUpgradeableProxy(
      address(yieldLidoImpl),
      address(proxyAdmin_),
      abi.encodeWithSelector(yieldLidoImpl.initialize.selector, address(addressProvider_), weth, stETH, unstETH)
    );
    YieldEthStakingLido yieldLido = YieldEthStakingLido(payable(yieldLidoProxy));
    console.log('YieldEthStakingLido:', address(yieldLido));

    return address(yieldLido);
  }

  function _deployYieldEthStakingEtherfi(address proxyAdmin_, address addressProvider_) internal returns (address) {
    address weth = address(0);
    address etherfiPool = address(0);

    uint256 chainId = config.getChainId();
    if (chainId == 1) {
      // mainnet
      weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
      etherfiPool = 0x308861A430be4cce5502d0A12724771Fc6DaF216;
    } else if (chainId == 11155111) {
      // sepolia
      weth = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;
      etherfiPool = 0xBD9277C1aF64e2D7c9Cf0df5f717f20b9a66fD7E;
    } else {
      revert('not support');
    }

    YieldEthStakingEtherfi yieldEtherfiImpl = new YieldEthStakingEtherfi();

    TransparentUpgradeableProxy yieldEtherfiProxy = new TransparentUpgradeableProxy(
      address(yieldEtherfiImpl),
      address(proxyAdmin_),
      abi.encodeWithSelector(yieldEtherfiImpl.initialize.selector, address(addressProvider_), weth, etherfiPool)
    );
    YieldEthStakingEtherfi yieldEtherfi = YieldEthStakingEtherfi(payable(yieldEtherfiProxy));
    console.log('YieldEthStakingEtherfi:', address(yieldEtherfi));

    return address(yieldEtherfi);
  }

  function _deployYieldSavingsDai(address proxyAdmin_, address addressProvider_) internal returns (address) {
    address dai = address(0);
    address sdai = address(0);

    uint256 chainId = config.getChainId();
    if (chainId == 1) {
      // mainnet
      dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
      sdai = 0x83F20F44975D03b1b09e64809B757c47f942BEeA;
    } else if (chainId == 11155111) {
      // sepolia
      dai = 0xf9a88B0cc31f248c89F063C2928fA10e5A029B88;
      sdai = 0x8A9214AF64f6F313a2eBe2F80cfDD470bFCC1a33;
    } else {
      revert('not support');
    }

    YieldSavingsDai yieldSDaiImpl = new YieldSavingsDai();

    TransparentUpgradeableProxy yieldSDaiProxy = new TransparentUpgradeableProxy(
      address(yieldSDaiImpl),
      address(proxyAdmin_),
      abi.encodeWithSelector(yieldSDaiImpl.initialize.selector, address(addressProvider_), dai, sdai)
    );
    YieldSavingsDai yieldSDai = YieldSavingsDai(payable(yieldSDaiProxy));
    console.log('YieldSavingsDai:', address(yieldSDai));

    return address(yieldSDai);
  }

  function _deployYieldSavingsUSDS(address proxyAdmin_, address addressProvider_) internal returns (address) {
    address usds = address(0);
    address susds = address(0);

    uint256 chainId = config.getChainId();
    if (chainId == 1) {
      // mainnet
      usds = 0xdC035D45d973E3EC169d2276DDab16f1e407384F;
      susds = 0xa3931d71877C0E7a3148CB7Eb4463524FEc27fbD;
    } else if (chainId == 11155111) {
      // sepolia
      usds = 0x99f5A9506504BB96d0019538608090015BA9EBDd;
      susds = 0xf8B05Dab36ea0492E4e358FeF83a608e4297b3D4;
    } else {
      revert('not support');
    }

    YieldSavingsUSDS yieldSUSDSImpl = new YieldSavingsUSDS();

    TransparentUpgradeableProxy yieldSUSDSProxy = new TransparentUpgradeableProxy(
      address(yieldSUSDSImpl),
      address(proxyAdmin_),
      abi.encodeWithSelector(yieldSUSDSImpl.initialize.selector, address(addressProvider_), usds, susds)
    );
    YieldSavingsUSDS yieldSUSDS = YieldSavingsUSDS(payable(yieldSUSDSProxy));
    console.log('YieldSavingsUSDS:', address(yieldSUSDS));

    return address(yieldSUSDS);
  }
}
