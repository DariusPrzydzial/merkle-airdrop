// SPDX-Licence-Indentifier: MIT
pragma solidity ^0.8.24;

import { Script, console } from "forge-std/Script.sol";
import { DevOpsTools } from "foundry-devops/src/DevOpsTools.sol";
import { MerkleAirdrop } from "../src/MerkleAirdrop.sol";

contract ClaimAirdrop is Script {
    address private constant CLAIMING_ADDRESS = 0x8988b981ACA6889a2A0336BaFaaa7cc34898eb77;

    bytes32 private constant PROOF_1 = 0x0c7ef881bb675a5858617babe0eb12b538067e289d35d5b044ee76b79d335191;
    bytes32 private constant PROOF_2 = 0x81f0e530b56872b6fc3e10f8873804230663f8407e21cef901b8aeb06a25e5e2;
    bytes32 private constant PROOF_3 = 0x2aadccb0553b8c9968b78ca32bb891c1dd527eb553ff5b19aa35560e4757e5b0;

    bytes32[] private proof = [PROOF_1, PROOF_2, PROOF_3];
    
    uint256 private constant AMOUNT_TO_COLLECT = (25 * 1e18); // 25.000000

    // the signature will change every time you redeploy the airdrop contract!
    // see vm.sign funciton in test:signMessage
    // foundryup, anvil, make deploy
    // cast call 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "getMessageHash(address,uint256)" 0x8988b981ACA6889a2A0336BaFaaa7cc34898eb77 25000000000000000000 --rpc-url http://localhost:8545
    //   0x5018102f98385ff5bf80e5ed30b943b15e878e3f2e1912245c1be05d9dec5cd5
    // cast wallet sign --no-hash 0x5018102f98385ff5bf80e5ed30b943b15e878e3f2e1912245c1be05d9dec5cd5 --private-key 0xxxx
    //   0x982ab17d2df0b5d4584d256b17b17dd85da487da8c770198aaf207b1ba634af94e888460cab2324fbee60b606440649d6a5f6f3b0ceee7ce35c0eeb2baf03ae81b
    // ^^ first Anvil Private Key
    // tryRecover from OZ which does not require separate v r s
    // bytes private SIGNATURE = hex"fbd2270e6f23fb5fe9248480c0f4be8a4e9bd77c3ad0b1333cc60b5debc511602a2a06c24085d8d7c038bad84edc53664c8ce0346caeaa3570afec0e61144dc11c";
    bytes private SIGNATURE = hex"982ab17d2df0b5d4584d256b17b17dd85da487da8c770198aaf207b1ba634af94e888460cab2324fbee60b606440649d6a5f6f3b0ceee7ce35c0eeb2baf03ae81b";
    // ^^ first Anvil Private Key

    error __ClaimAirdropScript__InvalidSignatureLength();

    function claimAirdrop(address airdrop) public {
        vm.startBroadcast();
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(SIGNATURE);
        console.log("Claiming Airdrop");
        MerkleAirdrop(airdrop).claim(CLAIMING_ADDRESS, AMOUNT_TO_COLLECT, proof, v, r, s);
        vm.stopBroadcast();
        console.log("Claimed Airdrop");
    }

    function splitSignature(bytes memory sig) public pure returns (uint8 v, bytes32 r, bytes32 s) {
        if (sig.length != 65) {
            revert __ClaimAirdropScript__InvalidSignatureLength();
        }   
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("MerkleAirdrop", block.chainid);
        claimAirdrop(mostRecentlyDeployed);
    }
}

