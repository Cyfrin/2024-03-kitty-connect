// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { Test, console } from "forge-std/Test.sol";
import { DeployKittyConnect } from "../script/DeployKittyConnect.s.sol";
import { HelperConfig } from "../script/HelperConfig.s.sol";
import { KittyConnect } from "../src/KittyConnect.sol";
import { KittyBridge, KittyBridgeBase, Client } from "../src/KittyBridge.sol";

contract KittyTest is Test {
    KittyConnect kittyConnect;
    KittyBridge kittyBridge;
    HelperConfig helperConfig;
    HelperConfig.NetworkConfig networkConfig;
    address kittyConnectOwner;
    address partnerA;
    address partnerB;
    address user;
    address ethUsdPriceFeed;

    event ShopPartnerAdded(address partner);
    event CatMinted(uint256 tokenId, string catIpfsHash);
    event TokensRedeemedForVetVisit(uint256 tokenId, uint256 amount, string remarks);
    event CatTransferredToNewOwner(address prevOwner, address newOwner, uint256 tokenId);

    function setUp() external {
        DeployKittyConnect deployer = new DeployKittyConnect();
        
        (kittyConnect, helperConfig) = deployer.run();
        networkConfig = helperConfig.getNetworkConfig();

        kittyConnectOwner = kittyConnect.getKittyConnectOwner();
        partnerA = kittyConnect.getKittyShopAtIdx(0);
        partnerB = kittyConnect.getKittyShopAtIdx(1);
        kittyBridge = KittyBridge(kittyConnect.getKittyBridge());
        user = makeAddr("user");
    }

    function testConstructor() public {
        address[] memory partners = networkConfig.initShopPartners;

        assertEq(partnerA, partners[0]);
        assertEq(partnerB, partners[1]);
        assert(kittyConnect.getIsKittyPartnerShop(partnerA) == true);
    }

    function test_onlyShopPartnersCanAllocateCatToUsers() public {
        address someUser = makeAddr("someUser");
        string memory catImageIpfsHash = "ipfs://QmbxwGgBGrNdXPm84kqYskmcMT3jrzBN8LzQjixvkz4c62";

        vm.expectRevert("KittyConnect__NotAPartner");
        vm.prank(someUser);
        kittyConnect.mintCatToNewOwner(user, catImageIpfsHash, "Hehe", "Hehe", block.timestamp);
    }

    function test_mintCatToNewOwnerIfCatOwnerIsShopPartner() public {
        string memory catImageIpfsHash = "ipfs://QmbxwGgBGrNdXPm84kqYskmcMT3jrzBN8LzQjixvkz4c62";

        vm.expectRevert("KittyConnect__CatOwnerCantBeShopPartner");
        vm.prank(partnerA);
        kittyConnect.mintCatToNewOwner(partnerB, catImageIpfsHash, "Hehe", "Hehe", block.timestamp);
    }
    
    function test_ShopPartnerGivesCatToCustomer() public {
        string memory catImageIpfsHash = "ipfs://QmbxwGgBGrNdXPm84kqYskmcMT3jrzBN8LzQjixvkz4c62";
        vm.warp(block.timestamp + 10 weeks);

        uint256 tokenId = kittyConnect.getTokenCounter();

        vm.expectEmit(false, false, false, true);
        emit CatMinted(tokenId, catImageIpfsHash);
        vm.prank(partnerA);
        kittyConnect.mintCatToNewOwner(user, catImageIpfsHash, "Meowdy", "Ragdoll", block.timestamp - 3 weeks);

        string memory tokenUri = kittyConnect.tokenURI(tokenId);
        console.log(tokenUri);
        KittyConnect.CatInfo memory catInfo = kittyConnect.getCatInfo(tokenId);
        uint256[] memory userCatTokenId = kittyConnect.getCatsTokenIdOwnedBy(user);

        assertEq(kittyConnect.ownerOf(tokenId), user);
        assertEq(kittyConnect.getTokenCounter(), tokenId + 1);
        assertEq(userCatTokenId[0], tokenId);
        assertEq(catInfo.catName, "Meowdy");
        assertEq(catInfo.breed, "Ragdoll");
        assertEq(catInfo.image, catImageIpfsHash);
        assertEq(catInfo.dob, block.timestamp - 3 weeks);
        assertEq(catInfo.shopPartner, partnerA);
        assertEq(catInfo.idx, 0);
    }

    function test_getCatAge() public {
        string memory catImageIpfsHash = "ipfs://QmbxwGgBGrNdXPm84kqYskmcMT3jrzBN8LzQjixvkz4c62";
        uint256 tokenId = kittyConnect.getTokenCounter();

        vm.prank(partnerA);
        kittyConnect.mintCatToNewOwner(user, catImageIpfsHash, "Meowdy", "Ragdoll", block.timestamp);
        
        vm.warp(block.timestamp + 10 weeks);
        vm.prank(user);
        uint256 catAge = kittyConnect.getCatAge(tokenId);

        assertEq(catAge, 10 weeks);
    }

    function test_onlyKittyConnectOwnerCanAddNewPartnerShop() public {
        address partnerC = makeAddr("partnerC");

        vm.prank(kittyConnectOwner);
        kittyConnect.addShop(partnerC);

        assertEq(kittyConnect.getKittyShopAtIdx(2), partnerC);
    }

    function test_revertsIfCallerIsNotKittyConnectOwner() public {
        address partnerC = makeAddr("partnerC");

        vm.expectRevert("KittyConnect__NotKittyConnectOwner");
        vm.prank(partnerC);
        kittyConnect.addShop(partnerC);
    }

    function test_tokenURI() public {
        string memory catImageIpfsHash = "ipfs://QmbxwGgBGrNdXPm84kqYskmcMT3jrzBN8LzQjixvkz4c62";
        string memory expectedTokenURI = "data:application/json;base64,eyJuYW1lIjogTWVvd2R5IiwgImJyZWVkIjogUmFnZG9sbCIsICJpbWFnZSI6IGlwZnM6Ly9RbWJ4d0dnQkdyTmRYUG04NGtxWXNrbWNNVDNqcnpCTjhMelFqaXh2a3o0YzYyIiwgImRvYiI6IDEsICJvd25lciI6IDB4NmNhNmQxZTJkNTM0N2JmYWIxZDkxZTg4M2YxOTE1NTYwZTA5MTI5ZCIsICJzaG9wUGFydG5lciI6IDB4NzA5OTc5NzBjNTE4MTJkYzNhMDEwYzdkMDFiNTBlMGQxN2RjNzljOCJ9";
        uint256 tokenId = kittyConnect.getTokenCounter();
        vm.prank(partnerA);
        kittyConnect.mintCatToNewOwner(user, catImageIpfsHash, "Meowdy", "Ragdoll", block.timestamp);

        string memory tokenUri = kittyConnect.tokenURI(tokenId);

        assertEq(tokenUri, expectedTokenURI);
    }

    modifier partnerGivesCatToOwner() {
        string memory catImageIpfsHash = "ipfs://QmbxwGgBGrNdXPm84kqYskmcMT3jrzBN8LzQjixvkz4c62";

        // Shop Partner gives Cat to user
        vm.prank(partnerA);
        kittyConnect.mintCatToNewOwner(user, catImageIpfsHash, "Meowdy", "Ragdoll", block.timestamp);
        _;
    }

    function test_transferCatToNewOwner() public {
        string memory catImageIpfsHash = "ipfs://QmbxwGgBGrNdXPm84kqYskmcMT3jrzBN8LzQjixvkz4c62";
        uint256 tokenId = kittyConnect.getTokenCounter();
        address newOwner = makeAddr("newOwner");

        // Shop Partner gives Cat to user
        vm.prank(partnerA);
        kittyConnect.mintCatToNewOwner(user, catImageIpfsHash, "Meowdy", "Ragdoll", block.timestamp);

        // Now user wants to transfer the cat to a new owner
        // first user approves the cat's token id to new owner
        vm.prank(user);
        kittyConnect.approve(newOwner, tokenId);

        // then the shop owner checks up with the new owner and confirms the transfer
        vm.expectEmit(false, false, false, true, address(kittyConnect));
        emit CatTransferredToNewOwner(user, newOwner, tokenId);
        vm.prank(partnerA);
        kittyConnect.safeTransferFrom(user, newOwner, tokenId);

        uint256[] memory newOwnerTokenIds = kittyConnect.getCatsTokenIdOwnedBy(newOwner);
        KittyConnect.CatInfo memory catInfo = kittyConnect.getCatInfo(tokenId);
        string memory tokenUri = kittyConnect.tokenURI(tokenId);
        console.log(tokenUri);


        assert(kittyConnect.getCatsTokenIdOwnedBy(user).length == 0);
        assert(newOwnerTokenIds.length == 1);
        assertEq(newOwnerTokenIds[0], tokenId);
        assertEq(catInfo.prevOwner[0], user);
    }

    function test_transferCatReverts_If_CallerIsNotAPartnerShop() public partnerGivesCatToOwner {
        uint256 tokenId = kittyConnect.getTokenCounter() - 1;
        address newOwner = makeAddr("newOwner");
        address notPartnerShop = makeAddr("notPartnerShop");

        vm.prank(user);
        kittyConnect.approve(newOwner, tokenId);

        vm.prank(notPartnerShop);
        vm.expectRevert("KittyConnect__NotAPartner");
        kittyConnect.safeTransferFrom(user, newOwner, tokenId);
    }

    function test_safetransferCatToNewOwner() public {
        string memory catImageIpfsHash = "ipfs://QmbxwGgBGrNdXPm84kqYskmcMT3jrzBN8LzQjixvkz4c62";
        uint256 tokenId = kittyConnect.getTokenCounter();
        address newOwner = makeAddr("newOwner");

        vm.prank(partnerA);
        kittyConnect.mintCatToNewOwner(user, catImageIpfsHash, "Meowdy", "Ragdoll", block.timestamp);

        vm.prank(user);
        kittyConnect.approve(newOwner, tokenId);

        vm.expectEmit(false, false, false, true, address(kittyConnect));
        emit CatTransferredToNewOwner(user, newOwner, tokenId);
        vm.prank(partnerA);
        kittyConnect.safeTransferFrom(user, newOwner, tokenId);

        assertEq(kittyConnect.ownerOf(tokenId), newOwner);
        assertEq(kittyConnect.getCatsTokenIdOwnedBy(user).length, 0);
        assertEq(kittyConnect.getCatsTokenIdOwnedBy(newOwner).length, 1);
        assertEq(kittyConnect.getCatsTokenIdOwnedBy(newOwner)[0], tokenId);
        assertEq(kittyConnect.getCatInfo(tokenId).prevOwner[0], user);
        assertEq(kittyConnect.getCatInfo(tokenId).prevOwner.length, 1);
        assertEq(kittyConnect.getCatInfo(tokenId).idx, 0);
    }

    // kittyBridge Tests
    function test_KittyBridgeConstructor() public {
        address mockLinkToken = 0x90193C961A926261B756D1E5bb255e67ff9498A1;

        assertEq(kittyBridge.getKittyConnectAddr(), address(kittyConnect));
        assertEq(kittyBridge.getGaslimit(), 400000);
        assertEq(kittyBridge.getLinkToken(), mockLinkToken);
    }

    function test_gasForCcipReceive() public {
        address sender = makeAddr("sender");
        bytes memory data = abi.encode(makeAddr("catOwner"), "meowdy", "ragdoll", "ipfs://QmbxwGgBGrNdXPm84kqYskmcMT3jrzBN8LzQjixvkz4c62", block.timestamp, partnerA);

        vm.prank(kittyConnectOwner);
        kittyBridge.allowlistSender(networkConfig.router, true);

        Client.Any2EVMMessage memory message = Client.Any2EVMMessage({
            messageId: bytes32(0),
            sourceChainSelector: networkConfig.otherChainSelector,
            sender: abi.encode(sender),
            data: data,
            destTokenAmounts: new Client.EVMTokenAmount[](0)
        });

        vm.prank(networkConfig.router);

        uint256 initGas = gasleft();
        kittyBridge.ccipReceive(message);

        uint256 finalGas = gasleft();

        uint256 gasUsed = initGas - finalGas;

        console.log("Gas Used -", gasUsed);
    }

    function test_allowlistSenderIsNotOwner() public {
        address sender = makeAddr("sender");

        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(sender);
        kittyBridge.allowlistSender(sender, true);
    }

    function test_allowlistSender() public {
        address sender = makeAddr("sender");

        vm.prank(kittyConnectOwner);
        kittyBridge.allowlistSender(sender, true);

        assert(kittyBridge.allowlistedSenders(sender) == true);
    }

    function test_allowlistDestinationChain() public {
        uint64 chainId = 1;

        vm.prank(kittyConnectOwner);
        kittyBridge.allowlistDestinationChain(chainId, true);

        assert(kittyBridge.allowlistedDestinationChains(chainId) == true);
    }

    function test_allowlistDestinationChainIsNotOwner() public {
        uint64 chainId = 1;
        address  attacker = makeAddr("attacker");   

        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(attacker);
        kittyBridge.allowlistDestinationChain(chainId, true);
    }

    function test_allowlistSourceChain() public {
        uint64 chainId = 1;

        vm.prank(kittyConnectOwner);
        kittyBridge.allowlistSourceChain(chainId, true);

        assert(kittyBridge.allowlistedSourceChains(chainId) == true);
    }

    function test_allowlistSourceChainRevertIfNotOwner() public {
        uint64 chainId = 1;
        address attacker = makeAddr("attacker");
        
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(attacker);
        kittyBridge.allowlistSourceChain(chainId, true);

    }

    function test_bridgeNftWithDataIfDestinationIsNotAllowlisted() public {
        address sender = makeAddr("sender");
        uint64 chainId = 1;
        bytes memory data = abi.encode(makeAddr("catOwner"), "meowdy", "ragdoll", "ipfs://QmbxwGgBGrNdXPm84kqYskmcMT3jrzBN8LzQjixvkz4c62", block.timestamp, partnerA);

        vm.expectRevert(abi.encodeWithSelector(KittyBridgeBase.KittyBridge__DestinationChainNotAllowlisted.selector, chainId));
        vm.prank(address(kittyConnect));
        kittyBridge.bridgeNftWithData(chainId, sender, data);
    }

    function test_updateGaslimit() public {
        uint256 newGaslimit = 500000;

        vm.prank(kittyConnectOwner);
        kittyBridge.updateGaslimit(newGaslimit);

        assertEq(kittyBridge.getGaslimit(), newGaslimit);
    }

    function test_updateGaslimitRevertIfNotOwner() public {
        uint256 newGaslimit = 500000;
        address attacker = makeAddr("attacker");

        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(attacker);
        kittyBridge.updateGaslimit(newGaslimit);
    }
}