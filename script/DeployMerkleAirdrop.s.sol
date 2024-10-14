// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { MerkleAirdrop, IERC20 } from "../src/MerkleAirdrop.sol";
import { Script } from "forge-std/Script.sol";
import { BagelToken } from "../src/BagelToken.sol";
import { console } from "forge-std/console.sol";

contract DeployMerkleAirdrop is Script {
    bytes32 public s_merkleRoot = 0xe88f0682889d167f4164f41fa53dc37d084f9cd5152ee4f448a3a9bd02150bfa;
    // 5 users, 25 Bagel tokens each
    uint256 public s_amountToTransfer = 5 * (25 * 1e18);

    // Deploy the airdrop contract and bagel token contract
    function deployMerkleAirdrop() public returns (MerkleAirdrop, BagelToken) {
        vm.startBroadcast();
        BagelToken bagelToken = new BagelToken();
        MerkleAirdrop airdrop = new MerkleAirdrop(s_merkleRoot, IERC20(bagelToken));
        // Send Bagel tokens -> Merkle Air Drop contract
        bagelToken.mint(bagelToken.owner(), s_amountToTransfer);
        IERC20(bagelToken).transfer(address(airdrop), s_amountToTransfer);
        vm.stopBroadcast();
        return (airdrop, bagelToken);
    }

    function run() external returns (MerkleAirdrop, BagelToken) {
        return deployMerkleAirdrop();
    }
}
