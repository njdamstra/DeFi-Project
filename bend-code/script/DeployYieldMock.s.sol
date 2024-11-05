// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Constants} from 'bend-code/src/libraries/helpers/Constants.sol';

import {MockERC20} from 'bend-code/test/mocks/MockERC20.sol';

import {MockStETH} from 'bend-code/test/mocks/MockStETH.sol';
import {MockUnstETH} from 'bend-code/test/mocks/MockUnstETH.sol';

import {MockeETH} from 'bend-code/test/mocks/MockeETH.sol';
import {MockEtherfiWithdrawRequestNFT} from 'bend-code/test/mocks/MockEtherfiWithdrawRequestNFT.sol';
import {MockEtherfiLiquidityPool} from 'bend-code/test/mocks/MockEtherfiLiquidityPool.sol';
import {MockWeETH} from 'bend-code/test/mocks/MockWeETH.sol';

import {MockSDAI} from 'bend-code/test/mocks/MockSDAI.sol';
import {MockDAIPot} from 'bend-code/test/mocks/MockDAIPot.sol';
import {MockSUSDS} from 'bend-code/test/mocks/MockSUSDS.sol';

import {Configured, ConfigLib, Config} from 'bend-code/config/Configured.sol';
import {DeployBase} from './DeployBase.s.sol';

import 'bend-code/lib/forge-std-f73c73d2018eb6a111f35e4dae7b4f27401e9421/src/Script.sol';

contract DeployYieldMock is DeployBase {
  using ConfigLib for Config;

  function _deploy() internal virtual override {
    // _deployMockLido();
    // _deployMockEtherfi();
    // _deployMockSDai();
    // _deployMockSUSDS();
  }

  function _deployMockLido() internal {
    MockStETH stETH = new MockStETH('MockStETH', 'stETH', 18);
    MockUnstETH unstETH = new MockUnstETH(address(stETH));

    stETH.setUnstETH(address(unstETH));
  }

  function _deployMockEtherfi() internal {
    MockeETH eETH = new MockeETH('MockeETH', 'eETH', 18);
    MockEtherfiWithdrawRequestNFT nft = new MockEtherfiWithdrawRequestNFT();
    MockEtherfiLiquidityPool pool = new MockEtherfiLiquidityPool(address(eETH), address(nft));

    eETH.setLiquidityPool(address(pool));
    nft.setLiquidityPool(address(pool), address(eETH));

    //MockWeETH weETH = new MockWeETH(address(pool), address(eETH));
    new MockWeETH(address(pool), address(eETH));
  }

  function _deployMockSDai() internal {
    // MockDAIPot pot = new MockDAIPot();
    // MockDAIPot pot = MockDAIPot(0x30252a71d6bC66f772b1Ed7d07CdEa2952a0F032);

    // DAI should be same with pool lending
    // MockERC20 dai = new MockERC20('Dai Stablecoin', 'DAI', 18);
    MockERC20 dai = MockERC20(0xf9a88B0cc31f248c89F063C2928fA10e5A029B88);

    new MockSDAI(address(dai));
  }

  function _deployMockSUSDS() internal {
    // USDS should be same with pool lending
    // MockERC20 usds = new MockERC20('USDS Stablecoin', 'USDS', 18);
    MockERC20 usds = MockERC20(0x99f5A9506504BB96d0019538608090015BA9EBDd);

    new MockSUSDS(address(usds));
  }
}
