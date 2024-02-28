// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { Script } from "forge-std/Script.sol";
import { MockLinkToken } from "@chainlink/contracts-ccip/src/v0.8/mocks/MockLinkToken.sol";

contract HelperConfig is Script {
    struct NetworkConfig{
        address[] initShopPartners;
        address router;
        address link;
        uint64 chainSelector;
        uint64 otherChainSelector;
    }

    NetworkConfig private networkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            networkConfig = getSepoliaConfig();
        }
        else if (block.chainid == 43113) {
            networkConfig = getFujiConfig();
        }
        else {
            networkConfig = getAnvilConfig();
        }
    }

    function getSepoliaConfig() internal pure returns (NetworkConfig memory) {
        address[] memory shopPartners = new address[](2);
        shopPartners[0] = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        shopPartners[1] = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

        return NetworkConfig({
            initShopPartners: shopPartners,
            router: 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            chainSelector: 16015286601757825753,
            otherChainSelector: 14767482510784806043
        });
    }

    function getFujiConfig() internal pure returns (NetworkConfig memory) {
        address[] memory shopPartners = new address[](2);
        shopPartners[0] = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        shopPartners[1] = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

        return NetworkConfig({
            initShopPartners: shopPartners,
            router: 0xF694E193200268f9a4868e4Aa017A0118C9a8177,
            link: 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846,
            chainSelector: 14767482510784806043,
            otherChainSelector: 16015286601757825753
        });
    }

    function getAnvilConfig() internal returns (NetworkConfig memory) {
        address[] memory shopPartners = new address[](2);
        shopPartners[0] = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
        shopPartners[1] = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;

        vm.startBroadcast();

        MockLinkToken mockLinkToken = new MockLinkToken();

        vm.stopBroadcast();

        return NetworkConfig({
            initShopPartners: shopPartners,
            router: 0xD0daae2231E9CB96b94C8512223533293C3693Bf,
            link: address(mockLinkToken),
            chainSelector: 16015286601757825753,
            otherChainSelector: 14767482510784806043
        });
    }

    function getNetworkConfig() external view returns (NetworkConfig memory) {
        return networkConfig;
    }
}