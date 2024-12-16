// SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "forge-std/Script.sol";
import "src/BondingCurve.sol";

contract BondingCurveDeploy is Script {
    uint32 constant RESERVE_RATIO = 333333; // 1/3 in ppm (parts per million)

    function run() external {
        address deployer = msg.sender;
        vm.startBroadcast();
        new BondingCurve(
            "BondingCurveMock",
            "BCM",
            RESERVE_RATIO,
            deployer // dev account for fees
        );
        vm.stopBroadcast();
    }
}
