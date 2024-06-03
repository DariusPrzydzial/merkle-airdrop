// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import { SignatureChecker } from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract MerkleAirdrop is EIP712{
    using ECDSA for bytes32;
    using SafeERC20 for IERC20; // why? prevent sending tokens to recipients who can’t receive

    error MerkleAirdrop__InvalidFeeAmount();
    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__TransferFailed();
    error MerkleAirdrop__AlreadyClaimed();
    error MerkleAirdrop__InvalidSignature();

    IERC20 private immutable i_airdropToken;
    bytes32 private immutable i_merkleRoot;
    mapping(address user => bool claimed) private s_hasClaimed;

    event Claimed(address account, uint256 amount);
    event MerkleRootUpdated(bytes32 newMerkleRoot);

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    constructor(bytes32 merkleRoot, IERC20 airdropToken) EIP712("Bagel Airdrop", "1.0.0") {
        i_merkleRoot = merkleRoot;
        i_airdropToken = airdropToken;
    }

    // claim the airdrop using a signature from the account owner
    function claim(address account, uint256 amount, bytes32[] calldata merkleProof, uint8 v, bytes32 r, bytes32 s) external {
        if (s_hasClaimed[account]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }

        // Verify the signature
        if (!_isValidSignature(account, _messageHash(account, amount), v, r, s)) {
            revert MerkleAirdrop__InvalidSignature();
        }

        // Verify the merkle proof
        // calculate the leaf node hash
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
        // verify the merkle proof (TODO: understand verify)
        if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }

        s_hasClaimed[account] = true; // prevent users claiming more than once and draining the contract
        emit Claimed(account, amount);
        // transfer the tokens
        i_airdropToken.safeTransfer(account, amount);
    }

    /*//////////////////////////////////////////////////////////////
                             VIEW AND PURE
    //////////////////////////////////////////////////////////////*/
    //why do I need this getter? -> cos it's a private variable
    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }

    function getAirdropToken() external view returns (IERC20) {
        return i_airdropToken;
    }

    /*//////////////////////////////////////////////////////////////
                             INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _getSigner(bytes32 digest, uint8 _v, bytes32 _r, bytes32 _s) internal pure returns (address) {
        (address signer, /*ECDSA.RecoverError recoverError*/, /*bytes32 signatureLength*/ ) =
            ECDSA.tryRecover(digest, _v, _r, _s);
        return signer;
    }

    // message we expect to have been signed
    function _messageHash(address account, uint256 amount)
    internal view returns (bytes32)
    {
        return _hashTypedDataV4(keccak256(abi.encode(
            keccak256("AirdropClaim(address account,uint256 amount)"),
            account,
            amount
        )));
    }

    function _isValidSignature(
        address signer, 
        bytes32 digest, 
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
    internal pure returns (bool)
    {
        // _getSigner is a function that returns the expected/calculated signer of the message whereas signature is the actual signer
        address actualSigner = _getSigner(digest, _v, _r, _s);
        return (actualSigner == signer);
    }

    // function _isValidSignature(
    //     uint256 message,
    //     uint8 _v,
    //     bytes32 _r,
    //     bytes32 _s,
    //     address signer // the account that is allowed in the merkle tree
    // )
    //     public
    //     pure
    //     returns (bool)
    // {
    //     // You can also use isValidSignatureNow
    //     address actualSigner = _getSigner(message, _v, _r, _s);
    //     return (actualSigner == signer); // verify the signer of the message is the account we wish to airdrop tokens to from the merkle tree
    // }

    // function _isValidSignature(address account, bytes32 hash, bytes memory signature) internal pure returns (bool) {
    //     bytes32 signedHash = MessageHashUtils.toEthSignedMessageHash(hash); //  NOTE: shouldnt i be using this????
    //     return signedHash.recover(signature) == account;
    // }

    
}