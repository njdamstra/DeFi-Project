// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Strings.sol';

import 'bend-code/test/setup/TestWithSetup.sol';
import 'bend-code/lib/forge-std-f73c73d2018eb6a111f35e4dae7b4f27401e9421/src/Test.sol';

contract TestACLManager is TestWithSetup {
  function test_RevertIf_CallerNotAdmin() public {
    bytes memory errorMsg = abi.encodePacked(
      'AccessControl: account ',
      Strings.toHexString(address(tsHacker1)),
      ' is missing role ',
      Strings.toHexString(uint256(0x00), 32)
    );

    // pool admin
    tsHEVM.expectRevert(errorMsg);
    tsHEVM.prank(address(tsHacker1));
    tsAclManager.addPoolAdmin(address(tsHacker1));

    tsHEVM.expectRevert(errorMsg);
    tsHEVM.prank(address(tsHacker1));
    tsAclManager.removePoolAdmin(address(tsHacker1));

    // emergency admin
    tsHEVM.expectRevert(errorMsg);
    tsHEVM.prank(address(tsHacker1));
    tsAclManager.addEmergencyAdmin(address(tsHacker1));

    tsHEVM.expectRevert(errorMsg);
    tsHEVM.prank(address(tsHacker1));
    tsAclManager.removeEmergencyAdmin(address(tsHacker1));

    // oracle admin
    tsHEVM.expectRevert(errorMsg);
    tsHEVM.prank(address(tsHacker1));
    tsAclManager.addOracleAdmin(address(tsHacker1));

    tsHEVM.expectRevert(errorMsg);
    tsHEVM.prank(address(tsHacker1));
    tsAclManager.removeOracleAdmin(address(tsHacker1));
  }

  function test_Should_PoolAdmin() public {
    address newAdmin = address(tsDepositor1);

    tsHEVM.startPrank(tsAclAdmin);

    tsAclManager.addPoolAdmin(newAdmin);
    assertEq(tsAclManager.isPoolAdmin(newAdmin), true, 'newAdmin should added');

    tsAclManager.removePoolAdmin(newAdmin);
    assertEq(tsAclManager.isPoolAdmin(newAdmin), false, 'newAdmin should removed');

    tsHEVM.stopPrank();
  }

  function test_Should_EmergencyAdmin() public {
    address newAdmin = address(tsDepositor1);

    tsHEVM.startPrank(tsAclAdmin);

    tsAclManager.addEmergencyAdmin(newAdmin);
    assertEq(tsAclManager.isEmergencyAdmin(newAdmin), true, 'newAdmin should added');

    tsAclManager.removeEmergencyAdmin(newAdmin);
    assertEq(tsAclManager.isEmergencyAdmin(newAdmin), false, 'newAdmin should removed');

    tsHEVM.stopPrank();
  }

  function test_Should_OracleAdmin() public {
    address newAdmin = address(tsDepositor1);

    tsHEVM.startPrank(tsAclAdmin);

    tsAclManager.addOracleAdmin(newAdmin);
    assertEq(tsAclManager.isOracleAdmin(newAdmin), true, 'newAdmin should added');

    tsAclManager.removeOracleAdmin(newAdmin);
    assertEq(tsAclManager.isOracleAdmin(newAdmin), false, 'newAdmin should removed');

    tsHEVM.stopPrank();
  }
}
