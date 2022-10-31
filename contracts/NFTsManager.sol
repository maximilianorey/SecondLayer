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

    function modPow(uint256 x, uint256 y, uint256 modu) public pure returns (uint256){
        unchecked {
            // Initialize answer
            uint256 res = 1;
        
            // Check till the number becomes zero
            while (y > 0) {
        
                // If y is odd, multiply x with result
                if (y % 2 == 1)
                    res = mulmod(res , x,modu);
        
                // y = y/2
                y = y >> 1;
        
                // Change x to x^2
                x = mulmod(x , x,modu);
            }
            return res % modu;
        }
        /*unchecked {     
            return (x ** y) % modu;
        }*/
    }

    function getGenerator(address dir) public view returns (uint256){
        unchecked{
            return(uint256(uint160(dir)) * 2 - 1) ** (nonces[dir] + 1);
        }
    }

    function getControl() public view returns(uint256){
        return control;
    }

    function getFRegister() public view returns(uint256){
        return firstRegister;
    }

    function getSRegister() public view returns(uint256){
        return secondRegister;
    }

    function deposit(address contractAddress, uint256 tokenId, uint256 fRegister,uint256 sRegister) public{
        require(fRegister!=0,"fRegister can not be zero");
        require(sRegister!=0,"sRegister can not be zero");
        uint256 nonceSender = nonces[msg.sender] + 1;
        uint256 generator;
        require(ERC721(contractAddress).ownerOf(tokenId)==msg.sender);
        unchecked {
            //generator = 1152345668272086887389084172046127027068235407060;
            generator = (uint256(uint160(msg.sender)) * 2 - 1) ** nonceSender;
        }
        require(generator!=0,"NULL GENERATOR");
        nonces[msg.sender] = nonceSender;
        erc721[contractAddress][tokenId] = generator;
        uint256 c;
        uint256 operation;
        unchecked{
            c = generator;
            uint256 op1 = modPow(fRegister, m,p);
            uint256 op2 = mulmod(modPow(sRegister, n,p),modPow(c, n,p),p);
            require(sRegister*c !=0,'PROBLEM0');
            //require(op1==check1,string(abi.encodePacked("fRegister: EXPECTED: ",Strings.toString(check1), " OBTAIN: ",Strings.toString(op1))));
            //require(op2==check2,string(abi.encodePacked("sREGISTER: EXPECTED: ",Strings.toString(check2), " OBTAIN: ",Strings.toString(op2))));
            operation = mulmod(op1 , op2 ,p);
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
            uint256 op1 = modPow(newFirstRegister , m,p);
            uint256 op2 = modPow(newSecondRegister * control, n,p);
            operation = mulmod(op1 , op2,p);
        }
        require(operation== 1, string(abi.encodePacked("SAVE BLOCK, OPERATION: ",Strings.toString(operation))));
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