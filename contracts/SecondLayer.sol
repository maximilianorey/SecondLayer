//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SecondLayer{
    uint256 public n;
    uint256 public m;
    uint256 public p;

    uint256 public firstRegister;
    uint256 public secondRegister;
    uint256 public control;

    mapping (address => uint256) public nonce;
    mapping (uint256 => uint256) public cell;

    constructor(uint256 n_, uint256 m_, uint256 p_){
        n = n_;
        m = m_;
        p = p_;

        firstRegister =1;
        secondRegister = 1;
        control = 1;
    }

    function getGenerator() public view returns (uint256){
        return uint256(uint160(msg.sender)) ** (nonce[msg.sender] + 1);
    }

    function deposit(uint256 fRegister,uint256 sRegister) payable public{
        require(fRegister!=0,"fRegister can not be zero");
        require(sRegister!=0,"sRegister can not be zero");
        uint256 nonceSender = nonce[msg.sender] + 1;
        uint256 generator = uint256(uint160(msg.sender)) ** nonceSender;
        nonce[msg.sender] = nonceSender;
        cell[generator] = msg.value;
        uint256 c = generator ** ((p-1)*(n-1)) % p;
        require(mulmod((fRegister ** m) , (sRegister ** n) ,p) == c, "INVALID CONDITION");
        firstRegister = mulmod(firstRegister, fRegister, p);
        secondRegister = mulmod(secondRegister, sRegister, p);
        control = c;
    }

    function saveBlock(uint256 fRegister,uint256 sRegister) public{
        require(fRegister!=0,"fRegister can not be zero");
        require(sRegister!=0,"sRegister can not be zero");
        uint256 newFirstRegister = mulmod(firstRegister, fRegister, p);
        uint256 newSecondRegister = mulmod(secondRegister, sRegister, p);
        require(mulmod((newFirstRegister ** m) , newSecondRegister ** n,p) == control, "INVALID CONDITION");
        firstRegister = newFirstRegister;
        secondRegister = newSecondRegister;
    }

    function withdrawal(uint256 generator,uint256 proof,uint256 v) public{
        require(proof!=0,"proof can not be zero");
        uint256 sRegister = secondRegister * proof;
        require(mulmod((firstRegister ** m) , (sRegister ** n),p) == control, "INVALID CONDITION");
        require(generator ** (v* uint256(uint160(msg.sender))) % p == proof, "NOT LINKED WITH SENDER");
        uint256 eth = cell[generator];
        require(eth!=0,"CELL ALREADY CLAIMED");
        cell[generator] = 0;
        payable(msg.sender).transfer(eth);
    }
}