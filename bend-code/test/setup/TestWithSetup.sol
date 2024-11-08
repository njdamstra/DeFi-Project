// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {TransparentUpgradeableProxy} from '@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import {ProxyAdmin} from '@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {Constants} from 'bend-code/src/libraries/helpers/Constants.sol';
import {WadRayMath} from 'bend-code/src/libraries/math/WadRayMath.sol';

import {IWETH} from 'bend-code/src/interfaces/IWETH.sol';

import {AddressProvider} from 'bend-code/src/AddressProvider.sol';
import {ACLManager} from 'bend-code/src/ACLManager.sol';
import {PriceOracle} from 'bend-code/src/PriceOracle.sol';
import {DefaultInterestRateModel} from 'bend-code/src/irm/DefaultInterestRateModel.sol';
import {PoolManager} from 'bend-code/src/PoolManager.sol';

import {YieldAccount} from 'bend-code/src/yield/YieldAccount.sol';
import {YieldRegistry} from 'bend-code/src/yield/YieldRegistry.sol';
import {YieldEthStakingLido} from 'bend-code/src/yield/lido/YieldEthStakingLido.sol';
import {YieldEthStakingEtherfi} from 'bend-code/src/yield/etherfi/YieldEthStakingEtherfi.sol';
import {YieldSavingsDai} from 'bend-code/src/yield/sdai/YieldSavingsDai.sol';
import {YieldSavingsUSDS} from 'bend-code/src/yield/susds/YieldSavingsUSDS.sol';

import {Installer} from 'bend-code/src/modules/Installer.sol';
import {ConfiguratorPool} from 'bend-code/src/modules/ConfiguratorPool.sol';
import {Configurator} from 'bend-code/src/modules/Configurator.sol';
import {BVault} from 'bend-code/src/modules/BVault.sol';
import {CrossLending} from 'bend-code/src/modules/CrossLending.sol';
import {CrossLiquidation} from 'bend-code/src/modules/CrossLiquidation.sol';
import {IsolateLending} from 'bend-code/src/modules/IsolateLending.sol';
import {IsolateLiquidation} from 'bend-code/src/modules/IsolateLiquidation.sol';
import {Yield} from 'bend-code/src/modules/Yield.sol';
import {PoolLens} from 'bend-code/src/modules/PoolLens.sol';
import {FlashLoan} from 'bend-code/src/modules/FlashLoan.sol';
import {UIPoolLens} from 'bend-code/src/modules/UIPoolLens.sol';

import {MockERC20} from 'bend-code/test/mocks/MockERC20.sol';
import {MockERC721} from 'bend-code/test/mocks/MockERC721.sol';
import {MockFaucet} from 'bend-code/test/mocks/MockFaucet.sol';
import {MockStETH} from 'bend-code/test/mocks/MockStETH.sol';
import {MockUnstETH} from 'bend-code/test/mocks/MockUnstETH.sol';

import {MockeETH} from 'bend-code/test/mocks/MockeETH.sol';
import {MockEtherfiLiquidityPool} from 'bend-code/test/mocks/MockEtherfiLiquidityPool.sol';
import {MockEtherfiWithdrawRequestNFT} from 'bend-code/test/mocks/MockEtherfiWithdrawRequestNFT.sol';

import {MockBendNFTOracle} from 'bend-code/test/mocks/MockBendNFTOracle.sol';
import {MockChainlinkAggregator} from 'bend-code/test/mocks/MockChainlinkAggregator.sol';

import {MockDAIPot} from 'bend-code/test/mocks/MockDAIPot.sol';
import {MockSDAI} from 'bend-code/test/mocks/MockSDAI.sol';
import {MockSUSDS} from 'bend-code/test/mocks/MockSUSDS.sol';

import {SDAIPriceAdapter} from 'bend-code/src/oracles/SDAIPriceAdapter.sol';
import {SUSDSPriceAdapter} from 'bend-code/src/oracles/SUSDSPriceAdapter.sol';

import {MockDelegateRegistryV2} from 'bend-code/test/mocks/MockDelegateRegistryV2.sol';

import {TestUser} from '../helpers/TestUser.sol';
import {TestWithUtils} from './TestWithUtils.sol';

import 'bend-code/lib/forge-std-f73c73d2018eb6a111f35e4dae7b4f27401e9421/src/Test.sol';

abstract contract TestWithSetup is TestWithUtils {
  Vm public tsHEVM = Vm(HEVM_ADDRESS);

  uint256 public constant TS_INITIAL_BALANCE = 1_000_000;

  address public tsDeployer;
  address public tsAclAdmin;
  address public tsPoolAdmin;
  address public tsEmergencyAdmin;
  address public tsOracleAdmin;
  address public tsTreasury;

  MockFaucet public tsFaucet;
  MockERC20 public tsWETH;
  MockERC20 public tsDAI;
  MockERC20 public tsUSDT;
  MockERC20 public tsUSDS;
  MockERC721 public tsWPUNK;
  MockERC721 public tsBAYC;
  MockERC721 public tsMAYC;
  MockStETH public tsStETH;
  MockUnstETH public tsUnstETH;
  MockeETH public tsEETH;
  MockEtherfiWithdrawRequestNFT public tsEtherfiWithdrawRequestNFT;
  MockEtherfiLiquidityPool public tsEtherfiLiquidityPool;
  MockDAIPot public tsDAIPot;
  MockSDAI public tsSDAI;
  MockSUSDS public tsSUSDS;
  MockDelegateRegistryV2 public tsDelegateRegistryV2;

  MockBendNFTOracle public tsBendNFTOracle;
  MockChainlinkAggregator tsCLAggregatorWETH;
  MockChainlinkAggregator tsCLAggregatorDAI;
  MockChainlinkAggregator tsCLAggregatorUSDS;
  MockChainlinkAggregator tsCLAggregatorUSDT;
  MockChainlinkAggregator tsCLAggregatorStETH;
  MockChainlinkAggregator tsCLAggregatorEETH;
  SDAIPriceAdapter tsCLAggregatorSDAI;
  SUSDSPriceAdapter tsCLAggregatorSUSDS;

  ProxyAdmin public tsProxyAdmin;
  AddressProvider public tsAddressProvider;
  ACLManager public tsAclManager;
  PriceOracle public tsPriceOracle;
  PoolManager public tsPoolManager;

  YieldRegistry public tsYieldRegistry;
  YieldEthStakingLido public tsYieldEthStakingLido;
  YieldEthStakingEtherfi public tsYieldEthStakingEtherfi;
  YieldSavingsDai public tsYieldSavingsDai;
  YieldSavingsUSDS public tsYieldSavingsUSDS;

  Installer public tsInstaller;
  ConfiguratorPool public tsConfiguratorPool;
  Configurator public tsConfigurator;
  BVault public tsBVault;
  CrossLending public tsCrossLending;
  CrossLiquidation public tsCrossLiquidation;
  IsolateLending public tsIsolateLending;
  IsolateLiquidation public tsIsolateLiquidation;
  Yield public tsYield;
  PoolLens tsPoolLens;
  FlashLoan tsFlashLoan;
  UIPoolLens tsUIPoolLens;

  uint32 public tsCommonPoolId;
  uint8 public tsLowRateGroupId;
  uint8 public tsMiddleRateGroupId;
  uint8 public tsHighRateGroupId;

  DefaultInterestRateModel public tsDefaultIRM;
  DefaultInterestRateModel public tsYieldRateIRM;
  DefaultInterestRateModel public tsLowRateIRM;
  DefaultInterestRateModel public tsMiddleRateIRM;
  DefaultInterestRateModel public tsHighRateIRM;

  TestUser public tsDepositor1;
  TestUser public tsDepositor2;
  TestUser public tsDepositor3;
  TestUser[] public tsDepositors;

  TestUser public tsBorrower1;
  TestUser public tsBorrower2;
  TestUser public tsBorrower3;
  TestUser[] public tsBorrowers;

  TestUser public tsLiquidator1;
  TestUser public tsLiquidator2;
  TestUser public tsLiquidator3;
  TestUser[] public tsLiquidators;

  TestUser public tsStaker1;
  TestUser public tsStaker2;
  TestUser public tsStaker3;
  TestUser[] public tsStakers;

  TestUser public tsHacker1;
  TestUser[] public tsHackers;

  uint256[] public tsD1TokenIds;
  uint256[] public tsD2TokenIds;
  uint256[] public tsD3TokenIds;
  uint256[] public tsB1TokenIds;
  uint256[] public tsB2TokenIds;
  uint256[] public tsB3TokenIds;

  function setUp() public {
    tsDeployer = address(this);
    tsAclAdmin = makeAddr('tsAclAdmin');
    tsPoolAdmin = makeAddr('tsPoolAdmin');
    tsEmergencyAdmin = makeAddr('tsEmergencyAdmin');
    tsOracleAdmin = makeAddr('tsOracleAdmin');
    tsTreasury = makeAddr('tsTreasury');

    initMockTokens();

    initMockOracles();

    initProtocolContracts();

    initInterestRateParams();

    initMockUsers();

    setContractsLabels();

    onSetUp();
  }

  function onSetUp() public virtual {}

  function initProtocolContracts() internal {
    /// Deploy proxies ///
    tsProxyAdmin = new ProxyAdmin();

    /// Address Provider
    AddressProvider addressProviderImpl = new AddressProvider();
    TransparentUpgradeableProxy addressProviderProxy = new TransparentUpgradeableProxy(
      address(addressProviderImpl),
      address(tsProxyAdmin),
      abi.encodeWithSelector(addressProviderImpl.initialize.selector)
    );
    tsAddressProvider = AddressProvider(address(addressProviderProxy));
    tsAddressProvider.setWrappedNativeToken(address(tsWETH));
    tsAddressProvider.setTreasury(tsTreasury);
    tsAddressProvider.setACLAdmin(tsAclAdmin);
    tsAddressProvider.setDelegateRegistryV2(address(tsDelegateRegistryV2));

    /// ACL Manager
    ACLManager aclManagerImpl = new ACLManager();
    TransparentUpgradeableProxy aclManagerProxy = new TransparentUpgradeableProxy(
      address(aclManagerImpl),
      address(tsProxyAdmin),
      abi.encodeWithSelector(aclManagerImpl.initialize.selector, tsAclAdmin)
    );
    tsAclManager = ACLManager(payable(address(aclManagerProxy)));
    tsAddressProvider.setACLManager(address(tsAclManager));

    // set acl mananger
    tsHEVM.startPrank(tsAclAdmin);
    tsAclManager.addPoolAdmin(tsPoolAdmin);
    tsAclManager.addEmergencyAdmin(tsEmergencyAdmin);
    tsAclManager.addOracleAdmin(tsOracleAdmin);
    tsHEVM.stopPrank();

    /// Price Oracle
    PriceOracle priceOracleImpl = new PriceOracle();
    TransparentUpgradeableProxy priceOracleProxy = new TransparentUpgradeableProxy(
      address(priceOracleImpl),
      address(tsProxyAdmin),
      abi.encodeWithSelector(
        priceOracleImpl.initialize.selector,
        address(tsAddressProvider),
        address(0),
        1e8,
        address(tsWETH),
        1e18
      )
    );
    tsPriceOracle = PriceOracle(payable(address(priceOracleProxy)));
    tsAddressProvider.setPriceOracle(address(tsPriceOracle));

    // Pool Manager
    bytes32 gitCommit = bytes32('1');
    Installer tsModInstallerImpl = new Installer(gitCommit);
    tsPoolManager = new PoolManager(address(tsAddressProvider), address(tsModInstallerImpl));
    tsAddressProvider.setPoolManager(address(tsPoolManager));

    tsInstaller = Installer(tsPoolManager.moduleIdToProxy(Constants.MODULEID__INSTALLER));

    address[] memory modules = new address[](11);
    uint modIdx = 0;

    ConfiguratorPool tsConfiguratorPoolImpl = new ConfiguratorPool(gitCommit);
    modules[modIdx++] = address(tsConfiguratorPoolImpl);

    Configurator tsConfiguratorImpl = new Configurator(gitCommit);
    modules[modIdx++] = address(tsConfiguratorImpl);

    BVault tsVaultImpl = new BVault(gitCommit);
    modules[modIdx++] = address(tsVaultImpl);

    CrossLending tsCrossLendingImpl = new CrossLending(gitCommit);
    modules[modIdx++] = address(tsCrossLendingImpl);

    CrossLiquidation tsCrossLiquidationImpl = new CrossLiquidation(gitCommit);
    modules[modIdx++] = address(tsCrossLiquidationImpl);

    IsolateLending tsIsolateLendingImpl = new IsolateLending(gitCommit);
    modules[modIdx++] = address(tsIsolateLendingImpl);

    IsolateLiquidation tsIsolateLiquidationImpl = new IsolateLiquidation(gitCommit);
    modules[modIdx++] = address(tsIsolateLiquidationImpl);

    Yield tsYieldImpl = new Yield(gitCommit);
    modules[modIdx++] = address(tsYieldImpl);

    FlashLoan tsFlashLoanImpl = new FlashLoan(gitCommit);
    modules[modIdx++] = address(tsFlashLoanImpl);

    PoolLens tsPoolLensImpl = new PoolLens(gitCommit);
    modules[modIdx++] = address(tsPoolLensImpl);

    UIPoolLens tsUIPoolLensImpl = new UIPoolLens(gitCommit);
    modules[modIdx++] = address(tsUIPoolLensImpl);

    tsHEVM.prank(tsPoolAdmin);
    tsInstaller.installModules(modules);

    tsConfiguratorPool = ConfiguratorPool(tsPoolManager.moduleIdToProxy(Constants.MODULEID__CONFIGURATOR_POOL));
    tsConfigurator = Configurator(tsPoolManager.moduleIdToProxy(Constants.MODULEID__CONFIGURATOR));
    tsBVault = BVault(tsPoolManager.moduleIdToProxy(Constants.MODULEID__BVAULT));
    tsCrossLending = CrossLending(tsPoolManager.moduleIdToProxy(Constants.MODULEID__CROSS_LENDING));
    tsCrossLiquidation = CrossLiquidation(tsPoolManager.moduleIdToProxy(Constants.MODULEID__CROSS_LIQUIDATION));
    tsIsolateLending = IsolateLending(tsPoolManager.moduleIdToProxy(Constants.MODULEID__ISOLATE_LENDING));
    tsIsolateLiquidation = IsolateLiquidation(tsPoolManager.moduleIdToProxy(Constants.MODULEID__ISOLATE_LIQUIDATION));
    tsYield = Yield(tsPoolManager.moduleIdToProxy(Constants.MODULEID__YIELD));
    tsPoolLens = PoolLens(tsPoolManager.moduleIdToProxy(Constants.MODULEID__POOL_LENS));
    tsFlashLoan = FlashLoan(tsPoolManager.moduleIdToProxy(Constants.MODULEID__FLASHLOAN));
    tsUIPoolLens = UIPoolLens(tsPoolManager.moduleIdToProxy(Constants.MODULEID__UI_POOL_LENS));

    // YieldRegistry
    YieldRegistry yieldRegistryImpl = new YieldRegistry();
    TransparentUpgradeableProxy yieldRegistryImplProxy = new TransparentUpgradeableProxy(
      address(yieldRegistryImpl),
      address(tsProxyAdmin),
      abi.encodeWithSelector(yieldRegistryImpl.initialize.selector, address(tsAddressProvider))
    );
    tsYieldRegistry = YieldRegistry(payable(address(yieldRegistryImplProxy)));
    tsAddressProvider.setYieldRegistry(address(tsYieldRegistry));

    YieldAccount yieldAccountImpl = new YieldAccount();
    tsHEVM.prank(tsPoolAdmin);
    tsYieldRegistry.setYieldAccountImplementation(address(yieldAccountImpl));

    // YieldEthStakingLido
    YieldEthStakingLido yieldEthStakingLidoImpl = new YieldEthStakingLido();
    TransparentUpgradeableProxy yieldEthStakingLidoProxy = new TransparentUpgradeableProxy(
      address(yieldEthStakingLidoImpl),
      address(tsProxyAdmin),
      abi.encodeWithSelector(
        yieldEthStakingLidoImpl.initialize.selector,
        address(tsAddressProvider),
        address(tsWETH),
        address(tsStETH),
        address(tsUnstETH)
      )
    );
    tsYieldEthStakingLido = YieldEthStakingLido(payable(address(yieldEthStakingLidoProxy)));
    tsHEVM.prank(tsPoolAdmin);
    tsYieldRegistry.addYieldManager(address(tsYieldEthStakingLido));

    // YieldEthStakingEtherfi
    YieldEthStakingEtherfi yieldEthStakingEtherfiImpl = new YieldEthStakingEtherfi();
    TransparentUpgradeableProxy yieldEthStakingEtherfiProxy = new TransparentUpgradeableProxy(
      address(yieldEthStakingEtherfiImpl),
      address(tsProxyAdmin),
      abi.encodeWithSelector(
        yieldEthStakingEtherfiImpl.initialize.selector,
        address(tsAddressProvider),
        address(tsWETH),
        address(tsEtherfiLiquidityPool)
      )
    );
    tsYieldEthStakingEtherfi = YieldEthStakingEtherfi(payable(address(yieldEthStakingEtherfiProxy)));
    tsHEVM.prank(tsPoolAdmin);
    tsYieldRegistry.addYieldManager(address(tsYieldEthStakingEtherfi));

    // YieldSavingsDai
    YieldSavingsDai yieldSavingsDaiImpl = new YieldSavingsDai();
    TransparentUpgradeableProxy yieldSavingsDaiProxy = new TransparentUpgradeableProxy(
      address(yieldSavingsDaiImpl),
      address(tsProxyAdmin),
      abi.encodeWithSelector(
        yieldSavingsDaiImpl.initialize.selector,
        address(tsAddressProvider),
        address(tsDAI),
        address(tsSDAI)
      )
    );
    tsYieldSavingsDai = YieldSavingsDai(payable(address(yieldSavingsDaiProxy)));
    tsHEVM.prank(tsPoolAdmin);
    tsYieldRegistry.addYieldManager(address(tsYieldSavingsDai));

    // YieldSavingsUSDS
    YieldSavingsUSDS yieldSavingsUSDSImpl = new YieldSavingsUSDS();
    TransparentUpgradeableProxy yieldSavingsUSDSProxy = new TransparentUpgradeableProxy(
      address(yieldSavingsUSDSImpl),
      address(tsProxyAdmin),
      abi.encodeWithSelector(
        yieldSavingsUSDSImpl.initialize.selector,
        address(tsAddressProvider),
        address(tsUSDS),
        address(tsSUSDS)
      )
    );
    tsYieldSavingsUSDS = YieldSavingsUSDS(payable(address(yieldSavingsUSDSProxy)));
    tsHEVM.prank(tsPoolAdmin);
    tsYieldRegistry.addYieldManager(address(tsYieldSavingsUSDS));

    // Interest Rate Model
    tsLowRateGroupId = 1;
    tsMiddleRateGroupId = 2;
    tsHighRateGroupId = 3;

    DefaultInterestRateModel defaultIrmImpl = new DefaultInterestRateModel();
    TransparentUpgradeableProxy defaultIrmProxy = new TransparentUpgradeableProxy(
      address(defaultIrmImpl),
      address(tsProxyAdmin),
      abi.encodeWithSelector(defaultIrmImpl.initialize.selector, address(tsAddressProvider))
    );
    tsDefaultIRM = DefaultInterestRateModel(address(defaultIrmProxy));

    tsYieldRateIRM = tsDefaultIRM;
    tsLowRateIRM = tsDefaultIRM;
    tsMiddleRateIRM = tsDefaultIRM;
    tsHighRateIRM = tsDefaultIRM;

    // set price oracle
    tsHEVM.startPrank(tsOracleAdmin);
    tsPriceOracle.setBendNFTOracle(address(tsBendNFTOracle));

    address[] memory oracleAssets = new address[](8);
    oracleAssets[0] = address(tsWETH);
    oracleAssets[1] = address(tsDAI);
    oracleAssets[2] = address(tsUSDT);
    oracleAssets[3] = address(tsStETH);
    oracleAssets[4] = address(tsEETH);
    oracleAssets[5] = address(tsSDAI);
    oracleAssets[6] = address(tsUSDS);
    oracleAssets[7] = address(tsSUSDS);
    address[] memory oracleAggs = new address[](8);
    oracleAggs[0] = address(tsCLAggregatorWETH);
    oracleAggs[1] = address(tsCLAggregatorDAI);
    oracleAggs[2] = address(tsCLAggregatorUSDT);
    oracleAggs[3] = address(tsCLAggregatorStETH);
    oracleAggs[4] = address(tsCLAggregatorEETH);
    oracleAggs[5] = address(tsCLAggregatorSDAI);
    oracleAggs[6] = address(tsCLAggregatorUSDS);
    oracleAggs[7] = address(tsCLAggregatorSUSDS);
    tsPriceOracle.setAssetChainlinkAggregators(oracleAssets, oracleAggs);
    tsHEVM.stopPrank();
  }

  function initMockTokens() internal {
    tsFaucet = new MockFaucet();

    tsWETH = MockERC20(tsFaucet.createMockERC20('MockWETH', 'WETH', 18));
    tsDAI = MockERC20(tsFaucet.createMockERC20('MockDAI', 'DAI', 18));
    tsUSDT = MockERC20(tsFaucet.createMockERC20('MockUSDT', 'USDT', 6));
    tsUSDS = MockERC20(tsFaucet.createMockERC20('MockUSDS', 'USDS', 18));

    tsWPUNK = MockERC721(tsFaucet.createMockERC721('MockWPUNK', 'WPUNK'));
    tsBAYC = MockERC721(tsFaucet.createMockERC721('MockBAYC', 'BAYC'));
    tsMAYC = MockERC721(tsFaucet.createMockERC721('MockMAYC', 'MAYC'));

    tsStETH = MockStETH(payable(tsFaucet.createMockStETH()));
    tsUnstETH = MockUnstETH(payable(tsFaucet.createMockUnstETH(address(tsStETH))));
    tsHEVM.prank(address(tsFaucet));
    tsStETH.setUnstETH(address(tsUnstETH));

    tsEETH = MockeETH(payable(tsFaucet.createMockeETH()));
    tsEtherfiWithdrawRequestNFT = new MockEtherfiWithdrawRequestNFT();
    tsEtherfiLiquidityPool = new MockEtherfiLiquidityPool(address(tsEETH), address(tsEtherfiWithdrawRequestNFT));

    tsHEVM.prank(address(tsFaucet));
    tsEETH.setLiquidityPool(address(tsEtherfiLiquidityPool));
    tsEtherfiWithdrawRequestNFT.setLiquidityPool(address(tsEtherfiLiquidityPool), address(tsEETH));

    tsDAIPot = new MockDAIPot();
    tsSDAI = new MockSDAI(address(tsDAI));

    tsSUSDS = new MockSUSDS(address(tsUSDS));

    tsDelegateRegistryV2 = new MockDelegateRegistryV2();
  }

  function initMockUsers() internal {
    uint256 baseUid;

    // depositors
    baseUid = 1;
    for (uint256 i = 0; i < 3; i++) {
      uint256 uid = ((i + 1) * 100);
      tsDepositors.push(new TestUser(tsPoolManager, uid));
      tsHEVM.label(address(tsDepositors[i]), string(abi.encodePacked('Depositor', Strings.toString(i + baseUid))));
      fillUserBalances(tsDepositors[i]);
    }
    tsDepositor1 = tsDepositors[0];
    tsDepositor2 = tsDepositors[1];
    tsDepositor3 = tsDepositors[2];

    // borrowers
    baseUid += 3;
    for (uint256 i = 0; i < 3; i++) {
      uint256 uid = ((i + baseUid) * 100);
      tsBorrowers.push(new TestUser(tsPoolManager, uid));
      tsHEVM.label(address(tsBorrowers[i]), string(abi.encodePacked('Borrower', Strings.toString(i + baseUid))));
      fillUserBalances(tsBorrowers[i]);
    }
    tsBorrower1 = tsBorrowers[0];
    tsBorrower2 = tsBorrowers[1];
    tsBorrower3 = tsBorrowers[2];

    // liquidators
    baseUid += 3;
    for (uint256 i = 0; i < 3; i++) {
      uint256 uid = ((i + baseUid) * 100);
      tsLiquidators.push(new TestUser(tsPoolManager, uid));
      tsHEVM.label(address(tsLiquidators[i]), string(abi.encodePacked('Liquidator', Strings.toString(i + baseUid))));
      fillUserBalances(tsLiquidators[i]);
    }
    tsLiquidator1 = tsLiquidators[0];
    tsLiquidator2 = tsLiquidators[1];
    tsLiquidator3 = tsLiquidators[2];

    // stakers
    baseUid += 3;
    for (uint256 i = 0; i < 3; i++) {
      uint256 uid = ((i + baseUid) * 100);
      tsStakers.push(new TestUser(tsPoolManager, uid));
      tsHEVM.label(address(tsStakers[i]), string(abi.encodePacked('Staker', Strings.toString(i + baseUid))));
      fillUserBalances(tsStakers[i]);
    }
    tsStaker1 = tsStakers[0];
    tsStaker2 = tsStakers[1];
    tsStaker3 = tsStakers[2];

    // hackers
    baseUid += 3;
    for (uint256 i = 0; i < 1; i++) {
      uint256 uid = ((i + baseUid) * 100);
      tsHackers.push(new TestUser(tsPoolManager, uid));
      tsHEVM.label(address(tsHackers[i]), string(abi.encodePacked('Hacker', Strings.toString(i + baseUid))));
      fillUserBalances(tsHackers[i]);
    }
    tsHacker1 = tsHackers[0];
  }

  function fillUserBalances(TestUser user) internal {
    tsHEVM.deal(address(user), 2_000_000 ether);

    tsHEVM.prank(address(user));
    IWETH(address(tsWETH)).deposit{value: TS_INITIAL_BALANCE * 1e18}();
    //tsFaucet.privateMintERC20(address(tsWETH), address(user), TS_INITIAL_BALANCE * 1e18);

    tsFaucet.privateMintERC20(address(tsDAI), address(user), TS_INITIAL_BALANCE * 1e18);
    tsFaucet.privateMintERC20(address(tsUSDT), address(user), TS_INITIAL_BALANCE * 1e6);
    tsFaucet.privateMintERC20(address(tsUSDS), address(user), TS_INITIAL_BALANCE * 1e18);

    uint256[] memory tokenIds = user.getTokenIds();
    tsFaucet.privateMintERC721(address(tsWPUNK), address(user), tokenIds);
    tsFaucet.privateMintERC721(address(tsBAYC), address(user), tokenIds);
    tsFaucet.privateMintERC721(address(tsMAYC), address(user), tokenIds);
  }

  function initMockOracles() internal {
    tsCLAggregatorWETH = new MockChainlinkAggregator(8, 'ETH / USD');
    tsHEVM.label(address(tsCLAggregatorWETH), 'MockCLAggregator(ETH/USD)');
    tsCLAggregatorWETH.updateAnswer(206066569863);

    tsCLAggregatorDAI = new MockChainlinkAggregator(8, 'DAI / USD');
    tsHEVM.label(address(tsCLAggregatorDAI), 'MockCLAggregator(DAI/USD)');
    tsCLAggregatorDAI.updateAnswer(99984627);

    tsCLAggregatorUSDS = new MockChainlinkAggregator(8, 'USDS / USD');
    tsHEVM.label(address(tsCLAggregatorUSDS), 'MockCLAggregator(USDS/USD)');
    tsCLAggregatorUSDS.updateAnswer(99984627);

    tsCLAggregatorUSDT = new MockChainlinkAggregator(8, 'USDT / USD');
    tsHEVM.label(address(tsCLAggregatorUSDT), 'MockCLAggregator(USDT/USD)');
    tsCLAggregatorUSDT.updateAnswer(100053000);

    tsCLAggregatorStETH = new MockChainlinkAggregator(8, 'stETH / USD');
    tsHEVM.label(address(tsCLAggregatorStETH), 'MockCLAggregator(StETH/USD)');
    tsCLAggregatorStETH.updateAnswer(204005904164);

    tsCLAggregatorEETH = new MockChainlinkAggregator(8, 'eETH / USD');
    tsHEVM.label(address(tsCLAggregatorEETH), 'MockCLAggregator(eETH/USD)');
    tsCLAggregatorEETH.updateAnswer(203005904164);

    tsCLAggregatorSDAI = new SDAIPriceAdapter(address(tsCLAggregatorDAI), address(tsDAIPot), 'sDAI / USD');
    tsHEVM.label(address(tsCLAggregatorSDAI), 'SDAIPriceAdapter(sDAI/USD)');

    tsCLAggregatorSUSDS = new SUSDSPriceAdapter(address(tsCLAggregatorDAI), address(tsDAIPot), 'sUSDS / USD');
    tsHEVM.label(address(tsCLAggregatorSUSDS), 'SUSDSPriceAdapter(sUSDS/USD)');

    tsBendNFTOracle = new MockBendNFTOracle();
    tsHEVM.label(address(tsBendNFTOracle), 'MockBendNFTOracle');
    tsBendNFTOracle.setAssetPrice(address(tsWPUNK), 58155486904761904761);
    tsBendNFTOracle.setAssetPrice(address(tsBAYC), 30919141261229331011);
    tsBendNFTOracle.setAssetPrice(address(tsMAYC), 5950381013403414953);
  }

  function setContractsLabels() internal {
    tsHEVM.label(address(tsWETH), 'WETH');
    tsHEVM.label(address(tsDAI), 'DAI');
    tsHEVM.label(address(tsUSDT), 'USDT');
    tsHEVM.label(address(tsWPUNK), 'WPUNK');
    tsHEVM.label(address(tsBAYC), 'BAYC');
    tsHEVM.label(address(tsMAYC), 'MAYC');

    tsHEVM.label(address(tsAclManager), 'AclManager');
    tsHEVM.label(address(tsPriceOracle), 'PriceOracle');
    tsHEVM.label(address(tsPoolManager), 'PoolManager');

    tsHEVM.label(address(tsDefaultIRM), 'DefaultIRM');
  }

  function initInterestRateParams() internal {
    tsHEVM.startPrank(tsPoolAdmin);

    uint32 poolId = 1;

    // WETH
    tsDefaultIRM.setInterestRateParams(
      poolId,
      address(tsWETH),
      0,
      (65 * WadRayMath.RAY) / 100,
      (1 * WadRayMath.RAY) / 100, // baseRate
      (5 * WadRayMath.RAY) / 100,
      (100 * WadRayMath.RAY) / 100
    );
    tsDefaultIRM.setInterestRateParams(
      poolId,
      address(tsWETH),
      tsLowRateGroupId,
      (65 * WadRayMath.RAY) / 100,
      (3 * WadRayMath.RAY) / 100, // baseRate
      (5 * WadRayMath.RAY) / 100,
      (100 * WadRayMath.RAY) / 100
    );
    tsDefaultIRM.setInterestRateParams(
      poolId,
      address(tsWETH),
      tsMiddleRateGroupId,
      (65 * WadRayMath.RAY) / 100,
      (5 * WadRayMath.RAY) / 100, // baseRate
      (5 * WadRayMath.RAY) / 100,
      (100 * WadRayMath.RAY) / 100
    );
    tsDefaultIRM.setInterestRateParams(
      poolId,
      address(tsWETH),
      tsHighRateGroupId,
      (65 * WadRayMath.RAY) / 100,
      (7 * WadRayMath.RAY) / 100, // baseRate
      (5 * WadRayMath.RAY) / 100,
      (100 * WadRayMath.RAY) / 100
    );

    // USDT
    tsDefaultIRM.setInterestRateParams(
      poolId,
      address(tsUSDT),
      0,
      (65 * WadRayMath.RAY) / 100,
      (3 * WadRayMath.RAY) / 100, // baseRate
      (3 * WadRayMath.RAY) / 100,
      (80 * WadRayMath.RAY) / 100
    );
    tsDefaultIRM.setInterestRateParams(
      poolId,
      address(tsUSDT),
      tsLowRateGroupId,
      (65 * WadRayMath.RAY) / 100,
      (5 * WadRayMath.RAY) / 100, // baseRate
      (3 * WadRayMath.RAY) / 100,
      (80 * WadRayMath.RAY) / 100
    );
    tsDefaultIRM.setInterestRateParams(
      poolId,
      address(tsUSDT),
      tsMiddleRateGroupId,
      (65 * WadRayMath.RAY) / 100,
      (7 * WadRayMath.RAY) / 100, // baseRate
      (3 * WadRayMath.RAY) / 100,
      (80 * WadRayMath.RAY) / 100
    );
    tsDefaultIRM.setInterestRateParams(
      poolId,
      address(tsUSDT),
      tsHighRateGroupId,
      (65 * WadRayMath.RAY) / 100,
      (9 * WadRayMath.RAY) / 100, // baseRate
      (3 * WadRayMath.RAY) / 100,
      (80 * WadRayMath.RAY) / 100
    );

    // DAI
    tsDefaultIRM.setInterestRateParams(
      poolId,
      address(tsDAI),
      0,
      (65 * WadRayMath.RAY) / 100,
      (2 * WadRayMath.RAY) / 100, // baseRate
      (5 * WadRayMath.RAY) / 100,
      (90 * WadRayMath.RAY) / 100
    );
    tsDefaultIRM.setInterestRateParams(
      poolId,
      address(tsDAI),
      tsLowRateGroupId,
      (65 * WadRayMath.RAY) / 100,
      (4 * WadRayMath.RAY) / 100, // baseRate
      (5 * WadRayMath.RAY) / 100,
      (90 * WadRayMath.RAY) / 100
    );
    tsDefaultIRM.setInterestRateParams(
      poolId,
      address(tsDAI),
      tsMiddleRateGroupId,
      (65 * WadRayMath.RAY) / 100,
      (6 * WadRayMath.RAY) / 100, // baseRate
      (5 * WadRayMath.RAY) / 100,
      (90 * WadRayMath.RAY) / 100
    );
    tsDefaultIRM.setInterestRateParams(
      poolId,
      address(tsDAI),
      tsHighRateGroupId,
      (65 * WadRayMath.RAY) / 100,
      (8 * WadRayMath.RAY) / 100, // baseRate
      (5 * WadRayMath.RAY) / 100,
      (90 * WadRayMath.RAY) / 100
    );

    // USDS
    tsDefaultIRM.setInterestRateParams(
      poolId,
      address(tsUSDS),
      0,
      (65 * WadRayMath.RAY) / 100,
      (2 * WadRayMath.RAY) / 100, // baseRate
      (5 * WadRayMath.RAY) / 100,
      (90 * WadRayMath.RAY) / 100
    );
    tsDefaultIRM.setInterestRateParams(
      poolId,
      address(tsUSDS),
      tsLowRateGroupId,
      (65 * WadRayMath.RAY) / 100,
      (4 * WadRayMath.RAY) / 100, // baseRate
      (5 * WadRayMath.RAY) / 100,
      (90 * WadRayMath.RAY) / 100
    );
    tsDefaultIRM.setInterestRateParams(
      poolId,
      address(tsUSDS),
      tsMiddleRateGroupId,
      (65 * WadRayMath.RAY) / 100,
      (6 * WadRayMath.RAY) / 100, // baseRate
      (5 * WadRayMath.RAY) / 100,
      (90 * WadRayMath.RAY) / 100
    );
    tsDefaultIRM.setInterestRateParams(
      poolId,
      address(tsUSDS),
      tsHighRateGroupId,
      (65 * WadRayMath.RAY) / 100,
      (8 * WadRayMath.RAY) / 100, // baseRate
      (5 * WadRayMath.RAY) / 100,
      (90 * WadRayMath.RAY) / 100
    );

    tsHEVM.stopPrank();
  }

  function initCommonPools() internal {
    tsHEVM.startPrank(tsPoolAdmin);

    tsCommonPoolId = tsConfiguratorPool.createPool('Common Pool');

    tsConfiguratorPool.addPoolGroup(tsCommonPoolId, tsLowRateGroupId);
    tsConfiguratorPool.addPoolGroup(tsCommonPoolId, tsMiddleRateGroupId);
    tsConfiguratorPool.addPoolGroup(tsCommonPoolId, tsHighRateGroupId);

    // asset some erc20 assets
    tsConfigurator.addAssetERC20(tsCommonPoolId, address(tsWETH));
    tsConfigurator.setAssetCollateralParams(tsCommonPoolId, address(tsWETH), 8050, 8300, 500);
    tsConfigurator.setAssetProtocolFee(tsCommonPoolId, address(tsWETH), 2000);
    tsConfigurator.setAssetClassGroup(tsCommonPoolId, address(tsWETH), tsLowRateGroupId);
    tsConfigurator.setAssetActive(tsCommonPoolId, address(tsWETH), true);
    tsConfigurator.setAssetBorrowing(tsCommonPoolId, address(tsWETH), true);
    tsConfigurator.setAssetSupplyCap(tsCommonPoolId, address(tsWETH), 100_000_000 * (10 ** tsWETH.decimals()));
    tsConfigurator.setAssetBorrowCap(tsCommonPoolId, address(tsWETH), 100_000_000 * (10 ** tsWETH.decimals()));

    tsConfigurator.addAssetERC20(tsCommonPoolId, address(tsDAI));
    tsConfigurator.setAssetCollateralParams(tsCommonPoolId, address(tsDAI), 7700, 8000, 500);
    tsConfigurator.setAssetProtocolFee(tsCommonPoolId, address(tsDAI), 2000);
    tsConfigurator.setAssetClassGroup(tsCommonPoolId, address(tsDAI), tsLowRateGroupId);
    tsConfigurator.setAssetActive(tsCommonPoolId, address(tsDAI), true);
    tsConfigurator.setAssetBorrowing(tsCommonPoolId, address(tsDAI), true);
    tsConfigurator.setAssetSupplyCap(tsCommonPoolId, address(tsDAI), 100_000_000 * (10 ** tsWETH.decimals()));
    tsConfigurator.setAssetBorrowCap(tsCommonPoolId, address(tsDAI), 100_000_000 * (10 ** tsWETH.decimals()));

    tsConfigurator.addAssetERC20(tsCommonPoolId, address(tsUSDT));
    tsConfigurator.setAssetCollateralParams(tsCommonPoolId, address(tsUSDT), 7400, 7600, 450);
    tsConfigurator.setAssetProtocolFee(tsCommonPoolId, address(tsUSDT), 2000);
    tsConfigurator.setAssetClassGroup(tsCommonPoolId, address(tsUSDT), tsLowRateGroupId);
    tsConfigurator.setAssetActive(tsCommonPoolId, address(tsUSDT), true);
    tsConfigurator.setAssetBorrowing(tsCommonPoolId, address(tsUSDT), true);
    tsConfigurator.setAssetSupplyCap(tsCommonPoolId, address(tsUSDT), 100_000_000 * (10 ** tsWETH.decimals()));
    tsConfigurator.setAssetBorrowCap(tsCommonPoolId, address(tsUSDT), 100_000_000 * (10 ** tsWETH.decimals()));

    tsConfigurator.addAssetERC20(tsCommonPoolId, address(tsUSDS));
    tsConfigurator.setAssetCollateralParams(tsCommonPoolId, address(tsUSDS), 7700, 8000, 500);
    tsConfigurator.setAssetProtocolFee(tsCommonPoolId, address(tsUSDS), 2000);
    tsConfigurator.setAssetClassGroup(tsCommonPoolId, address(tsUSDS), tsLowRateGroupId);
    tsConfigurator.setAssetActive(tsCommonPoolId, address(tsUSDS), true);
    tsConfigurator.setAssetBorrowing(tsCommonPoolId, address(tsUSDS), true);
    tsConfigurator.setAssetSupplyCap(tsCommonPoolId, address(tsUSDS), 100_000_000 * (10 ** tsWETH.decimals()));
    tsConfigurator.setAssetBorrowCap(tsCommonPoolId, address(tsUSDS), 100_000_000 * (10 ** tsWETH.decimals()));

    // add interest group to assets
    tsConfigurator.addAssetGroup(tsCommonPoolId, address(tsWETH), tsLowRateGroupId, address(tsLowRateIRM));
    tsConfigurator.addAssetGroup(tsCommonPoolId, address(tsWETH), tsHighRateGroupId, address(tsHighRateIRM));

    tsConfigurator.addAssetGroup(tsCommonPoolId, address(tsDAI), tsLowRateGroupId, address(tsLowRateIRM));
    tsConfigurator.addAssetGroup(tsCommonPoolId, address(tsDAI), tsHighRateGroupId, address(tsHighRateIRM));

    tsConfigurator.addAssetGroup(tsCommonPoolId, address(tsUSDS), tsLowRateGroupId, address(tsLowRateIRM));
    tsConfigurator.addAssetGroup(tsCommonPoolId, address(tsUSDS), tsHighRateGroupId, address(tsHighRateIRM));

    tsConfigurator.addAssetGroup(tsCommonPoolId, address(tsUSDT), tsLowRateGroupId, address(tsLowRateIRM));
    tsConfigurator.addAssetGroup(tsCommonPoolId, address(tsUSDT), tsHighRateGroupId, address(tsHighRateIRM));

    // add some nft assets
    tsConfigurator.addAssetERC721(tsCommonPoolId, address(tsWPUNK));
    tsConfigurator.setAssetCollateralParams(tsCommonPoolId, address(tsWPUNK), 6000, 8000, 1000);
    tsConfigurator.setAssetAuctionParams(tsCommonPoolId, address(tsWPUNK), 5000, 500, 2000, 1 days);
    tsConfigurator.setAssetClassGroup(tsCommonPoolId, address(tsWPUNK), tsLowRateGroupId);
    tsConfigurator.setAssetActive(tsCommonPoolId, address(tsWPUNK), true);
    tsConfigurator.setAssetSupplyCap(tsCommonPoolId, address(tsWPUNK), 10_000);

    tsConfigurator.addAssetERC721(tsCommonPoolId, address(tsBAYC));
    tsConfigurator.setAssetCollateralParams(tsCommonPoolId, address(tsBAYC), 6000, 8000, 1000);
    tsConfigurator.setAssetAuctionParams(tsCommonPoolId, address(tsBAYC), 5000, 500, 2000, 1 days);
    tsConfigurator.setAssetClassGroup(tsCommonPoolId, address(tsBAYC), tsLowRateGroupId);
    tsConfigurator.setAssetActive(tsCommonPoolId, address(tsBAYC), true);
    tsConfigurator.setAssetSupplyCap(tsCommonPoolId, address(tsBAYC), 10_000);

    tsConfigurator.addAssetERC721(tsCommonPoolId, address(tsMAYC));
    tsConfigurator.setAssetCollateralParams(tsCommonPoolId, address(tsMAYC), 5000, 8000, 1000);
    tsConfigurator.setAssetAuctionParams(tsCommonPoolId, address(tsMAYC), 5000, 500, 2000, 1 days);
    tsConfigurator.setAssetClassGroup(tsCommonPoolId, address(tsMAYC), tsHighRateGroupId);
    tsConfigurator.setAssetActive(tsCommonPoolId, address(tsMAYC), true);
    tsConfigurator.setAssetSupplyCap(tsCommonPoolId, address(tsMAYC), 10_000);

    // yield
    tsConfiguratorPool.setPoolYieldEnable(tsCommonPoolId, true);

    tsConfigurator.setAssetYieldEnable(tsCommonPoolId, address(tsWETH), true);
    tsConfigurator.setAssetYieldCap(tsCommonPoolId, address(tsWETH), 2000);
    tsConfigurator.setAssetYieldRate(tsCommonPoolId, address(tsWETH), address(tsYieldRateIRM));
    tsConfigurator.setManagerYieldCap(tsCommonPoolId, address(tsPoolManager), address(tsWETH), 2000);
    tsConfigurator.setManagerYieldCap(tsCommonPoolId, address(tsStaker1), address(tsWETH), 2000);

    tsConfigurator.setAssetYieldEnable(tsCommonPoolId, address(tsDAI), true);
    tsConfigurator.setAssetYieldCap(tsCommonPoolId, address(tsDAI), 2000);
    tsConfigurator.setAssetYieldRate(tsCommonPoolId, address(tsDAI), address(tsYieldRateIRM));
    tsConfigurator.setManagerYieldCap(tsCommonPoolId, address(tsPoolManager), address(tsDAI), 2000);
    tsConfigurator.setManagerYieldCap(tsCommonPoolId, address(tsStaker2), address(tsDAI), 2000);

    tsConfigurator.setAssetYieldEnable(tsCommonPoolId, address(tsUSDS), true);
    tsConfigurator.setAssetYieldCap(tsCommonPoolId, address(tsUSDS), 2000);
    tsConfigurator.setAssetYieldRate(tsCommonPoolId, address(tsUSDS), address(tsYieldRateIRM));
    tsConfigurator.setManagerYieldCap(tsCommonPoolId, address(tsPoolManager), address(tsUSDS), 2000);
    tsConfigurator.setManagerYieldCap(tsCommonPoolId, address(tsStaker2), address(tsUSDS), 2000);

    tsHEVM.stopPrank();
  }

  function initYieldEthStaking() internal {
    tsHEVM.startPrank(tsPoolAdmin);

    tsConfigurator.setManagerYieldCap(tsCommonPoolId, address(tsYieldEthStakingLido), address(tsWETH), 2000);
    tsConfigurator.setManagerYieldCap(tsCommonPoolId, address(tsYieldEthStakingEtherfi), address(tsWETH), 2000);
    tsConfigurator.setManagerYieldCap(tsCommonPoolId, address(tsYieldSavingsDai), address(tsDAI), 2000);
    tsConfigurator.setManagerYieldCap(tsCommonPoolId, address(tsYieldSavingsUSDS), address(tsUSDS), 2000);

    tsYieldEthStakingLido.setNftActive(address(tsBAYC), true);
    tsYieldEthStakingLido.setNftStakeParams(address(tsBAYC), 50000, 9000);
    tsYieldEthStakingLido.setNftUnstakeParams(address(tsBAYC), 0.01 ether, 1.05e18);

    tsYieldEthStakingEtherfi.setNftActive(address(tsBAYC), true);
    tsYieldEthStakingEtherfi.setNftStakeParams(address(tsBAYC), 20000, 9000);
    tsYieldEthStakingEtherfi.setNftUnstakeParams(address(tsBAYC), 0.01 ether, 1.05e18);

    tsYieldSavingsDai.setNftActive(address(tsBAYC), true);
    tsYieldSavingsDai.setNftStakeParams(address(tsBAYC), 50000, 9000);
    tsYieldSavingsDai.setNftUnstakeParams(address(tsBAYC), 100e18, 1.05e18);

    tsYieldSavingsUSDS.setNftActive(address(tsBAYC), true);
    tsYieldSavingsUSDS.setNftStakeParams(address(tsBAYC), 50000, 9000);
    tsYieldSavingsUSDS.setNftUnstakeParams(address(tsBAYC), 100e18, 1.05e18);

    tsHEVM.stopPrank();
  }
}
