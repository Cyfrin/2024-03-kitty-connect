// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {KittyConnect} from "../src/KittyConnect.sol";
import {KittyBridge} from "../src/KittyBridge.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/contracts/token/ERC20/IERC20.sol";

contract DeployKittyConnect is Script {
    function run() external returns (KittyConnect, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig.getNetworkConfig();
        KittyBridge kittyBridge;
        uint256 linkBalance = 8 ether;   // 8 link

        vm.startBroadcast();

        KittyConnect kittyConnect =
        new KittyConnect(networkConfig.initShopPartners, networkConfig.router, networkConfig.link);

        kittyBridge = KittyBridge(kittyConnect.getKittyBridge());
        kittyBridge.allowlistDestinationChain(networkConfig.otherChainSelector, true);
        kittyBridge.allowlistSourceChain(networkConfig.otherChainSelector, true);
        
        IERC20(networkConfig.link).transfer(address(kittyBridge), linkBalance);

        vm.stopBroadcast();

        return (kittyConnect, helperConfig);
    }
}
