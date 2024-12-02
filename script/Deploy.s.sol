// SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "forge-std/Script.sol";
import "src/BondingCurve.sol";

contract BondingCurveDeploy is Script {
    /// @dev : Deploy
    function run() external {
        vm.startBroadcast();
        new BondingCurve("BondingCurveMock", "BCM", msg.sender);
        vm.stopBroadcast();
    }
}
