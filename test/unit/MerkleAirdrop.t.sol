// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MerkleAirdrop} from "../../src/MerkleAirdrop.sol";
import {BagelToken} from "../../src/BagelToken.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {DeployMerkleAirdrop} from "../../script/DeployMerkleAirdrop.s.sol";
import {ZkSyncChainChecker} from "foundry-devops/src/ZkSyncChainChecker.sol";

contract MerkleAirdropTest is ZkSyncChainChecker, Test {
    MerkleAirdrop airdrop;
    BagelToken token;
    address gasPayer;
    address user;
    uint256 userPrivKey;
    
    bytes32 merkleRoot = 0xe88f0682889d167f4164f41fa53dc37d084f9cd5152ee4f448a3a9bd02150bfa;
    uint256 amountToCollect = (25 * 1e18); // 25.000000
    uint256 amountToSend = amountToCollect * 5;

    bytes32 proof1 = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 proof2 = 0x2079861289cee6299e8f18bc008dd72a261c2c1391a54b96701d561c0f89e325;
    bytes32 proof3 = 0x2aadccb0553b8c9968b78ca32bb891c1dd527eb553ff5b19aa35560e4757e5b0;
    bytes32[] proof = [proof1, proof2, proof3];

    bytes32 proofU1 = 0x0c7ef881bb675a5858617babe0eb12b538067e289d35d5b044ee76b79d335191;
    bytes32 proofU2 = 0x81f0e530b56872b6fc3e10f8873804230663f8407e21cef901b8aeb06a25e5e2;
    bytes32 proofU3 = 0x2aadccb0553b8c9968b78ca32bb891c1dd527eb553ff5b19aa35560e4757e5b0;

    bytes32[] proofU = [proofU1, proofU2, proofU3];

    function setUp() public {
        if (!isZkSyncChain()) {
            DeployMerkleAirdrop deployer = new DeployMerkleAirdrop();
            (airdrop, token) = deployer.deployMerkleAirdrop();
        } else {
            token = new BagelToken();
            airdrop = new MerkleAirdrop(merkleRoot, token);
            token.mint(token.owner(), amountToSend);
            token.transfer(address(airdrop), amountToSend);
        }
        gasPayer = makeAddr("gasPayer");
        (user, userPrivKey) = makeAddrAndKey("user");
    }

    function signMessage(uint256 privKey, address account) public view returns (uint8 v, bytes32 r, bytes32 s) {
        bytes32 hashedMessage = airdrop.getMessageHash(account, amountToCollect);
        (v, r, s) = vm.sign(privKey, hashedMessage);
    }

    function testUsersCanClaim() public {
        console.log("User address: %s", user);
        uint256 startingBalance = token.balanceOf(user);

        // get the signature
        vm.startPrank(user);
        (uint8 v, bytes32 r, bytes32 s) = signMessage(userPrivKey, user);
        vm.stopPrank();

        // gasPayer claims the airdrop for the user
        vm.prank(gasPayer);
        airdrop.claim(user, amountToCollect, proof, v, r, s);
        uint256 endingBalance = token.balanceOf(user);
        console.log("Ending balance: %d", endingBalance);
        assertEq(endingBalance - startingBalance, amountToCollect);
    }
    function testUserSelfClaim() public {
        address user2 = vm.envAddress("ADDRESS");
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        console.log("User address: %s", user2);
        uint256 startingBalance = token.balanceOf(user2);
        console.log("User balance: %d", startingBalance);

        // get the signature
        vm.startPrank(user2);
        (uint8 v, bytes32 r, bytes32 s) = signMessage(privateKey, user2);
        vm.stopPrank();

        // gasPayer claims the airdrop for the user
        vm.prank(user2);
        airdrop.claim(user2, amountToCollect, proofU, v, r, s);
        uint256 endingBalance = token.balanceOf(user2);
        console.log("Ending balance: %d", endingBalance);
        assertEq(endingBalance - startingBalance, amountToCollect);
    }
}
