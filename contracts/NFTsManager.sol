//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NFTsManager{
    uint256 public n;
    uint256 public m;
    uint256 public p;

    uint256 public firstRegister;
    uint256 public secondRegister;
    uint256 public control;

    mapping (address => uint256) public nonces;
    mapping (address => mapping (uint256 => uint256)) public erc721;

    constructor(uint256 n_, uint256 m_, uint256 p_){
        n = n_;
        m = m_;
        p = p_;

        firstRegister =1;
        secondRegister = 1;
        control = 1;
    }

    function modPow(uint256 x, uint256 y, uint256 mod) public pure returns (uint256){
        unchecked {
            /*// Initialize answer
            uint256 res = 1;
        
            // Check till the number becomes zero
            while (y > 0) {
        
                // If y is odd, multiply x with result
                if (y % 2 == 1)
                    res = (res * x);
        
                // y = y/2
                y = y >> 1;
        
                // Change x to x^2
                x = (x * x);
            }
            return res % mod;*/
            return (x ** y) % mod;
        }
    }

    function getGenerator(address dir) public view returns (uint256){
        unchecked{
            return (uint256(uint160(dir)) ** (nonces[dir] + 1)) % p;
        }
    }

    function deposit(address contractAddress, uint256 tokenId, uint256 fRegister,uint256 sRegister,uint256 gen) public{
        require(fRegister!=0,"fRegister can not be zero");
        require(sRegister!=0,"sRegister can not be zero");
        require(ERC721(contractAddress).ownerOf(tokenId)==msg.sender,"SENDER IS NOT OWNER");
        uint256 nonceSender = nonces[msg.sender] + 1;
        uint256 generator;
        unchecked {
            generator = modPow(uint256(uint160(msg.sender)) , nonceSender,p);            
        }
        require(generator!=0,"NULL GENERATOR");
        require(gen==generator,"BAD GENERATOR");
        nonces[msg.sender] = nonceSender;
        erc721[contractAddress][tokenId] = generator;
        uint256 c;
        uint256 operation;
        unchecked{
            c = generator;
            require(sRegister*c !=0,'PROBLEM0');
            require(modPow(sRegister * c, n,p)!=0,'PROBLEM1');
            require(modPow(fRegister, m,p)!=0,'PROBLEM2');
            operation = mulmod(modPow(fRegister, m,p) , modPow(sRegister * c, n,p) ,p);
        }
        require(operation == 1, Strings.toHexString(operation));
        unchecked {
            firstRegister = mulmod(firstRegister, fRegister, p);
            secondRegister = mulmod(secondRegister, sRegister, p);
            control = mulmod(control,c,p);   
        }
    }

    function saveBlock(uint256 fRegister,uint256 sRegister) public{
        require(fRegister!=0,"fRegister can not be zero");
        require(sRegister!=0,"sRegister can not be zero");
        uint256 newFirstRegister;
        uint256 newSecondRegister;
        unchecked{
            newFirstRegister = mulmod(firstRegister, fRegister, p);
            newSecondRegister = mulmod(secondRegister, sRegister, p);
        }
        uint256 operation;
        unchecked {
            operation = mulmod(modPow(newFirstRegister , m,p) , modPow(newSecondRegister*control,n,p),p);
        }
        require(operation== 1, "SAVE BLOCK: INVALID CONDITION");
        firstRegister = newFirstRegister;
        secondRegister = newSecondRegister;
    }

    function withdrawal(address contractAddress, uint256 tokenId,uint256 proof,uint256 v) public{
        require(proof!=0,"proof can not be zero");
        uint256 sRegister;
        unchecked {
            sRegister = secondRegister * proof;            
        }
        uint256 operation;
        unchecked {
            operation = mulmod((firstRegister ** m) , ((sRegister*control) ** n),p);
        }
        require(operation == 1, "INVALID CONDITION");
        uint256 generator = erc721[contractAddress][tokenId];
        require(generator!=0,"TOKEN ALREADY CLAIMED");
        unchecked {
            operation = generator ** (v* uint256(uint160(msg.sender))) % p;
        }
        require(operation == proof, "NOT LINKED WITH SENDER");
        ERC721 tokenContract = ERC721(contractAddress);
        require(tokenContract.ownerOf(tokenId)==address(this));
        erc721[contractAddress][tokenId] = 0;
        tokenContract.transferFrom(address(this), msg.sender, tokenId);
    }
}